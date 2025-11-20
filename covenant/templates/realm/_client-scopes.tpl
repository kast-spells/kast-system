{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

Covenant Realm - Client Scopes
Generates custom OIDC client scopes from realm/client-scopes/*.yaml
*/}}

{{- define "covenant.realm.clientScopes" -}}
{{- $root := . -}}
{{- $covenantIndex := include "covenant.scanCovenantIndex" . | fromYaml -}}
{{- $finalRealm := $covenantIndex.realm -}}
{{- $realmRef := printf "realm-%s" (required "covenant realm.name is required" $finalRealm.name) -}}
{{- $keycloakGlyphs := dict -}}

{{/* Scan client scopes from realm/client-scopes/*.yaml */}}
{{- $scopes := include "covenant.scanRealmClientScopes" . | fromJson -}}

{{/* Generate client scopes */}}
{{- range $scopeName, $scopeDef := $scopes }}
{{- $scopeKey := printf "scope-%s" $scopeName -}}
{{- $_ := set $keycloakGlyphs $scopeKey (dict
  "type" "clientScope"
  "realmRef" $realmRef
  "scopeName" $scopeName
  "description" $scopeDef.description
  "protocol" (default "openid-connect" $scopeDef.protocol)
  "default" (default false $scopeDef.default)
  "protocolMappers" $scopeDef.protocolMappers
) }}
{{- end }}

{{/* Render keycloak glyphs */}}
{{- range $glyphName, $glyph := $keycloakGlyphs }}
  {{- $glyphWithName := merge $glyph (dict "name" $glyphName) }}
  {{- if eq $glyph.type "clientScope" }}
    {{- include "keycloak.clientScope" (list $root $glyphWithName) }}
  {{- end }}
{{- end }}

{{- end -}}
