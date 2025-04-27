{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
 */}}
{{- define "summon.common.containerName" -}}
{{- /*## TODO fix name on the main container (hildy bot example)*/ -}}
{{- $root := index . 0 -}}
{{- $container := index . 1 -}}
{{- $containerName := index . 2 -}}
{{- $name := include "common.name" $root }}
{{- $ctName := ""}}
{{- if typeOf $containerName | eq "int" }}
{{- $ctName = "main" }}
{{- else }}
{{- $ctName = $containerName }}
{{- end }}
{{- if $container.name }}
{{- printf "%s-%s" $name  $container.name  }}
{{- else }}
{{- printf "%s-%s" $name  $ctName  }}
{{- end -}}
{{- end -}}

{{- define "summon.getImage" -}}
{{- $root := index . 0 -}}
{{- $container := index . 1 -}}
{{- $repository := default "" (default ($root.Values.image).repository ($container.image).repository) -}}
{{- $imageName := default "nginx" (default (include "common.name" $root) ($container.image).name) -}}
{{- $imageTag := default "latest" ($container.image).tag -}}
{{- if eq $repository "" }}
{{- printf "%s:%s" $imageName $imageTag -}}
{{- else }}
{{- printf "%s/%s:%s" $repository $imageName $imageTag -}}
{{- end -}}
{{- end -}}

{{- define "summon.common.container" -}}
{{- $root := index . 0 -}}
{{- $containers := index . 1 -}}
{{- range $containerName, $container := $containers }}
- name: {{ include "summon.common.containerName" (list $root $container $containerName )}}
  image: {{ include "summon.getImage" (list $root $container ) }}
  imagePullPolicy: {{ default "IfNotPresent" (default ($root.Values.image).pullPolicy ($container.image).pullPolicy ) }}
  {{- if $container.command }}
  {{- if eq ( kindOf $container.command ) "string" }}
  command: 
    - {{ $container.command }}
  {{- else }}
  command:
    {{- range $container.command }}
    - {{ . }}
    {{- end }}
  {{- end }}
  {{- end }}
  {{- if $container.args }}
  args:
    {{- range $container.args }}
    - {{ . }}
    {{- end }}
  {{- end }}
  {{- include "summon.common.workload.probes" ( default dict $container.probes ) | nindent 2 }}
    {{- with $container.resources }}
  resources:
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- include "summon.common.volumeMounts" $root | nindent 2 }}
  {{- include "summon.common.envs.envFrom" $root | nindent 2 }}
  {{- include "summon.common.envs.env" $root | nindent 2 }}
    {{- end }}
  {{- if $root.Values.service.enabled }}
  ports:
    {{- range $root.Values.service.ports }}
    - name: {{ default "http" .name }}
      containerPort: {{ default 80 .targetPort }}
      protocol: {{ default "TCP" .protocol }}
    {{- end }}
{{- end }}

{{- end -}}


##hay q definir como se levantan los volume mounts

##hay q definir como se levantan los volume mounts