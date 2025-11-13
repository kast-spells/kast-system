{{/*
OpenTelemetry Service
Exposes collector endpoints
*/}}
{{- define "opentelemetry.service" -}}
  {{- $root := index . 0 -}}
  {{- $glyph := index . 1 -}}

  {{- $collectorName := include "opentelemetry.collectorName" (list $root $glyph) -}}
  {{- $receivers := $glyph.receivers | default (list "otlp") -}}
  {{- $exporters := $glyph.exporters | default (list "datadog") -}}
---
apiVersion: v1
kind: Service
metadata:
  name: {{ $collectorName }}
  namespace: {{ $root.Release.Namespace }}
  labels:
    {{- include "opentelemetry.labels" (list $root $glyph) | nindent 4 }}
  {{- if $glyph.service }}
  {{- if $glyph.service.annotations }}
  annotations:
    {{- toYaml $glyph.service.annotations | nindent 4 }}
  {{- end }}
  {{- end }}
spec:
  type: {{ $glyph.serviceType | default "ClusterIP" }}
  {{- if and (eq ($glyph.serviceType | default "ClusterIP") "LoadBalancer") $glyph.loadBalancerIP }}
  loadBalancerIP: {{ $glyph.loadBalancerIP }}
  {{- end }}
  selector:
    app.kubernetes.io/name: {{ $collectorName }}
    app.kubernetes.io/component: opentelemetry-collector
  ports:
  - name: otlp-grpc
    port: 4317
    targetPort: 4317
    protocol: TCP
    {{- if and (eq ($glyph.serviceType | default "ClusterIP") "NodePort") $glyph.service }}
    {{- if $glyph.service.nodePorts }}
    {{- if $glyph.service.nodePorts.otlpGrpc }}
    nodePort: {{ $glyph.service.nodePorts.otlpGrpc }}
    {{- end }}
    {{- end }}
    {{- end }}
  - name: otlp-http
    port: 4318
    targetPort: 4318
    protocol: TCP
    {{- if and (eq ($glyph.serviceType | default "ClusterIP") "NodePort") $glyph.service }}
    {{- if $glyph.service.nodePorts }}
    {{- if $glyph.service.nodePorts.otlpHttp }}
    nodePort: {{ $glyph.service.nodePorts.otlpHttp }}
    {{- end }}
    {{- end }}
    {{- end }}
  - name: metrics
    port: 8888
    targetPort: 8888
    protocol: TCP
  - name: health
    port: 13133
    targetPort: 13133
    protocol: TCP
  {{- if has "jaeger" $receivers }}
  - name: jaeger-grpc
    port: 14250
    targetPort: 14250
    protocol: TCP
  - name: jaeger-thrift
    port: 14268
    targetPort: 14268
    protocol: TCP
  {{- end }}
  {{- if has "prometheus" $exporters }}
  - name: prometheus
    port: 8889
    targetPort: 8889
    protocol: TCP
  {{- end }}
{{- end -}}
