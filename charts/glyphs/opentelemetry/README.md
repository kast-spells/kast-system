# OpenTelemetry Glyph

Glyph para desplegar y configurar **OpenTelemetry Collector** con integración a **Datadog** siguiendo el patrón kast-system.

## Descripción

Este glyph permite:
- ✅ Desplegar OpenTelemetry Collector en diferentes modos (gateway, agent, sidecar)
- ✅ Configurar pipelines de métricas, trazas y logs
- ✅ Exportar telemetría a Datadog
- ✅ Auto-instrumentación de aplicaciones (Java, Python, Node.js, .NET, Go)
- ✅ Integración con Vault para secrets
- ✅ Configuración declarativa vía YAML

## Tipos de Glyph

### 1. `collectorGateway`

Collector centralizado (Deployment) que recibe telemetría y exporta a backends.

**Uso típico**: Punto central de recolección en el cluster.

```yaml
glyphs:
  opentelemetry:
    - type: collectorGateway
      name: gateway
      replicas: 3
      receivers: [otlp, prometheus]
      processors: [batch, memory_limiter]
      exporters: [datadog]
      datadogSelector:
        name: datadog-prod
```

**Ver ejemplo completo**: [`examples/basic-gateway.yaml`](./examples/basic-gateway.yaml)

### 2. `collectorAgent`

Collector por nodo (DaemonSet) que recolecta telemetría localmente.

**Uso típico**: Recolección eficiente de métricas de pods en cada nodo, forward a gateway.

```yaml
glyphs:
  opentelemetry:
    - type: collectorAgent
      name: agent
      forwardTo: otel-gateway.observability.svc:4317
      receivers: [otlp, prometheus]
```

**Ver ejemplo completo**: [`examples/basic-agent.yaml`](./examples/basic-agent.yaml)

### 3. `collectorSidecar`

Collector como sidecar container (para casos especiales).

**Uso típico**: Aplicaciones con requerimientos específicos de telemetría.

```yaml
glyphs:
  opentelemetry:
    - type: collectorSidecar
      name: sidecar
      forwardTo: otel-gateway.observability.svc:4317
```

### 4. `instrumentation`

Auto-instrumentación de aplicaciones usando OpenTelemetry Operator.

**Uso típico**: Aplicaciones Java, Python, Node.js que necesitan telemetría sin cambios de código.

```yaml
glyphs:
  opentelemetry:
    - type: instrumentation
      name: java-auto
      language: java
      endpoint: http://otel-agent.observability.svc:4317
      propagators:
        - tracecontext
        - baggage
```

**Ver ejemplo completo**: [`examples/app-with-instrumentation.yaml`](./examples/app-with-instrumentation.yaml)

## Configuración

### Receivers

Componentes que reciben telemetría:

```yaml
receivers:
  - otlp          # OTLP gRPC/HTTP (recomendado)
  - prometheus    # Métricas Prometheus
  - jaeger        # Trazas Jaeger (legacy)
```

### Processors

Componentes que procesan telemetría:

```yaml
processors:
  - batch                # Agrupa datos para eficiencia
  - memory_limiter       # Previene OOM
  - resourcedetection    # Detecta metadatos de infraestructura
  - k8sattributes        # Enriquece con metadatos de K8s
  - spanmetrics          # Genera métricas desde trazas
```

### Exporters

Componentes que exportan telemetría:

```yaml
exporters:
  - datadog       # Exporta a Datadog
  - prometheus    # Expone métricas Prometheus
  - logging       # Logs para debugging
```

## Pipelines

Define flujos de datos para cada tipo de telemetría:

```yaml
metricsPath:
  receivers: [otlp, prometheus]
  processors: [batch, memory_limiter, resourcedetection]
  exporters: [datadog]

tracesPath:
  receivers: [otlp, jaeger]
  processors: [batch, memory_limiter, spanmetrics]
  exporters: [datadog]

logsPath:
  receivers: [otlp]
  processors: [batch, memory_limiter]
  exporters: [datadog]
```

## Integración con Vault

El glyph se integra con Vault para manejar secrets de Datadog:

