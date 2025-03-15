{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
 */}}
{{- define "common.workload.statefulset" -}}
{{- $root := . -}}
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: {{ include "common.name" $root }}
  labels:
    {{- include "common.labels" $root | nindent 4}}
  annotations:
    {{- include "common.annotations" $root | nindent 4}}
spec:
  replicas: {{ default 1 .Values.workload.replicas }}
  selector:
    matchLabels:
      {{- include "common.selectorLabels" $root | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "common.selectorLabels" $root | nindent 8 }}
    spec:
      serviceAccountName: {{ include "common.serviceAccountName" $root }}
      initContainers:
        {{- if .Values.initContainers }}
        {{- include "common.container" (list $root .Values.initContainers ) | nindent 8 }}
        {{- end }}
      containers:
        {{- if .Values.sideCars }}
        {{- include "common.container" (list $root .Values.sideCars ) | nindent 8 }}
        {{- end }}
        #main Container
        {{- include "common.container" (list $root (list .Values) ) | nindent 8  }}
        {{- with .Values.nodeSelector }}
      nodeSelector:
          {{- toYaml $root | nindent 8 }}
        {{- end }}
        {{- with .Values.affinity }}
      affinity:
          {{- toYaml $root | nindent 8 }}
        {{- end }}
        {{- with .Values.tolerations }}
      tolerations:
          {{- toYaml $root | nindent 8 }}
        {{- end }}
        {{- with .Values.imagePullSecrets }}
      imagePullSecrets:
          {{- toYaml $root | nindent 8 }}
        {{- end }}

        {{- include "common.volumes" $root |nindent 6 }}
  volumeClaimTemplates:
  {{- range $name, $volume := .Values.volumes }}
    {{- if eq $volume.type "claimTemplates" }}
    - metadata:
        name: {{ $name }}
      spec:
        {{- if $volume.storageClassName }}
        storageClassName: {{ $volume.storageClassName }}
        {{- end }}
        accessModes: 
          - {{ default "ReadWriteOnce" $volume.accessMode }}
        resources:
          requests:
            storage: {{ $volume.size }}
    {{- end -}}
  {{- end -}}          
{{- end -}}
##TODO faltan volumenes