# Microspell

Opinionated Helm chart for microservice deployments. Wraps summon with microservice-specific defaults and integrations.

## Overview

Microspell is a trinket (specialized wrapper chart) that provides best-practice defaults for deploying microservices in kast. It combines summon workload management with automatic infrastructure integration (vault, istio, monitoring).

**Purpose:**
- Deploy microservices with opinionated defaults
- Automatic vault policy and secret management
- Automatic istio service mesh integration
- Built-in monitoring and observability
- Reduce configuration boilerplate

**Chart Name:** `microspell`

**Location:** `charts/trinkets/microspell/`

**Wrapper:** Built on top of summon chart

## Architecture

```
┌─────────────────────────────────────────────────────┐
│ Spell (microspell configuration)                    │
│ - service, secrets, infrastructure                  │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│ Microspell Trinket                                  │
│ - Opinionated defaults                              │
│ - Auto-generate glyphs (vault, istio)              │
│ - Inject monitoring config                          │
└──────────────────────┬──────────────────────────────┘
                       │
        ┌──────────────┴──────────────┐
        │                             │
┌───────▼──────────┐     ┌────────────▼──────────┐
│ Summon Chart     │     │ Glyphs (vault, istio) │
│ - Workload       │     │ - VaultPolicy         │
│ - Service        │     │ - VaultSecret         │
│ - Volumes        │     │ - VirtualService      │
└────────┬─────────┘     └────────────┬──────────┘
         │                            │
         └──────────────┬─────────────┘
                        │
        ┌───────────────▼───────────────┐
        │   Kubernetes Resources        │
        │ - Deployment + Service        │
        │ - Vault Policy + Secrets      │
        │ - Istio VirtualService        │
        └───────────────────────────────┘
```

## Key Differences from Summon

| Feature | Summon | Microspell |
|---------|--------|------------|
| **Infrastructure** | Manual glyphs | Auto-generated |
| **Vault** | Explicit glyph definition | Automatic policy + secrets |
| **Istio** | Explicit VirtualService | Auto-configured routing |
| **Defaults** | Minimal | Opinionated (replicas, resources) |
| **Service** | Manual configuration | Auto-enabled with external routing |
| **Monitoring** | Manual annotations | Auto-configured Prometheus |

**When to use Microspell:**
- Standard microservices following organizational patterns
- Need vault + istio integration
- Want sensible defaults

**When to use Summon:**
- Custom deployment patterns
- Non-microservice workloads (jobs, batch processing)
- Need full control over configuration

## Basic Usage

### Minimal Microservice

```yaml
name: my-service

image:
  repository: my-registry/my-service
  tag: v1.0.0
```

**Auto-generates:**
- Deployment (2 replicas by default)
- Service (external via Istio)
- Vault policy for ServiceAccount
- Istio VirtualService
- Prometheus scraping annotations

### With Secrets

```yaml
name: my-service

image:
  repository: my-registry/my-service
  tag: v1.0.0

secrets:
  database:
    location: vault
    path: chapter
  api-keys:
    location: vault
    path: book
```

**Auto-generates:**
- Vault policy with access to secrets
- VaultSecret resources syncing to K8s
- ServiceAccount for vault auth

## Configuration Reference

### Service

Microspell service configuration extends summon with routing:

```yaml
service:
  enabled: true              # Default: true (auto-enabled)
  external: true             # Expose via Istio (default: false)
  ports:
    - port: 80
      name: http
  prefix: /api/my-service    # URL prefix for routing
  hosts:                     # Custom hostnames
    - api.example.com
  circuitBreaking:           # Istio circuit breaker
    enabled: true
    maxRequestsPerConnection: 10
    consecutive5xxErrors: 5
  retry:                     # Istio retry policy
    attempts: 3
    perTryTimeout: 5s
  timeout: 30s               # Request timeout
```

**Simple external service:**
```yaml
service:
  external: true
  prefix: /api/users
```

**Result:** Accessible at `<gateway-host>/api/users`

### Infrastructure

Automatic infrastructure integration:

```yaml
infrastructure:
  prolicy:
    enabled: true            # Create vault policy (default: true)
    paths:                   # Additional vault paths
      - "database/creds/myapp"
      - "pki/issue/internal"
    capabilities:            # Path capabilities
      - read
      - list

  routing:
    enabled: true            # Create VirtualService (default: true if service.external)
    gateways:                # Istio gateways
      - external-gateway
    corsPolicy:              # CORS configuration
      allowOrigins:
        - regex: ".*"
      allowMethods:
        - GET
        - POST
      allowHeaders:
        - content-type
```

**Minimal (auto-configured):**
```yaml
# No infrastructure config needed
# Vault policy auto-created
# VirtualService auto-created if service.external: true
```

### Secrets

Microspell simplifies secret management:

