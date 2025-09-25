{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
 */}}
{{- define "summon.common.envs.envFrom"}}
envFrom:
  {{- if .Values.configMaps }}
    {{- include "summon.common.envs.configMaps" .Values.configMaps | nindent 2 -}}
  {{- end }}
  {{- if .Values.secrets }}
    {{- include "summon.common.envs.secrets" .Values.secrets | nindent 2 -}}
  {{- end }}
{{- end -}}

{{- define "summon.common.envs.configMaps" -}}
  {{- range $name, $content := . -}}
    {{- if eq ( default "" $content.contentType ) "env" }}
  - configMapRef:
      name: {{ $name | replace "." "-"  }}
    {{- end }}
  {{- end }}
{{- end -}}

{{- define "summon.common.envs.secrets" -}}
  {{- range $name, $content := . }}
    {{- if eq ( default "" $content.contentType ) "env" }}
  - secretRef:
      name: {{ $name | replace "." "-"}}
    {{- end -}}
  {{- end }}
{{- end -}}

{{- define "summon.common.envs.env" -}}
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
      configMapKeyRef:
        name: {{ (index $value "name") }}
        key: {{ (index $value "key") }}
{{- end -}}
{{- end -}}
{{- end -}}
