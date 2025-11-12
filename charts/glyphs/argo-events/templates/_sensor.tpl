{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

argo-events.sensor creates Sensor resources for Argo Events
Follows kast glyph parameter pattern with runic indexer integration

Parameters:
- Glyph usage: (list $root $glyphDefinition)

Usage:
- {{- include "argo-events.sensor" (list $root $glyphDefinition) }}

Example glyphDefinition:
  name: workflow-sensor
  selector:
    type: jetstream
    environment: production
  dependencies:
    - name: github-push
      eventSourceName: github-webhook
      eventName: my-repo
  triggers:
    - name: trigger-workflow
      type: argoWorkflow
      argoWorkflow:
        operation: submit
        source:
          resource:
            apiVersion: argoproj.io/v1alpha1
            kind: Workflow
 */}}
{{- define "argo-events.sensor" }}
{{- $root := index . 0 }}
{{- $glyphDefinition := index . 1 }}
{{- $resourceName := default (include "common.name" $root) $glyphDefinition.name }}

{{/* Find EventBus using runicIndexer */}}
{{- $eventBuses := get (include "runicIndexer.runicIndexer" (list $root.Values.lexicon (default dict $glyphDefinition.selector) "eventbus" $root.Values.chapter.name ) | fromJson) "results" }}

{{/* Find EventSources using runicIndexer if eventSourceSelector is provided */}}
{{- $eventSources := list }}
{{- if $glyphDefinition.eventSourceSelector }}
{{- $eventSources = get (include "runicIndexer.runicIndexer" (list $root.Values.lexicon (default dict $glyphDefinition.eventSourceSelector) "eventsource" $root.Values.chapter.name ) | fromJson) "results" }}
{{- end }}

{{/* Find Triggers using runicIndexer if triggerSelector is provided */}}
{{- $triggers := list }}
{{- if $glyphDefinition.triggerSelector }}
{{- $triggers = get (include "runicIndexer.runicIndexer" (list $root.Values.lexicon (default dict $glyphDefinition.triggerSelector) "trigger" $root.Values.chapter.name ) | fromJson) "results" }}
{{- end }}

{{- range $eventBus := $eventBuses }}
---
apiVersion: argoproj.io/v1alpha1
kind: Sensor
metadata:
  name: {{ $resourceName }}
  {{- if $eventBus.namespace }}
  namespace: {{ $eventBus.namespace }}
  {{- end }}
  labels:
    {{- include "common.labels" $root | nindent 4 }}
  {{- with $glyphDefinition.annotations }}
  annotations:
    {{- . | toYaml | nindent 4 }}
  {{- end }}
