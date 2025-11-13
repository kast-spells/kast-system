{{/*
OpenTelemetry Collector Agent (DaemonSet mode)
Per-node collector for local telemetry collection
*/}}
{{- define "opentelemetry.collectorAgent" -}}
  {{- $root := index . 0 -}}
  {{- $glyph := index . 1 -}}

  {{- $collectorName := include "opentelemetry.collectorName" (list $root $glyph) -}}

  {{- $datadogConf := dict -}}
  {{- if $glyph.datadogSelector -}}
    {{- $datadogConf = include "opentelemetry.getDatadogConfig" (list $root $glyph.datadogSelector) | fromYaml -}}
  {{- end -}}

  {{- /* For agent mode, we might forward to a gateway instead of exporting directly */ -}}
  {{- $agentGlyph := $glyph -}}
  {{- if $glyph.forwardTo -}}
    {{- $_ := set $agentGlyph "exporters" (list "otlp") -}}
  {{- end -}}

  {{- /* Generate ConfigMap */ -}}
  {{- include "opentelemetry.configMap" (list $root $agentGlyph $datadogConf) }}

  {{- /* Generate Service */ -}}
  {{- include "opentelemetry.service" (list $root $glyph) }}

  {{- /* Generate DaemonSet */ -}}
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: {{ $collectorName }}
  namespace: {{ $root.Release.Namespace }}
  labels:
    {{- include "opentelemetry.labels" (list $root $glyph) | nindent 4 }}
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: {{ $collectorName }}
      app.kubernetes.io/component: opentelemetry-collector
  {{- if $glyph.updateStrategy }}
  updateStrategy:
    {{- toYaml $glyph.updateStrategy | nindent 4 }}
  {{- else }}
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
  {{- end }}
  template:
    metadata:
      annotations:
        checksum/config: {{ include "opentelemetry.config" (list $root $agentGlyph $datadogConf) | sha256sum }}
        {{- if $glyph.podAnnotations }}
        {{- toYaml $glyph.podAnnotations | nindent 8 }}
        {{- end }}
      labels:
        app.kubernetes.io/name: {{ $collectorName }}
        app.kubernetes.io/component: opentelemetry-collector
        app.kubernetes.io/instance: {{ $root.Release.Name }}
        {{- if $glyph.podLabels }}
        {{- toYaml $glyph.podLabels | nindent 8 }}
        {{- end }}
    spec:
      serviceAccountName: {{ include "opentelemetry.serviceAccountName" (list $root $glyph) }}
      hostNetwork: {{ $glyph.hostNetwork | default false }}
      {{- if $glyph.securityContext }}
      securityContext:
        {{- toYaml $glyph.securityContext | nindent 8 }}
      {{- else }}
      securityContext:
        runAsUser: 0
        runAsGroup: 0
        fsGroup: 0
      {{- end }}
      containers:
      - name: otel-collector
        image: {{ $glyph.image.repository | default "otel/opentelemetry-collector-contrib" }}:{{ $glyph.image.tag | default "0.91.0" }}
        imagePullPolicy: {{ $glyph.image.pullPolicy | default "IfNotPresent" }}
        command:
          - /otelcol-contrib
          - --config=/conf/collector-config.yaml
        ports:
        - name: otlp-grpc
          containerPort: 4317
          protocol: TCP
          {{- if $glyph.hostNetwork }}
          hostPort: 4317
          {{- end }}
        - name: otlp-http
          containerPort: 4318
          protocol: TCP
          {{- if $glyph.hostNetwork }}
          hostPort: 4318
          {{- end }}
        - name: metrics
          containerPort: 8888
          protocol: TCP
        - name: health
          containerPort: 13133
          protocol: TCP
        {{- if has "jaeger" ($glyph.receivers | default list) }}
        - name: jaeger-grpc
          containerPort: 14250
          protocol: TCP
        - name: jaeger-thrift
          containerPort: 14268
          protocol: TCP
        {{- end }}
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
        - name: NODE_NAME
          valueFrom:
            fieldRef:
              fieldPath: spec.nodeName
        {{- if $glyph.forwardTo }}
        - name: OTEL_EXPORTER_OTLP_ENDPOINT
          value: {{ $glyph.forwardTo }}
        {{- end }}
        {{- if $glyph.env }}
        {{- toYaml $glyph.env | nindent 8 }}
        {{- end }}
        livenessProbe:
          httpGet:
            path: /
            port: 13133
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /
            port: 13133
          initialDelaySeconds: 10
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
        resources:
          {{- if $glyph.resources }}
          {{- toYaml $glyph.resources | nindent 10 }}
          {{- else }}
          limits:
            cpu: 500m
            memory: 1Gi
          requests:
            cpu: 100m
            memory: 200Mi
          {{- end }}
        volumeMounts:
        - name: config
          mountPath: /conf
          readOnly: true
        {{- if $glyph.volumeMounts }}
        {{- toYaml $glyph.volumeMounts | nindent 8 }}
        {{- end }}
      volumes:
      - name: config
        configMap:
          name: {{ $collectorName }}-config
          items:
          - key: collector-config.yaml
            path: collector-config.yaml
      {{- if $glyph.volumes }}
      {{- toYaml $glyph.volumes | nindent 6 }}
      {{- end }}
      {{- if $glyph.nodeSelector }}
      nodeSelector:
        {{- toYaml $glyph.nodeSelector | nindent 8 }}
      {{- end }}
      {{- if $glyph.tolerations }}
      tolerations:
        {{- toYaml $glyph.tolerations | nindent 8 }}
      {{- else }}
      tolerations:
      - operator: Exists
        effect: NoSchedule
      - operator: Exists
        effect: NoExecute
      {{- end }}
      {{- if $glyph.affinity }}
      affinity:
        {{- toYaml $glyph.affinity | nindent 8 }}
      {{- end }}
{{- end -}}
