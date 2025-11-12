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
  {{- if .Values.workload.volumeClaimTemplates }}
    {{- include "summon.common.volumeMounts.volumeClaimTemplates" .Values.workload.volumeClaimTemplates | nindent 2 -}}
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
    {{- if ne ( default "file" .contentType ) "env" }}
    {{- $fileName := ( default $name $content.name ) | replace "." "-" }}
- name: {{ $fileName }}
  {{- if $content.items }}
  {{/* If items are defined, mountPath is the directory */}}
  mountPath: {{ $content.mountPath }}
  {{- else }}
  {{/* If no items, mountPath includes filename (legacy behavior) */}}
  mountPath: {{ $content.mountPath }}/{{ ( default $name $content.name ) }}
  {{- end }}
  {{- if $content.subPath }}
  subPath: {{ $content.subPath }}
  {{- else if not $content.items }}
  {{/* Only use default subPath if items are NOT defined (single file mount) */}}
  subPath: {{ $fileName }}
  {{- end }}
    {{- end }}
  {{- end }}
{{- end -}}

{{- define "summon.common.volumeMounts.secrets" -}}
  {{- range $name, $content := . }}
    {{- if ne ( default "file" .contentType ) "env" }}
- name: {{ ( default $name $content.name ) | replace "." "-"}}
  mountPath: {{ $content.mountPath }}
  {{- if $content.subPath }}
  subPath: {{ $content.subPath }}
  {{- else if not $content.items }}
  {{/* Only use default subPath if items are NOT defined (single file mount) */}}
  subPath: {{ ( default $name $content.name ) | replace "." "-" }}
  {{- end }}
    {{- end }}
  {{- end }}
{{- end -}}

{{- define "summon.common.volumeMounts.volumeClaimTemplates" -}}
  {{- range $name, $content := . }}
- name: {{ $name }}
  mountPath: {{ $content.destinationPath }}
    {{- if $content.readOnly }}
  readOnly: {{ $content.readOnly }}
    {{- end }}
  {{- end }}
{{- end -}}


