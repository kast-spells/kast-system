{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

keycloak.flow creates KeycloakAuthFlow resources for custom authentication flows.
Uses the EDP Keycloak Operator CRDs.

Parameters:
- $root: Chart root context (index . 0)
- $glyphDefinition: Authentication flow configuration object (index . 1)

Required Configuration:
- glyphDefinition.realmRef: Keycloak realm name
- glyphDefinition.alias: Flow alias/identifier

Optional Configuration:
- glyphDefinition.name: Resource name (defaults to common.name)
- glyphDefinition.builtIn: Built-in flow flag (default: false)
- glyphDefinition.providerId: Provider ID (default: basic-flow)
- glyphDefinition.topLevel: Top-level flow flag (default: true)
- glyphDefinition.authenticationExecutions: List of authentication execution steps

Authentication Execution Structure:
- authenticator: Authenticator type/name
- requirement: Requirement level (REQUIRED, ALTERNATIVE, DISABLED, CONDITIONAL)
- priority: Execution order (0-based)
- authenticatorFlow: Whether this is a sub-flow (default: false)

Usage: {{- include "keycloak.flow" (list $root $glyph) }}
*/}}
{{- define "keycloak.flow" }}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1}}
---
apiVersion: v1.edp.epam.com/v1
kind: KeycloakAuthFlow
metadata:
  name: {{ default (include "common.name" $root) $glyphDefinition.name }}
  labels:
    {{- include "common.labels" $root | nindent 4}}
  {{- with $glyphDefinition.annotations }}
  annotations:
    {{- toYaml . | nindent 4}}
  {{- end }}
spec:
  alias: {{ required "glyphDefinition.alias is required" $glyphDefinition.alias }}
  builtIn: {{ default false $glyphDefinition.builtIn }}
  providerId: {{ default "basic-flow" $glyphDefinition.providerId }}
  topLevel: {{ default true $glyphDefinition.topLevel }}
  realmRef:
    name: {{ required "glyphDefinition.realmRef is required" $glyphDefinition.realmRef }}
    kind: {{ default "KeycloakRealm" $glyphDefinition.realmRefKind }}
  {{- if $glyphDefinition.authenticationExecutions }}
  authenticationExecutions:
  {{- range $glyphDefinition.authenticationExecutions }}
    - authenticator: {{ .authenticator }}
      requirement: {{ .requirement }}
      priority: {{ .priority }}
      authenticatorFlow: {{ default false .authenticatorFlow }}
  {{- end }}
  {{- end }}
{{- end }}