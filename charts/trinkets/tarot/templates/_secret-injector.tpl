{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

Secret and Environment Variable Injection Templates
Handles secret mounting and environment variable injection for workflow containers
*/}}

{{/*
Inject environment variables into container spec
Parameters: (list $root $container $cardSecrets $cardEnvs)
Returns: Environment variable array
*/}}
{{- define "tarot.injectEnvironmentVars" -}}
{{- $root := index . 0 -}}
{{- $container := index . 1 -}}
{{- $cardSecrets := index . 2 | default dict -}}
{{- $cardEnvs := index . 3 | default dict -}}

{{/* Merge environment variables: global -> card-specific */}}
{{- $allEnvs := merge ($root.Values.envs | default dict) $cardEnvs -}}

{{/* Generate environment variable list */}}
{{- $envVars := list -}}

{{/* Add regular environment variables */}}
{{- range $envName, $envValue := $allEnvs -}}
  {{- $resolvedValue := include "tarot.resolveValue" (list $root $envValue) -}}
  {{- $envVar := dict "name" $envName "value" $resolvedValue -}}
  {{- $envVars = append $envVars $envVar -}}
{{- end -}}

{{/* Add secret-based environment variables */}}
{{- $allSecrets := merge ($root.Values.secrets | default dict) $cardSecrets -}}
{{- range $secretName, $secretDef := $allSecrets -}}
  {{- if $secretDef.keys -}}
    {{- range $secretDef.keys -}}
      {{- $envVar := dict "name" (printf "%s_%s" ($secretName | upper) (. | upper)) -}}
      {{- $envVar = set $envVar "valueFrom" (dict "secretKeyRef" (dict "name" (include "tarot.getSecretName" (list $root $secretDef)) "key" .)) -}}
      {{- $envVars = append $envVars $envVar -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/* Add any existing environment variables from container definition */}}
{{- if $container.env -}}
  {{- $envVars = concat $envVars $container.env -}}
{{- end -}}

{{- if gt (len $envVars) 0 -}}
{{- $envVars | toYaml -}}
{{- else -}}
[]
{{- end -}}
{{- end -}}

{{/*
Inject volume mounts into container spec
Parameters: (list $root $container $cardSecrets $cardVolumes)
Returns: Volume mounts array
*/}}
{{- define "tarot.injectVolumeMounts" -}}
{{- $root := index . 0 -}}
{{- $container := index . 1 -}}
{{- $cardSecrets := index . 2 | default dict -}}
{{- $cardVolumes := index . 3 | default list -}}

{{- $volumeMounts := list -}}

{{/* Add volume mounts from card volumes */}}
{{- range $cardVolumes -}}
  {{- if .mountPath -}}
    {{- $volumeMount := dict "name" .name "mountPath" .mountPath -}}
    {{- if .subPath -}}
      {{- $volumeMount = set $volumeMount "subPath" .subPath -}}
    {{- end -}}
    {{- if .readOnly -}}
      {{- $volumeMount = set $volumeMount "readOnly" .readOnly -}}
    {{- end -}}
    {{- $volumeMounts = append $volumeMounts $volumeMount -}}
  {{- end -}}
{{- end -}}

{{/* Add secret mounts */}}
{{- $allSecrets := merge ($root.Values.secrets | default dict) $cardSecrets -}}
{{- range $secretName, $secretDef := $allSecrets -}}
  {{- if $secretDef.mount -}}
    {{- $volumeMount := dict "name" (printf "%s-secret" $secretName) "mountPath" $secretDef.mount -}}
    {{- if $secretDef.defaultMode -}}
      {{- $volumeMount = set $volumeMount "defaultMode" $secretDef.defaultMode -}}
    {{- end -}}
    {{- $volumeMounts = append $volumeMounts $volumeMount -}}
  {{- end -}}
{{- end -}}

{{/* Add any existing volume mounts from container definition */}}
{{- if $container.volumeMounts -}}
  {{- $volumeMounts = concat $volumeMounts $container.volumeMounts -}}
{{- end -}}

{{- if gt (len $volumeMounts) 0 -}}
{{- $volumeMounts | toYaml -}}
{{- else -}}
[]
{{- end -}}
{{- end -}}

