{{/*
kast - Kubernetes arcane spelling technology
OpenTelemetry Glyph - Main helpers
Copyright (C) 2024 kast-spells
Licensed under the GNU GPL v3. See LICENSE file for details.
*/}}

{{/*
Main entry point for opentelemetry glyph
Usage: {{- include "glyph.opentelemetry" (list $root $glyphDefinition) }}
*/}}
{{- define "glyph.opentelemetry" -}}
  {{- $root := index . 0 -}}
  {{- $glyph := index . 1 -}}

  {{- $type := $glyph.type | default "collectorGateway" -}}

  {{- if eq $type "collectorGateway" }}
    {{- include "opentelemetry.collectorGateway" (list $root $glyph) }}
  {{- else if eq $type "collectorAgent" }}
    {{- include "opentelemetry.collectorAgent" (list $root $glyph) }}
  {{- else if eq $type "collectorSidecar" }}
    {{- include "opentelemetry.collectorSidecar" (list $root $glyph) }}
  {{- else if eq $type "instrumentation" }}
    {{- include "opentelemetry.instrumentation" (list $root $glyph) }}
  {{- else }}
    {{- fail (printf "Unknown opentelemetry glyph type: %s" $type) }}
  {{- end -}}
{{- end -}}

{{/*
Get Datadog configuration from lexicon
Usage: {{- $datadogConf := include "opentelemetry.getDatadogConfig" (list $root $selector) | fromYaml }}
*/}}
{{- define "opentelemetry.getDatadogConfig" -}}
  {{- $root := index . 0 -}}
  {{- $selector := index . 1 -}}

  {{- $datadogConf := dict -}}
  {{- if $root.Values.appendix -}}
    {{- if $root.Values.appendix.lexicon -}}
      {{- range $item := $root.Values.appendix.lexicon -}}
        {{- if eq $item.type "datadog" -}}
          {{- $match := true -}}
          {{- range $key, $value := $selector -}}
            {{- if ne (index $item $key) $value -}}
              {{- $match = false -}}
            {{- end -}}
          {{- end -}}
          {{- if $match -}}
            {{- $datadogConf = $item -}}
          {{- end -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}

  {{- if not $datadogConf -}}
    {{- fail "No Datadog configuration found in lexicon matching selector" -}}
  {{- end -}}

  {{- $datadogConf | toYaml -}}
{{- end -}}

{{/*
Generate OpenTelemetry Collector configuration YAML
Usage: {{- include "opentelemetry.config" (list $root $glyph $datadogConf) }}
*/}}
{{- define "opentelemetry.config" -}}
  {{- $root := index . 0 -}}
  {{- $glyph := index . 1 -}}
  {{- $datadogConf := index . 2 -}}

  {{- $receivers := $glyph.receivers | default (list "otlp") -}}
  {{- $processors := $glyph.processors | default (list "batch" "memory_limiter" "resourcedetection") -}}
  {{- $exporters := $glyph.exporters | default (list "datadog") -}}

  {{- $metricsReceivers := list -}}
  {{- $tracesReceivers := list -}}
  {{- $logsReceivers := list -}}

  {{- if $glyph.metricsPath -}}
    {{- $metricsReceivers = $glyph.metricsPath.receivers -}}
  {{- else -}}
    {{- $metricsReceivers = $receivers -}}
  {{- end -}}

  {{- if $glyph.tracesPath -}}
    {{- $tracesReceivers = $glyph.tracesPath.receivers -}}
  {{- else -}}
    {{- $tracesReceivers = $receivers -}}
  {{- end -}}

  {{- if $glyph.logsPath -}}
    {{- $logsReceivers = $glyph.logsPath.receivers -}}
  {{- else -}}
    {{- $logsReceivers = $receivers -}}
  {{- end -}}
receivers:
  {{- if has "otlp" $receivers }}
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318
  {{- end }}

  {{- if has "prometheus" $receivers }}
  prometheus:
    config:
      scrape_configs:
        - job_name: 'otel-collector'
          scrape_interval: 30s
          static_configs:
            - targets: ['0.0.0.0:8888']
  {{- end }}

  {{- if has "jaeger" $receivers }}
  jaeger:
    protocols:
      grpc:
        endpoint: 0.0.0.0:14250
      thrift_http:
        endpoint: 0.0.0.0:14268
  {{- end }}

processors:
  {{- if has "batch" $processors }}
  batch:
    timeout: {{ $glyph.batchTimeout | default "10s" }}
    send_batch_size: {{ $glyph.batchSize | default 1024 }}
    send_batch_max_size: {{ $glyph.batchMaxSize | default 2048 }}
  {{- end }}

  {{- if has "memory_limiter" $processors }}
  memory_limiter:
    check_interval: 1s
    limit_percentage: 80
    spike_limit_percentage: 25
  {{- end }}

  {{- if has "resourcedetection" $processors }}
  resourcedetection:
    detectors: [env, system, docker, kubernetes]
    timeout: 5s
    override: false
  {{- end }}

  {{- if has "k8sattributes" $processors }}
  k8sattributes:
    auth_type: serviceAccount
    passthrough: false
    extract:
      metadata:
        - k8s.namespace.name
        - k8s.deployment.name
        - k8s.statefulset.name
        - k8s.daemonset.name
        - k8s.cronjob.name
        - k8s.job.name
        - k8s.node.name
        - k8s.pod.name
        - k8s.pod.uid
        - k8s.pod.start_time
  {{- end }}

  {{- if has "spanmetrics" $processors }}
  spanmetrics:
    metrics_exporter: prometheus
    latency_histogram_buckets: [2ms, 4ms, 6ms, 8ms, 10ms, 50ms, 100ms, 200ms, 400ms, 800ms, 1s, 1400ms, 2s, 5s, 10s, 15s]
    dimensions:
      - name: http.method
        default: GET
      - name: http.status_code
  {{- end }}

exporters:
  {{- if has "datadog" $exporters }}
  datadog:
    api:
      site: {{ $datadogConf.site | default "datadoghq.com" }}
      key: ${DD_API_KEY}
      {{- if $datadogConf.appKey }}
      app_key: ${DD_APP_KEY}
      {{- end }}
      fail_on_invalid_key: true

    host_metadata:
      enabled: true
      hostname_source: config_or_system
      tags:
        {{- range $key, $value := $datadogConf.labels }}
        - {{ $key }}:{{ $value }}
        {{- end }}

    traces:
      span_name_as_resource_name: true
      trace_buffer: {{ $glyph.traceBuffer | default 500 }}
      {{- if $glyph.computeStatsBySpanKind }}
      compute_stats_by_span_kind: {{ $glyph.computeStatsBySpanKind }}
      {{- end }}

    metrics:
      histograms:
        mode: {{ $glyph.histogramMode | default "distributions" }}
        send_aggregation_metrics: {{ $glyph.sendAggregationMetrics | default true }}
      {{- if $glyph.summaries }}
      summaries:
        mode: {{ $glyph.summaries.mode | default "gauges" }}
      {{- end }}
  {{- end }}

  {{- if has "prometheus" $exporters }}
  prometheus:
    endpoint: "0.0.0.0:8889"
    namespace: {{ $root.Release.Namespace }}
    send_timestamps: true
    metric_expiration: 5m
  {{- end }}

  {{- if has "logging" $exporters }}
  logging:
    loglevel: {{ $glyph.logLevel | default "info" }}
    sampling_initial: 5
    sampling_thereafter: 200
  {{- end }}

extensions:
  health_check:
    endpoint: :13133

  pprof:
    endpoint: :1777

  zpages:
    endpoint: :55679

service:
  extensions: [health_check, pprof, zpages]

  pipelines:
    {{- if or (has "otlp" $metricsReceivers) (has "prometheus" $metricsReceivers) }}
    metrics:
      receivers:
        {{- range $metricsReceivers }}
        - {{ . }}
        {{- end }}
      processors:
        {{- if $glyph.metricsPath }}
        {{- range $glyph.metricsPath.processors }}
        - {{ . }}
        {{- end }}
        {{- else }}
        {{- range $processors }}
        - {{ . }}
        {{- end }}
        {{- end }}
      exporters:
        {{- if $glyph.metricsPath }}
        {{- range $glyph.metricsPath.exporters }}
        - {{ . }}
        {{- end }}
        {{- else }}
        {{- range $exporters }}
        - {{ . }}
        {{- end }}
        {{- end }}
    {{- end }}

    {{- if or (has "otlp" $tracesReceivers) (has "jaeger" $tracesReceivers) }}
    traces:
      receivers:
        {{- range $tracesReceivers }}
        - {{ . }}
        {{- end }}
      processors:
        {{- if $glyph.tracesPath }}
        {{- range $glyph.tracesPath.processors }}
        - {{ . }}
        {{- end }}
        {{- else }}
        {{- range $processors }}
        - {{ . }}
        {{- end }}
        {{- end }}
      exporters:
        {{- if $glyph.tracesPath }}
        {{- range $glyph.tracesPath.exporters }}
        - {{ . }}
        {{- end }}
        {{- else }}
        {{- range $exporters }}
        - {{ . }}
        {{- end }}
        {{- end }}
    {{- end }}

    {{- if has "otlp" $logsReceivers }}
    logs:
      receivers:
        {{- range $logsReceivers }}
        - {{ . }}
        {{- end }}
      processors:
        {{- if $glyph.logsPath }}
        {{- range $glyph.logsPath.processors }}
        - {{ . }}
        {{- end }}
        {{- else }}
        {{- range $processors }}
        - {{ . }}
        {{- end }}
        {{- end }}
      exporters:
        {{- if $glyph.logsPath }}
        {{- range $glyph.logsPath.exporters }}
        - {{ . }}
        {{- end }}
        {{- else }}
        {{- range $exporters }}
        - {{ . }}
        {{- end }}
        {{- end }}
    {{- end }}

  telemetry:
    logs:
      level: {{ $glyph.logLevel | default "info" }}
    metrics:
      address: :8888
      level: detailed
{{- end -}}

{{/*
Generate collector name
Usage: {{- $name := include "opentelemetry.collectorName" (list $root $glyph) }}
*/}}
{{- define "opentelemetry.collectorName" -}}
  {{- $root := index . 0 -}}
  {{- $glyph := index . 1 -}}
  {{- $name := $glyph.name | default "otel-collector" -}}
  {{- printf "%s-%s" (include "common.name" $root) $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Generate labels for OpenTelemetry resources
Usage: {{- include "opentelemetry.labels" (list $root $glyph) }}
*/}}
{{- define "opentelemetry.labels" -}}
  {{- $root := index . 0 -}}
  {{- $glyph := index . 1 -}}
app.kubernetes.io/name: {{ include "opentelemetry.collectorName" (list $root $glyph) }}
app.kubernetes.io/instance: {{ $root.Release.Name }}
app.kubernetes.io/component: opentelemetry-collector
app.kubernetes.io/part-of: {{ $root.Values.spellbook.name }}
app.kubernetes.io/managed-by: kast-system
{{- end -}}

{{/*
Get service account name
Usage: {{- $sa := include "opentelemetry.serviceAccountName" (list $root $glyph) }}
*/}}
{{- define "opentelemetry.serviceAccountName" -}}
  {{- $root := index . 0 -}}
  {{- $glyph := index . 1 -}}
  {{- if $glyph.serviceAccount -}}
    {{- $glyph.serviceAccount -}}
  {{- else -}}
    {{- include "common.name" $root -}}
  {{- end -}}
{{- end -}}
