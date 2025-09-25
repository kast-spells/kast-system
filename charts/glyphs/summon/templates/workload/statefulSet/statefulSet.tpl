{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

summon.workload.statefulset creates StatefulSet resources for summon workloads  
Supports both direct usage and glyph parameter pattern

Parameters:
- Direct usage: . (root context)
- Glyph usage: (list $root $glyphDefinition)
 */}}
{{- define "summon.workload.statefulset" -}}
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
  {{- if not $root.Values.autoscaling.enabled }}
  replicas: {{ default 1 $root.Values.workload.replicas }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "common.selectorLabels" $root | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "common.selectorLabels" $root | nindent 8 }}
      annotations:
        {{- include "summon.checksums.annotations" $root | nindent 8 }}
    spec:
      serviceAccountName: {{ include "common.serviceAccountName" $root }}
      {{- with $root.Values.securityContext }}
      securityContext:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- if $root.Values.initContainers }}
      initContainers:
        {{- include "summon.common.container" (list $root $root.Values.initContainers ) | nindent 8 }}
      {{- end }}
      containers:
        {{- if $root.Values.sideCars }}
        {{- include "summon.common.container" (list $root $root.Values.sideCars ) | nindent 8 }}
        {{- end }}
        #main Container
        {{- include "summon.common.container" (list $root (list $root.Values) ) | nindent 8  }}
        {{- with $root.Values.nodeSelector }}
      nodeSelector:
          {{- toYaml . | nindent 8 }}
        {{- end }}
        {{- with $root.Values.affinity }}
      affinity:
          {{- toYaml . | nindent 8 }}
        {{- end }}
        {{- with $root.Values.tolerations }}
      tolerations:
          {{- toYaml . | nindent 8 }}
        {{- end }}
        {{- with $root.Values.imagePullSecrets }}
      imagePullSecrets:
          {{- toYaml . | nindent 8 }}
        {{- end }}

        {{- include "summon.common.volumes" $root |nindent 6 }}
  {{- if $root.Values.workload.volumeClaimTemplates }}
  volumeClaimTemplates:
  {{- range $name, $volume := $root.Values.workload.volumeClaimTemplates }}
    - metadata:
        name: {{ $name }}
      spec:
        {{- if $volume.storageClassName }}
        storageClassName: {{ $volume.storageClassName }}
        {{- end }}
        accessModes:
          - {{ default "ReadWriteOnce" $volume.accessModes }}
        resources:
          requests:
            storage: {{ $volume.size }}
  {{- end -}}
  {{- end -}}          
{{- end -}}
##TODO faltan volumenes