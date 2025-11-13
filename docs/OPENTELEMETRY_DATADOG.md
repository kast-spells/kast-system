# OpenTelemetry → Datadog Integration con Kast-System

## Índice
1. [Resumen Ejecutivo](#resumen-ejecutivo)
2. [Arquitectura Propuesta](#arquitectura-propuesta)
3. [Componentes](#componentes)
4. [Implementación](#implementación)
5. [Ejemplos de Uso](#ejemplos-de-uso)
6. [Migración desde Implementación Actual](#migración)
7. [Comparación: OpenTelemetry vs Alloy](#comparación-otel-vs-alloy)

---

## Resumen Ejecutivo

### Objetivo
Integrar **OpenTelemetry Collector** como recolector centralizado de métricas, trazas y logs, exportando hacia **Datadog** usando el patrón GitOps de **kast-system**.

### Estrategia
Crear un **glyph de opentelemetry** que permita:
- Desplegar collectors (gateway/agent/sidecar)
- Configurar pipelines de telemetría
- Integrar con Vault para secrets de Datadog
- Auto-instrumentación de aplicaciones
- Configuración declarativa vía YAML

### Ventajas del Enfoque
- ✅ **Vendor-agnostic**: OpenTelemetry es estándar, no lock-in con Datadog
- ✅ **GitOps nativo**: Todo en código, versionado, auditable
- ✅ **Reutilizable**: Glyphs compartidos entre aplicaciones
- ✅ **Seguro**: Secrets manejados por Vault
- ✅ **Modular**: Collectors independientes por namespace/workload
- ✅ **Testeable**: Workflow TDD integrado

---

## Arquitectura Propuesta

```
┌─────────────────────────────────────────────────────────────────┐
│                        APLICACIONES                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                       │
│  │  App A   │  │  App B   │  │  App C   │                       │
│  │ (summon) │  │ (summon) │  │ (summon) │                       │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘                       │
│       │             │             │                              │
│       │ OTLP        │ OTLP       │ OTLP                         │
│       ▼             ▼             ▼                              │
│  ┌──────────────────────────────────────┐                       │
│  │   OpenTelemetry Collector Agent      │ ◄── glyph: otel       │
│  │   (DaemonSet - por nodo)             │                       │
│  │   - Recibe: OTLP, Prometheus, Jaeger │                       │
│  │   - Procesa: batch, filter, enrich   │                       │
│  └──────────────────┬───────────────────┘                       │
│                     │ OTLP                                       │
│                     ▼                                            │
│  ┌──────────────────────────────────────┐                       │
│  │   OpenTelemetry Collector Gateway    │ ◄── spell: otel-gw    │
│  │   (Deployment - centralizado)        │                       │
│  │   - Recibe: de agents                │                       │
│  │   - Exporta: Datadog, Prometheus     │                       │
│  │   - Secrets: Vault (API keys)        │                       │
│  └──────────────────┬───────────────────┘                       │
│                     │                                            │
└─────────────────────┼────────────────────────────────────────────┘
                      │
                      │ Datadog API
                      ▼
               ┌──────────────┐
               │   Datadog    │
               │   (SaaS)     │
               └──────────────┘
```

### Flujo de Datos

```yaml
App → OTLP :4317 → OTel Agent (DaemonSet)
                    ↓ procesa/batch
                    → OTel Gateway (Deployment)
                       ↓ enriquece/exporta
                       → Datadog API
```

---

## Componentes

### 1. Glyph: `opentelemetry`

**Ubicación**: `charts/glyphs/opentelemetry/`

**Tipos de recursos generados**:
- `ConfigMap`: Configuración del collector (YAML)
- `Deployment`/`DaemonSet`/`StatefulSet`: Collector workload
- `Service`: Endpoints OTLP (gRPC/HTTP)
- `ServiceMonitor`: Auto-discovery de Prometheus Operator
- `VaultSecret`: API keys de Datadog (integración con glyph vault)

**Tipos de glyphs soportados**:

```yaml
glyphs:
  opentelemetry:
    # Tipo 1: Collector Gateway (centralizado)
    - type: collectorGateway
      name: otel-gateway
      replicas: 3
      exporters:
        - datadog
        - prometheus
      datadogSelector:
        name: datadog-prod  # Desde lexicon

    # Tipo 2: Collector Agent (por nodo)
    - type: collectorAgent
      name: otel-agent
      forwardTo: otel-gateway
      receivers:
        - otlp
        - prometheus
        - jaeger

    # Tipo 3: Sidecar (por pod)
    - type: collectorSidecar
      name: otel-sidecar
      forwardTo: otel-gateway

    # Tipo 4: Auto-instrumentación
    - type: instrumentation
      name: auto-instrument
      language: java  # java, python, nodejs, dotnet, go
      propagators:
        - tracecontext
        - baggage
```

### 2. Lexicon: Datadog Config

**Ubicación**: `bookrack/<book>/index.yaml` o `_lexicon/`

```yaml
appendix:
  lexicon:
    # Definir conexión a Datadog
    - type: datadog
      name: datadog-prod
      site: datadoghq.com  # o datadoghq.eu
      vaultSecretPath: "chapter"
      apiKeySecret:
        vaultPath: "/datadog/api-key"
        vaultKey: apiKey
      appKeySecret:  # Opcional
        vaultPath: "/datadog/app-key"
        vaultKey: appKey
      labels:
        environment: production
        team: platform
```

### 3. Spell: Despliegue de Collector

**Ubicación**: `bookrack/<book>/infrastructure/otel-collector.yaml`

```yaml
name: otel-collector-gateway
namespace: observability

# Usar summon para el workload base
workload:
  enabled: true
  type: deployment
  replicas: 3

image:
  repository: otel/opentelemetry-collector-contrib
  tag: 0.91.0

service:
  enabled: true
  ports:
    - name: otlp-grpc
      port: 4317
      targetPort: 4317
    - name: otlp-http
      port: 4318
      targetPort: 4318
    - name: metrics
      port: 8888
      targetPort: 8888

resources:
  limits:
    cpu: 1000m
    memory: 2Gi
  requests:
    cpu: 200m
    memory: 400Mi

autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70

# Integración con Vault para secrets
glyphs:
  vault:
    - type: secret
      name: datadog-api-key
      path: "chapter"
      keys:
        - apiKey
        - appKey
      serviceAccount: otel-collector

  # Configuración de OpenTelemetry
  opentelemetry:
    - type: collectorGateway
      name: gateway
      exporters:
        - datadog
        - prometheus
      datadogSelector:
        name: datadog-prod

      # Pipeline de métricas
      metricsPath:
        receivers:
          - otlp
          - prometheus
        processors:
          - batch
          - memory_limiter
          - resourcedetection
        exporters:
          - datadog
          - prometheus

      # Pipeline de trazas
      tracesPath:
        receivers:
          - otlp
          - jaeger
        processors:
          - batch
          - memory_limiter
          - spanmetrics
        exporters:
          - datadog

      # Pipeline de logs
      logsPath:
        receivers:
          - otlp
        processors:
          - batch
          - memory_limiter
        exporters:
          - datadog
```

### 4. Spell: Aplicación con Auto-instrumentación

**Ubicación**: `bookrack/<book>/applications/my-api.yaml`

```yaml
name: my-api
namespace: applications

workload:
  enabled: true
  type: deployment
  replicas: 3

image:
  repository: myorg/my-api
  tag: v1.0.0

# Variables de entorno para OTLP
env:
  - name: OTEL_EXPORTER_OTLP_ENDPOINT
    value: "http://otel-agent.observability.svc:4317"
  - name: OTEL_SERVICE_NAME
    value: "my-api"
  - name: OTEL_RESOURCE_ATTRIBUTES
    value: "deployment.environment=production,service.version=v1.0.0"

# Auto-instrumentación (opcional, si usas operator)
glyphs:
  opentelemetry:
    - type: instrumentation
      name: auto-instrument
      language: java
      propagators:
        - tracecontext
        - baggage
```

---

## Implementación

### Fase 1: Crear Glyph Base

```bash
# 1. Crear estructura del glyph
mkdir -p charts/glyphs/opentelemetry/{templates,examples,tests}

# 2. Archivos necesarios
touch charts/glyphs/opentelemetry/Chart.yaml
touch charts/glyphs/opentelemetry/values.yaml
touch charts/glyphs/opentelemetry/templates/_opentelemetry.tpl
touch charts/glyphs/opentelemetry/templates/collector-gateway.tpl
touch charts/glyphs/opentelemetry/templates/collector-agent.tpl
touch charts/glyphs/opentelemetry/templates/instrumentation.tpl
touch charts/glyphs/opentelemetry/templates/config-map.tpl
```

### Fase 2: Templates Principales

#### `templates/_opentelemetry.tpl` (Helper principal)

```yaml
{{- define "opentelemetry.config" -}}
{{- $root := index . 0 -}}
{{- $glyph := index . 1 -}}
{{- $datadogConf := index . 2 -}}

receivers:
  {{- if has "otlp" $glyph.receivers }}
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318
  {{- end }}

  {{- if has "prometheus" $glyph.receivers }}
  prometheus:
    config:
      scrape_configs:
        - job_name: 'otel-collector'
          scrape_interval: 30s
          static_configs:
            - targets: ['0.0.0.0:8888']
  {{- end }}

processors:
  batch:
    timeout: 10s
    send_batch_size: 1024

  memory_limiter:
    check_interval: 1s
    limit_mib: 512

  resourcedetection:
    detectors: [env, system, docker, kubernetes]
    timeout: 5s

exporters:
  {{- if has "datadog" $glyph.exporters }}
  datadog:
    api:
      site: {{ $datadogConf.site }}
      key: ${DD_API_KEY}

    host_metadata:
      enabled: true
      hostname_source: config_or_system

    traces:
      trace_buffer: 500

    metrics:
      histograms:
        mode: distributions
        send_aggregation_metrics: true
  {{- end }}

service:
  pipelines:
    metrics:
      receivers: {{ $glyph.metricsPath.receivers | toJson }}
      processors: {{ $glyph.metricsPath.processors | toJson }}
      exporters: {{ $glyph.metricsPath.exporters | toJson }}

    traces:
      receivers: {{ $glyph.tracesPath.receivers | toJson }}
      processors: {{ $glyph.tracesPath.processors | toJson }}
      exporters: {{ $glyph.tracesPath.exporters | toJson }}
{{- end -}}
```

### Fase 3: Testing

```bash
# Crear ejemplo TDD
make create-example CHART=opentelemetry EXAMPLE=basic-gateway

# Red phase
make tdd-red

# Implementar templates...

# Green phase
make tdd-green

# Generar snapshots
make generate-snapshots CHART=opentelemetry
```

---

## Ejemplos de Uso

### Ejemplo 1: Collector Centralizado Simple

**Book**: `bookrack/production-book/infrastructure/otel-gateway.yaml`

```yaml
name: otel-gateway
namespace: observability

workload:
  type: deployment
  replicas: 2

image:
  repository: otel/opentelemetry-collector-contrib
  tag: 0.91.0

glyphs:
  vault:
    - type: secret
      name: datadog-creds
      path: "chapter"
      keys: [apiKey]

  opentelemetry:
    - type: collectorGateway
      exporters: [datadog]
      datadogSelector:
        name: datadog-prod
```

### Ejemplo 2: DaemonSet Agent

**Book**: `bookrack/production-book/infrastructure/otel-agent.yaml`

```yaml
name: otel-agent
namespace: observability

workload:
  type: daemonset

image:
  repository: otel/opentelemetry-collector-contrib
  tag: 0.91.0

glyphs:
  opentelemetry:
    - type: collectorAgent
      forwardTo: otel-gateway.observability.svc:4317
      receivers:
        - otlp
        - prometheus
```

### Ejemplo 3: App con Auto-instrumentación Java

**Book**: `bookrack/production-book/applications/payment-api.yaml`

```yaml
name: payment-api
namespace: applications

workload:
  type: deployment
  replicas: 3

image:
  repository: myorg/payment-api
  tag: v2.0.0

glyphs:
  opentelemetry:
    - type: instrumentation
      name: java-auto
      language: java
      env:
        OTEL_EXPORTER_OTLP_ENDPOINT: http://otel-agent.observability.svc:4317
        OTEL_SERVICE_NAME: payment-api
        OTEL_METRICS_EXPORTER: otlp
        OTEL_TRACES_EXPORTER: otlp
        OTEL_LOGS_EXPORTER: otlp
```

---

## Migración desde Implementación Actual

### Paso 1: Inventario

```bash
# Identificar servicios actuales con telemetría
# (fuera de k8s - C#, Java, JS)
```

### Paso 2: Configuración Paralela

```yaml
# Desplegar OTel Collector sin afectar implementación actual
# Recolectar métricas en paralelo (dual write)
```

### Paso 3: Migración Gradual

```yaml
# Por servicio:
1. Agregar SDK de OpenTelemetry
2. Configurar OTLP endpoint
3. Validar métricas en Datadog
4. Remover cliente de Datadog nativo
5. Monitorear por 1 semana
```

### Paso 4: Deprecar Implementación Antigua

```yaml
# Una vez 100% de servicios migrados:
1. Remover agentes de Datadog (si existen)
2. Consolidar configuración en kast-system
3. Documentar proceso
```

---

## Comparación: OpenTelemetry vs Alloy

| Aspecto | OpenTelemetry | Grafana Alloy |
|---------|---------------|---------------|
| **Estándar** | ✅ CNCF standard, vendor-agnostic | ❌ Grafana-specific |
| **Adopción** | ✅ Mayor ecosistema, más SDKs | ⚠️ Creciente pero menor |
| **Backends** | ✅ Datadog, Prometheus, Jaeger, etc. | ⚠️ Principalmente Grafana Cloud |
| **Auto-instrumentación** | ✅ Java, Python, Node, .NET, Go | ⚠️ Limitado |
| **Complejidad** | ⚠️ Más complejo configurar | ✅ Más simple para Grafana |
| **Métricas** | ✅ OTLP, Prometheus, StatsD | ✅ Prometheus principalmente |
| **Trazas** | ✅ Native OTLP, Jaeger, Zipkin | ⚠️ Tempo/Jaeger |
| **Logs** | ✅ OTLP logs | ✅ Loki native |
| **Performance** | ✅ Optimizado, escalable | ✅ Similar |
| **Datadog** | ✅ Exporter oficial | ❌ Requiere conversión |
| **GitOps** | ✅ ConfigMaps YAML | ✅ ConfigMaps YAML |

### Recomendación

**Usar OpenTelemetry** porque:
1. ✅ **Requerimiento cumplido**: Exporta nativamente a Datadog
2. ✅ **Futuro-proof**: Si cambiamos de backend, solo cambiar exporter
3. ✅ **Ecosistema**: Más librerías, operadores, documentación
4. ✅ **Auto-instrumentación**: Más maduro para múltiples lenguajes
5. ✅ **Kast-system**: Se integra perfectamente con el patrón de glyphs

**Considerar Alloy solo si**:
- ❌ Migrar completamente a Grafana Cloud/Loki/Tempo
- ❌ No necesitamos Datadog específicamente
- ❌ Queremos algo más simple (pero perdemos flexibilidad)

---

## Próximos Pasos

1. ✅ **Aprobar diseño** (este documento)
2. ⬜ **Implementar glyph `opentelemetry`**
   - Templates base
   - Ejemplos TDD
   - Tests
3. ⬜ **Crear spells de ejemplo**
   - Gateway
   - Agent
   - App instrumentada
4. ⬜ **Documentación adicional**
   - Guía de migración detallada
   - Troubleshooting
   - Best practices
5. ⬜ **Testing en cluster real**
   - Desplegar collector
   - Validar export a Datadog
   - Métricas de performance

---

## Referencias

- [OpenTelemetry Docs](https://opentelemetry.io/docs/)
- [Datadog OpenTelemetry](https://docs.datadoghq.com/opentelemetry/)
- [OTel Collector Config](https://opentelemetry.io/docs/collector/configuration/)
- [Kast-System Glyphs](./GLYPHS.md)
- [Kast-System Vault](./VAULT.md)
