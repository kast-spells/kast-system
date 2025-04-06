{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
*/ -}}
{{- define "common.infra.labels" -}}
spelbook: {{ .Values.spellbook.name }}
chapter: {{ .Values.chapter.name }}
spell: {{ default .Chart.Name .Values.name }}
{{- end -}}

{{- define "common.infra.annotations" -}}
spelbook: {{ .Values.spellbook.name }}
{{- end -}}
