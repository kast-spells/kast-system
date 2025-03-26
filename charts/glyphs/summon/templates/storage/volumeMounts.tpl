{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
 */}}
{{- define "summon.common.volumeMounts" }}
volumeMounts:
  {{- if .Values.configMaps }}
    {{- include "summon.common.volumeMounts.configMaps" .Values.configMaps | nindent 2 -}}
  {{- end }}
  {{- if .Values.secrets }}
    {{- include "summon.common.volumeMounts.secrets" .Values.secrets | nindent 2 -}}
  {{- end }}
  {{- if .Values.volumes }}
    {{- include "summon.common.volumeMounts.volumes" .Values.volumes | nindent 2 -}}
  {{- end }}
{{- end -}}

{{- define "summon.common.volumeMounts.volumes" -}}
  {{- range $name, $content := . }}
- name: {{ $name }}
  mountPath: {{ $content.destinationPath }}
    {{- if .readOnly }}
  readOnly: {{ .readOnly }}
    {{- end }}
  {{- end }}
{{- end }}
## TODO el name deberia incluir la common.name
{{- define "summon.common.volumeMounts.configMaps" -}}
  {{- range $name, $content := .  }}
    {{- if and ( or (eq ( default "local" $content.location ) "local") (eq $content.location "create") ) (eq .type "file") }}
- name: {{ ( default $name $content.name ) | replace "." "-"}}
  mountPath: {{ $content.mountPath }}
  subPath: {{ default $name $content.key }}
    {{- end }}
  {{- end }}
{{- end -}}

{{- define "summon.common.volumeMounts.secrets" -}}
  {{- range $name, $content := . }}
    {{- if eq .type "file" }}
- name: {{ ( default $name $content.name ) | replace "." "-"}}
  mountPath: {{ $content.mountPath }}
  subPath: {{ default $name $content.key }}
    {{- end }}
  {{- end }}
{{- end -}}


