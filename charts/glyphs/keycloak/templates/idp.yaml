{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
*/}}
{{- define "keycloak.idp" }}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1}}
---
apiVersion: v1.edp.epam.com/v1
kind: KeycloakRealmIdentityProvider
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
  alias: {{ default $glyphDefinition.name $glyphDefinition.scopeName }}
  enabled: true
  displayName: {{ default $glyphDefinition.name $glyphDefinition.displayName }}
  providerId: google
  {{- if $glyphDefinition.firstFlow }}
  firstBrokerLoginFlowAlias: {{ $glyphDefinition.firstFlow }}
  {{- end }}
  trustEmail: true
  storeToken: {{ default true $glyphDefinition.storeToken }}
  config:
    clientId: {{ default "$google-oauth:client_id" $glyphDefinition.clientId }}
    clientSecret: {{ default "$google-oauth:client_secret" $glyphDefinition.clientSecret }}
    redirectUri: "{{ $glyphDefinition.realmRef }}/realms/{{ $glyphDefinition.realmRef }}/broker/google/endpoint"
    authorizationUrl: "https://accounts.google.com/o/oauth2/auth?hd={{ $glyphDefinition.authURl }}"
    tokenUrl: "https://accounts.google.com/o/oauth2/token"
    userInfoUrl: "https://www.googleapis.com/oauth2/v3/userinfo"
    logoutUrl: "https://accounts.google.com/o/oauth2/revoke"
    defaultScope: {{ default "openid email profile" $glyphDefinition.realmRefKind }}
    {{- if $glyphDefinition.accessType }}
    accessType: {{ $glyphDefinition.accessType }}
    {{- end }}
    # accessType: "offline"
    syncMode: IMPORT
{{- end }}