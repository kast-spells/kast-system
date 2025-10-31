{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

argo-events.eventSource creates EventSource resources for Argo Events
Follows kast glyph parameter pattern with runic indexer integration

Parameters:
- Glyph usage: (list $root $glyphDefinition)

Usage:
- {{- include "argo-events.eventSource" (list $root $glyphDefinition) }}

Supported EventSource types:
- github: GitHub webhook events
- gitlab: GitLab webhook events
- webhook: Generic webhook events
- bitbucket: Bitbucket webhook events
- resource: Kubernetes resource events (NEW)

Example glyphDefinition (github):
  name: github-webhook
  type: github
  selector:
    type: jetstream
    environment: production
  github:
    my-repo:
      owner: my-org
      repository: my-repo
      webhook:
        endpoint: /github
        port: "12000"
      events: ["push", "pull_request"]

Example glyphDefinition (resource):
  name: pod-monitor
  type: resource
  selector:
    type: jetstream
    environment: production
  resource:
    pod-monitoring:
      namespace: default
      group: ""
      version: v1
      resource: pods
      eventTypes: ["ADD", "UPDATE"]
      filter:
        labels:
          - key: app
            operation: "="
            value: myapp
        expression: |
          has(body.metadata.annotations['kast.ing/action'])
 */}}
{{- define "argo-events.eventSource" }}
{{- $root := index . 0 }}
{{- $glyphDefinition := index . 1 }}
{{- $resourceName := default (include "common.name" $root) $glyphDefinition.name }}
{{- $eventBuses := get (include "runicIndexer.runicIndexer" (list $root.Values.lexicon (default dict $glyphDefinition.selector) "eventbus" $root.Values.chapter.name ) | fromJson) "results" }}

{{/* Generate K8s Service if service.enabled = true */}}
{{- if and $glyphDefinition.service $glyphDefinition.service.enabled }}
---
apiVersion: v1
kind: Service
metadata:
  name: {{ $resourceName }}
  labels:
    {{- include "common.labels" $root | nindent 4 }}
  {{- with $glyphDefinition.service.annotations }}
  annotations:
    {{- . | toYaml | nindent 4 }}
  {{- end }}
spec:
  type: {{ default "ClusterIP" $glyphDefinition.service.type }}
  ports:
    - name: webhook
      port: 12000
      targetPort: 12000
      protocol: TCP
  selector:
    eventsource-name: {{ $resourceName }}
{{- end }}

{{/* Generate VirtualService if service has subdomain or prefix */}}
{{- if and $glyphDefinition.service $glyphDefinition.service.enabled (or $glyphDefinition.service.subdomain $glyphDefinition.service.prefix) }}
{{- $vsConfig := dict
  "enabled" true
  "selector" $glyphDefinition.service.selector
  "subdomain" $glyphDefinition.service.subdomain
  "httpRules" (list (dict
    "prefix" $glyphDefinition.service.prefix
    "rewrite" "/"
    "host" (printf "%s.%s.svc.cluster.local" $resourceName $root.Release.Namespace)
    "port" 12000
  ))
}}
{{- include "istio.virtualService" (list $root $vsConfig) }}
{{- end }}

