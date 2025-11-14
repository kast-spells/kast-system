{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
*/}}
{{- define "gcp.firewall" }}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1}}
---
apiVersion: compute.cnrm.cloud.google.com/v1beta1
kind: ComputeFirewall
metadata:
  labels:
    {{- include "common.infra.labels" $root | nindent 4}}
  name: {{ default (include "common.name" $root) $glyphDefinition.name }}
  annotations:
    {{- include "common.infra.annotations" $root | nindent 4}}
spec:
  direction: {{ default "INGRESS" $glyphDefinition.direction}}
  priority: {{ default 10 $glyphDefinition.priority }}
  description: {{ default $glyphDefinition.name $glyphDefinition.description }}
  {{- $glyphDefinition.rules | toYaml | nindent 2 }}
  networkRef:
    name: {{ $glyphDefinition.networkRef }}
    {{- if $glyphDefinition.networkRefNamespace }}
    namespace: {{ $glyphDefinition.networkRefNamespace }}
    {{- end }}
  {{- if not $glyphDefinition.noSourceTags }}
    {{- if $glyphDefinition.sourceTags }}
  sourceTags:
    {{- range $glyphDefinition.sourceTags }}
    - {{ . }}
    {{- end }}
    {{- else }}
  sourceTags:
    - {{ $glyphDefinition.name }}
    {{- end }}
  {{- else }}
  sourceTags: []
  {{- end }}
  {{- if not $glyphDefinition.noSourceRanges }}
    {{- if $glyphDefinition.sourceRanges }}
  sourceRanges:
    {{- range $glyphDefinition.sourceRanges }}
    - {{ . }}
    {{- end }}
    {{- else }}
  sourceRanges:
    - 0.0.0.0/0
    {{- end }}
  {{- else }}
  sourceRanges: []
  {{- end }}
  {{- if $glyphDefinition.otherSources }}
    {{- range $source, $contentList :=$glyphDefinition.otherSources }}
      {{ $source |nindent 4 }}:
      {{- $contentList | toYaml |nindent 6 }}
    {{- end }}
  {{- end }}
  {{- if not $glyphDefinition.noTargetTags }}
    {{- if $glyphDefinition.targetTags }}
  targetTags:
    {{- range $glyphDefinition.targetTags }}
    - {{ . }}
    {{- end }}
    {{- end }}
  {{- end }}
  {{- if not $glyphDefinition.noTargetRanges }}
    {{- if $glyphDefinition.targetRanges }}
  targetRanges:
    {{- range $glyphDefinition.targetRanges }}
    - {{ . }}
    {{- end }}
    {{- end }}
  {{- else }}
  targetRanges: []
  {{- end }}
  {{- if $glyphDefinition.otherTargets }}
    {{- range $target, $contentList := $glyphDefinition.otherTargets }}
      {{ $target |nindent 4 }}:
      {{- $contentList | toYaml |nindent 6 }}
    {{- end }}
  {{- end }}
{{- end }}
