{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
 */}}
{{- define "common.secrets" -}}
  {{- range $name, $content := .Values.secrets }}
    {{- if eq $content.location "create" }}
---
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "common.name" $ }}-{{ (default $name $content.name) |  replace "." "-" }}
data:
  {{ (default $name $content.name) |  replace "." "-" }}: |
  {{- if eq $content.contentType "yaml" }}
    {{- $content.content | toYaml | nindent 4 }}
  {{- else if eq $content.contentType "json" }}
    {{- $content.content | toJson | nindent 4 }}
  {{- else }}
    {{- $content.content |  nindent 4 }}
    {{- end }}
  {{- end }}
  {{- end }}
{{- end }}