```yaml
glyphs:
  vault:
    - type: secret
      name: datadog-api-key
      path: "chapter"
      keys:
        - apiKey
        - appKey
      serviceAccount: otel-collector

  opentelemetry:
    - type: collectorGateway
      datadogSecretName: datadog-api-key
      datadogApiKeyKey: apiKey
      datadogAppKeyKey: appKey
```

## Lexicon para Datadog

Define configuración de Datadog en el lexicon del book:

```yaml
appendix:
  lexicon:
    - type: datadog
      name: datadog-prod
      site: datadoghq.com  # o datadoghq.eu
      vaultSecretPath: "chapter"
      apiKeySecret:
        vaultPath: "/datadog/api-key"
        vaultKey: apiKey
      labels:
        environment: production
        team: platform
```

Luego referencia en el glyph:

```yaml
glyphs:
  opentelemetry:
    - type: collectorGateway
      datadogSelector:
        name: datadog-prod
```

## Recursos y Performance

### Gateway (recomendado para producción)

```yaml
resources:
  limits:
    cpu: 2000m
    memory: 4Gi
  requests:
    cpu: 500m
    memory: 1Gi

replicas: 3

affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
              - key: app.kubernetes.io/component
                operator: In
                values:
                  - opentelemetry-collector
          topologyKey: kubernetes.io/hostname
```

### Agent (recomendado para producción)

```yaml
resources:
  limits:
    cpu: 500m
    memory: 1Gi
  requests:
    cpu: 100m
    memory: 256Mi

tolerations:
  - operator: Exists
    effect: NoSchedule
  - operator: Exists
    effect: NoExecute
```

## Performance Tuning

### Batch Processor

```yaml
batchTimeout: "10s"      # Tiempo máximo antes de enviar
batchSize: 2048          # Tamaño de batch normal
batchMaxSize: 4096       # Tamaño máximo de batch
```

### Memory Limiter

```yaml
processors:
  - memory_limiter

# Configuración automática basada en recursos del container
# Límite: 80% de memoria asignada
# Spike: 25% adicional
```

### Trace Buffer

```yaml
traceBuffer: 1000  # Buffer de trazas (default: 500)
```

## Auto-Instrumentación

### Prerequisitos

1. **OpenTelemetry Operator** debe estar instalado en el cluster:

```bash
kubectl apply -f https://github.com/open-telemetry/opentelemetry-operator/releases/latest/download/opentelemetry-operator.yaml
```

### Lenguajes Soportados

| Lenguaje | Status | Image |
|----------|--------|-------|
| Java | ✅ GA | `autoinstrumentation-java:latest` |
| Python | ✅ GA | `autoinstrumentation-python:latest` |
| Node.js | ✅ GA | `autoinstrumentation-nodejs:latest` |
| .NET | ✅ GA | `autoinstrumentation-dotnet:latest` |
| Go | ⚠️ Beta | `autoinstrumentation-go:latest` |

### Habilitar en Aplicación

1. **Crear Instrumentation resource** (en spell de infra):

```yaml
glyphs:
  opentelemetry:
    - type: instrumentation
      name: java-auto
      language: java
      endpoint: http://otel-agent.observability.svc:4317
```

2. **Anotar pod** (en spell de aplicación):

```yaml
podAnnotations:
  instrumentation.opentelemetry.io/inject-java: "java-auto"
```

3. **Variables de entorno** (opcional, para customización):

```yaml
env:
  - name: OTEL_SERVICE_NAME
    value: "my-service"
  - name: OTEL_RESOURCE_ATTRIBUTES
    value: "deployment.environment=production"
```

## Arquitectura Recomendada

### Opción 1: Gateway Centralizado

```
Apps → Gateway → Datadog
```

**Pros**: Simple, menos recursos
**Cons**: Single point of failure (mitigar con replicas)

```yaml
# Solo gateway
glyphs:
  opentelemetry:
    - type: collectorGateway
      replicas: 3
```

### Opción 2: Agent + Gateway (Recomendado)

```
Apps → Agent (DaemonSet) → Gateway → Datadog
```

**Pros**: Escalable, resiliente, eficiente
**Cons**: Más recursos

```yaml
# Gateway
glyphs:
  opentelemetry:
    - type: collectorGateway
      name: gateway
      replicas: 3

# Agent
glyphs:
  opentelemetry:
    - type: collectorAgent
      name: agent
      forwardTo: otel-gateway.observability.svc:4317
```

