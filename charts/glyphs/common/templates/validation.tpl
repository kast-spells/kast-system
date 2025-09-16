{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

common.validateGlyphParameters validates standard glyph parameters and sets defaults.
Ensures consistent parameter structure across all glyphs.

Parameters:
- $root: Chart root context (index . 0)
- $glyphDefinition: Glyph configuration object (index . 1)

Returns: Validated and normalized glyph definition with defaults applied

Usage: {{- $glyph := include "common.validateGlyphParameters" (list $root $glyphDefinition) | fromYaml }}
*/}}
{{- define "common.validateGlyphParameters" -}}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1 -}}
{{- if not $glyphDefinition -}}
  {{- fail "Glyph definition is required" -}}
{{- end -}}
{{- if not (hasKey $glyphDefinition "name") -}}
  {{- $_ := set $glyphDefinition "name" (include "common.name" $root) -}}
{{- end -}}
{{- if not (hasKey $glyphDefinition "enabled") -}}
  {{- $_ := set $glyphDefinition "enabled" true -}}
{{- end -}}
{{- $glyphDefinition | toYaml -}}
{{- end -}}

{{/*
common.extractGlyphParameters extracts and validates the standard glyph parameter pattern.
Standardizes the (list $root $glyphDefinition) parameter extraction.

Parameters:
- .: Template context received as (list $root $glyphDefinition)

Returns: Dictionary with validated root and glyphDefinition

Usage: 
{{- $params := include "common.extractGlyphParameters" . | fromYaml }}
{{- $root := $params.root }}
{{- $glyphDefinition := $params.glyphDefinition }}
*/}}
{{- define "common.extractGlyphParameters" -}}
{{- if not (kindIs "slice" .) -}}
  {{- fail "Parameters must be passed as (list $root $glyphDefinition)" -}}
{{- end -}}
{{- if lt (len .) 2 -}}
  {{- fail "Both $root and $glyphDefinition parameters are required" -}}
{{- end -}}
root: {{ index . 0 | toYaml | nindent 2 }}
glyphDefinition: {{ index . 1 | toYaml | nindent 2 }}
{{- end -}}