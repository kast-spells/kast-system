{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

keycloak.clientScope creates KeycloakClientScope resources for custom OIDC scopes and mappers.
Uses the EDP Keycloak Operator CRDs.

Parameters:
- $root: Chart root context (index . 0)
- $glyphDefinition: Client scope configuration object (index . 1)

Required Configuration:
- glyphDefinition.realmRef: Keycloak realm name
- glyphDefinition.scopeName: Name of the client scope

Optional Configuration:
- glyphDefinition.name: Resource name (defaults to common.name)
- glyphDefinition.description: Scope description (defaults to scopeName)
- glyphDefinition.protocol: Protocol type (default: openid-connect)
- glyphDefinition.default: Default scope flag (default: false)
- glyphDefinition.protocolMappers: List of protocol mapper configurations

Protocol Mapper Structure:
- name: Mapper name
- protocol: Protocol type (openid-connect, saml)
- protocolMapper: Mapper type (e.g., oidc-usermodel-client-role-mapper)
- config: Key-value pairs for mapper configuration

Usage: {{- include "keycloak.clientScope" (list $root $glyph) }}
*/}}
{{- define "keycloak.clientScope" }}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1}}
---
apiVersion: v1.edp.epam.com/v1
kind: KeycloakClientScope
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
    kind: {{ default "ClusterKeycloakRealm" $glyphDefinition.realmRefKind }}
  name: {{ required "glyphDefinition.scopeName is required" $glyphDefinition.scopeName }}
  {{- if $glyphDefinition.description }}
  description: {{ $glyphDefinition.description }}
  {{- end }}
  protocol: {{ default "openid-connect" $glyphDefinition.protocol }}
  default: {{ default false $glyphDefinition.default }}
  {{- if $glyphDefinition.protocolMappers }}
  protocolMappers:
  {{- range $glyphDefinition.protocolMappers }}
    - name: {{ .name }}
      protocol: {{ .protocol }}
      protocolMapper: {{ .protocolMapper }}
      {{- if .config }}
      config:
        {{- range $key, $value := .config }}
        {{ $key | quote }}: {{ $value | quote }}
        {{- end }}
      {{- end }}
  {{- end }}
  {{- end }}
{{- end }}