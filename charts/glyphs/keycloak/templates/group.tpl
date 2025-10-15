{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

keycloak.group creates KeycloakRealmGroup resources for group management in Keycloak.
Uses the EDP Keycloak Operator CRDs.

Parameters:
- $root: Chart root context (index . 0)
- $glyphDefinition: Group configuration object (index . 1)

Required Configuration:
- glyphDefinition.realmRef: Keycloak realm name

Optional Configuration:
- glyphDefinition.name: Resource and group name (defaults to common.name)
- glyphDefinition.scopeName: Alternative group name if different from resource name
- glyphDefinition.realmRoles: List of realm roles assigned to group
- glyphDefinition.clientRoles: Client roles configuration

Usage: {{- include "keycloak.group" (list $root $glyph) }}
*/}}
{{- define "keycloak.group" }}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1}}
---
apiVersion: v1.edp.epam.com/v1
kind: KeycloakRealmGroup
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
  name: {{ default (default (include "common.name" $root) $glyphDefinition.name) $glyphDefinition.scopeName }}
  {{- if $glyphDefinition.realmRoles }}
  realmRoles:
  {{- range $glyphDefinition.realmRoles }}
    - {{ . }}
  {{- end }}
  {{- end }}
  {{- if $glyphDefinition.clientRoles }}
  clientRoles:
  {{- range $glyphDefinition.clientRoles }}
    - clientId: {{ .clientId }}
      roles:
      {{- range .roles }}
        - {{ . }}
      {{- end }}
  {{- end }}
  {{- end }}
{{- end }}
