# OpenTelemetry → Datadog Book

**Complete implementation guide** for deploying OpenTelemetry Collector with Datadog integration using kast-system patterns.

## 📚 Book Overview

Este book contiene todo lo necesario para desplegar un stack completo de observabilidad basado en OpenTelemetry con export a Datadog:

- ✅ **Addons**: OpenTelemetry Operator, Cert-Manager
- ✅ **Infrastructure**: Collectors (Gateway + Agents), Auto-Instrumentation
- ✅ **Applications**: Apps instrumentadas (Java, Python, Node.js)
- ✅ **Migration**: Ejemplos de dual-write para migración gradual

## 🗂️ Estructura del Book

```
otel-datadog-book/
├── index.yaml                      # Book configuration
├── _lexicon/                       # Infrastructure registry
│   └── datadog.yaml               # Datadog backends config
├── addons/                        # Chapter 1: Prerequisites
│   ├── README.md
│   ├── cert-manager.yaml         # Certificate management
│   └── otel-operator.yaml        # OpenTelemetry Operator
├── infrastructure/                # Chapter 2: Core collectors
│   ├── README.md
│   ├── otel-gateway.yaml         # Centralized collector
│   ├── otel-agent.yaml           # Per-node collector
│   ├── otel-instrumentation-java.yaml
│   ├── otel-instrumentation-python.yaml
│   └── otel-instrumentation-nodejs.yaml
├── applications/                  # Chapter 3: Instrumented apps
│   ├── README.md
│   ├── example-java-api.yaml     # Java with auto-instrumentation
│   ├── example-python-api.yaml   # Python with auto-instrumentation
│   └── example-nodejs-api.yaml   # Node.js with auto-instrumentation
└── migration-dual-write/          # Chapter 4: Migration strategy
    ├── README.md
    ├── legacy-java-app-dual.yaml
    ├── legacy-python-app-dual.yaml
    └── legacy-nodejs-app-dual.yaml
```

## 🎯 Arquitectura

```
┌─────────────────────────────────────────────────────────────────┐
│                     APPLICATIONS (Chapter 3)                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │  Java API    │  │ Python API   │  │ Node.js API  │          │
│  │ + OTel SDK   │  │ + OTel SDK   │  │ + OTel SDK   │          │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘          │
│         │                  │                  │                  │
│         │ OTLP :4317       │ OTLP :4317      │ OTLP :4317      │
│         ▼                  ▼                  ▼                  │
│  ┌────────────────────────────────────────────────────┐         │
│  │  OpenTelemetry Collector Agent (DaemonSet)        │         │
│  │  - Receives: OTLP, Prometheus                     │◄────┐   │
│  │  - Processes: batch, memory limiter                │     │   │
│  │  - Forwards: to Gateway                            │     │   │
│  └────────────────────┬───────────────────────────────┘     │   │
│                       │ OTLP :4317                          │   │
└───────────────────────┼─────────────────────────────────────┼───┘
                        │                                     │
              ┌─────────▼─────────────────────────┐          │
              │  INFRASTRUCTURE (Chapter 2)        │          │
              │  ┌─────────────────────────────┐  │          │
              │  │ OTel Collector Gateway      │  │          │
              │  │ - Receives: from agents     │  │          │
              │  │ - Processes: enrich, batch  │  │          │
              │  │ - Exports: Datadog API      │  │          │
              │  └────────────┬────────────────┘  │          │
              └───────────────┼───────────────────┘          │
                              │ Datadog API                  │
                              ▼                              │
                       ┌─────────────┐                       │
                       │  Datadog    │                       │
                       │  (SaaS)     │                       │
                       └─────────────┘                       │
                                                             │
      ┌──────────────────────────────────────────────────────┘
      │  ADDONS (Chapter 1)
      │  ┌───────────────────────────────┐
      │  │ OpenTelemetry Operator        │
      │  │ - Auto-Instrumentation CRDs   │
      │  │ - Webhook injection           │
      │  └───────────────────────────────┘
      └─────────────────────────────────────
```

## 🚀 Quick Start

### 1. Prerequisites

```bash
# Verificar tienes acceso al cluster
kubectl cluster-info

# Verificar namespace existe (o se creará automáticamente)
kubectl get ns observability || kubectl create ns observability
```

### 2. Configure Vault Secrets

Los Datadog API keys se manejan via Vault:

