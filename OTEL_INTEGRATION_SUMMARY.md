# Resumen: Integración OpenTelemetry → Datadog con Kast-System

## ¿Qué se implementó?

Se creó una integración completa de **OpenTelemetry Collector** con **Datadog** siguiendo el patrón GitOps de kast-system.

## Componentes Creados

### 1. Glyph de OpenTelemetry
📁 **Ubicación**: `charts/glyphs/opentelemetry/`

**Estructura**:
```
charts/glyphs/opentelemetry/
├── Chart.yaml                          # Metadata del glyph
├── values.yaml                         # Valores por defecto
├── README.md                           # Documentación de uso
├── templates/
│   ├── _opentelemetry.tpl             # Helpers principales
│   ├── config-map.tpl                 # ConfigMap del collector
│   ├── service.tpl                    # Service para endpoints
│   ├── collector-gateway.tpl          # Deployment (gateway mode)
│   ├── collector-agent.tpl            # DaemonSet (agent mode)
│   ├── collector-sidecar.tpl          # Sidecar container
│   └── instrumentation.tpl            # Auto-instrumentación
└── examples/
    ├── basic-gateway.yaml             # Gateway simple
    ├── basic-agent.yaml               # Agent (DaemonSet)
    ├── app-with-instrumentation.yaml  # App con auto-instrumentación
    └── complete-stack.yaml            # Stack completo
```

### 2. Documentación
📁 **Ubicación**: `docs/OPENTELEMETRY_DATADOG.md`

**Contenido**:
- ✅ Arquitectura propuesta
- ✅ Componentes y configuración
- ✅ Integración con Vault
- ✅ Ejemplos de uso
- ✅ Guía de migración
- ✅ Comparación OTel vs Alloy

## Tipos de Glyph Soportados

### 1. `collectorGateway` (Deployment)
Collector centralizado que recibe telemetría y exporta a Datadog.

```yaml
glyphs:
  opentelemetry:
    - type: collectorGateway
      name: gateway
      replicas: 3
      receivers: [otlp, prometheus, jaeger]
      exporters: [datadog]
      datadogSelector:
        name: datadog-prod
```

### 2. `collectorAgent` (DaemonSet)
Collector por nodo para recolección eficiente.

```yaml
glyphs:
  opentelemetry:
    - type: collectorAgent
      name: agent
      forwardTo: otel-gateway.observability.svc:4317
      receivers: [otlp, prometheus]
```

### 3. `collectorSidecar`
Sidecar container para casos especiales.

### 4. `instrumentation`
Auto-instrumentación para Java, Python, Node.js, .NET, Go.

```yaml
glyphs:
  opentelemetry:
    - type: instrumentation
      name: java-auto
      language: java
      endpoint: http://otel-agent:4317
```

## Patrón de Uso

### Spell 1: Infrastructure (Gateway)
```yaml
# bookrack/production-book/infrastructure/otel-gateway.yaml
name: otel-collector-gateway
namespace: observability

glyphs:
  vault:
    - type: secret
      name: datadog-api-key
      path: "chapter"
      keys: [apiKey]

  opentelemetry:
    - type: collectorGateway
      exporters: [datadog]
      datadogSelector:
        name: datadog-prod
```

### Spell 2: Infrastructure (Agent)
```yaml
# bookrack/production-book/infrastructure/otel-agent.yaml
name: otel-agent
namespace: observability

glyphs:
  opentelemetry:
    - type: collectorAgent
      forwardTo: otel-gateway.observability.svc:4317
```

### Spell 3: Application
```yaml
# bookrack/production-book/applications/my-api.yaml
name: my-api
namespace: applications

env:
  - name: OTEL_EXPORTER_OTLP_ENDPOINT
    value: "http://otel-agent.observability.svc:4317"

glyphs:
  opentelemetry:
    - type: instrumentation
      language: java
```

## Integración con Vault

El glyph se integra con el glyph de Vault para manejar secrets de Datadog:

```yaml
glyphs:
  vault:
    - type: secret
      name: datadog-creds
      path: "chapter"
      keys:
        - apiKey
        - appKey
```

## Lexicon para Datadog

Define configuración de Datadog en el book:

```yaml
appendix:
  lexicon:
    - type: datadog
      name: datadog-prod
      site: datadoghq.com
      vaultSecretPath: "chapter"
      labels:
        environment: production
```

## Arquitectura Recomendada

```
┌─────────────┐
│ Aplicación  │ (con auto-instrumentation o SDK)
└──────┬──────┘
       │ OTLP :4317
       ▼
┌─────────────┐
│ OTel Agent  │ (DaemonSet - por nodo)
│ - Recibe    │
│ - Procesa   │
└──────┬──────┘
       │ OTLP
       ▼
┌─────────────┐
│ OTel Gateway│ (Deployment - centralizado)
│ - Recibe    │
│ - Enriquece │
│ - Exporta   │
└──────┬──────┘
       │ Datadog API
       ▼
┌─────────────┐
│  Datadog    │
└─────────────┘
```

