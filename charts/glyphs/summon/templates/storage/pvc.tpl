{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

summon.persistentVolumeClaim creates PersistentVolumeClaim resources for volumes defined with type "pvc".
Automatically iterates through all volumes in .Values.volumes and creates PVCs for applicable ones.

Parameters:
- $root: Chart root context (accessed as . in the template)
- Reads .Values.volumes directly from root context

Volume Configuration:
- volume.type: must be "pvc" to generate PVC
- volume.name: optional custom PVC name (defaults to {chart-name}-{volume-key})
- volume.size: required storage size (e.g., "10Gi")
- volume.storageClassName: optional storage class
- volume.accessMode: optional access mode (defaults to "ReadWriteOnce")
- volume.labels: optional additional labels
- volume.annotations: optional additional annotations

Usage: 
- Direct: {{- include "summon.persistentVolumeClaim" . }}
- Glyph: {{- include "summon.persistentVolumeClaim.glyph" (list $root $glyphDefinition) }}
*/}}

{{/* Glyph-compatible PVC template that supports glyphDefinition.name */}}
{{- define "summon.persistentVolumeClaim.glyph" -}}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1 -}}
{{- $baseName := default (include "common.name" $root) $glyphDefinition.name -}}
  {{- range $name, $volume := $glyphDefinition.volumes }}
    {{- if and (eq $volume.type "pvc") (not $volume.stateClaimTemplate) }}
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  {{- $pvcName := "" }}
  {{- if $volume.name }}
    {{- $pvcName = $volume.name }}
  {{- else }}
    {{- $pvcName = print $baseName "-" $name }}
  {{- end }}
  name: {{ $pvcName }}
  labels:
    {{- include "common.labels" $root | nindent 4}}
    {{- with $volume.labels }}
    {{ toYaml . | nindent 4 }}
    {{- end }}
  annotations:
    {{- include "common.annotations" $root | nindent 4}}
    {{- with $volume.annotations }}
    {{ toYaml . | nindent 4 }}
    {{- end }}
spec:
  {{- if $volume.storageClassName }}
  storageClassName: {{ $volume.storageClassName }}
  {{- end }}
  accessModes: 
    - {{ default "ReadWriteOnce" $volume.accessMode }}
  resources:
    requests:
      storage: {{ $volume.size }}
{{- end }}
{{- end }}
{{- end }}

{{/* Original PVC template for direct summon usage */}}
{{- define "summon.persistentVolumeClaim" -}}
  {{- range $name, $volume := .Values.volumes }}
    {{- if and (eq $volume.type "pvc") (not $volume.stateClaimTemplate) }}
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  {{- $pvcName := "" }}
  {{- if $volume.name }}
    {{- $pvcName = $volume.name }}
  {{- else }}
    {{- $pvcName = print (include "common.name" $ ) "-" $name }}
  {{- end }}
  name: {{ $pvcName }}
  labels:
    {{- include "common.labels" $ | nindent 4}}
    {{- with $volume.labels }}
    {{ toYaml . | nindent 4 }}
    {{- end }}
  annotations:
    {{- include "common.annotations" $ | nindent 4}}
    {{- with $volume.annotations }}
    {{ toYaml . | nindent 4 }}
    {{- end }}
spec:
  {{- if $volume.storageClassName }}
  storageClassName: {{ $volume.storageClassName }}
  {{- end }}
  accessModes: 
    - {{ default "ReadWriteOnce" $volume.accessMode }}
  resources:
    requests:
      storage: {{ $volume.size }}
{{- end }}
{{- end }}
{{- end }}