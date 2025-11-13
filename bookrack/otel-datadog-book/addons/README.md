# Addons Chapter

Este chapter contiene los addons/operadores necesarios para habilitar la funcionalidad completa de OpenTelemetry.

## Componentes

### 1. OpenTelemetry Operator (`otel-operator.yaml`)

**Propósito**: Gestiona auto-instrumentación de aplicaciones sin cambios de código.

**Features**:
- ✅ CRD `Instrumentation` para configurar auto-instrumentación
- ✅ CRD `OpenTelemetryCollector` para gestionar collectors
- ✅ Admission webhooks para inyectar sidecars
- ✅ Soporte para Java, Python, Node.js, .NET, Go

**Deployment**:
```bash
# Via ArgoCD (automático si librarian está configurado)
# O manual:
kubectl apply -f bookrack/otel-datadog-book/addons/otel-operator.yaml
```

**Verificación**:
```bash
# Check operator está running
kubectl get pods -n opentelemetry-operator-system

# Check CRDs instalados
kubectl get crd | grep opentelemetry

# Deberías ver:
# instrumentations.opentelemetry.io
# opentelemetrycollectors.opentelemetry.io
```

### 2. Cert-Manager (`cert-manager.yaml`)

**Propósito**: Gestiona certificados para webhooks del operator (opcional).

**Nota**: El OpenTelemetry Operator puede auto-generar certificados si cert-manager no está disponible (`autoGenerateCert: true` en config).

**Deployment**:
```bash
kubectl apply -f bookrack/otel-datadog-book/addons/cert-manager.yaml
```

**Verificación**:
```bash
kubectl get pods -n cert-manager
```

## Order de Deployment

1. **cert-manager** (opcional, pero recomendado)
2. **otel-operator** (requiere cert-manager O auto-generate certs)

El `index.yaml` del book define `chapters: [addons, infrastructure, ...]` para asegurar que los addons se desplieguen primero.

## Troubleshooting

### Operator no arranca

```bash
# Ver logs
kubectl logs -n opentelemetry-operator-system deployment/opentelemetry-operator

# Verificar webhooks
kubectl get validatingwebhookconfiguration | grep opentelemetry
kubectl get mutatingwebhookconfiguration | grep opentelemetry
```

### Auto-instrumentación no funciona

```bash
# Verificar Instrumentation CR existe
kubectl get instrumentation -n observability

# Verificar pod tiene annotation
kubectl get pod <pod-name> -o jsonpath='{.metadata.annotations}'

# Buscar: instrumentation.opentelemetry.io/inject-<language>
```

### Webhook errors

Si cert-manager no está disponible, asegurar que `autoGenerateCert: true` en otel-operator config.

## Referencias

- [OpenTelemetry Operator](https://github.com/open-telemetry/opentelemetry-operator)
- [Cert-Manager](https://cert-manager.io/)
- [Auto-Instrumentation](https://opentelemetry.io/docs/kubernetes/operator/automatic/)
