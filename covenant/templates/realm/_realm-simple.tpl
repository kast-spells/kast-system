{{- define "covenant.realm.keycloakRealm.glyphs" -}}
{{- $covenantIndex := include "covenant.scanCovenantIndex" . | fromYaml -}}
{{- $finalRealm := $covenantIndex.realm -}}
{{- $bookPath := default .Release.Name .Values.name -}}
{{- $keycloakGlyphs := dict -}}
{{- $vaultGlyphs := dict -}}

{{/* Get Keycloak instance */}}
{{- $chapterName := "" -}}
{{- $chapterLabels := dict -}}
{{- if .Values.chapter }}
  {{- $chapterName = .Values.chapter.name -}}
  {{- $chapterLabels = dict "chapter" $chapterName -}}
{{- end }}
{{- $keycloakInstances := get (include "runicIndexer.runicIndexer" (list .Values.lexicon $chapterLabels "keycloak" $chapterName) | fromJson) "results" -}}
{{- $keycloakInstance := dict -}}
{{- range $keycloakInstances }}
  {{- $keycloakInstance = . -}}
{{- end }}
{{- $keycloakRef := required "keycloakInstance.keycloakCrdName is required in lexicon" $keycloakInstance.keycloakCrdName -}}

{{- if $finalRealm }}
{{- $_ := set $vaultGlyphs "stalwart-admin" (dict
  "type" "vaultSecret"
  "name" "stalwart-admin"
  "namespace" $.Release.Namespace
  "format" "plain"
  "randomKey" "password"
  "random" false
  "path" "book"
  "private" "admintools"
) }}

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
{{- end }}

{{- dict "keycloak" $keycloakGlyphs "vault" $vaultGlyphs | toJson -}}
{{- end -}}

{{- define "covenant.realm.roles.glyphs" -}}
{{- $covenantIndex := include "covenant.scanCovenantIndex" . | fromYaml -}}
{{- $finalRealm := $covenantIndex.realm -}}
{{- $realmRef := printf "realm-%s" (required "covenant realm.name is required" $finalRealm.name) -}}
{{- $keycloakGlyphs := dict -}}
{{- $rolesJson := include "covenant.scanRealmRoles" . -}}
{{- $roles := list -}}
{{- if $rolesJson }}
  {{- $roles = $rolesJson | fromJson -}}
{{- end }}
{{- if $roles }}
{{- range $role := $roles }}
{{- if $role }}
{{- $roleKey := printf "role-%s" $role.name -}}
{{- $_ := set $keycloakGlyphs $roleKey (dict
  "type" "realmRole"
  "realmRef" $realmRef
  "roleName" $role.name
  "description" (default "" $role.description)
  "composite" (default false $role.composite)
  "compositeRoles" $role.compositeRoles
  "attributes" $role.attributes
) }}
{{- end }}
{{- end }}
{{- end }}
{{- $keycloakGlyphs | toJson -}}
{{- end -}}

{{- define "covenant.realm.clientScopes.glyphs" -}}
{{- $covenantIndex := include "covenant.scanCovenantIndex" . | fromYaml -}}
{{- $finalRealm := $covenantIndex.realm -}}
{{- $realmRef := printf "realm-%s" (required "covenant realm.name is required" $finalRealm.name) -}}
{{- $keycloakGlyphs := dict -}}
{{- $scopes := include "covenant.scanRealmClientScopes" . | fromJson -}}
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
{{- $keycloakGlyphs | toJson -}}
{{- end -}}

{{- define "covenant.realm.idps.glyphs" -}}
{{- $bookPath := default .Release.Name .Values.name -}}
{{- $covenantIndex := include "covenant.scanCovenantIndex" . | fromYaml -}}
{{- $finalRealm := $covenantIndex.realm -}}
{{- $realmRef := printf "realm-%s" (required "covenant realm.name is required" $finalRealm.name) -}}
{{- $keycloakGlyphs := dict -}}
{{- $vaultGlyphs := dict -}}
{{- $idps := include "covenant.scanRealmIDPs" . | fromJson -}}
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
{{- if $idpDef.secret }}
{{- $secretKey := printf "secret-%s-idp" $idpName -}}
{{- $_ := set $vaultGlyphs $secretKey (dict
  "type" "vaultSecret"
  "name" $idpDef.secret
  "randomKey" "client_secret"
  "path" (default "book" $idpDef.vaultPath)
  "private" (default $bookPath $idpDef.vaultPrivate)
  "passPolicyName" (default "simple-password-policy" $idpDef.passPolicyName)
  "selector" (default dict $idpDef.vaultSelector)
  "format" "plain"
) }}
{{- end }}
{{- end }}
{{- dict "keycloak" $keycloakGlyphs "vault" $vaultGlyphs | toJson -}}
{{- end -}}

