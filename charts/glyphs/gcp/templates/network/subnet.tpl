{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
*/}}
{{- define "gcp.subnet" }}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1}}
---
apiVersion: compute.cnrm.cloud.google.com/v1beta1
kind: ComputeSubnetwork
metadata:
  name: {{ $glyphDefinition.name  }}
  annotations:
    {{- include "common.infra.annotations" $root | nindent 4}}
  labels:
    {{- include "common.infra.labels" $root | nindent 4 }}
spec:
  networkRef:
    name: {{ $glyphDefinition.networkRef }}
    {{- if $glyphDefinition.networkRefNamespace }}
    namespace: {{ $glyphDefinition.networkRefNamespace }}
    {{- end }}
  ipCidrRange: {{ $glyphDefinition.cidr }}
  region: {{ $glyphDefinition.region }}
  description: {{ default $glyphDefinition.name $glyphDefinition.description }}
  privateIpGoogleAccess: {{ default true $glyphDefinition.privateIpGoogleAccess }}
{{- end }}