{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
*/}}
{{- define "keycloak.realm" }}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1}}
---
apiVersion: v1.edp.epam.com/v1
kind: KeycloakRealm
metadata:
  labels:
    {{- include "common.infra.labels" $root | nindent 4}}
  name: {{ $glyphDefinition.name }}
  annotations:
    {{- include "common.infra.annotations" $root | nindent 4}}
spec:
  id: {{ default (uuidv4) $glyphDefinition.id }}
  realmName: {{ $glyphDefinition.name }}
  keycloakRef:
    name: {{ $glyphDefinition.keycloakRef }}
    kind: {{ default "Keycloak" $glyphDefinition.keycloakRefKind }}
  # passwordPolicy:
  #   - type: "forceExpiredPasswordChange"
  #     value: "365"
  #   - type: "length"
  #     value: "8"
  realmEventConfig:
    adminEventsDetailsEnabled: true
    adminEventsEnabled: true
    enabledEventTypes:
      - UPDATE_CONSENT_ERROR
      - CLIENT_LOGIN
    eventsEnabled: true
    eventsExpiration: 15000
    eventsListeners:
      - jboss-logging
  tokenSettings:
    accessTokenLifespan: 300
    accessCodeLifespan: 300
    accessToken: 300
    actionTokenGeneratedByAdminLifespan: 300
    actionTokenGeneratedByUserLifespan: 300
    refreshTokenMaxReuse: 300
    revokeRefreshToken: true
    defaultSignatureAlgorithm: RS256
{{- end }}