**Ver ejemplo completo**: [`examples/complete-stack.yaml`](./examples/complete-stack.yaml)

## Monitoreo del Collector

### Métricas Propias

El collector expone sus propias métricas en `:8888/metrics`:

```yaml
podAnnotations:
  prometheus.io/scrape: "true"
  prometheus.io/port: "8888"
  prometheus.io/path: "/metrics"
```

### Health Checks

```yaml
livenessProbe:
  httpGet:
    path: /
    port: 13133

readinessProbe:
  httpGet:
    path: /
    port: 13133
```

### Métricas Clave a Monitorear

- `otelcol_processor_batch_batch_send_size`
- `otelcol_exporter_sent_spans`
- `otelcol_exporter_sent_metric_points`
- `otelcol_receiver_accepted_spans`
- `otelcol_processor_refused_spans`

## Troubleshooting

### 1. Collector no arranca

```bash
# Ver logs
kubectl logs -n observability deployment/otel-collector-gateway

# Verificar configmap
kubectl get configmap -n observability otel-collector-gateway-config -o yaml
```

### 2. Métricas no llegan a Datadog

```bash
# Verificar API key
kubectl get secret -n observability datadog-api-key -o jsonpath='{.data.apiKey}' | base64 -d

# Verificar conectividad
kubectl exec -n observability deployment/otel-collector-gateway -- \
  curl -X POST https://api.datadoghq.com/api/v1/validate \
  -H "DD-API-KEY: <api-key>"
```

### 3. High memory usage

```yaml
# Reducir batch size
batchSize: 512
batchMaxSize: 1024

# Reducir trace buffer
traceBuffer: 200

# Ajustar memory_limiter
resources:
  limits:
    memory: 2Gi  # Incrementar si necesario
```

### 4. Debugging con logging exporter

```yaml
exporters:
  - logging  # Agrega temporalmente

logsPath:
  exporters: [datadog, logging]
```

## Testing

### Enviar métricas de prueba

```bash
# Port-forward al collector
kubectl port-forward -n observability svc/otel-collector-gateway 4317:4317

# Usar telemetrygen (https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/cmd/telemetrygen)
telemetrygen metrics --otlp-endpoint localhost:4317 --otlp-insecure --duration 10s
```

### Enviar trazas de prueba

```bash
telemetrygen traces --otlp-endpoint localhost:4317 --otlp-insecure --duration 10s
```

## Migración desde Implementación Actual

### Paso 1: Deploy en paralelo

Despliega OpenTelemetry sin afectar implementación actual:

```yaml
# Chapter: infrastructure
glyphs:
  opentelemetry:
    - type: collectorGateway
      # ... configuración
```

### Paso 2: Dual-write

Configura apps para enviar a ambos (legacy + otel):

```yaml
env:
  - name: DATADOG_AGENT_HOST  # Legacy
    value: datadog-agent
  - name: OTEL_EXPORTER_OTLP_ENDPOINT  # Nuevo
    value: http://otel-agent:4317
```

### Paso 3: Validar

Compara métricas en Datadog de ambas fuentes.

### Paso 4: Migrar

Remueve configuración legacy de apps una por una:

```yaml
# Remover
env:
  - name: DATADOG_AGENT_HOST
    value: datadog-agent

# Mantener
env:
  - name: OTEL_EXPORTER_OTLP_ENDPOINT
    value: http://otel-agent:4317
```

### Paso 5: Cleanup

Una vez 100% migrado:

```bash
# Remover agentes legacy
kubectl delete daemonset datadog-agent -n monitoring
```

## Referencias

- [OpenTelemetry Docs](https://opentelemetry.io/docs/)
- [Datadog + OpenTelemetry](https://docs.datadoghq.com/opentelemetry/)
- [OTel Collector Config](https://opentelemetry.io/docs/collector/configuration/)
- [OTel Operator](https://github.com/open-telemetry/opentelemetry-operator)
- [Kast-System Docs](../../../docs/)

## Soporte

Para issues o preguntas:
- GitHub: https://github.com/kast-spells/kast-system/issues
- Documentación: [OPENTELEMETRY_DATADOG.md](../../../docs/OPENTELEMETRY_DATADOG.md)