```bash
# En Vault, crear secrets:
vault kv put secret/observability/datadog/api-key \
  apiKey=dd_api_key_here \
  appKey=dd_app_key_here
```

### 3. Deploy via ArgoCD

Si usas librarian (recomendado):

```bash
# El librarian lee bookrack/ y genera ArgoCD Applications
# Los spells se desplegarán en orden:
# 1. addons
# 2. infrastructure
# 3. applications
# 4. migration-dual-write (solo si lo necesitas)
```

O deploy manual:

```bash
# Chapter 1: Addons
kubectl apply -f bookrack/otel-datadog-book/addons/

# Esperar que operator esté ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=opentelemetry-operator \
  -n opentelemetry-operator-system --timeout=300s

# Chapter 2: Infrastructure
kubectl apply -f bookrack/otel-datadog-book/infrastructure/

# Esperar que collectors estén ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/component=opentelemetry-collector \
  -n observability --timeout=300s

# Chapter 3: Applications (tus apps)
kubectl apply -f bookrack/otel-datadog-book/applications/
```

### 4. Verificar Deployment

```bash
# Verificar addons
kubectl get pods -n opentelemetry-operator-system
kubectl get crd | grep opentelemetry

# Verificar collectors
kubectl get pods -n observability
kubectl get svc -n observability

# Verificar instrumentation CRs
kubectl get instrumentation -n observability

# Test telemetría
kubectl port-forward -n observability svc/otel-collector-gateway 4317:4317
# Enviar test traces con telemetrygen
```

## 📖 Chapters Detallados

### Chapter 1: Addons

**Propósito**: Instalar prerequisitos necesarios.

**Componentes**:
- `otel-operator.yaml`: OpenTelemetry Operator (auto-instrumentation)
- `cert-manager.yaml`: Certificate management (webhooks)

**Lectura**: [addons/README.md](./addons/README.md)

### Chapter 2: Infrastructure

**Propósito**: Desplegar collectors y configuraciones de auto-instrumentación.

**Componentes**:
- `otel-gateway.yaml`: Collector centralizado (Deployment, 3 replicas)
- `otel-agent.yaml`: Collector per-node (DaemonSet)
- `otel-instrumentation-*.yaml`: Auto-instrumentation para Java/Python/Node.js

**Arquitectura**:
- Gateway: Recibe de agents, exporta a Datadog
- Agent: Recibe de pods locales, forwardea a gateway
- Instrumentation: CRs para habilitar auto-instrumentation

**Lectura**: [infrastructure/README.md](./infrastructure/README.md)

### Chapter 3: Applications

**Propósito**: Ejemplos de aplicaciones instrumentadas.

**Componentes**:
- `example-java-api.yaml`: Spring Boot con auto-instrumentation
- `example-python-api.yaml`: FastAPI/Flask con auto-instrumentation
- `example-nodejs-api.yaml`: Express con auto-instrumentation

**Uso**:
```yaml
# Patrón común para todas
podAnnotations:
  instrumentation.opentelemetry.io/inject-<language>: "<instrumentation-name>"

env:
  - name: OTEL_EXPORTER_OTLP_ENDPOINT
    value: "http://otel-collector-agent.observability.svc:4317"
  - name: OTEL_SERVICE_NAME
    value: "my-service"
```

**Lectura**: [applications/README.md](./applications/README.md)

### Chapter 4: Migration - Dual Write

**Propósito**: Migración gradual desde Datadog Agent nativo a OpenTelemetry.

**Estrategia**: Dual-write (enviar a ambos simultáneamente).

**Componentes**:
- `legacy-java-app-dual.yaml`: Java con dd-java-agent + OTel
- `legacy-python-app-dual.yaml`: Python con ddtrace + OTel
- `legacy-nodejs-app-dual.yaml`: Node.js con dd-trace + OTel

**Trade-offs**:
- ⚠️ Más recursos (CPU/memory +50-100%)
- ⚠️ Startup time más largo
- ✅ Validación lado a lado
- ✅ Rollback fácil

**Proceso**:
1. Deploy con dual-write
2. Validar métricas por 1-2 semanas
3. Cutover: remover legacy agent
4. Cleanup: reducir recursos

**Lectura**: [migration-dual-write/README.md](./migration-dual-write/README.md)

## 🔑 Conceptos Clave

### Lexicon

Define infraestructura disponible (`_lexicon/datadog.yaml`):

