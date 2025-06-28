{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
 */}}
{{- define "summon.pvc" }}
{{- $root := index . 0 }}
{{- $glyphDefinition := index . 1 }}
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {{ default $glyphDefinition.name (print (include "common.name" $root) "-pvc") | replace "." "-" }}
  labels:
    {{- include "common.labels" $root | nindent 4 }}
    {{- with $glyphDefinition.definition.labels }}
    {{ toYaml . | indent 4 }}
    {{- end }}
  annotations:
    {{- include "common.annotations" $root | nindent 4 }}
    {{- with $glyphDefinition.definition.annotations }}
    {{ toYaml . | indent 4 }}
    {{- end }}
spec:
  {{- with $glyphDefinition.definition.storageClassName }}
  storageClassName: {{ . }}
  {{- end }}
  accessModes:
    - {{ default "ReadWriteOnce" $glyphDefinition.definition.accessMode }}
  resources:
    requests:
      storage: {{ default "1Gi" $glyphDefinition.definition.size }}
{{- end }}