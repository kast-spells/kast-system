{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
*/}}
{{- define "gcp.dnsRecordSet" }}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1}}
---
apiVersion: dns.cnrm.cloud.google.com/v1beta1
kind: DNSRecordSet
metadata:
  name: {{ default  ( $glyphDefinition.url | lower | replace "." "-" | trimSuffix "-" ) $glyphDefinition.name  }}
  labels:
    {{- include "common.infra.labels" $root | nindent 4 }}
  annotations:
    {{- include "common.infra.annotations" $root | nindent 4}}
spec:
  name: {{ default  ( $glyphDefinition.name | lower | replace "-" "." | trimSuffix "." ) $glyphDefinition.url  }}.
  type: {{ default "A" $glyphDefinition.dnsType }}
  ttl: {{ default 30 $glyphDefinition.ttl }}
  managedZoneRef:
    name: {{ $glyphDefinition.managedZone }}
    {{- if $glyphDefinition.managedZoneNamespace }}
    namespace: {{ $glyphDefinition.managedZoneNamespace }}
    {{- end }}
  {{- with $glyphDefinition.records }}
  rrdatas:
  {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- if $glyphDefinition.compueAddresses }}
  rrdatasRefs:
  {{- range $glyphDefinition.compueAddresses }}
    - name: {{ .name }}
      kind: ComputeAddress
      {{- if .namespace }}
      namespace: {{ .namespace }}
      {{- end }}
  {{- end }}
  {{- end }}
{{- end }}

