{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
 */}}
{{- define "common.secrets" -}}
  {{- range $name, $content := .Values.secrets }}
    {{- if eq $content.location "create" }}
---
apiVersion: v1
kind: Secret
metadata:
  name: {{ (default $name $content.name) |  replace "." "-" }}
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

