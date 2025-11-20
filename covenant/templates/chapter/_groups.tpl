{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

Covenant Chapter - Groups
Generates KeycloakGroup resources for chapters and chapels
*/}}

{{- define "covenant.chapter.groups" -}}
{{- $root := . -}}
{{- $covenant := .Values.covenant -}}
{{- $bookPath := default .Release.Name .Values.name -}}
{{- if $covenant.chapterFilter }}
  {{- $bookPath = trimSuffix (printf "-%s" $covenant.chapterFilter) $bookPath -}}
{{- end }}
{{- $chapterFilter := $covenant.chapterFilter -}}
{{- $covenantIndex := include "covenant.scanCovenantIndex" . | fromYaml -}}
{{- $finalRealm := $covenantIndex.realm -}}
{{- $realmRef := printf "realm-%s" (required "covenant realm.name is required" $finalRealm.name) -}}
{{- $keycloakGlyphs := dict -}}

{{/* Get chapter index */}}
{{- $chapterIndex := include "covenant.scanChapterIndex" (list . $chapterFilter) | fromYaml -}}

{{/* Generate group for chapter (area) */}}
{{- $chapterGroupKey := printf "area-%s" $chapterFilter -}}
{{- $_ := set $keycloakGlyphs $chapterGroupKey (dict
  "type" "group"
  "name" $chapterFilter
  "realmRef" $realmRef
  "realmRoles" (default list $chapterIndex.realmRoles)
) }}

{{/* Generate groups for chapels */}}
{{- $members := include "covenant.scanChapterMembers" (list . $chapterFilter) | fromJson -}}
{{- $chapels := dict -}}

{{/* Collect unique chapels from members */}}
{{- range $memberKey, $member := $members }}
  {{- if $member.chapel }}
    {{- $chapelKey := printf "%s/%s" $chapterFilter $member.chapel -}}
    {{- if not (hasKey $chapels $chapelKey) }}
      {{- $_ := set $chapels $chapelKey (dict "name" $member.chapel "chapter" $chapterFilter) -}}
    {{- end }}
  {{- end }}
{{- end }}

{{/* Generate group for each chapel */}}
{{- range $chapelKey, $chapel := $chapels }}
{{- $groupGlyphKey := printf "chapel-%s" ($chapelKey | replace "/" "-") -}}
{{- $_ := set $keycloakGlyphs $groupGlyphKey (dict
  "type" "group"
  "name" ($chapelKey | replace "/" "-")
  "scopeName" $chapelKey
  "realmRef" $realmRef
) }}
{{- end }}

{{/* Render keycloak glyphs */}}
{{- range $glyphName, $glyph := $keycloakGlyphs }}
  {{- $glyphWithName := merge $glyph (dict "name" $glyphName) }}
  {{- if eq $glyph.type "group" }}
    {{- include "keycloak.group" (list $root $glyphWithName) }}
  {{- end }}
{{- end }}

{{- end -}}
