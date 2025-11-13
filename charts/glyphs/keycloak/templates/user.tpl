{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

keycloak.user creates KeycloakRealmUser resources for user management in Keycloak.
Uses the EDP Keycloak Operator CRDs.

Parameters:
- $root: Chart root context (index . 0)
- $glyphDefinition: User configuration object (index . 1)

Required Configuration:
- glyphDefinition.email: User email address
- glyphDefinition.realmRef: Keycloak realm name

Optional Configuration:
- glyphDefinition.name: Resource name (defaults to common.name)
- glyphDefinition.username: Username (defaults to email)
- glyphDefinition.firstName: User's first name
- glyphDefinition.lastName: User's last name
- glyphDefinition.enabled: Enable/disable user (default: true)
- glyphDefinition.emailVerified: Email verification status (default: true)
- glyphDefinition.groups: List of groups user belongs to
- glyphDefinition.requiredUserActions: List of required actions

Usage: {{- include "keycloak.user" (list $root $glyph) }}
*/}}
{{- define "keycloak.user" }}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1}}
---
apiVersion: v1.edp.epam.com/v1
kind: KeycloakRealmUser
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
  realm: {{ $glyphDefinition.realmRef }}
  username: {{ default $glyphDefinition.email $glyphDefinition.username }}
  email: {{ required "glyphDefinition.email is required" $glyphDefinition.email }}
  {{- if $glyphDefinition.firstName }}
  firstName: {{ $glyphDefinition.firstName }}
  {{- end }}
  {{- if $glyphDefinition.lastName }}
  lastName: {{ $glyphDefinition.lastName }}
  {{- end }}
  enabled: {{ default true $glyphDefinition.enabled }}
  emailVerified: {{ default true $glyphDefinition.emailVerified }}
  keepResource: true
  requiredUserActions: {{ default list $glyphDefinition.requiredUserActions | toJson }}
  {{- if $glyphDefinition.groups }}
  groups:
  {{- range $glyphDefinition.groups }}
    - {{ . }}
  {{- end }}
  {{- end }}
{{- end }}
