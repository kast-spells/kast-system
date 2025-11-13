{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
*/}}
{{- define "gcp.dnsManagedZone" }}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1}}
---
apiVersion: dns.cnrm.cloud.google.com/v1beta1
kind: DNSManagedZone
metadata:
  labels:
    {{- include "common.infra.labels" $root | nindent 4}}
  annotations:
    {{- include "common.infra.annotations" $root | nindent 4}}
  name: {{ default  $glyphDefinition.name ( (default "" $glyphDefinition.url) | lower | replace "." "-" | trimSuffix "-" )  }}
spec:
  dnssecConfig:
    state: {{default "on" $glyphDefinition.dnsSec }}
  description: {{ default $glyphDefinition.name $glyphDefinition.description }}
  dnsName:   {{ default  ( $glyphDefinition.name | lower | replace "-" "." | trimSuffix "." ) $glyphDefinition.url | trimSuffix "." }}.
  visibility: {{ default "public" $glyphDefinition.visibility }}
{{- end }}


