{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
*/}}

{{/*
FinOps / Cost Allocation Labels
These labels are used by tools like Kubecost for cost allocation and tracking.
Enable via: .Values.labels.finops.enabled

Recommended for:
- Kubecost cost allocation
- Cloud cost tracking and chargeback
- Resource usage analytics

Usage in values.yaml:
  labels:
    finops:
      enabled: true
      team: platform-team
      owner: john.doe
      costCenter: engineering
      environment: production  # Falls back to chapter.name if not set
*/}}
{{- define "common.finops.labels" -}}
{{- if .Values.labels }}
{{- if .Values.labels.finops }}
{{- if .Values.labels.finops.enabled }}
{{- with .Values.labels.finops.team }}
team: {{ . }}
{{- end }}
{{- with .Values.labels.finops.owner }}
owner: {{ . }}
{{- end }}
{{- with .Values.labels.finops.costCenter }}
cost-center: {{ . }}
{{- end }}
{{- with .Values.labels.finops.department }}
department: {{ . }}
{{- end }}
{{- with .Values.labels.finops.project }}
project: {{ . }}
{{- end }}
{{- if .Values.labels.finops.environment }}
environment: {{ .Values.labels.finops.environment }}
{{- else if .Values.chapter }}
{{- if .Values.chapter.name }}
environment: {{ .Values.chapter.name }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
