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
{{- $ctx := . -}}
{{- $resourceName := include "common.name" . -}}
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: {{ $resourceName }}
  labels:
    {{- include "common.labels" $ctx | nindent 4}}
  annotations:
    {{- include "common.annotations" $ctx | nindent 4}}
spec:
  replicas: {{ default 1 $ctx.Values.workload.replicas }}
  selector:
    matchLabels:
      {{- include "common.selectorLabels" $ctx | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "common.selectorLabels" $ctx | nindent 8 }}
    spec:
      serviceAccountName: {{ include "common.serviceAccountName" $ctx }}
      initContainers:
        {{- if $ctx.Values.initContainers }}
        {{- include "summon.common.container" (list $ctx $ctx.Values.initContainers ) | nindent 8 }}
        {{- end }}
      containers:
        {{- if $ctx.Values.sideCars }}
        {{- include "summon.common.container" (list $ctx $ctx.Values.sideCars ) | nindent 8 }}
        {{- end }}
        #main Container
        {{- include "summon.common.container" (list $ctx (list $ctx.Values) ) | nindent 8  }}
        {{- with $ctx.Values.nodeSelector }}
      nodeSelector:
          {{- toYaml . | nindent 8 }}
        {{- end }}
        {{- with $ctx.Values.affinity }}
      affinity:
          {{- toYaml . | nindent 8 }}
        {{- end }}
        {{- with $ctx.Values.tolerations }}
      tolerations:
          {{- toYaml . | nindent 8 }}
        {{- end }}
        {{- with $ctx.Values.imagePullSecrets }}
      imagePullSecrets:
          {{- toYaml . | nindent 8 }}
        {{- end }}

      {{- include "summon.common.volumes" $ctx |nindent 6 }}
  volumeClaimTemplates:
  {{- range $name, $volume := $ctx.Values.volumes }}
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