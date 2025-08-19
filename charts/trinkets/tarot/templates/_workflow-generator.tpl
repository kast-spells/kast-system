{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

Workflow Generation Templates
Generates Argo Workflow resources based on tarot reading and execution mode
*/}}

{{/*
Generate workflow template for a single card
Parameters: (list $root $cardName $cardDef $resolvedCard $dependencies)
Returns: Argo Workflow template definition
*/}}
{{- define "tarot.generateCardTemplate" -}}
{{- $root := index . 0 -}}
{{- $cardName := index . 1 -}}
{{- $cardDef := index . 2 -}}
{{- $resolvedCard := index . 3 -}}
{{- $dependencies := index . 4 | default list -}}

- name: {{ $cardName }}
  {{- if $resolvedCard.container }}
  container:
    {{/* Use summon image resolution */}}
    image: {{ include "summon.getImage" (list $root $resolvedCard) | quote }}
    {{- if $resolvedCard.container.command }}
    command:
    {{- range $resolvedCard.container.command }}
      - {{ . | quote }}
    {{- end }}
    {{- end }}
    {{- if $resolvedCard.container.args }}
    args:
    {{- range $resolvedCard.container.args }}
      - {{ . | quote }}
    {{- end }}
    {{- end }}
    {{- if or $root.Values.envs $cardDef.envs $root.Values.secrets $cardDef.secrets }}
    env:
      {{- include "tarot.injectEnvironmentVars" (list $root $resolvedCard.container ($cardDef.secrets | default dict) ($cardDef.envs | default dict)) | nindent 6 }}
    {{- end }}
    {{- if or $cardDef.volumes $root.Values.secrets $cardDef.secrets }}
    volumeMounts:
      {{- include "tarot.injectVolumeMounts" (list $root $resolvedCard.container ($cardDef.secrets | default dict) ($resolvedCard.volumes | default list)) | nindent 6 }}
    {{- end }}
    {{- if $resolvedCard.container.resources }}
    resources:
      {{- $resolvedCard.container.resources | toYaml | nindent 6 }}
    {{- end }}
    {{- if $resolvedCard.container.securityContext }}
    securityContext:
      {{- $resolvedCard.container.securityContext | toYaml | nindent 6 }}
    {{- end }}
    {{- if $resolvedCard.container.workingDir }}
    workingDir: {{ $resolvedCard.container.workingDir | quote }}
    {{- end }}
  {{- end }}
  {{- if $resolvedCard.script }}
  script:
    image: {{ $resolvedCard.script.image | quote }}
    command: {{ $resolvedCard.script.command | default list | toYaml }}
    source: |
      {{- $resolvedCard.script.source | nindent 6 }}
    {{- if or $root.Values.envs $cardDef.envs }}
    env:
      {{- include "tarot.injectEnvironmentVars" (list $root $resolvedCard.script ($cardDef.secrets | default dict) ($cardDef.envs | default dict)) | nindent 6 }}
    {{- end }}
  {{- end }}
  {{- if $resolvedCard.suspend }}
  suspend:
    {{- $resolvedCard.suspend | toYaml | nindent 4 }}
  {{- end }}
  {{- if $resolvedCard.resource }}
  resource:
    {{- $resolvedCard.resource | toYaml | nindent 4 }}
  {{- end }}
  {{- if $cardDef.parallelism }}
  parallelism: {{ $cardDef.parallelism }}
  {{- end }}
  {{- if $cardDef.nodeSelector }}
  nodeSelector:
    {{- $cardDef.nodeSelector | toYaml | nindent 4 }}
  {{- end }}
  {{- if $cardDef.tolerations }}
  tolerations:
    {{- $cardDef.tolerations | toYaml | nindent 4 }}
  {{- end }}
  {{- if $cardDef.affinity }}
  affinity:
    {{- $cardDef.affinity | toYaml | nindent 4 }}
  {{- end }}

{{- end }}

{{/*
Generate DAG task definition for a card
Parameters: (list $root $cardName $cardDef $dependencies)
Returns: DAG task definition
*/}}
{{- define "tarot.generateDAGTask" -}}
{{- $root := index . 0 -}}
{{- $cardName := index . 1 -}}
{{- $cardDef := index . 2 -}}
{{- $dependencies := index . 3 | default list -}}

- name: {{ $cardName }}
  template: {{ $cardName }}
  {{- if $dependencies }}
  {{- if gt (len $dependencies) 0 }}
  dependencies:
    {{- range $dependencies }}
    - {{ . }}
    {{- end }}
  {{- end }}
  {{- end }}
  {{- if $cardDef.with }}
  arguments:
    parameters:
    {{- range $paramName, $paramValue := $cardDef.with }}
      - name: {{ $paramName }}
        value: {{ include "tarot.resolveValue" (list $root $paramValue) | quote }}
    {{- end }}
  {{- end }}
{{- end -}}

{{/*
Generate steps definition for a card
Parameters: (list $root $cardName $cardDef)
Returns: Steps definition
*/}}
{{- define "tarot.generateStep" -}}
{{- $root := index . 0 -}}
{{- $cardName := index . 1 -}}
{{- $cardDef := index . 2 -}}

- - name: {{ $cardName }}
    template: {{ $cardName }}
    {{- if $cardDef.with }}
    arguments:
      parameters:
      {{- range $paramName, $paramValue := $cardDef.with }}
        - name: {{ $paramName }}
          value: {{ include "tarot.resolveValue" (list $root $paramValue) | quote }}
      {{- end }}
    {{- end }}
{{- end -}}

