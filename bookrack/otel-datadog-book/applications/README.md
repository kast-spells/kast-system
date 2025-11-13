# Applications Chapter

Este chapter contiene ejemplos de aplicaciones instrumentadas con OpenTelemetry usando auto-instrumentación.

## Aplicaciones de Ejemplo

### 1. Java API (`example-java-api.yaml`)

**Framework**: Spring Boot
**Lenguaje**: Java
**Puerto**: 8080

**Características**:
- Auto-instrumentación vía annotation
- Spring Web auto-instrumented
- JDBC/JPA queries traced
- HTTP clients traced
- Kafka producers/consumers traced
- Health checks via Spring Actuator

**Annotation clave**:
```yaml
podAnnotations:
  instrumentation.opentelemetry.io/inject-java: "java-auto"
```

**Instrumentaciones automáticas**:
- Spring Web MVC/WebFlux
- JDBC
- JPA/Hibernate
- HTTP Client (Apache/OkHttp)
- Kafka
- Redis
- MongoDB
- RabbitMQ

### 2. Python API (`example-python-api.yaml`)

**Framework**: FastAPI/Flask
**Lenguaje**: Python
**Puerto**: 8000

**Características**:
- Auto-instrumentación vía annotation
- Flask/FastAPI auto-instrumented
- SQL queries traced (psycopg2, SQLAlchemy)
- HTTP requests traced
- Log correlation habilitado

**Annotation clave**:
```yaml
podAnnotations:
  instrumentation.opentelemetry.io/inject-python: "python-auto"
```

**Instrumentaciones automáticas**:
- Flask
- Django
- FastAPI
- Requests
- Psycopg2 (PostgreSQL)
- SQLAlchemy
- Redis
- MongoDB (pymongo)
- Celery

### 3. Node.js API (`example-nodejs-api.yaml`)

**Framework**: Express
**Lenguaje**: Node.js
**Puerto**: 3000

**Características**:
- Auto-instrumentación vía annotation
- Express routes auto-instrumented
- MongoDB queries traced
- HTTP calls traced

**Annotation clave**:
```yaml
podAnnotations:
  instrumentation.opentelemetry.io/inject-nodejs: "nodejs-auto"
```

**Instrumentaciones automáticas**:
- Express
- HTTP/HTTPS
- MongoDB
- MySQL
- PostgreSQL
- Redis
- Kafka

## Patrón Común

Todas las aplicaciones siguen el mismo patrón:

### 1. Workload Base (Summon)
```yaml
workload:
  enabled: true
  type: deployment
  replicas: 3
```

### 2. Variables de Entorno OTLP
```yaml
env:
  - name: OTEL_EXPORTER_OTLP_ENDPOINT
    value: "http://otel-collector-agent.observability.svc:4317"
  - name: OTEL_SERVICE_NAME
    value: "my-service"
  - name: OTEL_RESOURCE_ATTRIBUTES
    value: "deployment.environment=production,service.version=v1.0.0"
```

### 3. Annotation de Auto-Instrumentación
```yaml
podAnnotations:
  instrumentation.opentelemetry.io/inject-<language>: "<instrumentation-name>"
```

## Variables de Entorno OpenTelemetry

### Requeridas

| Variable | Descripción | Ejemplo |
|----------|-------------|---------|
| `OTEL_EXPORTER_OTLP_ENDPOINT` | Endpoint del collector | `http://otel-agent:4317` |
| `OTEL_SERVICE_NAME` | Nombre del servicio | `my-api` |

### Opcionales (recomendadas)

| Variable | Descripción | Ejemplo |
|----------|-------------|---------|
| `OTEL_RESOURCE_ATTRIBUTES` | Tags/labels | `environment=prod,version=v1` |
| `OTEL_EXPORTER_OTLP_PROTOCOL` | Protocolo OTLP | `grpc` (default) |
| `OTEL_TRACES_SAMPLER` | Estrategia de sampling | `always_on`, `traceidratio` |
| `OTEL_PROPAGATORS` | Propagators de contexto | `tracecontext,baggage,b3` |

### Específicas por Lenguaje

**Java**:
```yaml
- name: OTEL_INSTRUMENTATION_KAFKA_ENABLED
  value: "true"
- name: OTEL_INSTRUMENTATION_JDBC_ENABLED
  value: "true"
```

**Python**:
```yaml
- name: OTEL_PYTHON_LOGGING_AUTO_INSTRUMENTATION_ENABLED
  value: "true"
- name: OTEL_PYTHON_LOG_CORRELATION
  value: "true"
```

**Node.js**:
```yaml
- name: NODE_OPTIONS
  value: "--require /otel-auto-instrumentation/autoinstrumentation.js"
```

## Telemetría Generada

### Métricas

**Runtime**:
- CPU usage
- Memory usage
- GC stats (Java)
- Event loop lag (Node.js)

