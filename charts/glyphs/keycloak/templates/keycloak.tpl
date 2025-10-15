{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

keycloak.keycloak creates Keycloak instance connection resources.
Uses the EDP Keycloak Operator CRDs.

Parameters:
- $root: Chart root context (index . 0)
- $glyphDefinition: Keycloak instance configuration object (index . 1)

Required Configuration:
- glyphDefinition.url: Keycloak server URL

Optional Configuration:
- glyphDefinition.name: Resource name (defaults to common.name)
- glyphDefinition.secret: Secret name containing admin credentials (default: keycloak-access)

Usage: {{- include "keycloak.keycloak" (list $root $glyph) }}
*/}}
{{- define "keycloak.keycloak" }}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1}}
---
apiVersion: v1.edp.epam.com/v1
kind: Keycloak
metadata:
  name: {{ default (include "common.name" $root) $glyphDefinition.name }}
  labels:
    {{- include "common.labels" $root | nindent 4}}
  {{- with $glyphDefinition.annotations }}
  annotations:
    {{- toYaml . | nindent 4}}
  {{- end }}
spec:
  secret: {{ default "keycloak-access" $glyphDefinition.secret }}
  url: {{ required "glyphDefinition.url is required" $glyphDefinition.url }}
{{- end }}