```yaml
lexicon:
  - type: datadog
    name: datadog-prod
    site: datadoghq.com
    vaultSecretPath: "chapter"
    apiKeySecret:
      vaultPath: "/observability/datadog/api-key"
      vaultKey: apiKey
    labels:
      environment: production
      default: book
```

Los glyphs pueden referenciar via selector:

```yaml
glyphs:
  opentelemetry:
    - type: collectorGateway
      datadogSelector:
        name: datadog-prod
```

### Glyphs

Templates reutilizables que generan recursos K8s.

**Glyph de OpenTelemetry**:
```yaml
glyphs:
  opentelemetry:
    - type: collectorGateway     # Deployment
    - type: collectorAgent       # DaemonSet
    - type: instrumentation      # Auto-instrumentation CR
```

**Glyph de Vault** (para secrets):
```yaml
glyphs:
  vault:
    - type: secret
      name: datadog-api-key
      path: "chapter"
      keys: [apiKey, appKey]
```

### Auto-Instrumentation

Inyección automática de OpenTelemetry SDK sin cambios de código.

**Habilitado via**:
1. Instrumentation CR (chapter infrastructure)
2. Annotation en pod (chapter applications)

```yaml
# 1. Crear Instrumentation
glyphs:
  opentelemetry:
    - type: instrumentation
      name: java-auto
      language: java

# 2. Anotar pod
podAnnotations:
  instrumentation.opentelemetry.io/inject-java: "java-auto"
```

## 🔧 Configuration

### Sampling

**Development** (capturar todo):
```yaml
env:
  - name: OTEL_TRACES_SAMPLER
    value: "always_on"
```

**Production** (reducir volumen):
```yaml
env:
  - name: OTEL_TRACES_SAMPLER
    value: "parentbased_traceidratio"
  - name: OTEL_TRACES_SAMPLER_ARG
    value: "0.1"  # Sample 10%
```

### Resources

**Gateway** (high throughput):
```yaml
resources:
  requests: {cpu: 500m, memory: 1Gi}
  limits: {cpu: 2000m, memory: 4Gi}
autoscaling:
  minReplicas: 2
  maxReplicas: 10
```

**Agent** (per-node):
```yaml
resources:
  requests: {cpu: 100m, memory: 256Mi}
  limits: {cpu: 500m, memory: 1Gi}
```

### Batch Configuration

**Gateway** (optimizado para throughput):
```yaml
batchTimeout: "10s"
batchSize: 2048
batchMaxSize: 4096
```

**Agent** (optimizado para latencia):
```yaml
batchTimeout: "5s"
batchSize: 512
batchMaxSize: 1024
```

## 📊 Monitoring

### Métricas de Collectors

Los collectors exponen métricas en `:8888/metrics`:

```bash
# Port-forward
kubectl port-forward -n observability svc/otel-collector-gateway 8888:8888

# Métricas clave
curl http://localhost:8888/metrics | grep -E \
  'otelcol_receiver_accepted_spans|otelcol_exporter_sent_spans|otelcol_processor_refused_spans'
```

### Datadog Dashboard

Métricas disponibles en Datadog:

- **APM → Services**: Ver services instrumentados
- **Infrastructure → Containers**: Ver collectors running
- **Metrics Explorer**: Buscar `otelcol.*`

### Alertas Recomendadas

```yaml
# Gateway no enviando a Datadog
otelcol_exporter_send_failed_spans{exporter="datadog"} > 100

# Agent perdiendo datos
otelcol_receiver_refused_spans > 50

# High memory usage
container_memory_usage_bytes{pod=~"otel-collector.*"} > 3Gi
```

## 🐛 Troubleshooting

### Collector no arranca

```bash
# Ver logs
kubectl logs -n observability deployment/otel-collector-gateway

# Verificar configmap
kubectl get configmap -n observability -o yaml | grep -A 50 collector-config

# Verificar secrets
kubectl get secret -n observability datadog-api-key -o yaml
```

### Telemetría no llega a Datadog

```bash
# Verificar conectividad
kubectl exec -n observability deployment/otel-collector-gateway -- \
  curl -v https://api.datadoghq.com/api/v1/validate

# Verificar API key válido
kubectl exec -n observability deployment/otel-collector-gateway -- \
  env | grep DD_API_KEY

# Ver logs de export
kubectl logs -n observability deployment/otel-collector-gateway | grep datadog
```

### Auto-instrumentación no funciona

