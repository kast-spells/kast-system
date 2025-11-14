{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
*/}}

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
{{- with $root.Values.securityContext }}
securityContext:
  {{- toYaml . | nindent 2 }}
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
  {{- include "summon.common.container" (list $root (list $root.Values) ) | nindent 2  }}
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
{{- with $root.Values.securityContext }}
securityContext:
  {{- toYaml . | nindent 2 }}
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
  {{- include "summon.common.container" (list $root (list $root.Values) ) | nindent 2  }}
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
