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
{{- range $glyphName, $currentGlyph := $glyphs -}}
  {{/* Ensure .name exists (use dict key if missing) */}}
  {{- if not (hasKey $currentGlyph "name") -}}
    {{- $_ := set $currentGlyph "name" $glyphName -}}
  {{- end -}}
  {{- if eq $currentGlyph.type $type -}}
    {{/* Check if ALL selectors match (AND logic) */}}
    {{- $allSelectorsMatch := true -}}
    {{- range $selector, $value := $selectors -}}
      {{- if not (and (hasKey $currentGlyph.labels $selector) (eq (index $currentGlyph.labels $selector) $value)) -}}
        {{- $allSelectorsMatch = false -}}
      {{- end -}}
    {{- end -}}
    {{/* Only add to results if selectors exist AND ALL selectors matched */}}
    {{- if and (gt (len $selectors) 0) $allSelectorsMatch -}}
      {{- $results = append $results $currentGlyph -}}
    {{- end -}}
    {{- if and (hasKey $currentGlyph.labels "default") (eq (len $results) 0) -}}
      {{- if eq (index $currentGlyph.labels "default") "book" -}}
        {{- $bookDefault = append $bookDefault $currentGlyph -}}
      {{- else if and (eq $currentGlyph.chapter $chapter) (eq (index $currentGlyph.labels "default") "chapter") -}}
        {{- $chapterDefault = append $chapterDefault $currentGlyph -}}
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