```yaml
secrets:
  # Vault secret (chapter scope)
  database:
    location: vault
    path: chapter            # chapter | book | absolute
    private: privates        # Path segment (default: publics)
    format: env              # env | yaml | json | plain

  # Vault secret (book scope)
  shared-api-key:
    location: vault
    path: book

  # Create inline secret
  webhook-secret:
    location: create
    type: env                # Secret type
    content: secret-value-123
    contentType: yaml        # yaml | json | plain

  # External secret
  external-config:
    location: external
    name: existing-secret    # Reference existing secret
```

**Auto-generated:**
- Vault policy with read access
- VaultSecret resources
- K8s Secrets

**Secret Usage:**

```yaml
secrets:
  app-config:
    location: vault
    path: chapter
    format: env

# Automatically available in pod as env vars:
# DATABASE_URL, API_KEY, etc.
```

### Workload

Extends summon workload configuration:

```yaml
workload:
  enabled: true
  type: deployment           # deployment | statefulset | job | cronjob
  replicas: 2                # Default: 2 (vs summon: 1)
  autoscaling:
    enabled: true            # Default: false
    minReplicas: 2
    maxReplicas: 10
    targetCPUUtilizationPercentage: 70
```

**Opinionated defaults:**
- `replicas: 2` (high availability)
- Readiness/liveness probes enabled
- Resource requests/limits recommended

### Monitoring

Auto-configured Prometheus integration:

```yaml
monitoring:
  enabled: true              # Default: true
  path: /metrics             # Metrics endpoint
  port: 9090                 # Metrics port (default: service port)
  scrapeInterval: 30s        # Scrape interval
```

**Auto-generates:**
```yaml
annotations:
  prometheus.io/scrape: "true"
  prometheus.io/path: /metrics
  prometheus.io/port: "9090"
```

### Resources

Opinionated resource defaults:

```yaml
resources:
  requests:
    cpu: 100m              # Default: 100m
    memory: 128Mi          # Default: 128Mi
  limits:
    cpu: 500m              # Default: 500m
    memory: 512Mi          # Default: 512Mi
```

**Override:**
```yaml
resources:
  requests:
    cpu: 500m
    memory: 512Mi
  limits:
    cpu: 2000m
    memory: 2Gi
```

## Examples

### Basic Microservice

```yaml
name: user-service

image:
  repository: my-registry/user-service
  tag: v1.2.3

service:
  external: true
  prefix: /api/users
```

**Generates:**
- Deployment (2 replicas)
- Service (ClusterIP)
- ServiceAccount
- Vault policy
- Istio VirtualService at `/api/users`
- Prometheus scraping

### With Database Secrets

```yaml
name: payment-service

image:
  repository: my-registry/payment-service
  tag: v2.0.0

service:
  external: true
  prefix: /api/payments

secrets:
  database:
    location: vault
    path: chapter
    format: env
  stripe-api:
    location: vault
    path: book
    private: secrets

envs:
  SERVICE_NAME: payment-service
  LOG_LEVEL: info
```

**Secrets available as env vars:**
- `DATABASE_URL`
- `DATABASE_PASSWORD`
- `STRIPE_API_KEY`

### Stateful Microservice

```yaml
name: session-store

workload:
  type: statefulset
  replicas: 3

image:
  repository: redis
  tag: "7-alpine"

service:
  enabled: true
  external: false  # Internal service only

volumes:
  data:
    type: pvc
    size: 10Gi
    destinationPath: /data

resources:
  requests:
    cpu: 500m
    memory: 512Mi
  limits:
    cpu: 1000m
    memory: 1Gi
```

### Scheduled Task

```yaml
name: backup-service

workload:
  type: cronjob
  schedule: "0 2 * * *"  # 2 AM daily

image:
  repository: backup-tool
  tag: latest

secrets:
  s3-credentials:
    location: vault
    path: book
    private: privates

volumes:
  data:
    type: pvc
    name: app-data
    destinationPath: /data
  backup:
    type: pvc
    size: 100Gi
    destinationPath: /backup

envs:
  BACKUP_TARGET: s3://my-bucket/backups
```

### Multi-Environment

**Development:**
```yaml
name: api-service

image:
  repository: api-service
  tag: develop

service:
  external: true
  prefix: /api

workload:
  replicas: 1  # Single replica in dev

resources:
  requests:
    cpu: 50m
    memory: 64Mi
```

**Production:**
```yaml
name: api-service

image:
  repository: api-service
  tag: v1.5.0

service:
  external: true
  prefix: /api
  circuitBreaking:
    enabled: true
  retry:
    attempts: 3

workload:
  replicas: 3
  autoscaling:
    enabled: true
    minReplicas: 3
    maxReplicas: 20

resources:
  requests:
    cpu: 500m
    memory: 512Mi
  limits:
    cpu: 2000m
    memory: 2Gi
```

## Integration Patterns

### With Vault

```yaml
name: secure-service

secrets:
  # Database credentials
  database:
    location: vault
    path: chapter
    format: env

  # API keys
  api-keys:
    location: vault
    path: book
    format: env

  # TLS certificates
  tls-cert:
    location: vault
    path: "/pki/issue/internal"
    format: plain

infrastructure:
  prolicy:
    paths:
      - "pki/issue/internal"
    capabilities:
      - create
      - update
```

