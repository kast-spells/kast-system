{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

Covenant Realm - Integrations (OIDC/SAML Clients)
Generates Keycloak clients and secrets from realm/integrations/*.yaml
*/}}

{{- define "covenant.realm.integrations" -}}
{{- $root := . -}}
{{- $bookPath := default .Release.Name .Values.name -}}
{{- $covenantIndex := include "covenant.scanCovenantIndex" . | fromYaml -}}
{{- $finalRealm := $covenantIndex.realm -}}
{{- $realmRef := printf "realm-%s" (required "covenant realm.name is required" $finalRealm.name) -}}
{{- $keycloakGlyphs := dict -}}
{{- $vaultGlyphs := dict -}}
{{- $certManagerGlyphs := dict -}}

{{/* Scan integrations from realm/integrations/*.yaml */}}
{{- $integrations := include "covenant.scanRealmIntegrations" . | fromJson -}}

{{/* Generate Keycloak clients */}}
{{- range $clientName, $clientDef := $integrations }}
{{- $_ := set $keycloakGlyphs $clientName (dict
  "type" "client"
  "realmRef" $realmRef
  "clientId" (default $clientName $clientDef.clientId)
  "webUrl" $clientDef.webUrl
  "redirectUris" (default (list (printf "%s/*" $clientDef.webUrl)) $clientDef.redirectUris)
  "defaultClientScopes" (default (list "profile" "email" "roles" "groups") $clientDef.defaultClientScopes)
  "directAccess" (default true $clientDef.directAccess)
  "stdFlow" (default true $clientDef.standardFlowEnabled)
  "public" (default false $clientDef.public)
  "protocol" (default "openid-connect" $clientDef.protocol)
  "webOrigins" (default list $clientDef.webOrigins)
  "secret" $clientDef.secret
) }}

{{/* Generate Secrets (OIDC or SAML) */}}
{{- if $clientDef.secret }}
{{- $protocol := default "openid-connect" $clientDef.protocol -}}

{{- if eq $protocol "saml" }}
{{/* SAML: Generate Certificate via cert-manager */}}
{{/* Application will mount the cert-manager secret directly */}}
{{- $certKey := printf "cert-%s" $clientName -}}
{{- $dnsName := regexReplaceAll "^https?://" $clientDef.webUrl "" | regexReplaceAll "/.*$" "" -}}
{{- $entityId := default (printf "https://%s/saml/metadata" $dnsName) (default "" $clientDef.saml.entityId) -}}
{{- $_ := set $certManagerGlyphs $certKey (dict
  "type" "certificate"
  "name" (printf "%s-saml" $clientName)
  "dnsNames" (list $dnsName)
  "commonName" $entityId
  "selector" (default (dict "environment" "production") $clientDef.certSelector)
) }}

{{- else }}
{{/* OIDC: VaultSecret in keycloak namespace (generates random + adds static client_id) */}}
{{- $secretKeyKeycloak := printf "secret-%s-keycloak" $clientName -}}
{{- $_ := set $vaultGlyphs $secretKeyKeycloak (dict
  "type" "vaultSecret"
  "name" $clientDef.secret
  "format" "plain"
  "staticData" (dict "client_id" (default $clientName $clientDef.clientId))
  "randomKey" "client_secret"
  "path" (default "book" $clientDef.vaultPath)
  "passPolicyName" (default "simple-password-policy" $clientDef.passPolicyName)
  "selector" (default dict $clientDef.vaultSelector)
) }}

{{/* VaultSecret in target namespace (reads same vault path, adds static client_id) */}}
{{- if $clientDef.secretNamespace }}
{{- $secretKeyTarget := printf "secret-%s-target" $clientName -}}
{{/* Build vault auth config */}}
{{- $vaultAuth := default dict $clientDef.vaultAuth -}}
{{- $targetServiceAccount := default $clientDef.secretNamespace (default $clientDef.serviceAccount $vaultAuth.serviceAccount) -}}
{{- $targetRole := default "" $vaultAuth.role -}}
{{/* Build glyph dict with conditional customRole */}}
{{- $glyphDict := dict
  "type" "vaultSecret"
  "name" $clientDef.secret
  "namespace" $clientDef.secretNamespace
  "format" "plain"
  "staticData" (dict "client_id" (default $clientName $clientDef.clientId))
  "randomKey" "client_secret"
  "random" false
  "path" (default "book" $clientDef.vaultPath)
  "selector" (default dict $clientDef.vaultSelector)
  "serviceAccount" $targetServiceAccount
}}
{{- if $targetRole }}
{{- $_ := set $glyphDict "customRole" $targetRole -}}
{{- end }}
{{- if $clientDef.secretLabels }}
{{- $_ := set $glyphDict "labels" $clientDef.secretLabels -}}
{{- end }}
{{- $_ := set $vaultGlyphs $secretKeyTarget $glyphDict }}
{{- end }}

{{- end }}
{{- end }}
{{- end }}

{{/* Render vault glyphs */}}
{{- range $glyphName, $glyph := $vaultGlyphs }}
  {{- $glyphWithName := merge $glyph (dict "name" $glyphName) }}
  {{- if eq $glyph.type "vaultSecret" }}
    {{- include "vault.vaultSecret" (list $root $glyphWithName) }}
  {{- end }}
{{- end }}

{{/* Render cert-manager glyphs */}}
{{- range $glyphName, $glyph := $certManagerGlyphs }}
  {{- $glyphWithName := merge $glyph (dict "name" $glyphName) }}
  {{- if eq $glyph.type "certificate" }}
    {{- include "certManager.certificate" (list $root $glyphWithName) }}
  {{- end }}
{{- end }}

{{/* Render keycloak glyphs */}}
{{- range $glyphName, $glyph := $keycloakGlyphs }}
  {{- $glyphWithName := merge $glyph (dict "name" $glyphName) }}
  {{- if eq $glyph.type "client" }}
    {{- include "keycloak.client" (list $root $glyphWithName) }}
  {{- end }}
{{- end }}

{{- end -}}
