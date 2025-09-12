{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
*/}}
{{- define "keycloak.user" }}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1}}
---
apiVersion: v1.edp.epam.com/v1
kind: KeycloakRealmUser
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
  realm: {{ $glyphDefinition.realmRef }}
  username: {{ default $glyphDefinition.email $glyphDefinition.username }}
  email: {{ $glyphDefinition.email }}
  enabled: {{ default true $glyphDefinition.enabled }}
  emailVerified: {{ default true $glyphDefinition.emailVerified }}
  keepResource: true
  requiredUserActions: []
  {{- if $glyphDefinition.groups }}
  groups:
  {{- range $glyphDefinition.groups }}
    - {{ . }}
  {{- end }}
  {{- end }}
{{- end }}