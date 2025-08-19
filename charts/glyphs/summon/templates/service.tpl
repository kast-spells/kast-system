{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

summon.service creates Service resources for summon workloads
Supports both direct usage and glyph parameter pattern

Parameters:
- Direct usage: . (root context)
- Glyph usage: (list $root $glyphDefinition)

Usage:
- Direct: {{- include "summon.service" . }}
- Glyph: {{- include "summon.service" (list $root $glyphDefinition) }}
 */}}
{{- define "summon.service" }}
{{- if kindIs "slice" . }}
  {{- $root := index . 0 }}
  {{- $glyphDefinition := index . 1 }}
  {{- $resourceName := default (include "common.name" $root) $glyphDefinition.name }}
  {{- $serviceConfig := $glyphDefinition.service }}
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
{{- if eq $serviceConfig.type "LoadBalancerSpecial"}}
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
{{- else }}
{{/* Direct usage - use $root for clarity */}}
{{- $root := . }}
---
apiVersion: v1
kind: Service
metadata:
  name: {{ include "common.name" $root }}
  labels:
    {{- include "common.labels" $root | nindent 4 }}
  {{- with $root.Values.service.annotations }}
  annotations:
    {{- . | toYaml | nindent 4 }}
  {{- end }}
spec:
  type: {{ default "ClusterIP" $root.Values.service.type }}
{{- if eq $root.Values.service.type "LoadBalancerSpecial"}}
## this is a placeholder
  loadBalancerIP: 1.2.3.4
  loadBalancerSourceRanges: #supported on EKS, GKS and AKS at least
    - 130.211.204.1/32 # loadBalancerSourceRanges defines the IP ranges that are allowed to access the load balancer
  healthCheckNodePort: 30000   # healthCheckNodePort defines the healthcheck node port for the LoadBalancer service type
{{- end }}
  ports:
  {{- if $root.Values.service.ports }}
    {{- range $root.Values.service.ports }}
    - port: {{ default 80 .port }}
      protocol: {{ default "TCP" .protocol }}
      name:  {{ default "http" .name }}
      targetPort: {{ default 80 (default .port .targetPort) }}
      {{- if .nodePort }}
      nodePort: {{ .nodePort }}
      {{- end }}
    {{- end }}
  {{- else }}
    - port: {{ default 80 $root.Values.service.port }}
      protocol: {{ default "TCP" $root.Values.service.protocol }}
      name:  {{ default "http" $root.Values.service.name }}
  {{- end }}
  selector:
    {{- include "common.selectorLabels" $root | nindent 4 }}
{{- end }}
{{- end}}