{{- range $eventBus := $eventBuses }}
---
apiVersion: argoproj.io/v1alpha1
kind: EventSource
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
    {{- $glyphDefinition.template | toYaml | nindent 4 }}
  {{- end }}
  {{- if $glyphDefinition.github }}
  github:
    {{- range $repoName, $repoConfig := $glyphDefinition.github }}
    {{ $repoName }}:
      {{- with $repoConfig.owner }}
      owner: {{ . }}
      {{- end }}
      {{- with $repoConfig.repository }}
      repository: {{ . }}
      {{- end }}
      {{- if $repoConfig.webhook }}
      webhook:
        {{- with $repoConfig.webhook.endpoint }}
        endpoint: {{ . }}
        {{- end }}
        {{- with $repoConfig.webhook.port }}
        port: {{ . | quote }}
        {{- end }}
        {{- with $repoConfig.webhook.method }}
        method: {{ . }}
        {{- end }}
        {{- with $repoConfig.webhook.url }}
        url: {{ . }}
        {{- end }}
        {{- if $repoConfig.webhook.secretRef }}
        secretRef:
          {{- with $repoConfig.webhook.secretRef.name }}
          name: {{ . }}
          {{- end }}
          {{- with $repoConfig.webhook.secretRef.key }}
          key: {{ . }}
          {{- end }}
        {{- end }}
      {{- end }}
      {{- with $repoConfig.events }}
      events:
        {{- . | toYaml | nindent 8 }}
      {{- end }}
      {{- if $repoConfig.auth }}
      auth:
        {{- if $repoConfig.auth.token }}
        token:
          {{- if $repoConfig.auth.token.secretRef }}
          secretRef:
            {{- with $repoConfig.auth.token.secretRef.name }}
            name: {{ . }}
            {{- end }}
            {{- with $repoConfig.auth.token.secretRef.key }}
            key: {{ . }}
            {{- end }}
          {{- end }}
        {{- end }}
      {{- end }}
      {{- with $repoConfig.webhookSecret }}
      webhookSecret:
        {{- if $repoConfig.webhookSecret.secretRef }}
        secretRef:
          {{- with $repoConfig.webhookSecret.secretRef.name }}
          name: {{ . }}
          {{- end }}
          {{- with $repoConfig.webhookSecret.secretRef.key }}
          key: {{ . }}
          {{- end }}
        {{- end }}
      {{- end }}
      {{- with $repoConfig.insecure }}
      insecure: {{ . }}
      {{- end }}
      {{- with $repoConfig.active }}
      active: {{ . }}
      {{- end }}
      {{- with $repoConfig.contentType }}
      contentType: {{ . }}
      {{- end }}
      {{- with $repoConfig.deleteHookOnFinish }}
      deleteHookOnFinish: {{ . }}
      {{- end }}
      {{- with $repoConfig.metadata }}
      metadata:
        {{- . | toYaml | nindent 8 }}
      {{- end }}
    {{- end }}
  {{- else if $glyphDefinition.gitlab }}
  gitlab:
    {{- range $repoName, $repoConfig := $glyphDefinition.gitlab }}
    {{ $repoName }}:
      {{- with $repoConfig.projectID }}
      projectID: {{ . | quote }}
      {{- end }}
      {{- with $repoConfig.projectName }}
      projectName: {{ . }}
      {{- end }}
      {{- with $repoConfig.gitlabBaseURL }}
      gitlabBaseURL: {{ . }}
      {{- end }}
      {{- if $repoConfig.webhook }}
      webhook:
        {{- with $repoConfig.webhook.endpoint }}
        endpoint: {{ . }}
        {{- end }}
        {{- with $repoConfig.webhook.port }}
        port: {{ . | quote }}
        {{- end }}
        {{- with $repoConfig.webhook.method }}
        method: {{ . }}
        {{- end }}
        {{- with $repoConfig.webhook.url }}
        url: {{ . }}
        {{- end }}
        {{- if $repoConfig.webhook.secretRef }}
        secretRef:
          {{- with $repoConfig.webhook.secretRef.name }}
          name: {{ . }}
          {{- end }}
          {{- with $repoConfig.webhook.secretRef.key }}
          key: {{ . }}
          {{- end }}
        {{- end }}
      {{- end }}
      {{- with $repoConfig.events }}
      events:
        {{- . | toYaml | nindent 8 }}
      {{- end }}
      {{- if $repoConfig.auth }}
      auth:
        {{- if $repoConfig.auth.token }}
        token:
          {{- if $repoConfig.auth.token.secretRef }}
          secretRef:
            {{- with $repoConfig.auth.token.secretRef.name }}
            name: {{ . }}
            {{- end }}
            {{- with $repoConfig.auth.token.secretRef.key }}
            key: {{ . }}
            {{- end }}
          {{- end }}
        {{- end }}
      {{- end }}
      {{- with $repoConfig.secretToken }}
      secretToken:
        {{- if $repoConfig.secretToken.secretRef }}
        secretRef:
          {{- with $repoConfig.secretToken.secretRef.name }}
          name: {{ . }}
          {{- end }}
          {{- with $repoConfig.secretToken.secretRef.key }}
          key: {{ . }}
          {{- end }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- else if $glyphDefinition.webhook }}
  webhook:
    {{- range $webhookName, $webhookConfig := $glyphDefinition.webhook }}
    {{ $webhookName }}:
      {{- with $webhookConfig.endpoint }}
      endpoint: {{ . }}
      {{- end }}
      {{- with $webhookConfig.port }}
      port: {{ . | quote }}
      {{- end }}
      {{- with $webhookConfig.method }}
      method: {{ . }}
      {{- end }}
      {{- with $webhookConfig.url }}
      url: {{ . }}
      {{- end }}
      {{- if $webhookConfig.auth }}
      auth:
        {{- $webhookConfig.auth | toYaml | nindent 8 }}
      {{- end }}
      {{- with $webhookConfig.metadata }}
      metadata:
        {{- . | toYaml | nindent 8 }}
      {{- end }}
    {{- end }}
  {{- else if $glyphDefinition.bitbucket }}
  bitbucket:
    {{- range $repoName, $repoConfig := $glyphDefinition.bitbucket }}
    {{ $repoName }}:
      {{- with $repoConfig.owner }}
      owner: {{ . }}
      {{- end }}
      {{- with $repoConfig.repositorySlug }}
      repositorySlug: {{ . }}
      {{- end }}
      {{- if $repoConfig.webhook }}
      webhook:
        {{- with $repoConfig.webhook.endpoint }}
        endpoint: {{ . }}
        {{- end }}
        {{- with $repoConfig.webhook.port }}
        port: {{ . | quote }}
        {{- end }}
        {{- with $repoConfig.webhook.method }}
        method: {{ . }}
        {{- end }}
        {{- with $repoConfig.webhook.url }}
        url: {{ . }}
        {{- end }}
        {{- if $repoConfig.webhook.secretRef }}
        secretRef:
          {{- with $repoConfig.webhook.secretRef.name }}
          name: {{ . }}
          {{- end }}
          {{- with $repoConfig.webhook.secretRef.key }}
          key: {{ . }}
          {{- end }}
        {{- end }}
      {{- end }}
      {{- with $repoConfig.events }}
      events:
        {{- . | toYaml | nindent 8 }}
      {{- end }}
      {{- if $repoConfig.auth }}
      auth:
        {{- if $repoConfig.auth.basic }}
        basic:
          {{- if $repoConfig.auth.basic.username }}
          username:
            {{- if $repoConfig.auth.basic.username.secretRef }}
            secretRef:
              {{- with $repoConfig.auth.basic.username.secretRef.name }}
              name: {{ . }}
              {{- end }}
              {{- with $repoConfig.auth.basic.username.secretRef.key }}
              key: {{ . }}
              {{- end }}
            {{- end }}
          {{- end }}
          {{- if $repoConfig.auth.basic.password }}
          password:
            {{- if $repoConfig.auth.basic.password.secretRef }}
            secretRef:
              {{- with $repoConfig.auth.basic.password.secretRef.name }}
              name: {{ . }}
              {{- end }}
              {{- with $repoConfig.auth.basic.password.secretRef.key }}
              key: {{ . }}
              {{- end }}
            {{- end }}
          {{- end }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- else if $glyphDefinition.resource }}
  resource:
    {{- range $resourceName, $resourceConfig := $glyphDefinition.resource }}
    {{ $resourceName }}:
      {{- with $resourceConfig.namespace }}
      namespace: {{ . }}
      {{- end }}
      {{- with $resourceConfig.group }}
      group: {{ . }}
      {{- end }}
      {{- with $resourceConfig.version }}
      version: {{ . }}
      {{- end }}
      {{- with $resourceConfig.resource }}
      resource: {{ . }}
      {{- end }}
      {{- with $resourceConfig.eventTypes }}
      eventTypes:
        {{- . | toYaml | nindent 8 }}
      {{- end }}
      {{- if $resourceConfig.filter }}
      filter:
        {{- if $resourceConfig.filter.prefix }}
        prefix: {{ $resourceConfig.filter.prefix }}
        {{- end }}
        {{- if $resourceConfig.filter.labels }}
        labels:
          {{- range $resourceConfig.filter.labels }}
          - key: {{ .key }}
            {{- with .operation }}
            operation: {{ . }}
            {{- end }}
            {{- with .value }}
            value: {{ . | quote }}
            {{- end }}
          {{- end }}
        {{- end }}
        {{- if $resourceConfig.filter.fields }}
        fields:
          {{- range $resourceConfig.filter.fields }}
          - key: {{ .key }}
            {{- with .operation }}
            operation: {{ . }}
            {{- end }}
            {{- with .value }}
            value: {{ . | quote }}
            {{- end }}
          {{- end }}
        {{- end }}
        {{- with $resourceConfig.filter.expression }}
        expression: |
          {{- . | nindent 10 }}
        {{- end }}
        {{- if $resourceConfig.filter.createdBy }}
        createdBy:
          {{- $resourceConfig.filter.createdBy | toYaml | nindent 10 }}
        {{- end }}
        {{- if $resourceConfig.filter.afterStart }}
        afterStart: {{ $resourceConfig.filter.afterStart }}
        {{- end }}
      {{- end }}
      {{- with $resourceConfig.metadata }}
      metadata:
        {{- . | toYaml | nindent 8 }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end}}