## Ventajas de este Enfoque

1. ✅ **GitOps nativo**: Todo en código, versionado
2. ✅ **Vendor-agnostic**: OpenTelemetry es estándar CNCF
3. ✅ **Reutilizable**: Glyphs compartidos entre aplicaciones
4. ✅ **Seguro**: Secrets manejados por Vault
5. ✅ **Modular**: Collectors independientes por namespace
6. ✅ **Escalable**: Agent + Gateway pattern
7. ✅ **Testeable**: Workflow TDD integrado

## Comparación: OpenTelemetry vs Alloy

| Criterio | OpenTelemetry | Grafana Alloy |
|----------|---------------|---------------|
| **Datadog Export** | ✅ Nativo | ❌ Requiere conversión |
| **Estándar** | ✅ CNCF | ❌ Grafana-specific |
| **Auto-instrument** | ✅ Maduro | ⚠️ Limitado |
| **Backends** | ✅ Múltiples | ⚠️ Principalmente Grafana |
| **Adopción** | ✅ Mayor | ⚠️ Menor |

**Recomendación**: **OpenTelemetry** porque cumple el requerimiento de Datadog y es futuro-proof.

## Próximos Pasos

### Para Testing

1. **Desplegar collector gateway**:
   ```bash
   # Aplicar spell de gateway
   kubectl apply -f bookrack/production-book/infrastructure/otel-gateway.yaml
   ```

2. **Desplegar collector agent**:
   ```bash
   # Aplicar spell de agent
   kubectl apply -f bookrack/production-book/infrastructure/otel-agent.yaml
   ```

3. **Instrumentar aplicación**:
   ```yaml
   # Agregar a spell de app
   podAnnotations:
     instrumentation.opentelemetry.io/inject-java: "java-auto"
   ```

4. **Validar en Datadog**:
   - Ver métricas en Datadog dashboard
   - Verificar trazas distribuidas
   - Revisar logs

### Para Producción

1. ✅ **Review de código** (este PR)
2. ⬜ **Testing en cluster de desarrollo**
   - Desplegar collectors
   - Validar export a Datadog
   - Métricas de performance
3. ⬜ **Migración gradual**
   - Por servicio (C#, Java, JS)
   - Dual-write temporal
   - Validación de métricas
4. ⬜ **Deprecar implementación antigua**
   - Una vez 100% migrado
   - Remover agentes legacy
5. ⬜ **Documentación adicional**
   - Runbooks de troubleshooting
   - Best practices por lenguaje

## Archivos Clave

| Archivo | Descripción |
|--------|-------------|
| `docs/OPENTELEMETRY_DATADOG.md` | Diseño y arquitectura completa |
| `charts/glyphs/opentelemetry/README.md` | Guía de uso del glyph |
| `charts/glyphs/opentelemetry/examples/` | 4 ejemplos de uso |
| `charts/glyphs/opentelemetry/templates/` | Templates Helm |

## Comandos Útiles

### Testing local del glyph
```bash
# Validar sintaxis
make glyphs opentelemetry

# TDD workflow
make create-example CHART=opentelemetry EXAMPLE=basic-gateway
make tdd-red
# ... implementar
make tdd-green
```

### Deploy real
```bash
# Via ArgoCD (recomendado)
# El librarian generará las Applications automáticamente

# O manual (testing)
helm template otel-gateway charts/glyphs/opentelemetry \
  -f bookrack/production-book/infrastructure/otel-gateway.yaml
```

## Preguntas & Respuestas

**Q: ¿Por qué OpenTelemetry y no Alloy?**
A: OpenTelemetry tiene soporte nativo para Datadog y es vendor-agnostic (estándar CNCF).

**Q: ¿Cómo se manejan los secrets de Datadog?**
A: A través del glyph de Vault, siguiendo el patrón existente de kast-system.

**Q: ¿Qué pasa con la implementación actual?**
A: Se puede hacer migración gradual con dual-write, validar, y deprecar la antigua.

**Q: ¿Necesito cambiar código de aplicaciones?**
A: No si usas auto-instrumentation. Solo agregar annotation al pod.

**Q: ¿Funciona con C#, Java, JavaScript?**
A: Sí, OpenTelemetry soporta todos esos lenguajes con auto-instrumentation o SDK.

## Contacto

Para dudas o feedback:
- **GitHub Issues**: https://github.com/kast-spells/kast-system/issues
- **Branch**: `claude/otel-datadog-integration-01SKvMfXFJc9puCwkPnt39Ns`
- **Base**: `feature/coding-standards`
