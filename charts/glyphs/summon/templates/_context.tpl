{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

DEPRECATED: This approach was wrong. Use standard glyph pattern instead:
- $root := index . 0 
- $glyphDefinition := index . 1
- Access $glyphDefinition data directly, don't merge contexts
*/}}

{{/*
summon.getName gets the appropriate name for summon resources
Supports both direct usage and glyph parameter patterns

Parameters:
- Direct usage: . (root context) 
- Glyph usage: (list $root $glyphDefinition)

Returns: Resource name (glyphDefinition.name takes priority over common.name)
*/}}
{{- define "summon.getName" -}}
{{- if kindIs "slice" . -}}
  {{- $root := index . 0 -}}
  {{- $glyphDefinition := index . 1 -}}
  {{- default (include "common.name" $root) $glyphDefinition.name -}}
{{- else -}}
  {{- include "common.name" . -}}
{{- end -}}
{{- end -}}