{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
 */}}
{{- define "summon.common.volumes"}}
volumes:
  {{- if .Values.configMaps }}
    {{- include "summon.common.volumes.configMaps" .Values.configMaps | nindent 2 -}}
  {{- end }}
  {{- if .Values.secrets }}
    {{- include "summon.common.volumes.secrets" .Values.secrets | nindent 2 -}}
  {{- end }}
  {{- if .Values.volumes }}
    {{- include "summon.common.volumes.volumes" . | nindent 2 -}}
  {{- end }}
{{- end -}}


{{- define "summon.common.volumes.volumes" -}}
  {{- range $name, $volume := .Values.volumes }}
- name: {{ $name }}
  {{- if eq $volume.type "emptyDir" }}
  emptyDir:
    {{- if $volume.inMemory }} 
      medium: "Memory"
    {{- end }}
      sizeLimit: {{default "" $volume.size}}
    {{- end }}
  {{- if eq $volume.type "hostPath" }}
  hostPath: 
    path: {{ $volume.path }}
    type: Directory
    {{- end }}
  {{- if eq $volume.type "nfs" }}
  nfs:
    server: {{ $volume.server }}
    path: {{ $volume.path }}
    {{- end }}
  {{- if eq $volume.type "pvc" }}
  persistentVolumeClaim:
    {{- $pvcName := "" }}
    {{- if $volume.name }}
      {{- $pvcName = $volume.name }}
    {{- else }}
      {{- $pvcName = print (include "common.name" $ ) "-" $name }}
    {{- end }}
    claimName: {{ $pvcName }}
  {{- end }}
{{- end }}
{{- end }}

{{- define "summon.common.volumes.configMaps" -}}
  {{- range $name, $content := .  }}
    {{- if ne ( default "file" .contentType ) "env" }}
- name: {{ ( default $name $content.name ) | replace "." "-"}}
  configMap:
    name: {{ ( default $name $content.name ) | replace "." "-" }}
    {{- if $content.defaultMode }}
    defaultMode: {{ $content.defaultMode }}
    {{- end }}
    {{- if $content.items }}
    items:
      {{- range $content.items }}
      - key: {{ .key }}
        path: {{ .path }}
        {{- if .mode }}
        mode: {{ .mode }}
        {{- end }}
      {{- end }}
    {{- end }}
    {{- end }}
  {{- end }}
{{- end -}}

{{- define "summon.common.volumes.secrets" -}}
  {{- range $name, $content := . }}
    {{- if ne ( default "file" .contentType ) "env" }}
- name: {{ ( default $name $content.name ) | replace "." "-"}}
  secret:
    secretName: {{ ( default $name $content.name ) | replace "." "-" }}
    {{- if $content.defaultMode }}
    defaultMode: {{ $content.defaultMode }}
    {{- end }}
    {{- if $content.items }}
    items:
      {{- range $content.items }}
      - key: {{ .key }}
        path: {{ .path }}
        {{- if .mode }}
        mode: {{ .mode }}
        {{- end }}
      {{- end }}
    {{- end }}
    {{- end }}
  {{- end }}
{{- end -}}