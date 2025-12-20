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
{{- if typeIs "string" $container.image -}}
  {{/* Simple string format: "nginx:latest" - used by tarot and other systems */}}
  {{- print $container.image -}}
{{- else if and $container.container $container.container.image -}}
  {{/* Handle nested container.container.image structure */}}
  {{- if typeIs "string" $container.container.image -}}
    {{- printf $container.container.image -}}
  {{- else -}}
    {{- $repository := default "" (default ($root.Values.image).repository ($container.container.image).repository) -}}
    {{- $imageName := default "nginx" (default (include "common.name" $root) ($container.container.image).name) -}}
    {{- $imageTag := default "latest" ($container.container.image).tag -}}
    {{- if eq $repository "" -}}
      {{- printf "%s:%s" $imageName $imageTag -}}
    {{- else -}}
      {{- printf "%s/%s:%s" $repository $imageName $imageTag -}}
    {{- end -}}
  {{- end -}}
{{- else if $container.image -}}
  {{/* Structured format: {repository: "", name: "", tag: ""} */}}
  {{- $repository := default "" (default ($root.Values.image).repository ($container.image).repository) -}}
  {{- $imageName := default "nginx" (default (include "common.name" $root) ($container.image).name) -}}
  {{- $imageTag := default "latest" ($container.image).tag -}}
  {{- if eq $repository "" -}}
    {{- printf "%s:%s" $imageName $imageTag -}}
  {{- else -}}
    {{- printf "%s/%s:%s" $repository $imageName $imageTag -}}
  {{- end -}}
{{- else -}}
  {{/* Fallback to default */}}
  {{- printf "%s:latest" (include "common.name" $root) -}}
{{- end -}}
{{- end -}}

{{- define "summon.common.container" -}}
{{- $root := index . 0 -}}
{{- $containers := index . 1 -}}
{{- range $containerName, $container := $containers }}
- name: {{ include "summon.common.containerName" (list $root $container $containerName )}}
  image: {{ include "summon.getImage" (list $root $container ) }}
  {{- $pullPolicy := "IfNotPresent" }}
  {{- if $root.Values.image.pullPolicy }}
    {{- $pullPolicy = $root.Values.image.pullPolicy }}
  {{- end }}
  {{- if and $container.image (not (kindIs "string" $container.image)) }}
    {{- if $container.image.pullPolicy }}
      {{- $pullPolicy = $container.image.pullPolicy }}
    {{- end }}
  {{- end }}
  imagePullPolicy: {{ $pullPolicy }}
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
    {{- toYaml $container.args | nindent 4 }}
  {{- end }}
  {{- if $container.lifecycle }}
  lifecycle:
    {{- if $container.lifecycle.postStart }}
    postStart:
      {{- if $container.lifecycle.postStart.exec }}
      exec:
        command:
          {{- toYaml $container.lifecycle.postStart.exec.command | nindent 10 }}
      {{- else if $container.lifecycle.postStart.httpGet }}
      httpGet:
        {{- toYaml $container.lifecycle.postStart.httpGet | nindent 8 }}
      {{- end }}
    {{- end }}
    {{- if $container.lifecycle.preStop }}
    preStop:
      {{- if $container.lifecycle.preStop.exec }}
      exec:
        command:
          {{- toYaml $container.lifecycle.preStop.exec.command | nindent 10 }}
      {{- else if $container.lifecycle.preStop.httpGet }}
      httpGet:
        {{- toYaml $container.lifecycle.preStop.httpGet | nindent 8 }}
      {{- end }}
    {{- end }}
  {{- end }}
  {{- include "summon.common.workload.probes" ( default dict $container.probes ) | nindent 2 }}
    {{- with $container.resources }}
  resources:
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- /* Determine securityContext: use workload.securityContext for main container, $container.securityContext otherwise */ -}}
  {{- $containerSecCtx := dict -}}
  {{- if and (typeOf $containerName | eq "int") $root.Values.workload.securityContext -}}
    {{- /* Main container (numeric index): use workload.securityContext */ -}}
    {{- $containerSecCtx = $root.Values.workload.securityContext -}}
  {{- else if $container.securityContext -}}
    {{- /* SideCar/initContainer: use their own securityContext */ -}}
    {{- $containerSecCtx = $container.securityContext -}}
  {{- end -}}
  {{- with $containerSecCtx }}
  securityContext:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- include "summon.common.volumeMounts" $root | nindent 2 }}
  {{- include "summon.common.envs.envFrom" $root | nindent 2 }}
  {{- include "summon.common.envs.env" $root | nindent 2 }}
  {{- include "summon.container.ports" (list $root $container) | nindent 2 }}
{{- end }}

{{- end -}}


##hay q definir como se levantan los volume mounts

##hay q definir como se levantan los volume mounts