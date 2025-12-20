{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
*/}}

{{/*
summon.podSecurityContext filters securityContext to only include pod-level valid fields.
Container-level fields (capabilities, privileged, etc.) are excluded.

Pod-level valid fields:
- runAsUser, runAsGroup, runAsNonRoot
- fsGroup, fsGroupChangePolicy
- seccompProfile, seLinuxOptions
- supplementalGroups, sysctls
- windowsOptions

Parameters:
  $securityContext - The securityContext dictionary

Returns: Filtered securityContext with only pod-level fields
*/}}
{{- define "summon.podSecurityContext" -}}
{{- $ctx := . -}}
{{- $podFields := dict -}}
{{- $validPodFields := list "runAsUser" "runAsGroup" "runAsNonRoot" "fsGroup" "fsGroupChangePolicy" "seccompProfile" "seLinuxOptions" "supplementalGroups" "sysctls" "windowsOptions" -}}
{{- range $key, $value := $ctx -}}
  {{- if has $key $validPodFields -}}
    {{- $_ := set $podFields $key $value -}}
  {{- end -}}
{{- end -}}
{{- if $podFields -}}
  {{- toYaml $podFields -}}
{{- end -}}
{{- end -}}

{{/*
summon.common.podSpec generates the common pod specification shared by all workload types.
Used by: Deployment, StatefulSet, Job, CronJob, DaemonSet

Parameters:
  $root - Root context (.)

Returns: Pod spec YAML (lines 30-62 from deployment.tpl)

Usage:
  {{- include "summon.common.podSpec" $root | nindent 6 }}
*/}}
{{- define "summon.common.podSpec" -}}
{{- $root := . -}}
serviceAccountName: {{ include "common.serviceAccountName" $root }}
{{- with $root.Values.runtimeClassName }}
runtimeClassName: {{ . }}
{{- end }}
{{- with $root.Values.securityContext }}
{{- $podSecCtx := include "summon.podSecurityContext" . | fromYaml }}
{{- if $podSecCtx }}
securityContext:
  {{- toYaml $podSecCtx | nindent 2 }}
{{- end }}
{{- end }}
{{- if $root.Values.initContainers }}
initContainers:
  {{- include "summon.common.container" (list $root $root.Values.initContainers ) | nindent 2 }}
{{- end }}
containers:
  {{- if $root.Values.sideCars }}
  {{- include "summon.common.container" (list $root $root.Values.sideCars ) | nindent 2 }}
  {{- end }}
  #main Container
  {{- if $root.Values.containers }}
  {{- include "summon.common.container" (list $root $root.Values.containers ) | nindent 2  }}
  {{- else }}
  {{- include "summon.common.container" (list $root (list $root.Values) ) | nindent 2  }}
  {{- end }}
  {{- with $root.Values.nodeSelector }}
nodeSelector:
    {{- toYaml . | nindent 2 }}
  {{- end }}
  {{- with $root.Values.affinity }}
affinity:
    {{- toYaml . | nindent 2 }}
  {{- end }}
  {{- with $root.Values.tolerations }}
tolerations:
    {{- toYaml . | nindent 2 }}
  {{- end }}
  {{- with $root.Values.imagePullSecrets }}
imagePullSecrets:
    {{- toYaml . | nindent 2 }}
  {{- end }}

  {{- include "summon.common.volumes" $root |nindent 0 }}
{{- end -}}

{{/*
summon.common.podSpec.body generates the pod specification body (without serviceAccountName).
Used by: Job, CronJob (which need to insert restartPolicy before this section)

Parameters:
  $root - Root context (.)

Returns: Pod spec YAML starting from securityContext (excludes serviceAccountName)

Usage:
  {{- include "summon.common.podSpec.body" $root | nindent 8 }}
*/}}
{{- define "summon.common.podSpec.body" -}}
{{- $root := . -}}
{{- with $root.Values.runtimeClassName }}
runtimeClassName: {{ . }}
{{- end }}
{{- with $root.Values.securityContext }}
{{- $podSecCtx := include "summon.podSecurityContext" . | fromYaml }}
{{- if $podSecCtx }}
securityContext:
  {{- toYaml $podSecCtx | nindent 2 }}
{{- end }}
{{- end }}
{{- if $root.Values.initContainers }}
initContainers:
  {{- include "summon.common.container" (list $root $root.Values.initContainers ) | nindent 2 }}
{{- end }}
containers:
  {{- if $root.Values.sideCars }}
  {{- include "summon.common.container" (list $root $root.Values.sideCars ) | nindent 2 }}
  {{- end }}
  #main Container
  {{- if $root.Values.containers }}
  {{- include "summon.common.container" (list $root $root.Values.containers ) | nindent 2  }}
  {{- else }}
  {{- include "summon.common.container" (list $root (list $root.Values) ) | nindent 2  }}
  {{- end }}
  {{- with $root.Values.nodeSelector }}
nodeSelector:
    {{- toYaml . | nindent 2 }}
  {{- end }}
  {{- with $root.Values.affinity }}
affinity:
    {{- toYaml . | nindent 2 }}
  {{- end }}
  {{- with $root.Values.tolerations }}
tolerations:
    {{- toYaml . | nindent 2 }}
  {{- end }}
  {{- with $root.Values.imagePullSecrets }}
imagePullSecrets:
    {{- toYaml . | nindent 2 }}
  {{- end }}

  {{- include "summon.common.volumes" $root |nindent 0 }}
{{- end -}}
