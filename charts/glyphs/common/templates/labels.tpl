{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
*/}}

{{/*
Official Kubernetes recommended labels
https://kubernetes.io/docs/concepts/overview/working-with-objects/common-labels/
These labels are always applied and follow the app.kubernetes.io/* standard.
*/}}
{{- define "common.labels" -}}
{{ include "common.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
{{- if .Values.component }}
app.kubernetes.io/component: {{ .Values.component }}
{{- end }}
{{- if .Values.spellbook }}
{{- if .Values.spellbook.name }}
app.kubernetes.io/part-of: {{ .Values.spellbook.name }}
{{- end }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels - used for pod selection
NOTE: These must remain stable and should not include mutable values
*/}}
{{- define "common.selectorLabels" -}}
app.kubernetes.io/name: {{ include "common.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
All labels combined
This helper combines all label sets based on enabled toggles:
- Official Kubernetes labels (always included)
- Infrastructure labels (always included)
- FinOps labels (if .Values.labels.finops.enabled)
- Covenant labels (if .Values.labels.covenant.enabled)

Usage:
  labels:
    {{- include "common.all.labels" $root | nindent 4 }}
*/}}
{{- define "common.all.labels" -}}
{{- include "common.labels" . }}
{{- include "common.infra.labels" . }}
{{- if .Values.labels }}
{{- if .Values.labels.finops }}
{{- if .Values.labels.finops.enabled }}
{{- include "common.finops.labels" . }}
{{- end }}
{{- end }}
{{- if .Values.labels.covenant }}
{{- if .Values.labels.covenant.enabled }}
{{- include "common.covenant.labels" . }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}