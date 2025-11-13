{{/*
OpenTelemetry Instrumentation CR
Enables auto-instrumentation for applications
Requires OpenTelemetry Operator to be installed
*/}}
{{- define "opentelemetry.instrumentation" -}}
  {{- $root := index . 0 -}}
  {{- $glyph := index . 1 -}}

  {{- $instrumentationName := $glyph.name | default "auto-instrumentation" -}}
  {{- $language := $glyph.language | required "language is required for instrumentation glyph" -}}

  {{- $validLanguages := list "java" "python" "nodejs" "dotnet" "go" -}}
  {{- if not (has $language $validLanguages) -}}
    {{- fail (printf "Invalid language '%s'. Must be one of: %s" $language (join ", " $validLanguages)) -}}
  {{- end -}}
---
apiVersion: opentelemetry.io/v1alpha1
kind: Instrumentation
metadata:
  name: {{ $instrumentationName }}
  namespace: {{ $root.Release.Namespace }}
  labels:
    app.kubernetes.io/name: {{ $instrumentationName }}
    app.kubernetes.io/component: instrumentation
    app.kubernetes.io/part-of: {{ $root.Values.spellbook.name }}
    app.kubernetes.io/managed-by: kast-system
spec:
  exporter:
    endpoint: {{ $glyph.endpoint | default "http://otel-agent:4317" }}

  {{- if $glyph.propagators }}
  propagators:
    {{- toYaml $glyph.propagators | nindent 4 }}
  {{- else }}
  propagators:
    - tracecontext
    - baggage
  {{- end }}

  {{- if $glyph.sampler }}
  sampler:
    {{- toYaml $glyph.sampler | nindent 4 }}
  {{- end }}

  {{- if eq $language "java" }}
  java:
    image: {{ $glyph.image | default "ghcr.io/open-telemetry/opentelemetry-operator/autoinstrumentation-java:latest" }}
    {{- if $glyph.env }}
    env:
      {{- toYaml $glyph.env | nindent 6 }}
    {{- end }}
    {{- if $glyph.resources }}
    resources:
      {{- toYaml $glyph.resources | nindent 6 }}
    {{- end }}
  {{- end }}

  {{- if eq $language "python" }}
  python:
    image: {{ $glyph.image | default "ghcr.io/open-telemetry/opentelemetry-operator/autoinstrumentation-python:latest" }}
    {{- if $glyph.env }}
    env:
      {{- toYaml $glyph.env | nindent 6 }}
    {{- end }}
    {{- if $glyph.resources }}
    resources:
      {{- toYaml $glyph.resources | nindent 6 }}
    {{- end }}
  {{- end }}

  {{- if eq $language "nodejs" }}
  nodejs:
    image: {{ $glyph.image | default "ghcr.io/open-telemetry/opentelemetry-operator/autoinstrumentation-nodejs:latest" }}
    {{- if $glyph.env }}
    env:
      {{- toYaml $glyph.env | nindent 6 }}
    {{- end }}
    {{- if $glyph.resources }}
    resources:
      {{- toYaml $glyph.resources | nindent 6 }}
    {{- end }}
  {{- end }}

  {{- if eq $language "dotnet" }}
  dotnet:
    image: {{ $glyph.image | default "ghcr.io/open-telemetry/opentelemetry-operator/autoinstrumentation-dotnet:latest" }}
    {{- if $glyph.env }}
    env:
      {{- toYaml $glyph.env | nindent 6 }}
    {{- end }}
    {{- if $glyph.resources }}
    resources:
      {{- toYaml $glyph.resources | nindent 6 }}
    {{- end }}
  {{- end }}

  {{- if eq $language "go" }}
  go:
    image: {{ $glyph.image | default "ghcr.io/open-telemetry/opentelemetry-operator/autoinstrumentation-go:latest" }}
    {{- if $glyph.env }}
    env:
      {{- toYaml $glyph.env | nindent 6 }}
    {{- end }}
    {{- if $glyph.resources }}
    resources:
      {{- toYaml $glyph.resources | nindent 6 }}
    {{- end }}
  {{- end }}

  {{- if $glyph.volumeClaimTemplates }}
  volumeClaimTemplates:
    {{- toYaml $glyph.volumeClaimTemplates | nindent 4 }}
  {{- end }}
{{- end -}}
