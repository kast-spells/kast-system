{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

Covenant Realm - Identity Providers
Generates identity providers from realm/idps/*.yaml
*/}}

{{- define "covenant.realm.idps" -}}
{{- $root := . -}}
{{- $bookPath := default .Release.Name .Values.name -}}
{{- $fullName := $bookPath -}}
{{- $covenantIndex := include "covenant.scanCovenantIndex" . | fromYaml -}}
{{- $finalRealm := $covenantIndex.realm -}}
{{- $realmRef := printf "realm-%s" (required "covenant realm.name is required" $finalRealm.name) -}}
{{- $keycloakGlyphs := dict -}}
{{- $vaultGlyphs := dict -}}

{{/* Scan identity providers from realm/idps/*.yaml */}}
{{- $idps := include "covenant.scanRealmIDPs" . | fromJson -}}

{{/* Generate identity providers */}}
{{- range $idpName, $idpDef := $idps }}
{{- $idpKey := printf "idp-%s" $idpName -}}
{{- $_ := set $keycloakGlyphs $idpKey (dict
  "type" "idp"
  "realmRef" $realmRef
  "alias" $idpName
  "providerId" $idpDef.providerId
  "displayName" $idpDef.displayName
  "enabled" (default true $idpDef.enabled)
  "trustEmail" (default true $idpDef.trustEmail)
  "storeToken" (default true $idpDef.storeToken)
  "linkOnly" $idpDef.linkOnly
  "firstBrokerLoginFlowAlias" $idpDef.firstBrokerLoginFlowAlias
  "postBrokerLoginFlowAlias" $idpDef.postBrokerLoginFlowAlias
  "config" $idpDef.config
) }}

{{/* Generate Vault secret for IDP client_secret if configured */}}
{{- if $idpDef.secret }}
{{- $secretKey := printf "secret-%s-idp" $idpName -}}
{{- $_ := set $vaultGlyphs $secretKey (dict
  "type" "vaultSecret"
  "name" $idpDef.secret
  "randomKey" "client_secret"
  "path" (default "book" $idpDef.vaultPath)
  "private" (default $fullName $idpDef.vaultPrivate)
  "passPolicyName" (default "simple-password-policy" $idpDef.passPolicyName)
  "selector" (default dict $idpDef.vaultSelector)
  "format" "plain"
) }}
{{- end }}
{{- end }}

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
  {{- if eq $glyph.type "idp" }}
    {{- include "keycloak.identityProvider" (list $root $glyphWithName) }}
  {{- end }}
{{- end }}

{{- end -}}
