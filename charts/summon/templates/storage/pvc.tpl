{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
 */}}
{{- define "common.persistanteVolumeClaim" -}}
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
    {{ toYaml . | indent 4 }}
    {{- end }}
  annotations:
    {{- include "common.annotations" $ | nindent 4}}
    {{- with $volume.annotations }}
    {{ toYaml . | indent 4 }}
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