{{/*
Generate volumes for workflow spec using summon volume patterns
Parameters: (list $root $allCards)
Returns: Volumes array
*/}}
{{- define "tarot.generateVolumes" -}}
{{- $root := index . 0 -}}
{{- $allCards := index . 1 -}}

{{/* Build summon-compatible volume definition from all cards */}}
{{- $summonVolumes := dict -}}
{{- $volumeNames := list -}}

{{/* Collect all volumes from cards following summon patterns */}}
{{- range $cardName, $cardDef := $allCards -}}
  {{- if $cardDef.volumes -}}
    {{- range $cardDef.volumes -}}
      {{- if not (has .name $volumeNames) -}}
        {{- $summonVolumes = set $summonVolumes .name . -}}
        {{- $volumeNames = append $volumeNames .name -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/* Create summon-compatible context and generate volumes */}}
{{- $summonContext := deepCopy $root -}}
{{- $_ := set $summonContext.Values "volumes" $summonVolumes -}}

{{/* Collect secrets for secret volumes */}}
{{- $allSecrets := merge ($root.Values.secrets | default dict) -}}
{{- range $cardName, $cardDef := $allCards -}}
  {{- if $cardDef.secrets -}}
    {{- $allSecrets = merge $allSecrets $cardDef.secrets -}}
  {{- end -}}
{{- end -}}
{{- $_ := set $summonContext.Values "secrets" $allSecrets -}}

{{/* Use summon volume glyph to generate volume definitions */}}
{{- $volumeOutput := include "summon.common.volumes.volumes" $summonContext -}}

{{/* Generate secret volumes manually since summon handles them differently */}}
{{- $secretVolumes := list -}}
{{- range $secretName, $secretDef := $allSecrets -}}
  {{- if $secretDef.mount -}}
    {{- $volumeName := printf "%s-secret" $secretName -}}
    {{- if not (has $volumeName $volumeNames) -}}
      {{- $volume := dict "name" $volumeName -}}
      {{- $secretVolume := dict "secretName" (include "tarot.getSecretName" (list $root $secretDef)) -}}
      {{- if $secretDef.defaultMode -}}
        {{- $secretVolume = set $secretVolume "defaultMode" $secretDef.defaultMode -}}
      {{- end -}}
      {{- $volume = set $volume "secret" $secretVolume -}}
      {{- $secretVolumes = append $secretVolumes $volume -}}
      {{- $volumeNames = append $volumeNames $volumeName -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/* Combine summon-generated volumes with secret volumes */}}
{{- if $volumeOutput -}}
{{- $volumeOutput | nindent 0 }}
{{- end -}}
{{- if $secretVolumes -}}
{{- $secretVolumes | toYaml -}}
{{- end -}}
{{- end -}}

{{/*
Merge secrets from multiple sources
Parameters: (list $globalSecrets $cardSecrets)
Returns: Merged secrets dictionary
*/}}
{{- define "tarot.mergeSecrets" -}}
{{- $globalSecrets := index . 0 | default dict -}}
{{- $cardSecrets := index . 1 | default dict -}}
{{- merge $globalSecrets $cardSecrets | toJson -}}
{{- end -}}

{{/*
Merge environment variables from multiple sources
Parameters: (list $globalEnvs $cardEnvs)
Returns: Merged environment variables dictionary
*/}}
{{- define "tarot.mergeEnvs" -}}
{{- $globalEnvs := index . 0 | default dict -}}
{{- $cardEnvs := index . 1 | default dict -}}
{{- merge $globalEnvs $cardEnvs | toJson -}}
{{- end -}}

{{/*
Generate PVC resources using summon PVC glyph
Parameters: (list $root $allCards)
Returns: PVC resource definitions for volumes with type "pvc"
*/}}
{{- define "tarot.generatePVCResources" -}}
{{- $root := index . 0 -}}
{{- $allCards := index . 1 -}}

