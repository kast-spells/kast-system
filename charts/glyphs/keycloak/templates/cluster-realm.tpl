{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

keycloak.clusterRealm creates ClusterKeycloakRealm resources for cluster-scoped realm configuration.
Uses the EDP Keycloak Operator CRDs (v1alpha1).

ClusterKeycloakRealm is cluster-scoped and can be referenced from any namespace,
making it ideal for multi-namespace deployments like covenant.

Parameters:
- $root: Chart root context (index . 0)
- $glyphDefinition: Realm configuration object (index . 1)

Required Configuration:
- glyphDefinition.realmName: Realm name/identifier
- glyphDefinition.clusterKeycloakRef: Name of ClusterKeycloak instance

Optional Configuration:
- glyphDefinition.name: Resource name (defaults to common.name)
- glyphDefinition.displayName: Realm display name
- glyphDefinition.passwordPolicy: List of password policy rules
- glyphDefinition.themes: Theme configuration (login, account, admin, email)
- glyphDefinition.eventConfig: Event logging configuration
- glyphDefinition.tokenSettings: Token lifetime settings

Usage: {{- include "keycloak.clusterRealm" (list $root $glyph) }}
*/}}
{{- define "keycloak.clusterRealm" }}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1}}
---
apiVersion: v1.edp.epam.com/v1alpha1
kind: ClusterKeycloakRealm
metadata:
  name: {{ default (include "common.name" $root) $glyphDefinition.name }}
  labels:
    {{- include "common.labels" $root | nindent 4}}
  {{- with $glyphDefinition.annotations }}
  annotations:
    {{- toYaml . | nindent 4}}
  {{- end }}
spec:
  realmName: {{ required "glyphDefinition.realmName is required" $glyphDefinition.realmName }}
  {{- if $glyphDefinition.displayName }}
  displayName: {{ $glyphDefinition.displayName }}
  {{- end }}
  clusterKeycloakRef: {{ required "glyphDefinition.clusterKeycloakRef is required for ClusterKeycloakRealm" $glyphDefinition.clusterKeycloakRef }}
  {{- if $glyphDefinition.passwordPolicy }}
  passwordPolicy:
  {{- range $glyphDefinition.passwordPolicy }}
    - type: {{ .type }}
      value: {{ .value | quote }}
  {{- end }}
  {{- end }}
  {{- if $glyphDefinition.themes }}
  {{- with $glyphDefinition.themes }}
  {{- if .login }}
  loginTheme: {{ .login }}
  {{- end }}
  {{- if .account }}
  accountTheme: {{ .account }}
  {{- end }}
  {{- if .admin }}
  adminTheme: {{ .admin }}
  {{- end }}
  {{- if .email }}
  emailTheme: {{ .email }}
  {{- end }}
  {{- end }}
  {{- end }}
  {{- if $glyphDefinition.eventConfig }}
  realmEventConfig:
    adminEventsDetailsEnabled: {{ default true $glyphDefinition.eventConfig.adminEventsDetailsEnabled }}
    adminEventsEnabled: {{ default true $glyphDefinition.eventConfig.adminEventsEnabled }}
    {{- if $glyphDefinition.eventConfig.enabledEventTypes }}
    enabledEventTypes:
    {{- range $glyphDefinition.eventConfig.enabledEventTypes }}
      - {{ . }}
    {{- end }}
    {{- end }}
    eventsEnabled: {{ default true $glyphDefinition.eventConfig.eventsEnabled }}
    eventsExpiration: {{ default 15000 $glyphDefinition.eventConfig.eventsExpiration }}
    {{- if $glyphDefinition.eventConfig.eventsListeners }}
    eventsListeners:
    {{- range $glyphDefinition.eventConfig.eventsListeners }}
      - {{ . }}
    {{- end }}
    {{- else }}
    eventsListeners:
      - jboss-logging
    {{- end }}
  {{- else }}
  realmEventConfig:
    adminEventsDetailsEnabled: true
    adminEventsEnabled: true
    eventsEnabled: true
    eventsExpiration: 15000
    eventsListeners:
      - jboss-logging
  {{- end }}
  {{- if $glyphDefinition.tokenSettings }}
  tokenSettings:
    accessTokenLifespan: {{ default 300 $glyphDefinition.tokenSettings.accessTokenLifespan }}
    accessCodeLifespan: {{ default 300 $glyphDefinition.tokenSettings.accessCodeLifespan }}
    accessToken: {{ default 300 $glyphDefinition.tokenSettings.accessToken }}
    actionTokenGeneratedByAdminLifespan: {{ default 300 $glyphDefinition.tokenSettings.actionTokenGeneratedByAdminLifespan }}
    actionTokenGeneratedByUserLifespan: {{ default 300 $glyphDefinition.tokenSettings.actionTokenGeneratedByUserLifespan }}
    refreshTokenMaxReuse: {{ default 0 $glyphDefinition.tokenSettings.refreshTokenMaxReuse }}
    revokeRefreshToken: {{ default true $glyphDefinition.tokenSettings.revokeRefreshToken }}
    defaultSignatureAlgorithm: {{ default "RS256" $glyphDefinition.tokenSettings.defaultSignatureAlgorithm }}
  {{- else }}
  tokenSettings:
    accessTokenLifespan: 300
    accessCodeLifespan: 300
    accessToken: 300
    actionTokenGeneratedByAdminLifespan: 300
    actionTokenGeneratedByUserLifespan: 300
    refreshTokenMaxReuse: 0
    revokeRefreshToken: true
    defaultSignatureAlgorithm: RS256
  {{- end }}
{{- end }}
