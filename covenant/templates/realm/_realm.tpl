{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

Covenant Realm - KeycloakRealm Resource
Generates KeycloakRealm and stalwart-admin secret for post-provisioning
*/}}

{{- define "covenant.realm.keycloakRealm" -}}
{{- $root := . -}}
{{- $bookPath := default .Release.Name .Values.name -}}
{{- $covenantIndex := include "covenant.scanCovenantIndex" . | fromYaml -}}
{{- $finalRealm := $covenantIndex.realm -}}
{{- $keycloakGlyphs := dict -}}
{{- $vaultGlyphs := dict -}}

{{- if $finalRealm }}

{{/* Get Keycloak instance from lexicon */}}
{{- $chapterName := "" -}}
{{- $chapterLabels := dict -}}
{{- if $root.Values.chapter }}
  {{- $chapterName = $root.Values.chapter.name -}}
  {{- $chapterLabels = dict "chapter" $chapterName -}}
{{- end }}
{{- $keycloakInstances := get (include "runicIndexer.runicIndexer" (list $root.Values.lexicon $chapterLabels "keycloak" $chapterName) | fromJson) "results" -}}
{{- $keycloakInstance := dict -}}
{{- range $keycloakInstances }}
  {{- $keycloakInstance = . -}}
{{- end }}
{{- $keycloakRef := required "keycloakInstance.keycloakCrdName is required in lexicon" $keycloakInstance.keycloakCrdName -}}

{{/* Generate stalwart-admin VaultSecret in keycloak namespace (shared across all chapters) */}}
{{/* This reads stalwart-admin from book path: /spellbook/book/publics/stalwart-admin */}}
{{/* Needed by post-provisioning jobs to authenticate to Stalwart REST API */}}
{{/* IMPORTANT: Only generate in main covenant (not chapterFilter), as it's a shared resource */}}
{{/* Path: "book" = /spellbook/book/publics/* accessible by covenant (read) and stalwart (write) */}}
{{- $stalwartAdminKey := "stalwart-admin" -}}
{{- $_ := set $vaultGlyphs $stalwartAdminKey (dict
  "type" "vaultSecret"
  "name" "stalwart-admin"
  "namespace" .Release.Namespace
  "format" "plain"
  "randomKey" "password"
  "random" false
  "path" "book"
  "private" "admintools"
) }}

{{/* Generate KeycloakRealm resource */}}
{{- $realmKey := print "realm-" (default "kast" $finalRealm.name) -}}
{{- $_ := set $keycloakGlyphs $realmKey (dict
  "type" "realm"
  "realmName" (default "kast" $finalRealm.name)
  "displayName" (default "Kast Organization" $finalRealm.displayName)
  "keycloakRef" (default $keycloakRef $finalRealm.keycloakRef)
  "enabled" (default true $finalRealm.enabled)
  "passwordPolicy" $finalRealm.passwordPolicy
  "themes" $finalRealm.themes
  "eventConfig" $finalRealm.eventConfig
  "tokenSettings" $finalRealm.tokenSettings
  "sslRequired" $finalRealm.sslRequired
) }}

{{/* Render vault glyphs */}}
{{- range $glyphName, $glyph := $vaultGlyphs }}
  {{- $glyphWithName := merge $glyph (dict "name" $glyphName) }}
  {{- if eq $glyph.type "vaultSecret" }}
    {{- include "vault.vaultSecret" (list $root $glyphWithName) }}
  {{- end }}
{{- end }}

{{/* Render keycloak glyphs */}}
{{- range $glyphName, $glyph := $keycloakGlyphs }}
  {{- $glyphWithName := merge $glyph (dict "name" $glyphName) }}
  {{- if eq $glyph.type "realm" }}
    {{- include "keycloak.realm" (list $root $glyphWithName) }}
  {{- end }}
{{- end }}

{{- end }}
{{- end -}}
