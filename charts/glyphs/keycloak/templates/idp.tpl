{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

keycloak.idp creates KeycloakRealmIdentityProvider resources for external identity provider integration.
Uses the EDP Keycloak Operator CRDs.

Parameters:
- $root: Chart root context (index . 0)
- $glyphDefinition: Identity provider configuration object (index . 1)

Required Configuration:
- glyphDefinition.realmRef: Keycloak realm name
- glyphDefinition.providerId: Provider type (google, github, oidc, saml, etc.)
- glyphDefinition.alias: IDP alias/identifier

Optional Configuration:
- glyphDefinition.name: Resource name (defaults to common.name)
- glyphDefinition.displayName: Display name for IDP
- glyphDefinition.enabled: Enable/disable IDP (default: true)
- glyphDefinition.trustEmail: Trust email from IDP (default: true)
- glyphDefinition.storeToken: Store tokens (default: true)
- glyphDefinition.linkOnly: Link accounts only (default: false)
- glyphDefinition.firstBrokerLoginFlowAlias: First broker login flow
- glyphDefinition.postBrokerLoginFlowAlias: Post broker login flow
- glyphDefinition.config: Provider-specific configuration (clientId, clientSecret, URLs, etc.)

Usage: {{- include "keycloak.idp" (list $root $glyph) }}
*/}}
{{- define "keycloak.idp" }}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1}}
---
apiVersion: v1.edp.epam.com/v1
kind: KeycloakRealmIdentityProvider
metadata:
  name: {{ default (include "common.name" $root) $glyphDefinition.name }}
  labels:
    {{- include "common.labels" $root | nindent 4}}
  {{- with $glyphDefinition.annotations }}
  annotations:
    {{- toYaml . | nindent 4}}
  {{- end }}
spec:
  realmRef:
    name: {{ required "glyphDefinition.realmRef is required" $glyphDefinition.realmRef }}
    kind: {{ default "KeycloakRealm" $glyphDefinition.realmRefKind }}
  alias: {{ required "glyphDefinition.alias is required" $glyphDefinition.alias }}
  enabled: {{ default true $glyphDefinition.enabled }}
  {{- if $glyphDefinition.displayName }}
  displayName: {{ $glyphDefinition.displayName }}
  {{- end }}
  providerId: {{ required "glyphDefinition.providerId is required" $glyphDefinition.providerId }}
  {{- if $glyphDefinition.firstBrokerLoginFlowAlias }}
  firstBrokerLoginFlowAlias: {{ $glyphDefinition.firstBrokerLoginFlowAlias }}
  {{- end }}
  {{- if $glyphDefinition.postBrokerLoginFlowAlias }}
  postBrokerLoginFlowAlias: {{ $glyphDefinition.postBrokerLoginFlowAlias }}
  {{- end }}
  trustEmail: {{ default true $glyphDefinition.trustEmail }}
  storeToken: {{ default true $glyphDefinition.storeToken }}
  {{- if $glyphDefinition.linkOnly }}
  linkOnly: {{ $glyphDefinition.linkOnly }}
  {{- end }}
  {{- if $glyphDefinition.config }}
  config:
    {{- range $key, $value := $glyphDefinition.config }}
    {{ $key }}: {{ $value | quote }}
    {{- end }}
  {{- end }}
{{- end }}