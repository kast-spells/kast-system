{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

keycloak.realmRole creates KeycloakRealmRole resources for role management.
Uses the EDP Keycloak Operator CRDs.

Parameters:
- $root: Chart root context (index . 0)
- $glyphDefinition: Realm role configuration object (index . 1)

Required Configuration:
- glyphDefinition.realmRef: Keycloak realm name
- glyphDefinition.roleName: Name of the role

Optional Configuration:
- glyphDefinition.name: Resource name (defaults to common.name)
- glyphDefinition.description: Role description
- glyphDefinition.composite: Whether this is a composite role (default: false)
- glyphDefinition.compositeRoles: List of roles this role is composed of (if composite)
- glyphDefinition.attributes: Additional role attributes

Usage: {{- include "keycloak.realmRole" (list $root $glyph) }}
*/}}
{{- define "keycloak.realmRole" }}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1}}
---
apiVersion: v1.edp.epam.com/v1
kind: KeycloakRealmRole
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
  name: {{ required "glyphDefinition.roleName is required" $glyphDefinition.roleName }}
  {{- if $glyphDefinition.description }}
  description: {{ $glyphDefinition.description }}
  {{- end }}
  composite: {{ default false $glyphDefinition.composite }}
  {{- if and $glyphDefinition.composite $glyphDefinition.compositeRoles }}
  composites:
  {{- range $glyphDefinition.compositeRoles }}
    - name: {{ . }}
  {{- end }}
  {{- end }}
  {{- if $glyphDefinition.attributes }}
  attributes:
    {{- range $key, $value := $glyphDefinition.attributes }}
    {{ $key }}:
      {{- if kindIs "slice" $value }}
      {{- range $value }}
      - {{ . }}
      {{- end }}
      {{- else }}
      - {{ $value }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
