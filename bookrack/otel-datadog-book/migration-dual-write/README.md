# Migration: Dual-Write Chapter

Este chapter contiene ejemplos de aplicaciones configuradas para enviar telemetría a **AMBOS** backends simultáneamente durante la migración:
- ✅ **Legacy**: Datadog Agent nativo (ddtrace, dd-trace, dd-java-agent)
- ✅ **New**: OpenTelemetry Collector → Datadog

## ¿Por qué Dual-Write?

El dual-write permite:
1. ✅ **Validación**: Comparar métricas entre ambos sistemas
2. ✅ **Confianza**: Probar OpenTelemetry sin afectar monitoring existente
3. ✅ **Rollback**: Desactivar OpenTelemetry si hay problemas
4. ✅ **Gradual**: Migrar servicio por servicio, no todo de golpe

## Aplicaciones de Ejemplo

### 1. Java Application (`legacy-java-app-dual.yaml`)

**Dual Instrumentation**:
- **Legacy**: Datadog Java Agent (`dd-java-agent.jar`)
- **New**: OpenTelemetry auto-instrumentation

**Cómo funciona**:
```yaml
# Init container descarga dd-java-agent.jar
initContainers:
  - name: datadog-agent-downloader
    # Downloads dd-java-agent.jar to /dd-java-agent/

# Java agent via JAVA_TOOL_OPTIONS
env:
  - name: JAVA_TOOL_OPTIONS
    value: "-javaagent:/dd-java-agent/dd-java-agent.jar"

# OpenTelemetry via annotation
podAnnotations:
  instrumentation.opentelemetry.io/inject-java: "java-auto"
```

**Trade-offs**:
- ⚠️ Mayor uso de CPU/memoria (ambos agents corriendo)
- ⚠️ Startup time más largo
- ✅ Datos idénticos en ambos sistemas para comparar

### 2. Python Application (`legacy-python-app-dual.yaml`)

**Dual Instrumentation**:
- **Legacy**: `ddtrace-run` wrapper
- **New**: OpenTelemetry `opentelemetry-instrument`

**Cómo funciona**:
```yaml
# Ambos wrappers en command
command:
  - sh
  - -c
  - |
    exec ddtrace-run opentelemetry-instrument python app.py
```

**Prerequisitos**:
Dockerfile debe incluir ambos packages:
```dockerfile
RUN pip install \
    ddtrace \
    opentelemetry-distro \
    opentelemetry-exporter-otlp
```

### 3. Node.js Application (`legacy-nodejs-app-dual.yaml`)

**Dual Instrumentation**:
- **Legacy**: `dd-trace/init` require
- **New**: OpenTelemetry auto-instrumentation

**Cómo funciona**:
```yaml
env:
  - name: NODE_OPTIONS
    value: >-
      --require dd-trace/init
      --require /otel-auto-instrumentation/autoinstrumentation.js
```

**Importante**: Orden de `--require` importa:
1. Primero `dd-trace/init`
2. Después OpenTelemetry

## Configuración Común

### Variables de Entorno

**Datadog Legacy**:
```yaml
- name: DD_AGENT_HOST
  valueFrom:
    fieldRef:
      fieldPath: status.hostIP  # Node IP donde corre Datadog agent
- name: DD_TRACE_AGENT_PORT
  value: "8126"
- name: DD_SERVICE
  value: "my-service"
- name: DD_ENV
  value: "production"
- name: DD_VERSION
  value: "v1.0.0"
```

**OpenTelemetry New**:
```yaml
- name: OTEL_EXPORTER_OTLP_ENDPOINT
  value: "http://otel-collector-agent.observability.svc:4317"
- name: OTEL_SERVICE_NAME
  value: "my-service"
- name: OTEL_RESOURCE_ATTRIBUTES
  value: "deployment.environment=production,service.version=v1.0.0"
```

### Recursos

**IMPORTANTE**: Dual instrumentation requiere más recursos:

```yaml
resources:
  limits:
    cpu: 2000m      # ~2x normal
    memory: 2Gi     # ~2x normal
  requests:
    cpu: 400m       # ~1.5x normal
    memory: 768Mi   # ~1.5x normal
```

### Health Checks

Aumentar timeouts debido a overhead:

```yaml
livenessProbe:
  initialDelaySeconds: 90  # vs 60 normal
readinessProbe:
  initialDelaySeconds: 45  # vs 30 normal
```

## Proceso de Migración

### Fase 1: Preparación

1. ✅ Desplegar OpenTelemetry collectors (chapter `infrastructure`)
2. ✅ Validar collectors están recibiendo y exportando a Datadog
3. ✅ Preparar imágenes con ambas librerías (ddtrace + opentelemetry)

### Fase 2: Dual-Write (ESTA FASE)

1. ✅ Desplegar app con dual instrumentation
2. ✅ Monitorear recursos (CPU/memoria pueden subir)
3. ✅ Validar telemetría en Datadog desde ambas fuentes:
   - Service `my-app` (legacy - via dd-trace)
   - Service `my-app` (new - via OTel)

### Fase 3: Validación

Comparar en Datadog:

**Métricas a validar**:
| Métrica | Legacy | OpenTelemetry | Diff Aceptable |
|---------|--------|---------------|----------------|
| Request rate | 1000 req/s | 995 req/s | ±5% |
| P95 latency | 200ms | 205ms | ±10% |
| Error rate | 0.5% | 0.48% | ±0.1% |

**Comandos útiles**:
```bash
# Comparar métricas en Datadog
# Dashboard → APM → Service Comparison
# Filter: service:my-app
# Group by: instrumentation.library.name
```

### Fase 4: Cutover

Una vez validado (típicamente 1-2 semanas):

