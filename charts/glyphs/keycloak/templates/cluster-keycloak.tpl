{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

keycloak.clusterKeycloak creates a cluster-scoped Keycloak instance connection resource.
Uses the EDP Keycloak Operator ClusterKeycloak CRD.

ClusterKeycloak is cluster-scoped and can be referenced from any namespace,
unlike the namespace-scoped Keycloak resource.

Parameters:
- $root: Chart root context (index . 0)
- $glyphDefinition: ClusterKeycloak instance configuration object (index . 1)

Required Configuration:
- glyphDefinition.url: Keycloak server URL
- glyphDefinition.secret: Secret name containing admin credentials (must exist in operator namespace)

Optional Configuration:
- glyphDefinition.name: Resource name (defaults to common.name)
- glyphDefinition.adminType: Admin type (user or serviceAccount, default: user)
- glyphDefinition.insecureSkipVerify: Skip TLS verification (default: false)
- glyphDefinition.caCert: CA certificate configuration (configMapKeyRef)

Note: The secret referenced must exist in the operator's namespace (OPERATOR_NAMESPACE env var).
For most installations, this is the "keycloak" namespace.

Usage: {{- include "keycloak.clusterKeycloak" (list $root $glyph) }}
*/}}
{{- define "keycloak.clusterKeycloak" }}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1}}
---
apiVersion: v1.edp.epam.com/v1alpha1
kind: ClusterKeycloak
metadata:
  name: {{ default (include "common.name" $root) $glyphDefinition.name }}
  labels:
    {{- include "common.labels" $root | nindent 4}}
  {{- with $glyphDefinition.annotations }}
  annotations:
    {{- toYaml . | nindent 4}}
  {{- end }}
spec:
  url: {{ required "glyphDefinition.url is required" $glyphDefinition.url }}
  secret: {{ required "glyphDefinition.secret is required" $glyphDefinition.secret }}
  {{- if $glyphDefinition.adminType }}
  adminType: {{ $glyphDefinition.adminType }}
  {{- else }}
  adminType: user
  {{- end }}
  {{- if hasKey $glyphDefinition "insecureSkipVerify" }}
  insecureSkipVerify: {{ $glyphDefinition.insecureSkipVerify }}
  {{- end }}
  {{- with $glyphDefinition.caCert }}
  caCert:
    {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end }}
