{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
 */}}
{{- define "summon.cronjob" -}}
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: {{ include "common.name" . }}
  labels:
{{- include "common.labels" . | nindent 2}}
  annotations:
{{- include "common.annotations" . | nindent 2}}
spec:
  schedule: {{ .Values.workload.schedule | quote }}
  jobTemplate:
    spec:
      template:
        metadata:
          labels:
            app: {{ include "common.name" . }}
            run: {{  .Release.Namespace }}
            app.kubernetes.io/name: {{ include "common.name" . }}
        spec:
          serviceAccountName: {{ include "common.serviceAccountName" . }}
          initContainers:
          {{- if .Values.initContainers }}
          {{- include "summon.container" (list . .Values.initContainers ) | nindent 12 }}
          {{- end }}
          containers:
          {{- if .Values.sideCars }}
          {{- include "summon.container" (list . .Values.sideCars ) | nindent 12 }}
          {{- end }}
          {{- include "summon.container" (list . .Values  ) | nindent 12  }}
          {{- with .nodeSelector }}
          nodeSelector:
            {{- toYaml . | nindent 8 }}
          {{- end }}
          {{- with .affinity }}
          affinity:
            {{- toYaml . | nindent 8 }}
          {{- end }}
          {{- with .tolerations }}
          tolerations:
            {{- toYaml . | nindent 8 }}
          {{- end }}
          {{- with .Values.imagePullSecrets }}
          imagePullSecrets:
            {{- toYaml . | nindent 8 }}
          {{- end }}
          {{- if .podSecurityContext }}
          securityContext:
            {{- toYaml .podSecurityContext | nindent 8 }}
          {{- end }}
          {{- include "summon.common.volumes" . | nindent 10 }}
{{- end -}}

#TODO faltan los volumenes