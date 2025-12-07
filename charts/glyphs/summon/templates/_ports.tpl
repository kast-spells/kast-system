{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

Port-related helper functions for summon workloads
*/}}

{{/*
summon.defaultPortName generates default port name

Only one default: port 80 → "http"
Everything else → "port-{number}"

Usage:
  {{ include "summon.defaultPortName" 80 }}
  Returns: "http"

Parameters:
  - Port number (integer)

Returns:
  - "http" for port 80, otherwise "port-{number}"
*/}}
{{- define "summon.defaultPortName" -}}
{{- $port := . -}}
{{- if eq (int $port) 80 -}}
http
{{- else -}}
port-{{ $port }}
{{- end -}}
{{- end -}}

{{/*
summon.container.ports generates container port definitions

Decision tree:
1. If containers[].ports[] defined → use those (container-first)
2. Else if service.ports[] defined → generate from service (backward compatible)
3. Else → no ports

Usage:
  {{- include "summon.container.ports" (list $root $container) }}

Parameters:
  - list with:
    - $root: Chart root context
    - $container: Container definition

Returns:
  - YAML ports array for container spec
*/}}
{{- define "summon.container.ports" -}}
{{- $root := index . 0 -}}
{{- $container := index . 1 -}}

{{- if $container.ports }}
  {{/* PHASE 2: Container ports explicitly defined (container-first) */}}
ports:
  {{- range $container.ports }}
  - name: {{ .name | default (include "summon.defaultPortName" .containerPort) }}
    containerPort: {{ .containerPort }}
    protocol: {{ .protocol | default "TCP" }}
  {{- end }}

{{- else if $root.Values.service.ports }}
  {{/* FALLBACK: Generate from service.ports[] (backward compatible) */}}
ports:
  {{- range $root.Values.service.ports }}
  - name: {{ .name | default (include "summon.defaultPortName" (.targetPort | default .port | default 80)) }}
    containerPort: {{ .targetPort | default .port | default 80 }}
    protocol: {{ .protocol | default "TCP" }}
  {{- end }}

{{- else if $root.Values.services }}
  {{/* PHASE 3: Multiple services - collect unique ports from all services */}}
  {{- $uniquePorts := dict }}
  {{- range $serviceName, $serviceConfig := $root.Values.services }}
    {{- range $serviceConfig.ports }}
      {{- $portKey := printf "%v-%s" (.targetPort | default .port) (.protocol | default "TCP") }}
      {{- if not (hasKey $uniquePorts $portKey) }}
        {{- $_ := set $uniquePorts $portKey (dict "port" (.targetPort | default .port) "protocol" (.protocol | default "TCP") "name" (.name | default "")) }}
      {{- end }}
    {{- end }}
  {{- end }}
  {{- if gt (len $uniquePorts) 0 }}
ports:
    {{- range $portKey, $portDef := $uniquePorts }}
  - name: {{ $portDef.name | default (include "summon.defaultPortName" $portDef.port) }}
    containerPort: {{ $portDef.port }}
    protocol: {{ $portDef.protocol }}
    {{- end }}
  {{- end }}

{{- end }}
{{- end -}}

{{/*
summon.resolveTargetPort resolves targetPort reference to actual port number

Supports:
- Numeric targetPort: returns as-is
- Named targetPort: looks up in containers[].ports[] by name

Usage:
  {{ include "summon.resolveTargetPort" (list $root .targetPort) }}

Parameters:
  - list with:
    - $root: Chart root context
    - targetPort: Port reference (number or name string)

Returns:
  - Port number or original value if not found
*/}}
{{- define "summon.resolveTargetPort" -}}
{{- $root := index . 0 -}}
{{- $targetPort := index . 1 -}}

{{- if kindIs "string" $targetPort }}
  {{/* Named reference - search in containers[].ports[] */}}
  {{- $found := false }}
  {{- range $containerName, $container := $root.Values.containers }}
    {{- range $container.ports }}
      {{- if eq .name $targetPort }}
        {{- print .containerPort -}}
        {{- $found = true }}
      {{- end }}
    {{- end }}
  {{- end }}
  {{- if not $found }}
    {{/* Fallback: return name as-is (will be resolved by K8s) */}}
    {{- print $targetPort -}}
  {{- end }}
{{- else }}
  {{/* Numeric port - return as-is */}}
  {{- print $targetPort -}}
{{- end }}
{{- end -}}
