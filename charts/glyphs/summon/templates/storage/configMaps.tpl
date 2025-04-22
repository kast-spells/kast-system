{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
 */}}
{{- define "summon.configMap" }}
{{- $root := index . 0 }}
{{- $glyphDefinition := index . 1}}
---
kind: ConfigMap
apiVersion: v1
metadata:
  name: {{ (default $glyphDefinition.name ) |  replace "." "-" }}
data:
  {{ (default $glyphDefinition.name ) |  replace "." "-" }}: |
  {{- if eq $glyphDefinition.contentType "yaml" }}
    {{- $glyphDefinition.content | toYaml | nindent 4 }}
  {{- else if eq $glyphDefinition.contentType "json" }}
    {{- $glyphDefinition.content | toJson | nindent 4 }}
  {{- else }}
    {{- $glyphDefinition.content |  nindent 4 }}
  {{- end }}
{{- end }}

