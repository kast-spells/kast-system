{{/*
OpenTelemetry Collector Sidecar
Generates sidecar container spec for injection into application pods
This is meant to be included in summon or other workload templates
*/}}
{{- define "opentelemetry.collectorSidecar" -}}
  {{- $root := index . 0 -}}
  {{- $glyph := index . 1 -}}

  {{- $collectorName := include "opentelemetry.collectorName" (list $root $glyph) -}}

  {{- $datadogConf := dict -}}
  {{- if $glyph.datadogSelector -}}
    {{- $datadogConf = include "opentelemetry.getDatadogConfig" (list $root $glyph.datadogSelector) | fromYaml -}}
  {{- end -}}

  {{- /* For sidecar mode, we typically forward to a gateway */ -}}
  {{- $sidecarGlyph := $glyph -}}
  {{- if $glyph.forwardTo -}}
    {{- $_ := set $sidecarGlyph "exporters" (list "otlp") -}}
  {{- end -}}

  {{- /* Generate ConfigMap */ -}}
  {{- include "opentelemetry.configMap" (list $root $sidecarGlyph $datadogConf) }}

  {{- /* Output sidecar container spec (not a full workload) */ -}}
  {{- /* This should be used by referencing in summon or other workload glyphs */ -}}
---
# Sidecar container spec for {{ $collectorName }}
# Include this in your workload's containers array
- name: otel-collector-sidecar
  image: {{ $glyph.image.repository | default "otel/opentelemetry-collector-contrib" }}:{{ $glyph.image.tag | default "0.91.0" }}
  imagePullPolicy: {{ $glyph.image.pullPolicy | default "IfNotPresent" }}
  command:
    - /otelcol-contrib
    - --config=/conf/collector-config.yaml
  ports:
  - name: otlp-grpc
    containerPort: 4317
    protocol: TCP
  - name: otlp-http
    containerPort: 4318
    protocol: TCP
  - name: metrics
    containerPort: 8888
    protocol: TCP
  env:
  {{- if not $glyph.forwardTo }}
  - name: DD_API_KEY
    valueFrom:
      secretKeyRef:
        name: {{ $glyph.datadogSecretName | default (printf "%s-datadog-creds" $collectorName) }}
        key: {{ $glyph.datadogApiKeyKey | default "apiKey" }}
  {{- if $datadogConf.appKey }}
  - name: DD_APP_KEY
    valueFrom:
      secretKeyRef:
        name: {{ $glyph.datadogSecretName | default (printf "%s-datadog-creds" $collectorName) }}
        key: {{ $glyph.datadogAppKeyKey | default "appKey" }}
  {{- end }}
  {{- end }}
  - name: POD_NAME
    valueFrom:
      fieldRef:
        fieldPath: metadata.name
  - name: POD_NAMESPACE
    valueFrom:
      fieldRef:
        fieldPath: metadata.namespace
  {{- if $glyph.forwardTo }}
  - name: OTEL_EXPORTER_OTLP_ENDPOINT
    value: {{ $glyph.forwardTo }}
  {{- end }}
  {{- if $glyph.env }}
  {{- toYaml $glyph.env | nindent 2 }}
  {{- end }}
  resources:
    {{- if $glyph.resources }}
    {{- toYaml $glyph.resources | nindent 4 }}
    {{- else }}
    limits:
      cpu: 200m
      memory: 512Mi
    requests:
      cpu: 50m
      memory: 128Mi
    {{- end }}
  volumeMounts:
  - name: otel-collector-config
    mountPath: /conf
    readOnly: true
{{- end -}}
