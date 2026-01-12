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
    {{- include "common.all.labels" $root | nindent 4 }}
    {{- with $serviceConfig.labels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- with $serviceConfig.annotations }}
  annotations:
    {{- include "common.annotations" $root | nindent 4 }}
    {{- toYaml . | nindent 4 }}
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
  {{- if $serviceConfig.clusterIP }}
  clusterIP: {{ $serviceConfig.clusterIP }}
  {{- end }}
  {{- if $serviceConfig.publishNotReadyAddresses }}
  publishNotReadyAddresses: {{ $serviceConfig.publishNotReadyAddresses }}
  {{- end }}
  ports:
  {{- if $serviceConfig.ports }}
    {{- range $serviceConfig.ports }}
    {{- $targetPortValue := .targetPort | default .port | default 80 }}
    {{- $portValue := .port | default $targetPortValue }}
    - port: {{ $portValue }}
      protocol: {{ .protocol | default "TCP" }}
      name: {{ .name | default (include "summon.defaultPortName" $portValue) }}
      targetPort: {{ $targetPortValue }}
      {{- if .nodePort }}
      nodePort: {{ .nodePort }}
      {{- end }}
    {{- end }}
  {{- else }}
    - port: {{ $serviceConfig.port | default 80 }}
      protocol: {{ $serviceConfig.protocol | default "TCP" }}
      name: {{ $serviceConfig.name | default "http" }}
  {{- end }}
  selector:
    {{- include "common.selectorLabels" $root | nindent 4 }}
{{- end -}}

{{/*
summon.services.render renders one or multiple Service resources

Decision tree:
1. If services[] (plural) defined → render multiple services (PHASE 3)
2. Else if service.enabled → render single service with smart defaults (PHASE 2)
3. Else → no services

Usage:
  {{- include "summon.services.render" . }}

Parameters:
  - Root context

Returns:
  - One or more Service resources
*/}}
{{- define "summon.services.render" -}}
{{- $root := . -}}

{{- if .Values.services }}
  {{/* PHASE 3: Multiple services */}}
  {{- range $serviceName, $serviceConfig := .Values.services }}
    {{- $enabled := true }}
    {{- if hasKey $serviceConfig "enabled" }}
      {{- $enabled = $serviceConfig.enabled }}
    {{- end }}
    {{- if $enabled }}
      {{- $fullServiceName := printf "%s-%s" (include "common.name" $root) $serviceName }}
      {{- include "summon.service" (list $root $serviceConfig $fullServiceName) }}
    {{- end }}
  {{- end }}

{{- else if .Values.service.enabled }}
  {{/* PHASE 2: Single service with smart defaults */}}
  {{- if .Values.service.ports }}
    {{/* Explicit service.ports defined - use as-is */}}
    {{- include "summon.service" (list $root .Values.service nil) }}

  {{- else if .Values.containers }}
    {{/* PHASE 2: Auto-generate service.ports from containers[].ports[] */}}
    {{- $autoServiceConfig := dict "type" (.Values.service.type | default "ClusterIP") }}

    {{/* Copy other service config */}}
    {{- if .Values.service.annotations }}
      {{- $_ := set $autoServiceConfig "annotations" .Values.service.annotations }}
    {{- end }}
    {{- if .Values.service.labels }}
      {{- $_ := set $autoServiceConfig "labels" .Values.service.labels }}
    {{- end }}
    {{- if .Values.service.clusterIP }}
      {{- $_ := set $autoServiceConfig "clusterIP" .Values.service.clusterIP }}
    {{- end }}

    {{/* Collect all container ports */}}
    {{- $autoPorts := list }}
    {{- range $containerName, $container := .Values.containers }}
      {{- if $container.ports }}
        {{- range $container.ports }}
          {{- $portDef := dict "port" .containerPort "targetPort" .containerPort "name" (.name | default (include "summon.defaultPortName" .containerPort)) "protocol" (.protocol | default "TCP") }}
          {{- $autoPorts = append $autoPorts $portDef }}
        {{- end }}
      {{- end }}
    {{- end }}

    {{- if gt (len $autoPorts) 0 }}
      {{- $_ := set $autoServiceConfig "ports" $autoPorts }}
      {{- include "summon.service" (list $root $autoServiceConfig nil) }}
    {{- end }}

  {{- else }}
    {{/* FALLBACK: Original behavior (from service.port single value) */}}
    {{- include "summon.service" (list $root .Values.service nil) }}
  {{- end }}
{{- end }}
{{- end -}}