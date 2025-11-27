{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
*/ -}}
{{- define "common.infra.labels" -}}
{{- if .Values.spellbook }}
{{- if .Values.spellbook.name }}
spelbook: {{ .Values.spellbook.name }}
{{- end }}
{{- end }}
{{- if .Values.chapter }}
{{- if .Values.chapter.name }}
chapter: {{ .Values.chapter.name }}
{{- end }}
{{- end }}
{{- if .Values.name }}
spell: {{ .Values.name }}
{{- else if .Chart }}
{{- if .Chart.Name }}
spell: {{ .Chart.Name }}
{{- end }}
{{- end }}
{{- end -}}

{{- define "common.infra.annotations" -}}
{{- if .Values.spellbook }}
{{- if .Values.spellbook.name }}
spelbook: {{ .Values.spellbook.name }}
{{- end }}
{{- end }}
{{- end -}}
