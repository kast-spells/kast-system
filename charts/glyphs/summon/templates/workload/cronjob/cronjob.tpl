{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
 */}}
{{- define "summon.workload.cronjob" -}}
{{- $root := . -}}
---
apiVersion: batch/v1
kind: CronJob
metadata:
  name: {{ include "common.name" $root }}
  labels:
    {{- include "common.all.labels" $root | nindent 4 }}
    {{- with $root.Values.workload.labels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- with $root.Values.workload.annotations }}
  annotations:
    {{- include "common.annotations" $root | nindent 4 }}
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  schedule: {{ $root.Values.workload.schedule | quote }}
  {{- if $root.Values.workload.concurrencyPolicy }}
  concurrencyPolicy: {{ $root.Values.workload.concurrencyPolicy }}
  {{- end }}
  {{- if $root.Values.workload.successfulJobsHistoryLimit }}
  successfulJobsHistoryLimit: {{ $root.Values.workload.successfulJobsHistoryLimit }}
  {{- end }}
  {{- if $root.Values.workload.failedJobsHistoryLimit }}
  failedJobsHistoryLimit: {{ $root.Values.workload.failedJobsHistoryLimit }}
  {{- end }}
  jobTemplate:
    spec:
      {{- if $root.Values.workload.backoffLimit }}
      backoffLimit: {{ $root.Values.workload.backoffLimit }}
      {{- end }}
      {{- if $root.Values.workload.activeDeadlineSeconds }}
      activeDeadlineSeconds: {{ $root.Values.workload.activeDeadlineSeconds }}
      {{- end }}
      template:
        metadata:
          labels:
            {{- include "common.selectorLabels" $root | nindent 12 }}
          annotations:
            {{- include "summon.checksums.annotations" $root | nindent 12 }}
        spec:
          serviceAccountName: {{ include "common.serviceAccountName" $root }}
          {{- if $root.Values.workload.restartPolicy }}
          restartPolicy: {{ $root.Values.workload.restartPolicy }}
          {{- else }}
          restartPolicy: OnFailure
          {{- end }}
          {{- include "summon.common.podSpec.body" $root | nindent 10 }}
{{- end -}}
