{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

summon.service creates Service resources for summon workloads
Supports both direct usage and glyph parameter pattern

Parameters:
- Direct usage: . (root context)
- Glyph usage: (list $root $glyphDefinition)

Usage:
- Direct: {{- include "summon.service" (list . .Values.service nil) }}
- Glyph: {{- include "summon.service" (list $root $glyphDefinition.service $glyphDefinition.name) }}
 */}}
{{- define "summon.service" }}
{{/* Parameters: (list $root $serviceConfig $resourceName) 
     - $root: Chart root context for labels and selectors
     - $serviceConfig: Service configuration (can be .Values.service for direct or $glyphDefinition.service for glyph)
     - $resourceName: Optional custom name (defaults to common.name if nil)
*/}}
{{- $root := index . 0 }}
{{- $serviceConfig := index . 1 }}
{{- $resourceName := default (include "common.name" $root) (index . 2) }}
---
apiVersion: v1
kind: Service
metadata:
  name: {{ $resourceName }}
  labels:
    {{- include "common.labels" $root | nindent 4 }}
  {{- with $serviceConfig.annotations }}
  annotations:
    {{- . | toYaml | nindent 4 }}
  {{- end }}
spec:
  type: {{ default "ClusterIP" $serviceConfig.type }}
{{- if eq $serviceConfig.type "LoadBalancerSpecial" }}
## this is a placeholder
  loadBalancerIP: 1.2.3.4
  loadBalancerSourceRanges: #supported on EKS, GKS and AKS at least
    - 130.211.204.1/32 # loadBalancerSourceRanges defines the IP ranges that are allowed to access the load balancer
  healthCheckNodePort: 30000   # healthCheckNodePort defines the healthcheck node port for the LoadBalancer service type
{{- end }}
  ports:
  {{- if $serviceConfig.ports }}
    {{- range $serviceConfig.ports }}
    - port: {{ default 80 .port }}
      protocol: {{ default "TCP" .protocol }}
      name:  {{ default "http" .name }}
      targetPort: {{ default 80 (default .port .targetPort) }}
      {{- if .nodePort }}
      nodePort: {{ .nodePort }}
      {{- end }}
    {{- end }}
  {{- else }}
    - port: {{ default 80 $serviceConfig.port }}
      protocol: {{ default "TCP" $serviceConfig.protocol }}
      name:  {{ default "http" $serviceConfig.name }}
  {{- end }}
  selector:
    {{- include "common.selectorLabels" $root | nindent 4 }}
{{- end -}}