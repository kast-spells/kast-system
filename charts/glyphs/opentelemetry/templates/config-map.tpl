{{/*
OpenTelemetry ConfigMap generator
Generates ConfigMap with collector configuration
*/}}
{{- define "opentelemetry.configMap" -}}
  {{- $root := index . 0 -}}
  {{- $glyph := index . 1 -}}
  {{- $datadogConf := index . 2 -}}

  {{- $collectorName := include "opentelemetry.collectorName" (list $root $glyph) -}}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ $collectorName }}-config
  namespace: {{ $root.Release.Namespace }}
  labels:
    {{- include "opentelemetry.labels" (list $root $glyph) | nindent 4 }}
data:
  collector-config.yaml: |
{{ include "opentelemetry.config" (list $root $glyph $datadogConf) | indent 4 }}
{{- end -}}