spec:
  eventBusName: {{ default $eventBus.name $glyphDefinition.eventBusName }}
  {{- if $glyphDefinition.template }}
  template:
    {{- with $glyphDefinition.template.serviceAccountName }}
    serviceAccountName: {{ . }}
    {{- end }}
    {{- if $glyphDefinition.template.container }}
    container:
      {{- $glyphDefinition.template.container | toYaml | nindent 6 }}
    {{- end }}
    {{- with $glyphDefinition.template.volumes }}
    volumes:
      {{- . | toYaml | nindent 6 }}
    {{- end }}
    {{- with $glyphDefinition.template.nodeSelector }}
    nodeSelector:
      {{- . | toYaml | nindent 6 }}
    {{- end }}
    {{- with $glyphDefinition.template.tolerations }}
    tolerations:
      {{- . | toYaml | nindent 6 }}
    {{- end }}
    {{- with $glyphDefinition.template.metadata }}
    metadata:
      {{- . | toYaml | nindent 6 }}
    {{- end }}
    {{- with $glyphDefinition.template.securityContext }}
    securityContext:
      {{- . | toYaml | nindent 6 }}
    {{- end }}
    {{- with $glyphDefinition.template.affinity }}
    affinity:
      {{- . | toYaml | nindent 6 }}
    {{- end }}
    {{- with $glyphDefinition.template.priorityClassName }}
    priorityClassName: {{ . }}
    {{- end }}
    {{- with $glyphDefinition.template.priority }}
    priority: {{ . }}
    {{- end }}
    {{- with $glyphDefinition.template.imagePullSecrets }}
    imagePullSecrets:
      {{- . | toYaml | nindent 6 }}
    {{- end }}
  {{- end }}
  {{- if or $glyphDefinition.dependencies (gt (len $eventSources) 0) }}
  dependencies:
    {{- if $glyphDefinition.dependencies }}
    {{/* Use inline dependencies (backward compatibility) */}}
    {{- range $glyphDefinition.dependencies }}
    - name: {{ .name }}
      {{- with .eventSourceName }}
      eventSourceName: {{ . }}
      {{- end }}
      {{- with .eventName }}
      eventName: {{ . }}
      {{- end }}
      {{- if .filters }}
      filters:
        {{- if .filters.expression }}
        expression: |
          {{- .filters.expression | nindent 10 }}
        {{- end }}
        {{- if .filters.exprs }}
        exprs:
          {{- range .filters.exprs }}
          - expr: {{ .expr }}
            {{- if .fields }}
            fields:
              {{- range .fields }}
              - name: {{ .name }}
                path: {{ .path }}
              {{- end }}
            {{- end }}
          {{- end }}
        {{- end }}
        {{- if .filters.data }}
        data:
          {{- range .filters.data }}
          - path: {{ .path }}
            type: {{ .type }}
            value:
              {{- .value | toYaml | nindent 14 }}
            {{- with .comparator }}
            comparator: {{ . }}
            {{- end }}
          {{- end }}
        {{- end }}
        {{- if .filters.context }}
        context:
          {{- .filters.context | toYaml | nindent 10 }}
        {{- end }}
        {{- if .filters.time }}
        time:
          {{- .filters.time | toYaml | nindent 10 }}
        {{- end }}
        {{- if .filters.script }}
        script: {{ .filters.script }}
        {{- end }}
      {{- end }}
      {{- if .transform }}
      transform:
        {{- .transform | toYaml | nindent 8 }}
      {{- end }}
    {{- end }}
    {{- else }}
    {{/* Build dependencies dynamically from eventSources found by runicIndexer */}}
    {{- range $eventSource := $eventSources }}
    - name: {{ $eventSource.name }}
      eventSourceName: {{ $eventSource.name }}
      eventName: {{ default $eventSource.name $eventSource.eventName }}
      {{- if $glyphDefinition.dependencyFilters }}
      filters:
        {{- $glyphDefinition.dependencyFilters | toYaml | nindent 8 }}
      {{- end }}
    {{- end }}
    {{- end }}
  {{- end }}
  {{- if or $glyphDefinition.triggers (gt (len $triggers) 0) }}
  triggers:
    {{- if $glyphDefinition.triggers }}
    {{/* Use inline triggers (backward compatibility) */}}
    {{- range $glyphDefinition.triggers }}
    - template:
        name: {{ .name }}
        {{- if eq .type "argoWorkflow" }}
        argoWorkflow:
          {{- with .argoWorkflow.operation }}
          operation: {{ . }}
          {{- end }}
          {{- if .argoWorkflow.source }}
          source:
            {{- if .argoWorkflow.source.resource }}
            resource:
              {{- .argoWorkflow.source.resource | toYaml | nindent 14 }}
            {{- end }}
            {{- if .argoWorkflow.source.file }}
            file:
              {{- .argoWorkflow.source.file | toYaml | nindent 14 }}
            {{- end }}
            {{- if .argoWorkflow.source.url }}
            url:
              {{- .argoWorkflow.source.url | toYaml | nindent 14 }}
            {{- end }}
            {{- if .argoWorkflow.source.configmap }}
            configmap:
              {{- .argoWorkflow.source.configmap | toYaml | nindent 14 }}
            {{- end }}
            {{- if .argoWorkflow.source.git }}
            git:
              {{- .argoWorkflow.source.git | toYaml | nindent 14 }}
            {{- end }}
          {{- end }}
        {{- else if eq .type "http" }}
        http:
          {{- with .http.url }}
          url: {{ . }}
          {{- end }}
          {{- with .http.payload }}
          payload:
            {{- . | toYaml | nindent 12 }}
          {{- end }}
          {{- with .http.method }}
          method: {{ . }}
          {{- end }}
          {{- with .http.headers }}
          headers:
            {{- . | toYaml | nindent 12 }}
          {{- end }}
          {{- if .http.basicAuth }}
          basicAuth:
            {{- .http.basicAuth | toYaml | nindent 12 }}
          {{- end }}
          {{- with .http.tls }}
          tls:
            {{- . | toYaml | nindent 12 }}
          {{- end }}
        {{- else if eq .type "k8s" }}
        k8s:
          {{- with .k8s.group }}
          group: {{ . }}
          {{- end }}
          {{- with .k8s.version }}
          version: {{ . }}
          {{- end }}
          {{- with .k8s.resource }}
          resource: {{ . }}
          {{- end }}
          {{- with .k8s.operation }}
          operation: {{ . }}
          {{- end }}
          {{- if .k8s.source }}
          source:
            {{- .k8s.source | toYaml | nindent 12 }}
          {{- end }}
          {{- with .k8s.liveObject }}
          liveObject: {{ . }}
          {{- end }}
        {{- else if eq .type "nats" }}
        nats:
          {{- with .nats.url }}
          url: {{ . }}
          {{- end }}
          {{- with .nats.subject }}
          subject: {{ . }}
          {{- end }}
          {{- with .nats.payload }}
          payload:
            {{- . | toYaml | nindent 12 }}
          {{- end }}
          {{- if .nats.parameters }}
          parameters:
            {{- .nats.parameters | toYaml | nindent 12 }}
          {{- end }}
          {{- if .nats.tls }}
          tls:
            {{- .nats.tls | toYaml | nindent 12 }}
          {{- end }}
        {{- else if eq .type "kafka" }}
        kafka:
          {{- with .kafka.url }}
          url: {{ . }}
          {{- end }}
          {{- with .kafka.topic }}
          topic: {{ . }}
          {{- end }}
          {{- with .kafka.partition }}
          partition: {{ . }}
          {{- end }}
          {{- with .kafka.payload }}
          payload:
            {{- . | toYaml | nindent 12 }}
          {{- end }}
          {{- if .kafka.requiredAcks }}
          requiredAcks: {{ .kafka.requiredAcks }}
          {{- end }}
          {{- if .kafka.compress }}
          compress: {{ .kafka.compress }}
          {{- end }}
          {{- if .kafka.flushFrequency }}
          flushFrequency: {{ .kafka.flushFrequency }}
          {{- end }}
          {{- if .kafka.tls }}
          tls:
            {{- .kafka.tls | toYaml | nindent 12 }}
          {{- end }}
          {{- if .kafka.sasl }}
          sasl:
            {{- .kafka.sasl | toYaml | nindent 12 }}
          {{- end }}
        {{- else if eq .type "slack" }}
        slack:
          {{- if .slack.token }}
          token:
            {{- .slack.token | toYaml | nindent 12 }}
          {{- end }}
          {{- with .slack.channel }}
          channel: {{ . }}
          {{- end }}
          {{- with .slack.message }}
          message: {{ . }}
          {{- end }}
          {{- if .slack.parameters }}
          parameters:
            {{- .slack.parameters | toYaml | nindent 12 }}
          {{- end }}
        {{- else if eq .type "log" }}
        log:
          {{- with .log.intervalSeconds }}
          intervalSeconds: {{ . }}
          {{- end }}
        {{- end }}
      {{- if .conditions }}
      conditions: {{ .conditions }}
      {{- end }}
      {{- if .policy }}
      policy:
        {{- .policy | toYaml | nindent 8 }}
      {{- end }}
      {{- if .retryStrategy }}
      retryStrategy:
        {{- .retryStrategy | toYaml | nindent 8 }}
      {{- end }}
      {{- if .rateLimit }}
      rateLimit:
        {{- with .rateLimit.unit }}
        unit: {{ . }}
        {{- end }}
        {{- with .rateLimit.requestsPerUnit }}
        requestsPerUnit: {{ . }}
        {{- end }}
      {{- end }}
      {{- if .parameters }}
      parameters:
        {{- range .parameters }}
        - src:
            dependencyName: {{ .src.dependencyName }}
            {{- with .src.dataKey }}
            dataKey: {{ . }}
            {{- end }}
            {{- with .src.dataTemplate }}
            dataTemplate: {{ . }}
            {{- end }}
            {{- with .src.value }}
            value: {{ . }}
            {{- end }}
          dest: {{ .dest }}
          {{- with .operation }}
          operation: {{ . }}
          {{- end }}
        {{- end }}
      {{- end }}
    {{- end }}
    {{- else }}
    {{/* Build triggers dynamically from triggers found by runicIndexer */}}
    {{- range $trigger := $triggers }}
    - template:
        name: {{ $trigger.name }}
        argoWorkflow:
          operation: {{ default "submit" $trigger.operation }}
          source:
            resource:
              apiVersion: argoproj.io/v1alpha1
              kind: Workflow
              metadata:
                generateName: {{ $trigger.reading }}-
                namespace: {{ default $root.Release.Namespace $trigger.namespace }}
              spec:
                workflowTemplateRef:
                  name: {{ $trigger.reading }}
      {{- if $trigger.parameters }}
      parameters:
        {{- $trigger.parameters | toYaml | nindent 8 }}
      {{- end }}
    {{- end }}
    {{- end }}
  {{- end }}
  {{- if $glyphDefinition.errorOnFailedRound }}
  errorOnFailedRound: {{ .errorOnFailedRound }}
  {{- end }}
  {{- if $glyphDefinition.replicas }}
  replicas: {{ .replicas }}
  {{- end }}
{{- end }}
{{- end}}