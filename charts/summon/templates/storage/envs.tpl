{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
 */}}
{{- define "common.envs.envFrom"}}
envFrom:
  {{- if .Values.configMaps }}
    {{- include "common.envs.configMaps" .Values.configMaps | nindent 2 -}}
  {{- end }}
  {{- if .Values.secrets }}
    {{- include "common.envs.secrets" .Values.secrets | nindent 2 -}}
  {{- end }}
{{- end -}}

{{- define "common.envs.configMaps" -}}
  {{- range $name, $content := . -}}
    {{- if eq $content.type "env" }}
  - configMapRef:
      name: {{ $name | replace "." "-"  }}
    {{- end }}
  {{- end }}
{{- end -}}

{{- define "common.envs.secrets" -}}
  {{- range $name, $content := . }}
    {{- if eq $content.type "env" }}
  - secretRef:
      name: {{ $name | replace "." "-"}}
    {{- end -}}
  {{- end }}
{{- end -}}

{{- define "common.envs.env" -}}
env:
  {{- if .Values.spellbook }}
  - name: SPELLBOOK_NAME
    value: {{  .Values.spellbook.name }}
  - name: CHAPTER_NAME
    value: {{  .Values.chapter.name }}
  - name: SPELL_NAME
    value: {{ default .Release.name .Values.name }}
  {{- end }}
{{- range $key, $value := .Values.envs }}
{{- if eq (kindOf $value) "string" }}
  - name: {{ $key | upper }}
    value: {{ $value | quote }}
{{- else if eq (index $value "type") "secret" }}
  - name: {{ $key | upper }}
    valueFrom:
      secretKeyRef:
        name: {{ (index $value "name") }}
        key: {{ (index $value "key") }}
{{- else if eq (index $value "type") "configMap" }}
  - name: {{ $key }}
    valueFrom:
      configMap:
        name: {{ (index $value "name") }}
        key: {{ (index $value "key") }}
{{- end -}}
{{- end -}}
{{- end -}}