**HTTP**:
- Request rate
- Response time (p50, p95, p99)
- Error rate
- Status code distribution

**Database**:
- Query duration
- Connection pool stats
- Query errors

### Trazas (Traces)

**HTTP Requests**:
- Endpoint
- Method
- Status code
- Duration
- Headers (filtered)

**Database Queries**:
- Query text (sanitized)
- Duration
- Database name
- Table/collection

**External Calls**:
- Destination
- Method
- Duration
- Status

### Logs

**Structured Logs**:
- Timestamp
- Level (INFO, WARN, ERROR)
- Message
- Trace ID (correlation)
- Span ID (correlation)

## Resource Attributes (Tags en Datadog)

Las aplicaciones envían estos atributos automáticamente:

```yaml
# Definidos en env vars
deployment.environment: "production"
service.version: "v1.0.0"
service.namespace: "applications"
team: "backend"
language: "java"

# Detectados automáticamente por collector
k8s.namespace.name: "applications"
k8s.pod.name: "example-java-api-xyz"
k8s.deployment.name: "example-java-api"
k8s.node.name: "node-1"
host.name: "node-1"
container.id: "abc123"
```

## Sampling

### Producción (reducir volumen)

```yaml
env:
  - name: OTEL_TRACES_SAMPLER
    value: "parentbased_traceidratio"
  - name: OTEL_TRACES_SAMPLER_ARG
    value: "0.1"  # Sample 10% de trazas
```

### Development/Staging (todo)

```yaml
env:
  - name: OTEL_TRACES_SAMPLER
    value: "always_on"
```

### Smart Sampling (recomendado)

```yaml
# En Instrumentation CR
sampler:
  type: parentbased_traceidratio
  argument: "0.1"
```

Esto muestrea 10% de trazas, pero siempre incluye:
- Errores
- Latencias altas
- Trazas padres (mantiene contexto completo)

## Verificación

### 1. Pod tiene sidecar inyectado

```bash
kubectl get pod <pod-name> -n applications -o jsonpath='{.spec.containers[*].name}'

# Deberías ver:
# app-container opentelemetry-auto-instrumentation
```

### 2. Variables de entorno

```bash
kubectl exec -n applications <pod-name> -- env | grep OTEL
```

### 3. Telemetría fluyendo

```bash
# Ver logs de app
kubectl logs -n applications <pod-name> -c app-container

# Ver logs de collector agent
kubectl logs -n observability daemonset/otel-collector-agent
```

### 4. Métricas en Datadog

Ir a Datadog → APM → Services → buscar `example-java-api`

## Troubleshooting

### Auto-instrumentación no funciona

```bash
# 1. Verificar Instrumentation CR existe
kubectl get instrumentation -n observability

# 2. Verificar operator está corriendo
kubectl get pods -n opentelemetry-operator-system

# 3. Verificar annotation en pod
kubectl get pod <pod-name> -n applications -o yaml | grep instrumentation

# 4. Ver logs del operator
kubectl logs -n opentelemetry-operator-system deployment/opentelemetry-operator
```

### No aparecen trazas en Datadog

```bash
# 1. Verificar endpoint es alcanzable
kubectl exec -n applications <pod-name> -- \
  curl -v http://otel-collector-agent.observability.svc:4317

# 2. Ver logs de app para errores OTLP
kubectl logs -n applications <pod-name> | grep -i otel

# 3. Ver métricas del collector agent
kubectl port-forward -n observability daemonset/otel-collector-agent 8888:8888
curl http://localhost:8888/metrics | grep receiver_accepted
```

### Latencia alta después de instrumentar

**Causas**:
- Sampling = `always_on` en producción (muestrear todo)
- Batch size muy pequeño
- Network latency al collector

**Soluciones**:
```yaml
# Reducir sampling
- name: OTEL_TRACES_SAMPLER_ARG
  value: "0.1"  # 10% en vez de 100%

# Aumentar batch size en agent
batchTimeout: "10s"
batchSize: 1024
```

### Alto uso de memoria

**Causa**: Instrumentación automática aumenta memory footprint.

**Solución**:
```yaml
resources:
  limits:
    memory: 1Gi  # Aumentar de 512Mi
  requests:
    memory: 512Mi  # Aumentar de 256Mi
```

## Migración desde Agente Nativo

Ver chapter `migration-dual-write` para ejemplos de apps que envían a ambos (Datadog agent + OpenTelemetry).

## Referencias

- [Java Auto-Instrumentation](https://opentelemetry.io/docs/instrumentation/java/automatic/)
- [Python Auto-Instrumentation](https://opentelemetry.io/docs/instrumentation/python/automatic/)
- [Node.js Auto-Instrumentation](https://opentelemetry.io/docs/instrumentation/js/automatic/)
- [OpenTelemetry Operator](https://github.com/open-telemetry/opentelemetry-operator)