1. ✅ Remover configuración de Datadog agent
2. ✅ Mantener solo OpenTelemetry
3. ✅ Reducir recursos a nivel normal

**Spell post-migración**:
```yaml
# Usar spell normal (sin dual-write)
# Ver: bookrack/otel-datadog-book/applications/example-java-api.yaml
```

### Fase 5: Cleanup

```bash
# Desinstalar Datadog agents (si ya no se usan)
kubectl delete daemonset datadog-agent -n monitoring

# Actualizar todas las apps a usar solo OpenTelemetry
```

## Comparación de Telemetría

### Dashboard en Datadog

**Crear dashboard de comparación**:

```json
{
  "title": "Migration: Dual-Write Validation",
  "widgets": [
    {
      "definition": {
        "title": "Request Rate: Legacy vs OTel",
        "type": "timeseries",
        "requests": [
          {
            "q": "sum:trace.requests{service:my-app,instrumentation.library.name:dd-trace}.as_count()",
            "display_type": "line",
            "style": {"palette": "dog_classic"}
          },
          {
            "q": "sum:trace.requests{service:my-app,instrumentation.library.name:opentelemetry}.as_count()",
            "display_type": "line",
            "style": {"palette": "warm"}
          }
        ]
      }
    }
  ]
}
```

### Queries útiles

**APM Traces**:
```
# Legacy traces
service:my-app AND @instrumentation.library.name:dd-trace

# OpenTelemetry traces
service:my-app AND @instrumentation.library.name:opentelemetry
```

**Logs**:
```
# Ver si hay errores de instrumentación
service:my-app @log_level:ERROR (otel OR ddtrace)
```

## Troubleshooting

### Conflictos entre agentes

**Síntoma**: App crashea al iniciar, logs muestran:
```
Error: Cannot initialize tracer - already initialized
```

**Causa**: Ambos agentes intentan instrumentar mismo código.

**Solución Java**:
```yaml
# Asegurar que ambos usan diferentes mecanismos
# dd-java-agent: -javaagent
# OpenTelemetry: via operator injection (no conflict)
```

**Solución Python**:
```python
# En código, configurar para coexistir:
from ddtrace import tracer as dd_tracer
from opentelemetry import trace as otel_trace

# Desactivar auto-patch de uno si es necesario
dd_tracer.configure(patch_modules={"flask": False})
```

### Alto uso de memoria

**Síntoma**: Pods reinicios frecuentes, OOMKilled.

**Solución**:
```yaml
resources:
  limits:
    memory: 4Gi  # Duplicar si es necesario
```

O desactivar profiling en uno:
```yaml
env:
  - name: DD_PROFILING_ENABLED
    value: "false"  # Reduce overhead
```

### Métricas no coinciden

**Síntoma**: Legacy muestra 1000 req/s, OpenTelemetry 800 req/s.

**Posibles causas**:
1. Sampling diferente
2. Timing de reporting diferente
3. Health checks excluidos en uno

**Solución**:
```yaml
# Asegurar sampling idéntico
# Legacy
- name: DD_TRACE_SAMPLE_RATE
  value: "1.0"

# OpenTelemetry
- name: OTEL_TRACES_SAMPLER
  value: "always_on"
```

### Latencia duplicada

**Síntoma**: Spans aparecen duplicados en traces.

**Causa**: Ambos agentes creando spans para mismo operation.

**Solución**: Normal durante dual-write. Filtrar en Datadog dashboard:
```
# Ver solo uno
service:my-app AND @instrumentation.library.name:opentelemetry
```

## Métricas de Overhead

**Esperado durante dual-write**:

| Recurso | Sin Instrumentación | Solo Datadog | Solo OTel | Dual-Write |
|---------|---------------------|--------------|-----------|------------|
| CPU | 100m | 150m (+50%) | 140m (+40%) | 250m (+150%) |
| Memory | 256Mi | 384Mi (+50%) | 350Mi (+37%) | 650Mi (+154%) |
| Startup | 10s | 15s (+5s) | 14s (+4s) | 25s (+15s) |

## Duración Recomendada

**Por servicio**:
- ⏱️ **Mínimo**: 1 semana (168 horas de datos)
- ⏱️ **Recomendado**: 2 semanas (captura ciclos semanales)
- ⏱️ **Crítico**: 1 mes (máxima confianza)

**Total proyecto**:
- Si tienes 20 servicios y migras 2/semana → 10 semanas
- Puedes paralelizar (migrar múltiples servicios simultáneamente)

## Checklist de Migración

### Por Servicio

- [ ] App funciona con dual-write en dev
- [ ] Recursos aumentados (CPU +50%, memory +50%)
- [ ] Health checks ajustados (timeouts +50%)
- [ ] Deploy a producción en horario de bajo tráfico
- [ ] Monitorear recursos por 24h
- [ ] Comparar métricas en Datadog por 7 días
- [ ] Validar alertas no falsan por dual telemetría
- [ ] Cutover: remover legacy instrumentation
- [ ] Reducir recursos a normal
- [ ] Monitorear post-cutover por 48h

### Global

- [ ] Documentar proceso y learnings
- [ ] Actualizar runbooks
- [ ] Deprecar Datadog agents (cuando 100% migrado)
- [ ] Celebrar 🎉

## Referencias

- [Datadog Java Agent](https://docs.datadoghq.com/tracing/trace_collection/dd_libraries/java/)
- [Datadog Python (ddtrace)](https://ddtrace.readthedocs.io/)
- [Datadog Node.js (dd-trace)](https://datadoghq.dev/dd-trace-js/)
- [OpenTelemetry Migration](https://opentelemetry.io/docs/migration/)