{{/*
Generate main workflow entrypoint based on execution mode
Parameters: (list $root $allCards $resolvedCards)
Returns: Main template definition
*/}}
{{- define "tarot.generateMainTemplate" -}}
{{- $root := index . 0 -}}
{{- $allCards := index . 1 -}}
{{- $resolvedCards := index . 2 -}}
{{- $executionMode := $root.Values.tarot.executionMode | default "dag" -}}

- name: main
  {{- if eq $executionMode "container" }}
  {{/* Single container execution */}}
  {{- $firstCard := "" -}}
  {{- range $cardName, $cardDef := $allCards -}}
    {{- if not $firstCard -}}
      {{- $firstCard = $cardName -}}
    {{- end -}}
  {{- end -}}
  {{- if $firstCard -}}
    {{- $cardDef := index $allCards $firstCard -}}
    {{- $resolvedCard := index $resolvedCards $firstCard -}}
  {{- if $resolvedCard.container }}
  container:
    image: {{ include "summon.getImage" (list $root $resolvedCard) | quote }}
    {{- if $resolvedCard.container.command }}
    command:
      {{- $resolvedCard.container.command | toYaml | nindent 6 }}
    {{- end }}
    {{- if $resolvedCard.container.args }}
    args:
      {{- $resolvedCard.container.args | toYaml | nindent 6 }}
    {{- end }}
  {{- end }}
  {{- end }}

  {{- else if eq $executionMode "dag" }}
  {{/* DAG execution with dependencies */}}
  dag:
    tasks:
    {{- range $cardName, $cardDef := $allCards }}
      {{- $dependencies := list }}
      {{- if $cardDef.depends }}
        {{- $dependencies = $cardDef.depends }}
      {{- end }}
      {{- include "tarot.generateDAGTask" (list $root $cardName $cardDef $dependencies) | nindent 4 }}
    {{- end }}

  {{- else if eq $executionMode "steps" }}
  {{/* Sequential/parallel steps execution */}}
  steps:
    {{/* Group cards by position for step ordering */}}
    {{- $foundationCards := list -}}
    {{- $actionCards := list -}}
    {{- $challengeCards := list -}}
    {{- $outcomeCards := list -}}
    
    {{- range $cardName, $cardDef := $allCards -}}
      {{- $position := $cardDef.position | default "action" -}}
      {{- if eq $position "foundation" -}}
        {{- $foundationCards = append $foundationCards $cardName -}}
      {{- else if eq $position "action" -}}
        {{- $actionCards = append $actionCards $cardName -}}
      {{- else if eq $position "challenge" -}}
        {{- $challengeCards = append $challengeCards $cardName -}}
      {{- else if eq $position "outcome" -}}
        {{- $outcomeCards = append $outcomeCards $cardName -}}
      {{- end -}}
    {{- end -}}
    
    {{/* Generate steps in position order */}}
    {{- if $foundationCards }}
    {{- range $foundationCards }}
      {{- $cardDef := index $allCards . }}
      {{- include "tarot.generateStep" (list $root . $cardDef) | nindent 4 }}
    {{- end }}
    {{- end }}
    
    {{- if $actionCards }}
    {{- range $actionCards }}
      {{- $cardDef := index $allCards . }}
      {{- include "tarot.generateStep" (list $root . $cardDef) | nindent 4 }}
    {{- end }}
    {{- end }}
    
    {{- if $challengeCards }}
    {{- range $challengeCards }}
      {{- $cardDef := index $allCards . }}
      {{- include "tarot.generateStep" (list $root . $cardDef) | nindent 4 }}
    {{- end }}
    {{- end }}
    
    {{- if $outcomeCards }}
    {{- range $outcomeCards }}
      {{- $cardDef := index $allCards . }}
      {{- include "tarot.generateStep" (list $root . $cardDef) | nindent 4 }}
    {{- end }}
    {{- end }}

  {{- else if eq $executionMode "suspend" }}
  {{/* Suspend execution with approval gates */}}
  steps:
    {{- range $cardName, $cardDef := $allCards }}
      {{- include "tarot.generateStep" (list $root $cardName $cardDef) | nindent 4 }}
    {{- end }}

  {{- else }}
  {{/* Default to DAG for unknown execution modes */}}
  dag:
    tasks:
    {{- range $cardName, $cardDef := $allCards }}
      {{- $dependencies := list }}
      {{- if $cardDef.depends }}
        {{- $dependencies = $cardDef.depends }}
      {{- end }}
      {{- include "tarot.generateDAGTask" (list $root $cardName $cardDef $dependencies) | nindent 4 }}
    {{- end }}
  {{- end }}
{{- end -}}

{{/*
Generate all card templates
Parameters: (list $root $allCards $resolvedCards)
Returns: All card template definitions
*/}}
{{- define "tarot.generateAllCardTemplates" -}}
{{- $root := index . 0 -}}
{{- $allCards := index . 1 -}}
{{- $resolvedCards := index . 2 -}}

{{- range $cardName, $cardDef := $allCards }}
{{- $resolvedCard := index $resolvedCards $cardName }}
{{- $dependencies := include "tarot.getCardDependencies" (list $cardName $cardDef $allCards) | fromJson }}
{{- include "tarot.generateCardTemplate" (list $root $cardName $cardDef $resolvedCard $dependencies) }}
{{ "" }}
{{- end }}
{{- end -}}