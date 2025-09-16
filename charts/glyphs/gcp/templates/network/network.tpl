{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
*/}}
{{- define "gcp.network" }}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1}}
---
apiVersion: compute.cnrm.cloud.google.com/v1beta1
kind: ComputeSubnetwork
metadata:
  name: {{ $glyphDefinition.name  }}
  labels:
    {{- include "common.infra.labels" $root | nindent 4 }}
  annotations:
    {{- include "common.infra.annotations" $root | nindent 4}}
spec:
  routingMode: {{ default "REGIONAL" $glyphDefinition.routingMode }}
  autoCreateSubnetworks: {{ default false $glyphDefinition.autoCreateSubnetworks }}
{{- end }}
