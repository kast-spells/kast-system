{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
 */}}
{{- define "summon.common.volumes"}}
{{- $container := . }}
volumes:
  {{- if $container.configMaps }}
    {{- include "summon.common.volumes.configMaps" $container.configMaps | nindent 2 -}}
  {{- end }}
  {{- if $container.secrets }}
    {{- include "summon.common.volumes.secrets" $container.secrets | nindent 2 -}}
  {{- end }}
  {{- if $container.volumes }}
    {{- include "summon.common.volumes.volumes" $container | nindent 2 -}}
  {{- end }}
{{- end -}}


{{- define "summon.common.volumes.volumes" -}}
{{- $container := . }}
  {{- range $name, $volume := $container.volumes }}
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
    {{- if and ( or (eq ( default "local" $content.location ) "local") (eq $content.location "create") ) (eq .type "file") }}
- name: {{ ( default $name $content.name ) | replace "." "-"}}
  configMap: 
    name: {{ default $name $content.key }}
    {{- end }}
  {{- end }}
{{- end -}}

{{- define "summon.common.volumes.secrets" -}}
  {{- range $name, $content := . }}
    {{- if eq .type "file" }}
- name: {{ ( default $name $content.name ) | replace "." "-"}}
  secret: 
    secretName: {{ default $name $content.key }}
    {{- end }}
  {{- end }}
{{- end -}}