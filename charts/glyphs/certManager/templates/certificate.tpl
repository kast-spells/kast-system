{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

certManager.certificate creates cert-manager Certificate resources for TLS certificate management.
Uses runicIndexer to discover available ClusterIssuers and generates certificates for each.

Parameters:
- $root: Chart root context (index . 0)
- $glyphDefinition: Certificate configuration object (index . 1)

Required Configuration:
- glyphDefinition.dnsNames: array of DNS names for the certificate

Optional Configuration:
- glyphDefinition.selector: selector for runicIndexer to find cert-issuers
- glyphDefinition.name: certificate name component

Generated Resources:
- Certificate name: {common.name}-{issuer.name}-cert
- Secret name: {common.name}-{glyphDefinition.name}-cert

Usage: {{- include "certManager.certificate" (list $root $glyph) }}
*/}}
{{- define "certManager.certificate" }}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1}}
{{- $issuers := get (include "runicIndexer.runicIndexer" (list $root.Values.lexicon (default dict $glyphDefinition.selector) "cert-issuer" $root.Values.chapter.name ) | fromJson) "results" }}
{{- range $issuer := $issuers }}
---
kind: Certificate
apiVersion: cert-manager.io/v1
metadata:
  name: {{ default (include "common.name" $root) $glyphDefinition.name }}-{{ $issuer.name }}-cert
  labels:
    {{- include "common.all.labels" $root | nindent 4 }}
    {{- with $glyphDefinition.labels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- with $glyphDefinition.annotations }}
  annotations:
    {{- include "common.annotations" $root | nindent 4 }}
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  commonName: {{ index $glyphDefinition.dnsNames 0 }}
  dnsNames:
  {{- $glyphDefinition.dnsNames | toYaml | nindent 2 }}
  issuerRef:
    kind: ClusterIssuer
    name: {{ $issuer.name }}
  secretName: {{ include "common.name" $root }}-{{ $glyphDefinition.name }}-cert
{{- end }}
{{- end }}