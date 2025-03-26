{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
 */}}
{{- define "summon.workload.deployment" -}}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "common.name" . }}
  labels:
    {{- include "common.labels" . | nindent 4}}
  annotations:
    {{- include "common.annotations" . | nindent 4}}
spec:
  {{- if not .Values.autoscaling.enabled }}
  replicas: {{ default 1 .Values.workload.replicas }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "common.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "common.selectorLabels" . | nindent 8 }}
    spec:
      serviceAccountName: {{ include "common.serviceAccountName" . }}
      {{- with .Values.securityContext }}
      securityContext:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- if .Values.initContainers }}
      initContainers:
        {{- include "summon.common.container" (list . .Values.initContainers ) | nindent 8 }}
      {{- end }}
      containers:
        {{- if .Values.sideCars }}
        {{- include "summon.common.container" (list . .Values.sideCars ) | nindent 8 }}
        {{- end }}
        #main Container
        {{- include "summon.common.container" (list . (list .Values) ) | nindent 8  }}
        {{- with .Values.nodeSelector }}
      nodeSelector:
          {{- toYaml . | nindent 8 }}
        {{- end }}
        {{- with .Values.affinity }}
      affinity:
          {{- toYaml . | nindent 8 }}
        {{- end }}
        {{- with .Values.tolerations }}
      tolerations:
          {{- toYaml . | nindent 8 }}
        {{- end }}
        {{- with .Values.imagePullSecrets }}
      imagePullSecrets:
          {{- toYaml . | nindent 8 }}
        {{- end }}

        {{- include "summon.common.volumes" . |nindent 6 }}
{{- end -}}

##TODO faltan los volumenes