**Auto-configured:**
- Vault policy with read access to chapter/book secrets
- VaultSecret resources
- ServiceAccount authentication

### With Istio

```yaml
name: frontend-service

service:
  external: true
  prefix: /
  hosts:
    - app.example.com
  corsPolicy:
    allowOrigins:
      - exact: "https://app.example.com"
    allowMethods:
      - GET
      - POST
    allowHeaders:
      - authorization
      - content-type
  retry:
    attempts: 3
    perTryTimeout: 5s
  timeout: 30s
```

**Auto-configured:**
- VirtualService with CORS
- Retry policy
- Timeout configuration

### With Monitoring

```yaml
name: metrics-service

monitoring:
  enabled: true
  path: /metrics
  port: 9090

# Custom metrics
annotations:
  prometheus.io/additional-scrape-configs: |
    - job_name: custom-metrics
      metrics_path: /custom
```

## Best Practices

### Use Path Scoping

```yaml
secrets:
  # Chapter-specific (e.g., dev vs prod)
  database:
    location: vault
    path: chapter

  # Shared across environments
  api-keys:
    location: vault
    path: book
```

### Enable Circuit Breaking for External Services

```yaml
service:
  external: true
  circuitBreaking:
    enabled: true
    consecutive5xxErrors: 5
  retry:
    attempts: 3
```

### Set Resource Limits

```yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi
```

### Use Autoscaling

```yaml
workload:
  replicas: 2
  autoscaling:
    enabled: true
    minReplicas: 2
    maxReplicas: 10
```

### Configure Health Checks

```yaml
# Inherited from summon
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 30

readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 10
```

## Troubleshooting

### Vault Secret Not Syncing

**Check:**

```bash
# Vault policy created
kubectl get policy -n vault <service-name>-policy

# VaultSecret resource
kubectl get vaultsecret -n <namespace> <secret-name>

# Describe VaultSecret
kubectl describe vaultsecret -n <namespace> <secret-name>

# Check vault-operator logs
kubectl logs -n vault-operator deployment/vault-config-operator
```

**Common causes:**
- ServiceAccount not created
- Vault policy missing path
- Vault path doesn't exist

### Istio Routing Not Working

**Check:**

```bash
# VirtualService created
kubectl get virtualservice -n <namespace> <service-name>-vs

# Describe VirtualService
kubectl describe virtualservice -n <namespace> <service-name>-vs

# Check Istio configuration
istioctl analyze -n <namespace>

# Check gateway configuration
kubectl get gateway -n istio-system
```

**Common causes:**
- Gateway not specified in lexicon
- service.external not enabled
- Incorrect prefix or hosts

### Service Not Auto-Enabled

**Check configuration:**

```yaml
# Explicit enable (if needed)
service:
  enabled: true  # Redundant in microspell but allowed
```

**Microspell auto-enables service by default**

## Comparison: Microspell vs Summon

**Same application in both:**

### Summon

```yaml
name: api-service

image:
  repository: api-service
  tag: v1.0.0

workload:
  replicas: 2

service:
  enabled: true
  type: ClusterIP
  port: 80

serviceAccount:
  enabled: true

glyphs:
  vault:
    - type: prolicy
      name: api-service-policy
      serviceAccount: api-service
    - type: secret
      name: database-creds
      format: env
      path: chapter
      keys: [username, password]

  istio:
    - type: virtualService
      name: api-service-vs
      hosts:
        - api.example.com
      http:
        - match:
            - uri:
                prefix: /api
          route:
            - destination:
                host: api-service
                port:
                  number: 80
      gateways:
        - external-gateway

annotations:
  prometheus.io/scrape: "true"
  prometheus.io/port: "80"
```

### Microspell

```yaml
name: api-service

image:
  repository: api-service
  tag: v1.0.0

service:
  external: true
  prefix: /api

secrets:
  database-creds:
    location: vault
    path: chapter
```

**Result:** Same resources, 75% less configuration.

## Related Documentation

- [SUMMON.md](SUMMON.md) - Base workload chart
- [VAULT.md](VAULT.md) - Vault integration details
- [GETTING_STARTED.md](GETTING_STARTED.md) - Tutorial
- [EXAMPLES_INDEX.md](EXAMPLES_INDEX.md) - All examples
- [charts/trinkets/README.md](../charts/trinkets/README.md) - Trinkets overview

## Examples Location

`charts/trinkets/microspell/examples/` - 8 comprehensive examples

**Quick access:**
- Basic: `basic-microservice.yaml`
- Advanced: `advanced-microservice.yaml`
- Vault: `vault-secrets-comprehensive.yaml`
- Volumes: `volumes-comprehensive.yaml`
- StatefulSet: `statefulset-redis-cluster.yaml`
- Job: `job-data-processor.yaml`
- CronJob: `cronjob-backup-scheduler.yaml`