{{- define "covenant.realm.authFlows.glyphs" -}}
{{- $covenantIndex := include "covenant.scanCovenantIndex" . | fromYaml -}}
{{- $finalRealm := $covenantIndex.realm -}}
{{- $realmRef := printf "realm-%s" (required "covenant realm.name is required" $finalRealm.name) -}}
{{- $keycloakGlyphs := dict -}}
{{- $flows := include "covenant.scanRealmAuthFlows" . | fromJson -}}
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
{{- $keycloakGlyphs | toJson -}}
{{- end -}}

{{- define "covenant.realm.integrations.glyphs" -}}
{{- $covenantIndex := include "covenant.scanCovenantIndex" . | fromYaml -}}
{{- $finalRealm := $covenantIndex.realm -}}
{{- $realmRef := printf "realm-%s" (required "covenant realm.name is required" $finalRealm.name) -}}
{{- $keycloakGlyphs := dict -}}
{{- $vaultGlyphs := dict -}}
{{- $certManagerGlyphs := dict -}}
{{- $integrations := include "covenant.scanRealmIntegrations" . | fromJson -}}
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
{{- if $clientDef.secret }}
{{- $protocol := default "openid-connect" $clientDef.protocol -}}
{{- if eq $protocol "saml" }}
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
{{- if $clientDef.secretNamespace }}
{{- $secretKeyTarget := printf "secret-%s-target" $clientName -}}
{{- $vaultAuth := default dict $clientDef.vaultAuth -}}
{{- $targetServiceAccount := default $clientDef.secretNamespace (default $clientDef.serviceAccount $vaultAuth.serviceAccount) -}}
{{- $targetRole := default "" $vaultAuth.role -}}
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
{{- dict "keycloak" $keycloakGlyphs "vault" $vaultGlyphs "certManager" $certManagerGlyphs | toJson -}}
{{- end -}}

{{- define "covenant.chapter.glyphs" -}}
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
{{- $chapterIndex := include "covenant.scanChapterIndex" (list . $chapterFilter) | fromYaml -}}
{{- $chapterGroupKey := printf "area-%s" $chapterFilter -}}
{{- $_ := set $keycloakGlyphs $chapterGroupKey (dict
  "type" "group"
  "name" $chapterFilter
  "realmRef" $realmRef
  "realmRoles" (default list $chapterIndex.realmRoles)
) }}
{{- $members := include "covenant.scanChapterMembers" (list . $chapterFilter) | fromJson -}}
{{- $chapels := dict -}}
{{- range $memberKey, $member := $members }}
  {{- if $member.chapel }}
    {{- $chapelKey := printf "%s/%s" $chapterFilter $member.chapel -}}
    {{- if not (hasKey $chapels $chapelKey) }}
      {{- $_ := set $chapels $chapelKey (dict "name" $member.chapel "chapter" $chapterFilter) -}}
    {{- end }}
  {{- end }}
{{- end }}
{{- range $chapelKey, $chapel := $chapels }}
{{- $groupGlyphKey := printf "chapel-%s" ($chapelKey | replace "/" "-") -}}
{{- $_ := set $keycloakGlyphs $groupGlyphKey (dict
  "type" "group"
  "name" ($chapelKey | replace "/" "-")
  "scopeName" $chapelKey
  "realmRef" $realmRef
) }}
{{- end }}
{{- range $memberKey, $member := $members }}
{{- $userGlyphKey := $memberKey | replace "/" "-" -}}
{{- $baseUsername := "" -}}
{{- if $member.overrideUsername }}
  {{- $baseUsername = $member.overrideUsername -}}
{{- else }}
  {{- $baseUsername = printf "%s.%s" ($member.firstName | lower) ($member.lastName | lower) -}}
{{- end }}
{{- $generatedUsername := printf "%s@%s" $baseUsername $finalRealm.emailDomain -}}
{{- $groups := $member.groups -}}
{{- if not $groups }}
  {{- $chapelKey := printf "%s/%s" $chapterFilter $member.chapel -}}
  {{- $groups = list $chapelKey $chapterFilter -}}
{{- end }}
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
{{- $keycloakGlyphs | toJson -}}
{{- end -}}
