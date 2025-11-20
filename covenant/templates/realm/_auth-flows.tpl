{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

Covenant Realm - Authentication Flows
Generates authentication flows from realm/auth-flows/*.yaml
*/}}

{{- define "covenant.realm.authFlows" -}}
{{- $root := . -}}
{{- $covenantIndex := include "covenant.scanCovenantIndex" . | fromYaml -}}
{{- $finalRealm := $covenantIndex.realm -}}
{{- $realmRef := printf "realm-%s" (required "covenant realm.name is required" $finalRealm.name) -}}
{{- $keycloakGlyphs := dict -}}

{{/* Scan auth flows from realm/auth-flows/*.yaml */}}
{{- $flows := include "covenant.scanRealmAuthFlows" . | fromJson -}}

{{/* Generate authentication flows */}}
{{- range $flowName, $flowDef := $flows }}
{{- $flowKey := printf "flow-%s" $flowName -}}
{{- $_ := set $keycloakGlyphs $flowKey (dict
  "type" "flow"
  "realmRef" $realmRef
  "alias" $flowName
  "builtIn" (default false $flowDef.builtIn)
  "providerId" (default "basic-flow" $flowDef.providerId)
  "topLevel" (default true $flowDef.topLevel)
  "authenticationExecutions" $flowDef.authenticationExecutions
) }}
{{- end }}

{{/* Render keycloak glyphs */}}
{{- range $glyphName, $glyph := $keycloakGlyphs }}
  {{- $glyphWithName := merge $glyph (dict "name" $glyphName) }}
  {{- if eq $glyph.type "flow" }}
    {{- include "keycloak.authenticationFlow" (list $root $glyphWithName) }}
  {{- end }}
{{- end }}

{{- end -}}
