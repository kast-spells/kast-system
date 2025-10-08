{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
*/}}
{{- define "runicIndexer.runicIndexer" -}}
{{- $glyphs := index . 0 -}}
{{- $selectors := index . 1 -}}
{{- $type := index . 2 -}}
{{- $chapter := index . 3 -}}
{{- $results := list -}}
{{- $bookDefault := list -}}
{{- $chapterDefault := list -}}

{{/* Dictionary format - iterate over key/value pairs */}}
{{- range $glyphName, $currrentGlyph := $glyphs -}}
  {{/* Ensure .name exists (use dict key if missing) */}}
  {{- if not (hasKey $currrentGlyph "name") -}}
    {{- $_ := set $currrentGlyph "name" $glyphName -}}
  {{- end -}}
  {{- if eq $currrentGlyph.type $type -}}
    {{/* Check if ALL selectors match (AND logic) */}}
    {{- $allSelectorsMatch := true -}}
    {{- range $selector, $value := $selectors -}}
      {{- if not (and (hasKey $currrentGlyph.labels $selector) (eq (index $currrentGlyph.labels $selector) $value)) -}}
        {{- $allSelectorsMatch = false -}}
      {{- end -}}
    {{- end -}}
    {{/* Only add to results if ALL selectors matched */}}
    {{- if $allSelectorsMatch -}}
      {{- $results = append $results $currrentGlyph -}}
    {{- end -}}
    {{- if and (hasKey $currrentGlyph.labels "default") (eq (len $results) 0) -}}
      {{- if eq (index $currrentGlyph.labels "default") "book" -}}
        {{- $bookDefault = append $bookDefault $currrentGlyph -}}
      {{- else if and (eq $currrentGlyph.chapter $chapter) (eq (index $currrentGlyph.labels "default") "chapter") -}}
        {{- $chapterDefault = append $chapterDefault $currrentGlyph -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- if (eq (len $results) 0) -}}
  {{- if (eq (len $chapterDefault) 0) -}}
    {{- $results = $bookDefault -}}
  {{- else -}}
    {{- $results = $chapterDefault -}}
  {{- end -}}
{{- end -}}
{{- dict "results" $results | toJson -}}
{{- end -}}