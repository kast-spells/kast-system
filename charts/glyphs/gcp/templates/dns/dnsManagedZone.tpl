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
  name: {{ default  $glyphDefinition.name ( (default "" $glyphDefinition.url) | lower | replace "." "-" | trimSuffix "-" )  }}
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
  dnssecConfig:
    state: {{default "on" $glyphDefinition.dnsSec }}
  description: {{ default $glyphDefinition.name $glyphDefinition.description }}
  dnsName:   {{ default  ( $glyphDefinition.name | lower | replace "-" "." | trimSuffix "." ) $glyphDefinition.url | trimSuffix "." }}.
  visibility: {{ default "public" $glyphDefinition.visibility }}
{{- end }}


