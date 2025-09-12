{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
*/}}
{{- define "keycloaj.clientScope" }}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1}}
---
apiVersion: v1.edp.epam.com/v1
kind: KeycloakClientScope
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
  description: {{ default $glyphDefinition.name $glyphDefinition.description }}
  protocol: {{ default "openid-connect" $glyphDefinition.realmRef }}
  default: {{ default true $glyphDefinition.realmRef }}
  protocolMappers:
    - name: roles
      protocol: openid-connect
      protocolMapper: "oidc-usermodel-client-role-mapper"
      config:
        "multivalued": "true"
        "client.id": "grafana"
        "id.token.claim": "true"
        "access.token.claim": "true"
        "userinfo.token.claim": "true"
        "claim.name": "resource_access.${client_id}.roles"
{{- end }}
---
  protocolMappers:
    - name: groups
      protocol: openid-connect
      protocolMapper: "oidc-group-membership-mapper"
      config:
        "access.token.claim": "true"
        "claim.name": "groups"
        "full.path": "false"
        "id.token.claim": "true"
        "userinfo.token.claim": "true"
---
  protocolMappers:
    - name: Audience for NetBird Management API
      protocol: openid-connect
      protocolMapper: oidc-audience-mapper
      config:
        included.client.audience: netbird
        id.token.claim: "false"
        access.token.claim: "true"