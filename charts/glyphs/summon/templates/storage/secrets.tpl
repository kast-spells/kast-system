{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
 */}}
{{- define "summon.secrets" }}
{{- $root := index . 0 }}
{{- $glyphDefinition := index . 1}}
---
kind: Secret
apiVersion: v1
metadata:
  name: {{ (default $glyphDefinition.name $glyphDefinition.definition.name) |  replace "." "-" }}
stringData:
  {{ (default $glyphDefinition.name $glyphDefinition.definition.name) |  replace "." "-" }}: |
  {{- if eq $glyphDefinition.definition.contentType "yaml" }}
    {{- $glyphDefinition.definition.content | toYaml | nindent 4 }}
  {{- else if eq $glyphDefinition.definition.contentType "json" }}
    {{- $glyphDefinition.definition.content | toJson | nindent 4 }}
  {{- else if eq $glyphDefinition.definition.contentType "toml" }}
    {{- $glyphDefinition.definition.content | toToml | nindent 4 }}
  {{- else if eq $glyphDefinition.definition.type "env" }}
    {{/* Si type: env y content es un map, convertir a YAML automáticamente */}}
    {{- if kindIs "map" $glyphDefinition.definition.content }}
      {{- $glyphDefinition.definition.content | toYaml | nindent 4 }}
    {{- else }}
      {{- $glyphDefinition.definition.content | nindent 4 }}
    {{- end }}
  {{- else }}
    {{/* Para otros casos, usar content tal cual si es string, o convertir a YAML si es map */}}
    {{- if kindIs "map" $glyphDefinition.definition.content }}
      {{- $glyphDefinition.definition.content | toYaml | nindent 4 }}
    {{- else }}
      {{- $glyphDefinition.definition.content | nindent 4 }}
    {{- end }}
  {{- end }}
{{- end }}
