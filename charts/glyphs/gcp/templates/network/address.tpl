{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
*/}}
{{- define "gcp.address" }}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1}}
---
apiVersion: compute.cnrm.cloud.google.com/v1beta1
kind: ComputeAddress
metadata:
  labels:
    {{- include "common.infra.labels" $root | nindent 4}}
  name: {{ default (include "common.name" $root) $glyphDefinition.name }}
  annotations:
    {{- include "common.infra.annotations" $root | nindent 4}}
spec:
  addressType: EXTERNAL
  description: {{ default $glyphDefinition.name $glyphDefinition.description }}
  location: us-east5
  ipVersion: {{ default "IPV4" $glyphDefinition.ipVersion}}
{{- end }}