{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
 */}}
{{- define "summon.serviceAccount" }}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1}}
{{- if $glyphDefinition.enabled }}
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ default (include "common.name" $root ) $glyphDefinition.name }}
  labels:
    {{- include "common.labels" $root | nindent 4 }}
  {{- with $glyphDefinition.labels }}
    {{- toYaml . | nindent 4 }}
  {{- end }}    
  annotations:
    {{- include "common.annotations" $root | nindent 4 }}
  {{- with $glyphDefinition.annotations }}
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- if $glyphDefinition.secret }}
secrets:
  - name: {{ $glyphDefinition.secret }}
  {{- end }}
  {{- if $glyphDefinition.automountServiceAccountToken }}
automountServiceAccountToken:
  - name: true
  {{- end }}
  {{- if $glyphDefinition.imagePullSecrets }}
    {{- if eq (kindOf $glyphDefinition.imagePullSecrets) "string" }}
secrets: ##TODO WTF
 - name: {{ $glyphDefinition.imagePullSecrets }}
    {{- else }}
  secrets:
      {{ range $glyphDefinition.imagePullSecrets }}
 - name: {{ . }}
      {{- end }} 
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}