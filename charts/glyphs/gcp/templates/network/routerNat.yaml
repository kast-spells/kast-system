{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
*/}}

{{- define "gcp.routerNat" }}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1}}
---
apiVersion: compute.cnrm.cloud.google.com/v1beta1
kind: ComputeRouterNAT
metadata:
  name: {{ $glyphDefinition.name  }}
  annotations:
    {{- include "common.infra.annotations" $root | nindent 4}}
  labels:
    {{- include "common.infra.labels" $root | nindent 4 }}
spec:
  region: {{ $glyphDefinition.region }}
  networkRef:
    name: {{ $glyphDefinition.networkRef }}
    {{- if $glyphDefinition.networkRefNamespace }}
    namespace: {{ $glyphDefinition.networkRefNamespace }}
    {{- end }}
  ## TODO HARDCODED
  natIpAllocateOption: AUTO_ONLY
  sourceSubnetworkIpRangesToNat: LIST_OF_SUBNETWORKS
  subnetwork:
  {{- range $glyphDefinition.subnets }}
    - subnetworkRef:
        name: {{ .name }}
      sourceIpRangesToNat:
        - ALL_IP_RANGES
  {{- end }}
  minPortsPerVm: 64
  enableEndpointIndependentMapping: {{ default true $glyphDefinition.enableEndpointIndependentMapping }}
  description: {{ default $glyphDefinition.name $glyphDefinition.description }}
{{- end }}