{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

Covenant Chapter - Users
Generates KeycloakUser resources for members
*/}}

{{- define "covenant.chapter.users" -}}
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

{{/* Get chapter index for defaults */}}
{{- $chapterIndex := include "covenant.scanChapterIndex" (list . $chapterFilter) | fromYaml -}}

{{/* Scan chapter members */}}
{{- $members := include "covenant.scanChapterMembers" (list . $chapterFilter) | fromJson -}}

{{/* Generate users for members */}}
{{- range $memberKey, $member := $members }}
{{- $userGlyphKey := $memberKey | replace "/" "-" -}}

{{/* Auto-generate username and email from firstName.lastName@emailDomain (lastName optional) */}}
{{- $baseUsername := "" -}}
{{- if $member.overrideUsername }}
  {{- $baseUsername = $member.overrideUsername -}}
{{- else if $member.lastName }}
  {{- $baseUsername = printf "%s.%s" ($member.firstName | lower) ($member.lastName | lower) -}}
{{- else }}
  {{- $baseUsername = $member.firstName | lower -}}
{{- end }}
{{- $generatedUsername := printf "%s@%s" $baseUsername $finalRealm.emailDomain -}}

{{/* Auto-assign groups if not specified */}}
{{- $groups := $member.groups -}}
{{- if not $groups }}
  {{- $chapelKey := printf "%s/%s" $chapterFilter $member.chapel -}}
  {{- $groups = list $chapelKey $chapterFilter -}}
{{- end }}

{{/* Generate user */}}
{{- $_ := set $keycloakGlyphs $userGlyphKey (dict
  "type" "user"
  "realmRef" $realmRef
  "username" $generatedUsername
  "email" $generatedUsername
  "firstName" (default "" $member.firstName)
  "lastName" (default "" $member.lastName)
  "enabled" (ne (default "active" $member.status) "suspended")
  "emailVerified" (default true $member.emailVerified)
  "groups" $groups
  "realmRoles" (default list $member.realmRoles)
) }}
{{- end }}

{{/* Render keycloak glyphs */}}
{{- range $glyphName, $glyph := $keycloakGlyphs }}
  {{- $glyphWithName := merge $glyph (dict "name" $glyphName) }}
  {{- if eq $glyph.type "user" }}
    {{- include "keycloak.user" (list $root $glyphWithName) }}
  {{- end }}
{{- end }}

{{- end -}}
