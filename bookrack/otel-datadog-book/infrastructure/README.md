# Infrastructure Chapter

Este chapter contiene la infraestructura core de OpenTelemetry: collectors y configuraciones de auto-instrumentación.

## Componentes

### 1. OpenTelemetry Collector Gateway (`otel-gateway.yaml`)

**Propósito**: Collector centralizado que recibe telemetría y exporta a Datadog.

**Arquitectura**:
- Deployment con 3 réplicas (HA)
- Autoscaling (2-10 pods)
- Pod anti-affinity para distribución
- Recibe de agents vía OTLP
- Exporta a Datadog

**Receivers**:
- OTLP gRPC/HTTP (primary)
- Prometheus
- Jaeger (para migración)

**Processors**:
- Batch (eficiencia)
- Memory limiter (prevenir OOM)
- Resource detection (metadata de infra)
- K8s attributes (metadata de pods)
- Span metrics (métricas desde trazas)

**Exporters**:
- Datadog (primary)
- Prometheus endpoint
- Logging (debug)

**Resources**:
```yaml
requests: 500m CPU, 1Gi memory
limits: 2000m CPU, 4Gi memory
autoscaling: 2-10 pods @ 70% CPU
```

**Endpoints**:
- OTLP gRPC: `:4317`
- OTLP HTTP: `:4318`
- Metrics: `:8888`
- Health: `:13133`

### 2. OpenTelemetry Collector Agent (`otel-agent.yaml`)

**Propósito**: DaemonSet que corre en cada nodo para recolección eficiente local.

**Arquitectura**:
- DaemonSet (1 pod por nodo)
- Recibe telemetría de pods locales
- Forwardea a gateway
- Lightweight processing

**Forward to**: `otel-collector-gateway.observability.svc:4317`

**Resources**:
```yaml
requests: 100m CPU, 256Mi memory
limits: 500m CPU, 1Gi memory
```

**Tolerations**: Corre en todos los nodos (incluyendo masters si es necesario)

### 3. Auto-Instrumentación

Configuraciones de auto-instrumentación para diferentes lenguajes usando OpenTelemetry Operator.

#### Java (`otel-instrumentation-java.yaml`)

**Instrumentaciones habilitadas**:
- Spring Web
- JDBC
- Kafka
- Redis
- MongoDB
- HTTP Client

**Uso en aplicación**:
```yaml
# En spell de aplicación
podAnnotations:
  instrumentation.opentelemetry.io/inject-java: "java-auto"
```

#### Python (`otel-instrumentation-python.yaml`)

**Instrumentaciones habilitadas**:
- Flask
- Django
- FastAPI
- Requests
- Psycopg2
- SQLAlchemy
- Redis

**Uso en aplicación**:
```yaml
podAnnotations:
  instrumentation.opentelemetry.io/inject-python: "python-auto"
```

#### Node.js (`otel-instrumentation-nodejs.yaml`)

**Instrumentaciones habilitadas**:
- HTTP
- Express
- MongoDB
- MySQL
- Redis
- Kafka

**Uso en aplicación**:
```yaml
podAnnotations:
  instrumentation.opentelemetry.io/inject-nodejs: "nodejs-auto"
```

## Flujo de Telemetría

```
┌──────────────┐
│  App (Pod)   │
│  + injected  │
│  OTel SDK    │
└──────┬───────┘
       │ OTLP :4317
       ▼
┌──────────────┐
│  Agent       │ (DaemonSet - local en nodo)
│  - Recibe    │
│  - Batch     │
└──────┬───────┘
       │ OTLP :4317
       ▼
┌──────────────┐
│  Gateway     │ (Deployment - centralizado)
│  - Recibe    │
│  - Enriquece │
│  - Exporta   │
└──────┬───────┘
       │ Datadog API
       ▼
┌──────────────┐
│  Datadog     │
└──────────────┘
```

## Deployment Order

1. **Gateway**: Debe estar corriendo primero
2. **Agent**: Forwardea a gateway
3. **Instrumentation**: Crea CRs para auto-instrumentación

