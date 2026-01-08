{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

Covenant Post-Provisioning - Member Jobs
Generates member-level post-provisioning Jobs (condition-based: roles/groups)
*/}}

{{- define "covenant.postProvisioning.memberJobs" -}}
{{- $root := . -}}
{{- $covenant := .Values.covenant -}}
{{- $bookPath := default .Release.Name .Values.name -}}
{{- if $covenant.chapterFilter }}
  {{- $bookPath = trimSuffix (printf "-%s" $covenant.chapterFilter) $bookPath -}}
{{- end }}
{{- $chapterFilter := $covenant.chapterFilter -}}
{{- $postProvisionSA := printf "%s-post-provision" $bookPath -}}

{{/* Get covenant index and chapter index */}}
{{- $covenantIndex := include "covenant.scanCovenantIndex" . | fromYaml -}}
{{- $finalRealm := $covenantIndex.realm -}}
{{- $chapterIndex := include "covenant.scanChapterIndex" (list . $chapterFilter) | fromYaml -}}

{{/* Get Keycloak instance from lexicon */}}
{{- $chapterName := "" -}}
{{- $chapterLabels := dict -}}
{{- if $root.Values.chapter }}
  {{- $chapterName = $root.Values.chapter.name -}}
  {{- $chapterLabels = dict "chapter" $chapterName -}}
{{- end }}
{{- $keycloakInstances := get (include "runicIndexer.runicIndexer" (list $root.Values.lexicon $chapterLabels "keycloak" $chapterName) | fromJson) "results" -}}
{{- $keycloakInstance := dict -}}
{{- range $keycloakInstances }}
  {{- $keycloakInstance = . -}}
{{- end }}

{{/* Scan chapter members */}}
{{- $members := include "covenant.scanChapterMembers" (list . $chapterFilter) | fromJson -}}

{{/* Generate member-level post-provisioning jobs */}}
{{- range $memberKey, $member := $members }}
  {{- $memberName := $member.username | default $member.email -}}
  {{- $memberRoles := default list $member.realmRoles -}}
  {{- $memberGroups := default list $member.groups -}}

  {{/* Auto-generate username if not already set */}}
  {{- if not $memberName }}
    {{- $baseUsername := "" -}}
    {{- if $member.overrideUsername }}
      {{- $baseUsername = $member.overrideUsername -}}
    {{- else }}
      {{- $baseUsername = printf "%s.%s" ($member.firstName | lower) ($member.lastName | lower) -}}
    {{- end }}
    {{- $memberName = printf "%s@%s" $baseUsername $finalRealm.emailDomain -}}
  {{- end }}

  {{/* Loop through each post-provisioning definition */}}
  {{- range $postProv := $chapterIndex.memberPostProvisioning }}
    {{- if not (eq $postProv.enabled false) }}
    {{- $conditionsMet := false -}}

    {{/* Check if user has any required roles */}}
    {{- if $postProv.conditions.roles }}
      {{- range $requiredRole := $postProv.conditions.roles }}
        {{- if has $requiredRole $memberRoles }}
          {{- $conditionsMet = true -}}
        {{- end }}
      {{- end }}
    {{- end }}

    {{/* Check if user has any required groups */}}
    {{- if $postProv.conditions.groups }}
      {{- range $requiredGroup := $postProv.conditions.groups }}
        {{- if has $requiredGroup $memberGroups }}
          {{- $conditionsMet = true -}}
        {{- end }}
      {{- end }}
    {{- end }}

    {{/* If conditions are met, generate the Job */}}
    {{- if $conditionsMet }}
      {{- $jobName := printf "%s-%s-%s" $postProv.name ($memberKey | replace "/" "-") "provision" | trunc 63 | trimSuffix "-" -}}
---
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ $jobName }}
  namespace: {{ $root.Release.Namespace }}
  labels:
    app.kubernetes.io/name: {{ $postProv.name }}
    app.kubernetes.io/instance: {{ $root.Release.Name }}
    app.kubernetes.io/managed-by: {{ $root.Release.Service }}
    covenant.kast.io/member: {{ $memberKey | replace "/" "-" | trunc 63 | trimSuffix "-" }}
    covenant.kast.io/post-provisioning: {{ $postProv.name }}
  annotations:
    covenant.kast.io/member-email: {{ $memberName }}
    covenant.kast.io/member-username: {{ $memberName }}
spec:
  {{- if $postProv.job.backoffLimit }}
  backoffLimit: {{ $postProv.job.backoffLimit }}
  {{- end }}
  {{- if $postProv.job.activeDeadlineSeconds }}
  activeDeadlineSeconds: {{ $postProv.job.activeDeadlineSeconds }}
  {{- end }}
  template:
    metadata:
      labels:
        app.kubernetes.io/name: {{ $postProv.name }}
        app.kubernetes.io/instance: {{ $root.Release.Name }}
        covenant.kast.io/member: {{ $memberKey | replace "/" "-" | trunc 63 | trimSuffix "-" }}
    spec:
      serviceAccountName: {{ $postProvisionSA }}
      {{- if $postProv.job.restartPolicy }}
      restartPolicy: {{ $postProv.job.restartPolicy }}
      {{- else }}
      restartPolicy: Never
      {{- end }}
      containers:
        - name: {{ $postProv.container.name }}
          image: {{ $postProv.container.image.name }}:{{ $postProv.container.image.tag }}
          {{- if $postProv.container.command }}
          command:
            {{- range $postProv.container.command }}
            - {{ . }}
            {{- end }}
          {{- end }}
          {{- if $postProv.container.args }}
          args:
            {{- range $arg := $postProv.container.args }}
            {{- $templatedArg := $arg -}}
            {{- $templatedArg = $templatedArg | replace "{{ .username }}" $memberName -}}
            {{- $templatedArg = $templatedArg | replace "{{ .email }}" $memberName -}}
            {{- $templatedArg = $templatedArg | replace "{{ .firstName }}" (default "" $member.firstName) -}}
            {{- $templatedArg = $templatedArg | replace "{{ .lastName }}" (default "" $member.lastName) -}}
            {{- $templatedArg = $templatedArg | replace "{{ .groups | join \",\" }}" (join "," $memberGroups) -}}
            {{- $templatedArg = $templatedArg | replace "{{ .groups | toJson }}" (toJson $memberGroups) -}}
            - {{ $templatedArg | quote }}
            {{- end }}
          {{- end }}
          env:
            {{- if $postProv.container.env }}
            {{- toYaml $postProv.container.env | nindent 12 }}
            {{- end }}
            # Dynamic values from lexicon (via runicIndexer)
            - name: KEYCLOAK_URL
              value: {{ $keycloakInstance.url | quote }}
            - name: KEYCLOAK_REALM
              value: {{ $finalRealm.name | quote }}
          {{- if $postProv.container.resources }}
          resources:
            {{- toYaml $postProv.container.resources | nindent 12 }}
          {{- end }}
    {{- end }}
    {{- end }}
  {{- end }}
{{- end }}

{{- end -}}
