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
    {{- include "common.labels" $root | nindent 4}}
  annotations:
    {{- include "common.annotations" $root | nindent 4}}
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
          {{- with $root.Values.securityContext }}
          securityContext:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- if $root.Values.initContainers }}
          initContainers:
            {{- include "summon.common.container" (list $root $root.Values.initContainers ) | nindent 12 }}
          {{- end }}
          containers:
            {{- if $root.Values.sideCars }}
            {{- include "summon.common.container" (list $root $root.Values.sideCars ) | nindent 12 }}
            {{- end }}
            #main Container
            {{- include "summon.common.container" (list $root (list $root.Values) ) | nindent 12  }}
          {{- with $root.Values.nodeSelector }}
          nodeSelector:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with $root.Values.affinity }}
          affinity:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with $root.Values.tolerations }}
          tolerations:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with $root.Values.imagePullSecrets }}
          imagePullSecrets:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- include "summon.common.volumes" $root |nindent 10 }}
{{- end -}}