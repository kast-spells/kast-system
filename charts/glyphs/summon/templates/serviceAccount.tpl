{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
 */}}
{{- define "summon.serviceAccount" }}
{{- if .Values.serviceAccount.enabled }}
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ default (include "common.name" . ) .Values.serviceAccount.name }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
  {{- with .Values.serviceAccount.labels }}
    {{- toYaml . | nindent 4 }}
  {{- end }}    
  annotations:
    {{- include "common.annotations" . | nindent 4 }}
  {{- with .Values.serviceAccount.annotations }}
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- if .Values.serviceAccount.secret }}
secrets:
  - name: {{ .Values.serviceAccount.secret }}
  {{- end }}
  {{- if .Values.serviceAccount.automountServiceAccountToken }}
automountServiceAccountToken:
  - name: true
  {{- end }}
  {{- if .Values.serviceAccount.imagePullSecrets }}
    {{- if eq (kindOf .Values.serviceAccount.imagePullSecrets) "string" }}
secrets: ##TODO WTF
 - name: {{ .Values.serviceAccount.imagePullSecrets }}
    {{- else }}
  secrets:
      {{ range .Values.serviceAccount.imagePullSecrets }}
 - name: {{ . }}
      {{- end }} 
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}