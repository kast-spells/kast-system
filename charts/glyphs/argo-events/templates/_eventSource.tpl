{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

argo-events.eventSource creates EventSource resources for Argo Events
Follows kast glyph parameter pattern with runic indexer integration

Parameters:
- Glyph usage: (list $root $glyphDefinition)

Usage:
- {{- include "argo-events.eventSource" (list $root $glyphDefinition) }}

Example glyphDefinition:
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
 */}}
{{- define "argo-events.eventSource" }}
{{- $root := index . 0 }}
{{- $glyphDefinition := index . 1 }}
{{- $resourceName := default (include "common.name" $root) $glyphDefinition.name }}
{{- $eventBuses := get (include "runicIndexer.runicIndexer" (list $root.Values.lexicon (default dict $glyphDefinition.selector) "eventbus" $root.Values.chapter.name ) | fromJson) "results" }}
{{- range $eventBus := $eventBuses }}
---
apiVersion: argoproj.io/v1alpha1
kind: EventSource
metadata:
  name: {{ $resourceName }}
  labels:
    {{- include "common.labels" $root | nindent 4 }}
  {{- with $glyphDefinition.annotations }}
  annotations:
    {{- . | toYaml | nindent 4 }}
  {{- end }}
spec:
  eventBusName: {{ default $eventBus.name $glyphDefinition.eventBusName }}
  {{- if $glyphDefinition.service }}
  service:
    {{- $glyphDefinition.service | toYaml | nindent 4 }}
  {{- end }}
  {{- if eq $glyphDefinition.type "github" }}
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
  {{- else if eq $glyphDefinition.type "gitlab" }}
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
  {{- else if eq $glyphDefinition.type "webhook" }}
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
  {{- else if eq $glyphDefinition.type "bitbucket" }}
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
  {{- end }}
{{- end }}
{{- end}}