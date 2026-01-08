{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

Covenant Post-Provisioning - Chapter Jobs
Generates chapter-level post-provisioning Jobs (run once per chapter)
*/}}

{{- define "covenant.postProvisioning.chapterJobs" -}}
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

{{/* Generate chapter-level post-provisioning jobs */}}
{{- range $postProv := $chapterIndex.chapterPostProvisioning }}
{{- if not (eq $postProv.enabled false) }}
{{- $jobName := printf "%s-%s-%s" $bookPath $chapterFilter $postProv.name | trunc 63 | trimSuffix "-" -}}

{{/* Support both inline script and scriptFile */}}
{{- $scriptContent := "" -}}
{{- if $postProv.scriptFile }}
  {{/* Read script from file in bookrack/{book}/covenant/scripts/ */}}
  {{- $scriptPath := printf "bookrack/%s/covenant/scripts/%s" $bookPath $postProv.scriptFile -}}
  {{- if not ($.Files.Glob $scriptPath) }}
    {{- fail (printf "Chapter post-provisioning scriptFile not found: %s" $scriptPath) -}}
  {{- end }}
  {{- $scriptContent = $.Files.Get $scriptPath -}}
{{- else if $postProv.script }}
  {{/* Use inline script */}}
  {{- $scriptContent = $postProv.script -}}
{{- else }}
  {{- fail (printf "Chapter %s postProvisioning '%s' requires either 'script' or 'scriptFile'" $chapterFilter $postProv.name) -}}
{{- end }}
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
    covenant.kast.io/chapter: {{ $chapterFilter }}
    covenant.kast.io/post-provisioning: chapter
  annotations:
    covenant.kast.io/post-prov-name: {{ $postProv.name }}
spec:
  {{- if $postProv.backoffLimit }}
  backoffLimit: {{ $postProv.backoffLimit }}
  {{- else }}
  backoffLimit: 3
  {{- end }}
  {{- if $postProv.activeDeadlineSeconds }}
  activeDeadlineSeconds: {{ $postProv.activeDeadlineSeconds }}
  {{- end }}
  template:
    metadata:
      labels:
        app.kubernetes.io/name: {{ $postProv.name }}
        app.kubernetes.io/instance: {{ $root.Release.Name }}
        covenant.kast.io/chapter: {{ $chapterFilter }}
    spec:
      serviceAccountName: {{ $postProvisionSA }}
      {{- if $postProv.restartPolicy }}
      restartPolicy: {{ $postProv.restartPolicy }}
      {{- else }}
      restartPolicy: Never
      {{- end }}
      containers:
        - name: {{ $postProv.name }}
          {{- if $postProv.container }}
          image: {{ $postProv.container.image.name }}:{{ $postProv.container.image.tag }}
          {{- else }}
          image: bitnami/kubectl:latest
          {{- end }}
          command: ["/bin/sh", "-c"]
          args:
            - |
{{ $scriptContent | nindent 14 }}
          env:
            - name: CHAPTER_NAME
              value: {{ $chapterFilter | quote }}
            - name: BOOK_PATH
              value: {{ $bookPath | quote }}
            - name: NAMESPACE
              value: {{ $root.Release.Namespace | quote }}
            - name: KEYCLOAK_URL
              value: {{ $keycloakInstance.url | quote }}
            - name: KEYCLOAK_REALM
              value: {{ $finalRealm.name | quote }}
            {{- if $postProv.env }}
            {{- toYaml $postProv.env | nindent 12 }}
            {{- end }}
          {{- if $postProv.resources }}
          resources:
            {{- toYaml $postProv.resources | nindent 12 }}
          {{- end }}
{{- end }}
{{- end }}

{{- end -}}