El `index.yaml` del book maneja este orden automáticamente.

## Secrets Management

Los secrets de Datadog se manejan via Vault:

```yaml
glyphs:
  vault:
    - type: secret
      name: datadog-api-key
      path: "chapter"
      keys: [apiKey, appKey]
```

El glyph de OpenTelemetry lee estos secrets automáticamente.

## Monitoreo

### Métricas del Collector

Los collectors exponen sus propias métricas en `:8888/metrics`:

```yaml
podAnnotations:
  prometheus.io/scrape: "true"
  prometheus.io/port: "8888"
```

**Métricas clave**:
- `otelcol_receiver_accepted_spans`
- `otelcol_receiver_refused_spans`
- `otelcol_exporter_sent_spans`
- `otelcol_processor_batch_batch_send_size`
- `otelcol_process_runtime_total_sys_memory_bytes`

### Health Checks

```bash
# Gateway
kubectl port-forward -n observability svc/otel-collector-gateway 13133:13133
curl http://localhost:13133/

# Agent
kubectl port-forward -n observability daemonset/otel-collector-agent 13133:13133
curl http://localhost:13133/
```

## Scaling

### Gateway

**Horizontal**: Autoscaling automático (2-10 pods @ 70% CPU/80% memory)

**Vertical**: Ajustar resources en spell:
```yaml
resources:
  limits:
    cpu: 4000m     # Aumentar si es necesario
    memory: 8Gi
```

### Agent

**Nota**: DaemonSet escala automáticamente (1 pod por nodo).

**Vertical**: Ajustar resources si los nodos son grandes:
```yaml
resources:
  limits:
    cpu: 1000m
    memory: 2Gi
```

## Troubleshooting

### Gateway no recibe telemetría

```bash
# Ver logs
kubectl logs -n observability deployment/otel-collector-gateway -f

# Verificar endpoints
kubectl get svc -n observability otel-collector-gateway

# Port-forward y enviar test
kubectl port-forward -n observability svc/otel-collector-gateway 4317:4317
# Usar telemetrygen o app de prueba
```

### Agent no forwardea a gateway

```bash
# Ver logs
kubectl logs -n observability daemonset/otel-collector-agent -f

# Verificar conectividad
kubectl exec -n observability daemonset/otel-collector-agent -- \
  curl -v http://otel-collector-gateway.observability.svc:4317
```

### Auto-instrumentación no funciona

```bash
# Verificar Instrumentation CR existe
kubectl get instrumentation -n observability

# Verificar operator está corriendo
kubectl get pods -n opentelemetry-operator-system

# Verificar annotation en pod
kubectl describe pod <pod-name> -n <namespace>
```

### Datadog no recibe métricas

```bash
# Verificar API key
kubectl get secret -n observability datadog-api-key -o yaml

# Ver logs del gateway
kubectl logs -n observability deployment/otel-collector-gateway | grep datadog

# Verificar conectividad a Datadog
kubectl exec -n observability deployment/otel-collector-gateway -- \
  curl -X POST https://api.datadoghq.com/api/v1/validate \
  -H "DD-API-KEY: <api-key>"
```

## Performance Tuning

### Batch Size

Gateway maneja alto throughput:
```yaml
batchTimeout: "10s"
batchSize: 2048
batchMaxSize: 4096
```

Agent es más conservador:
```yaml
batchTimeout: "5s"
batchSize: 512
batchMaxSize: 1024
```

### Memory Limiter

Automático basado en resources:
- Límite: 80% de memory limit
- Spike: 25% adicional

### Sampling

Para reducir volumen de trazas en producción:
```yaml
# En Instrumentation
sampler:
  type: parentbased_traceidratio
  argument: "0.1"  # Sample 10% de trazas
```

## Referencias

- [OTel Collector Config](https://opentelemetry.io/docs/collector/configuration/)
- [Datadog Exporter](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/exporter/datadogexporter)
- [Auto-Instrumentation](https://opentelemetry.io/docs/kubernetes/operator/automatic/)