{{/* Collect all volumes that need PVCs */}}
{{- $pvcVolumes := dict -}}
{{- range $cardName, $cardDef := $allCards -}}
  {{- if $cardDef.volumes -}}
    {{- range $cardDef.volumes -}}
      {{- if eq .type "pvc" -}}
        {{- $pvcVolumes = set $pvcVolumes .name . -}}
      {{- else if eq .type "persistentVolumeClaim" -}}
        {{/* Support both "pvc" and "persistentVolumeClaim" types */}}
        {{- $pvcVolumes = set $pvcVolumes .name . -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/* Generate PVC resources using summon glyph for each volume */}}
{{- range $volumeName, $volumeDef := $pvcVolumes -}}
  {{- $pvcDef := dict -}}
  {{- $pvcDef = set $pvcDef "name" $volumeName -}}
  {{- $pvcDef = set $pvcDef "size" ($volumeDef.size | default "1Gi") -}}
  {{- if $volumeDef.storageClassName -}}
    {{- $pvcDef = set $pvcDef "storageClassName" $volumeDef.storageClassName -}}
  {{- end -}}
  {{- if $volumeDef.accessMode -}}
    {{- $pvcDef = set $pvcDef "accessMode" $volumeDef.accessMode -}}
  {{- end -}}
  {{- if $volumeDef.labels -}}
    {{- $pvcDef = set $pvcDef "labels" $volumeDef.labels -}}
  {{- end -}}
  {{- if $volumeDef.annotations -}}
    {{- $pvcDef = set $pvcDef "annotations" $volumeDef.annotations -}}
  {{- end -}}

  {{/* Use summon PVC glyph to generate the PVC resource */}}
  {{- include "summon.persistentVolumeClaim.glyph" (list $root $pvcDef) }}

{{- end -}}
{{- end -}}

{{/*
Generate secret resources - creates ExternalSecret for vault integration
Parameters: (list $root $allSecrets)
Returns: ExternalSecret resource definitions for vault integration
*/}}
{{- define "tarot.generateSecretResources" -}}
{{- $root := index . 0 -}}
{{- $allSecrets := index . 1 -}}

{{/* Convert tarot secrets to vault glyph format */}}
{{- $vaultSecrets := list -}}
{{- range $secretName, $secretDef := $allSecrets -}}
  {{- if eq $secretDef.type "vault-secret" -}}
    {{/* Convert tarot vault-secret format to vault glyph format */}}
    {{- $vaultGlyphSecret := dict -}}
    {{- $vaultGlyphSecret = set $vaultGlyphSecret "type" "secret" -}}
    {{- $vaultGlyphSecret = set $vaultGlyphSecret "name" $secretName -}}
    {{- $vaultGlyphSecret = set $vaultGlyphSecret "format" "plain" -}}
    {{- $vaultGlyphSecret = set $vaultGlyphSecret "keys" $secretDef.keys -}}
    {{/* Convert absolute path to vault glyph path format */}}
    {{- if hasPrefix "secret/" $secretDef.path -}}
      {{- $vaultGlyphSecret = set $vaultGlyphSecret "path" (trimPrefix "secret/" $secretDef.path) -}}
    {{- else -}}
      {{- $vaultGlyphSecret = set $vaultGlyphSecret "path" $secretDef.path -}}
    {{- end -}}
    {{- $vaultSecrets = append $vaultSecrets $vaultGlyphSecret -}}
  {{- end -}}
{{- end -}}

{{/* Generate vault secrets using vault glyph */}}
{{- if $vaultSecrets -}}
  {{- range $vaultSecret := $vaultSecrets -}}
    {{- include "vault.secret" (list $root $vaultSecret) -}}
  {{- end -}}
{{- end -}}

{{/* Generate k8s secrets directly (vault glyph doesn't handle these) */}}
{{- range $secretName, $secretDef := $allSecrets -}}
  {{- if eq $secretDef.type "k8s-secret" -}}
    {{/* Generate standard Kubernetes Secret */}}
---
apiVersion: v1
kind: Secret
metadata:
  name: {{ $secretDef.name }}
  labels:
    {{- include "tarot.labels" $root | nindent 4 }}
type: Opaque
# Note: K8s secret data would need to be provided externally

  {{- end -}}
{{- end -}}
{{- end -}}