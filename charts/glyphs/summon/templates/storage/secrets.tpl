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
{{- $contentType := default "file" $glyphDefinition.definition.contentType }}
{{- if eq $contentType "env" }}
  {{/* Para contentType: env, crear cada key-value como entrada separada en el Secret */}}
  {{- if kindIs "map" $glyphDefinition.definition.content }}
  {{- range $key, $value := $glyphDefinition.definition.content }}
  {{ $key }}: {{ $value | quote }}
  {{- end }}
  {{- else }}
  {{/* Si contentType: env pero content es string, crear una sola entrada */}}
  {{ (default $glyphDefinition.name $glyphDefinition.definition.name) |  replace "." "-" }}: {{ $glyphDefinition.definition.content | quote }}
  {{- end }}
  {{- else }}
  {{/* Para otros tipos (file, yaml, json, toml), crear una sola entrada con el contenido formateado */}}
  {{ (default $glyphDefinition.name $glyphDefinition.definition.name) |  replace "." "-" }}: |
  {{- if eq $contentType "yaml" }}
    {{- $glyphDefinition.definition.content | toYaml | nindent 4 }}
  {{- else if eq $contentType "json" }}
    {{- $glyphDefinition.definition.content | toJson | nindent 4 }}
  {{- else if eq $contentType "toml" }}
    {{- $glyphDefinition.definition.content | toToml | nindent 4 }}
  {{- else }}
    {{/* Para contentType: file o default, usar content tal cual si es string, o convertir a YAML si es map */}}
    {{- if kindIs "map" $glyphDefinition.definition.content }}
      {{- $glyphDefinition.definition.content | toYaml | nindent 4 }}
    {{- else }}
      {{- $glyphDefinition.definition.content | nindent 4 }}
    {{- end }}
  {{- end }}
  {{- end }}
{{- end }}
