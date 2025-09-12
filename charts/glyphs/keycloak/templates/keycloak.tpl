{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
*/}}
{{- define "keycloak.keycloak" }}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1}}
---
apiVersion: v1.edp.epam.com/v1
kind: Keycloak
metadata:
  labels:
    {{- include "common.infra.labels" $root | nindent 4}}
  name: {{ $glyphDefinition.name }}
  annotations:
    {{- include "common.infra.annotations" $root | nindent 4}}
spec:
  secret: {{ default "keycloak-access" $glyphDefinition.secret }}
  url: {{ default "http://keycloak.keycloak.svc" $glyphDefinition.url }}
{{- end }}