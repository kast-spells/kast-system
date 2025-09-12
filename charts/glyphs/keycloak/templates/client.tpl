{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
*/}}
{{- define "keycloaj.client" }}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1}}
---
apiVersion: v1.edp.epam.com/v1
kind: KeycloakClient
metadata:
  labels:
    {{- include "common.infra.labels" $root | nindent 4}}
  name: {{ $glyphDefinition.name }}
  annotations:
    {{- include "common.infra.annotations" $root | nindent 4}}
spec:
  realmRef:
    name: {{ $glyphDefinition.realmRef }}
    kind: {{ default "KeycloakRealm" $glyphDefinition.realmRefKind }}
  advancedProtocolMappers: {{ default "true" $glyphDefinition.advMappers }}
  clientId: {{ default $glyphDefinition.name $glyphDefinition.clientId }}
  directAccess: {{ default true $glyphDefinition.directAccess }}
  {{- if $glyphDefinition.public }}
  public: true
  {{- end }}
  {{- if $glyphDefinition.protocol }}
  protocol: {{ $glyphDefinition.protocol }}
  {{- end }}
  secret: ${{ default "keycloak-client.client_id" $glyphDefinition.secret }}
  webUrl: {{ $glyphDefinition.webUrl }}
  standardFlowEnabled: {{ default true $glyphDefinition.stdFlow }}
  # implicitFlowEnabled: false
  {{- if $glyphDefinition.attributes }}
  attributes:
    {{- if $glyphDefinition.attributes.logoutURL }}
    post.logout.redirect.uris: {{ $glyphDefinition.attributes.logoutURL }}
    {{- end }}
    {{- if $glyphDefinition.attributes.oauth2Grant }}
    oauth2.device.authorization.grant.enabled: {{ default true $glyphDefinition.attributes.oauth2Grant }}
    {{- end }}
    {{- if $glyphDefinition.attributes.authService }}
    authorization.services.enabled: {{ default true $glyphDefinition.authService }}
    {{- end }}
    {{- if $glyphDefinition.protocol }}
    protocol: {{ $glyphDefinition.protocol }}
    {{- end }}
  {{- end }}
  defaultClientScopes:
  {{- range $glyphDefinition.defaultClientScopes }}
    - {{ . }}
  {{- end }}
  redirectUris:
  {{- range $glyphDefinition.redirectUris }}
    - {{ . }}
  {{- end }}
  {{- if $glyphDefinition.optionalClientScopes }}
  optionalClientScopes:
  {{- range $glyphDefinition.optionalClientScopes }}
    - {{ . }}
  {{- end }}
  {{- end }}
  {{- if $glyphDefinition.clientRoles }}
  clientRoles:
  {{- range $glyphDefinition.clientRoles }}
    - {{ . }}
  {{- end }}
  {{- end }}
  {{- if $glyphDefinition.webOrigins }}
  webOrigins:
  {{- range $glyphDefinition.webOrigins }}
    - {{ . }}
  {{- end }}
  {{- end }}
  {{- if ($glyphDefinition.serviceAccount).enabled }}
  serviceAccount:
    enabled: true
    {{- if $glyphDefinition.serviceAccount.clientRoles }}
    clientRoles:
    {{- range $glyphDefinition.serviceAccount.clientRoles }}
      - {{ toYaml . }}
    {{- end }}
  {{- end }}
  {{- end }}
{{- end }}