```bash
# Verificar operator running
kubectl get pods -n opentelemetry-operator-system

# Verificar Instrumentation CR existe
kubectl get instrumentation -n observability

# Verificar annotation en pod
kubectl get pod <pod> -n applications -o jsonpath='{.metadata.annotations}' | grep instrumentation

# Ver logs de operator
kubectl logs -n opentelemetry-operator-system -l app.kubernetes.io/name=opentelemetry-operator
```

### Apps con alto uso de memoria

**Durante dual-write**:
```yaml
# Aumentar resources
resources:
  limits:
    memory: 2Gi  # 2x normal
```

**Post-migración**:
```yaml
# Desactivar profiling si sigue alto
env:
  - name: OTEL_INSTRUMENTATION_PROFILING_ENABLED
    value: "false"
```

## 📈 Performance

### Throughput Esperado

**Gateway** (3 replicas):
- 50,000 spans/s
- 20,000 metrics/s
- 10,000 logs/s

**Agent** (per-node):
- 10,000 spans/s
- 5,000 metrics/s

### Latencia

- P50: <5ms (overhead instrumentation)
- P95: <15ms
- P99: <30ms

### Overhead de Recursos

| Componente | CPU | Memory |
|------------|-----|--------|
| Gateway (per replica) | 500m | 1Gi |
| Agent (per node) | 100m | 256Mi |
| Instrumentation (per pod) | +20m | +64Mi |

## 🔐 Security

### RBAC

Collectors necesitan permisos K8s:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: otel-collector
rules:
  - apiGroups: [""]
    resources: ["pods", "nodes", "namespaces"]
    verbs: ["get", "list", "watch"]
```

### Secrets

Datadog API keys vía Vault:

```yaml
glyphs:
  vault:
    - type: secret
      name: datadog-api-key
      path: "chapter"
      keys: [apiKey, appKey]
```

### Network Policies

Limitar acceso a collectors:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: otel-collector-gateway
spec:
  podSelector:
    matchLabels:
      app: otel-collector-gateway
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              name: observability
      ports:
        - protocol: TCP
          port: 4317
```

## 🎓 Best Practices

1. ✅ **Usar Agent + Gateway**: Más escalable que gateway solo
2. ✅ **Sampling en producción**: 10-20% suficiente para mayoría de casos
3. ✅ **Resource attributes consistentes**: Definir en book defaults
4. ✅ **Monitorear collectors**: Alertas en métricas de collectors
5. ✅ **Dual-write durante migración**: Validar antes de cutover
6. ✅ **Autoscaling en gateway**: HPA configurado por defecto
7. ✅ **Pod anti-affinity**: Gateway distribuido entre nodos

## 📚 Referencias

### Documentación Externa
- [OpenTelemetry Docs](https://opentelemetry.io/docs/)
- [Datadog + OpenTelemetry](https://docs.datadoghq.com/opentelemetry/)
- [OTel Collector](https://opentelemetry.io/docs/collector/)
- [OTel Operator](https://github.com/open-telemetry/opentelemetry-operator)

### Documentación kast-system
- [OPENTELEMETRY_DATADOG.md](../../docs/OPENTELEMETRY_DATADOG.md): Diseño completo
- [Glyph OpenTelemetry](../../charts/glyphs/opentelemetry/README.md): Documentación del glyph
- [GLYPHS.md](../../docs/GLYPHS.md): Sistema de glyphs
- [BOOKRACK.md](../../docs/BOOKRACK.md): Sistema de books

## 🤝 Contributing

Para reportar issues o mejoras:
- GitHub Issues: https://github.com/kast-spells/kast-system/issues

## 📄 License

GNU GPL v3 - Ver LICENSE file para detalles.

---

## 🎯 Next Steps

### Para empezar:
1. ✅ Leer [addons/README.md](./addons/README.md)
2. ✅ Leer [infrastructure/README.md](./infrastructure/README.md)
3. ✅ Deploy chapter por chapter
4. ✅ Validar telemetría en Datadog

### Para producción:
1. ✅ Ajustar resources según tu load
2. ✅ Configurar sampling apropiado
3. ✅ Configurar alertas en Datadog
4. ✅ Documentar runbooks

### Para migración:
1. ✅ Leer [migration-dual-write/README.md](./migration-dual-write/README.md)
2. ✅ Deploy 1 servicio con dual-write
3. ✅ Validar por 1-2 semanas
4. ✅ Migrar resto de servicios gradualmente

**¡Happy Observing! 🔭**
