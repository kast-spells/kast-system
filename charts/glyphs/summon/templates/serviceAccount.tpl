{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

summon.serviceAccount creates ServiceAccount resources for summon workloads
Supports both direct usage and glyph parameter pattern

Parameters:
- Direct usage: . (root context)
- Glyph usage: (list $root $glyphDefinition)

Usage:
- Direct: {{- include "summon.serviceAccount" . }}
- Glyph: {{- include "summon.serviceAccount" (list $root $glyphDefinition) }}
 */}}
{{- define "summon.serviceAccount" }}
{{- $root := . }}
{{- $glyphDefinition := dict }}
{{- $saConfig := dict }}

{{/* Detect if called with glyph pattern (list) or direct (root context) */}}
{{- if kindIs "slice" . }}
  {{- $root = index . 0 }}
  {{- $glyphDefinition = index . 1 }}
  {{/* Glyph mode: use glyphDefinition directly */}}
  {{- $saConfig = $glyphDefinition }}
{{- else }}
  {{/* Direct mode: use Values.serviceAccount */}}
  {{- $saConfig = $root.Values.serviceAccount }}
{{- end }}

{{- if $saConfig.enabled }}
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ default (include "common.name" $root) $saConfig.name }}
  {{- if $saConfig.namespace }}
  namespace: {{ $saConfig.namespace }}
  {{- end }}
  labels:
    {{- include "common.all.labels" $root | nindent 4 }}
    {{- with $saConfig.labels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- with $saConfig.annotations }}
  annotations:
    {{- include "common.annotations" $root | nindent 4 }}
    {{- toYaml . | nindent 4 }}
  {{- end }}
{{- if $saConfig.secret }}
secrets:
  - name: {{ $saConfig.secret }}
{{- end }}
{{- if $saConfig.automountServiceAccountToken }}
automountServiceAccountToken: true
{{- end }}
{{- if $saConfig.imagePullSecrets }}
  {{- if eq (kindOf $saConfig.imagePullSecrets) "string" }}
imagePullSecrets:
  - name: {{ $saConfig.imagePullSecrets }}
  {{- else }}
imagePullSecrets:
    {{- range $saConfig.imagePullSecrets }}
  - name: {{ . }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}
{{- end }}