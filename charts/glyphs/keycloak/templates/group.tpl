{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
*/}}
{{- define "keycloak.group" }}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1}}
---
apiVersion: v1.edp.epam.com/v1
kind: KeycloakRealmGroup
  labels:
    {{- include "common.infra.labels" $root | nindent 4}}
  name: {{ $glyphDefinition.name }}
  annotations:
    {{- include "common.infra.annotations" $root | nindent 4}}
spec:
  realmRef:
    name: {{ $glyphDefinition.realmRef }}
    kind: {{ default "KeycloakRealm" $glyphDefinition.realmRefKind }}
  name: {{ default $glyphDefinition.name $glyphDefinition.scopeName }}
  # clientRoles:
  #   - clientId: grafana
  #     roles:
  #       - admin
{{- end }}