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
{{- if $root.Values.serviceAccount.enabled }}
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ default (include "common.name" $root) $root.Values.serviceAccount.name }}
  labels:
    {{- include "common.labels" $root | nindent 4 }}
  {{- with $root.Values.serviceAccount.labels }}
    {{- toYaml . | nindent 4 }}
  {{- end }}    
  annotations:
    {{- include "common.annotations" $root | nindent 4 }}
  {{- with $root.Values.serviceAccount.annotations }}
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- if $root.Values.serviceAccount.secret }}
secrets:
  - name: {{ $root.Values.serviceAccount.secret }}
  {{- end }}
  {{- if $root.Values.serviceAccount.automountServiceAccountToken }}
automountServiceAccountToken:
  - name: true
  {{- end }}
  {{- if $root.Values.serviceAccount.imagePullSecrets }}
    {{- if eq (kindOf $root.Values.serviceAccount.imagePullSecrets) "string" }}
secrets: ##TODO WTF
 - name: {{ $root.Values.serviceAccount.imagePullSecrets }}
    {{- else }}
  secrets:
      {{ range $root.Values.serviceAccount.imagePullSecrets }}
 - name: {{ . }}
      {{- end }} 
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}