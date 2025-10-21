# Summon

Base Helm chart for Kubernetes workload deployments in kast-system.

## Overview

Summon is the fundamental chart for deploying workloads (Deployments, StatefulSets, Jobs, CronJobs) in kast. It provides opinionated defaults while remaining flexible for different deployment patterns.

**Purpose:**
- Deploy containers to Kubernetes
- Manage workload configuration (replicas, resources, volumes)
- Create supporting resources (Services, ConfigMaps, Secrets)
- Enable autoscaling, probes, and lifecycle management

**Chart Name:** `summon`

**Location:** `charts/summon/`

**Default Trinket:** Used when spell has no `chart` or `path` specified

## Architecture

```
┌─────────────────────────────────────────────────────┐
│ Spell YAML (values)                                 │
│ - image, service, volumes, envs                     │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│ Summon Chart                                        │
│ - Generates K8s workload resources                  │
│ - Applies opinionated defaults                      │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│ Kubernetes Resources                                │
│ - Deployment/StatefulSet/Job/CronJob               │
│ - Service, ServiceAccount                           │
│ - ConfigMaps, PersistentVolumeClaims                │
│ - HorizontalPodAutoscaler                           │
└─────────────────────────────────────────────────────┘
```

## Core Concepts

### Workload Types

Summon supports 4 workload types:

| Type | Use Case | Generated Resource |
|------|----------|-------------------|
| `deployment` | Stateless applications | Deployment |
| `statefulset` | Stateful applications | StatefulSet |
| `job` | One-time tasks | Job |
| `cronjob` | Scheduled tasks | CronJob |

**Default:** `deployment`

**Selection:**

```yaml
workload:
  type: deployment  # or statefulset, job, cronjob
```

### Resource Generation

**Always Generated:**
- Workload (Deployment/StatefulSet/Job/CronJob)
- ServiceAccount (if `serviceAccount.enabled: true`)

**Conditionally Generated:**
- Service (if `service.enabled: true`)
- PersistentVolumeClaims (if `volumes.*.type: pvc`)
- ConfigMaps (if `configMaps.*` defined)
- HorizontalPodAutoscaler (if `autoscaling.enabled: true`)

## Basic Usage

### Minimal Deployment

```yaml
name: my-app
image:
  repository: nginx
  tag: alpine
service:
  enabled: true
```

**Generates:**
- Deployment with 1 replica
- Service (ClusterIP) on port 80
- ServiceAccount

### Production Deployment

```yaml
name: my-app
image:
  repository: my-registry/my-app
  tag: v1.2.3
  pullPolicy: Always

workload:
  replicas: 3

service:
  enabled: true
  type: ClusterIP
  ports:
    - port: 80
      name: http

resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi

autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
```

**Generates:**
- Deployment with 3 replicas (autoscaled 2-10)
- Service with named port
- HorizontalPodAutoscaler
- Resource limits/requests

## Configuration Reference

### Image

```yaml
image:
  repository: nginx           # Required: Image repository
  name: myapp                # Optional: Image name (alternative to repository)
  tag: latest                # Optional: Image tag (default: latest)
  pullPolicy: IfNotPresent   # Optional: Pull policy
  imagePullSecrets:          # Optional: Image pull secrets
    - name: regcred
```

**Full image resolution:**
- `repository` alone: `nginx:latest`
- `repository` + `tag`: `nginx:alpine`
- `name` + `tag`: `<registry>/<name>:tag` (registry from defaults)

### Workload

```yaml
workload:
  enabled: true               # Enable workload (default: true)
  type: deployment           # deployment | statefulset | job | cronjob
  replicas: 1                # Number of replicas (default: 1)
  restartPolicy: Always      # Pod restart policy (for jobs)
  backoffLimit: 3            # Job retry limit
```

**Deployment:**
```yaml
workload:
  type: deployment
  replicas: 3
```

**StatefulSet:**
```yaml
workload:
  type: statefulset
  replicas: 3
```

**Job:**
```yaml
workload:
  type: job
  restartPolicy: OnFailure
  backoffLimit: 3
```

**CronJob:**
```yaml
workload:
  type: cronjob
  schedule: "0 2 * * *"      # Cron schedule
  concurrencyPolicy: Forbid  # Allow | Forbid | Replace
```

### Service

```yaml
service:
  enabled: true               # Create service (default: false)
  type: ClusterIP            # ClusterIP | LoadBalancer | NodePort
  ports:                     # Port configuration
    - port: 80               # Service port
      targetPort: 8080       # Container port (default: same as port)
      protocol: TCP          # Protocol (default: TCP)
      name: http             # Port name
  annotations:               # Service annotations
    service.beta.kubernetes.io/aws-load-balancer-type: nlb
  labels:                    # Service labels
    monitoring: enabled
```

**Simple service:**
```yaml
service:
  enabled: true
  port: 80
```

**Multiple ports:**
```yaml
service:
  enabled: true
  ports:
    - port: 80
      name: http
    - port: 8080
      name: admin
    - port: 9090
      name: metrics
```

### ServiceAccount

```yaml
serviceAccount:
  enabled: true               # Create ServiceAccount (default: false)
  name: custom-sa            # Override name
  annotations:               # ServiceAccount annotations
    eks.amazonaws.com/role-arn: arn:aws:iam::123:role/my-role
```

**Used for:**
- Vault authentication
- AWS IAM roles (IRSA)
- GCP Workload Identity
- RBAC bindings

### Environment Variables

```yaml
envs:
  # Simple key-value
  ENVIRONMENT: production
  LOG_LEVEL: info

  # From secret
  DATABASE_PASSWORD:
    type: secret
    name: db-credentials
    key: password

  # From configmap
  APP_CONFIG:
    type: configMap
    name: app-config
    key: config.json
```

**envFrom (entire secret/configmap):**
```yaml
envsFrom:
  - secretRef:
      name: app-secrets
  - configMapRef:
      name: app-config
```

### Resources

```yaml
resources:
  requests:
    cpu: 100m              # Minimum CPU
    memory: 128Mi          # Minimum memory
  limits:
    cpu: 500m              # Maximum CPU
    memory: 512Mi          # Maximum memory
```

**Best practices:**
- Always set requests (scheduling)
- Set limits to prevent resource exhaustion
- requests < limits

### Volumes

Summon supports multiple volume types:

#### PersistentVolumeClaim

```yaml
volumes:
  data:
    type: pvc
    size: 10Gi
    storageClassName: fast-ssd
    accessModes:
      - ReadWriteOnce
    destinationPath: /app/data
```

**Generates:** PVC + volumeMount

#### ConfigMap

```yaml
volumes:
  config:
    type: configMap
    name: app-config          # Existing ConfigMap
    destinationPath: /etc/config
    subPath: config.yaml      # Optional: Mount specific file
```

#### Secret

```yaml
volumes:
  certs:
    type: secret
    name: tls-certs
    destinationPath: /etc/tls
```

#### EmptyDir

```yaml
volumes:
  tmp:
    type: emptyDir
    destinationPath: /tmp
    sizeLimit: 1Gi
```

#### HostPath

```yaml
volumes:
  docker:
    type: hostPath
    path: /var/run/docker.sock
    destinationPath: /var/run/docker.sock
```

**Multiple volumes:**
```yaml
volumes:
  data:
    type: pvc
    size: 20Gi
    destinationPath: /app/data
  logs:
    type: pvc
    size: 10Gi
    destinationPath: /app/logs
  config:
    type: configMap
    name: app-config
    destinationPath: /etc/config
  tmp:
    type: emptyDir
    destinationPath: /tmp
```

### ConfigMaps

Create ConfigMaps from content:

```yaml
configMaps:
  app-config:
    location: create         # Create new ConfigMap
    contentType: file        # file | env
    mountPath: /etc/config   # Mount location
    name: config.yaml        # File name
    content: |               # File content
      server:
        port: 8080
        host: 0.0.0.0
```

**Content types:**

**File:**
```yaml
configMaps:
  nginx-conf:
    contentType: file
    mountPath: /etc/nginx
    name: nginx.conf
    content: |
      server {
        listen 80;
        server_name localhost;
      }
```

**Environment:**
```yaml
configMaps:
  app-env:
    contentType: env
    content:
      DATABASE_URL: postgres://localhost/mydb
      REDIS_URL: redis://localhost:6379
```

### Autoscaling

```yaml
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
  targetMemoryUtilizationPercentage: 80  # Optional
```

**Generates:** HorizontalPodAutoscaler

**Requirements:**
- Metrics server installed
- Resource requests defined

### Probes

```yaml
# Liveness probe
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10

# Readiness probe
readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 5

# Startup probe
startupProbe:
  httpGet:
    path: /startup
    port: 8080
  failureThreshold: 30
  periodSeconds: 10
```

**Probe types:**

**HTTP:**
```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8080
    scheme: HTTP
```

**TCP:**
```yaml
livenessProbe:
  tcpSocket:
    port: 3306
```

**Exec:**
```yaml
livenessProbe:
  exec:
    command:
      - cat
      - /tmp/healthy
```

### Command & Args

```yaml
command:
  - /bin/sh
  - -c

args:
  - |
    echo "Starting application..."
    exec /app/server
```

**Override entrypoint:**
```yaml
command: ["/custom-entrypoint.sh"]
args: ["--config", "/etc/config.yaml"]
```

### Annotations & Labels

```yaml
# Pod annotations
annotations:
  prometheus.io/scrape: "true"
  prometheus.io/port: "9090"

# Pod labels
labels:
  team: platform
  environment: production
```

**Common annotations:**
- Prometheus scraping
- Istio configuration
- Config checksums (auto-restart)

### Security Context

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 2000
  capabilities:
    drop:
      - ALL
```

### Node Selection

```yaml
nodeSelector:
  kubernetes.io/os: linux
  node-type: compute

tolerations:
  - key: "dedicated"
    operator: "Equal"
    value: "apps"
    effect: "NoSchedule"

affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
        - matchExpressions:
            - key: zone
              operator: In
              values:
                - us-west-1a
```

## Examples

### Simple Web Application

```yaml
name: web-app
image:
  repository: nginx
  tag: alpine

service:
  enabled: true
  port: 80

envs:
  ENVIRONMENT: production
```

### Stateful Database

```yaml
name: postgres
workload:
  type: statefulset
  replicas: 3

image:
  repository: postgres
  tag: "14"

service:
  enabled: true
  port: 5432

volumes:
  data:
    type: pvc
    size: 100Gi
    destinationPath: /var/lib/postgresql/data

envs:
  POSTGRES_PASSWORD:
    type: secret
    name: postgres-creds
    key: password
```

### Scheduled Backup Job

```yaml
name: backup-job
workload:
  type: cronjob
  schedule: "0 2 * * *"  # 2 AM daily

image:
  repository: backup-tool
  tag: latest

command: ["/backup.sh"]

volumes:
  backup-storage:
    type: pvc
    size: 500Gi
    destinationPath: /backups

envs:
  BACKUP_TARGET: s3://my-bucket/backups
```

### Data Processing Job

```yaml
name: data-processor
workload:
  type: job
  restartPolicy: OnFailure
  backoffLimit: 3

image:
  repository: data-processor
  tag: v1.0.0

resources:
  limits:
    cpu: 4
    memory: 8Gi
  requests:
    cpu: 2
    memory: 4Gi

volumes:
  input:
    type: pvc
    name: input-data
    destinationPath: /input
  output:
    type: pvc
    name: output-data
    destinationPath: /output
```

## Integration Patterns

### With Vault (Secrets)

```yaml
name: app
image:
  repository: myapp

# Glyphs create vault policy and secret
glyphs:
  vault:
    - type: prolicy
      name: app-policy
      serviceAccount: app
    - type: secret
      name: app-secret
      format: env
      keys: [api_key, database_url]

# ServiceAccount for vault auth
serviceAccount:
  enabled: true
```

**Result:** VaultSecret synced to K8s Secret, mounted as env vars

### With Istio (Service Mesh)

```yaml
name: api-service
image:
  repository: api

service:
  enabled: true
  port: 8080

# Istio routing
glyphs:
  istio:
    - type: virtualService
      name: api-vs
      hosts:
        - api.example.com
      http:
        - route:
            - destination:
                host: api-service
                port:
                  number: 8080
```

**Result:** Istio VirtualService routes traffic to service

### With External Charts (Runes)

```yaml
name: web-app
image:
  repository: webapp

# Deploy database alongside
runes:
  - name: postgresql
    repository: https://charts.bitnami.com/bitnami
    chart: postgresql
    revision: 12.8.0
    values:
      auth:
        database: webapp_db

envs:
  DATABASE_HOST: postgresql
```

**Result:** Multi-source Application (webapp + postgresql)

## Testing

```bash
# Test single example
make test CHART=summon EXAMPLE=basic-deployment

# Test all summon examples
make test CHART=summon

# Render specific example
helm template test charts/summon \
  -f charts/summon/examples/basic-deployment.yaml

# Debug rendering
helm template test charts/summon \
  -f charts/summon/examples/complex-production.yaml \
  --debug
```

## Best Practices

### Always Set Resource Requests

```yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi
```

**Reason:** Enables proper scheduling and autoscaling

### Use Named Ports

```yaml
service:
  ports:
    - port: 80
      name: http      # Named port
    - port: 8080
      name: admin
```

**Reason:** Service mesh compatibility, clarity

### Enable ServiceAccount for Vault

```yaml
serviceAccount:
  enabled: true

glyphs:
  vault:
    - type: prolicy
      serviceAccount: <app-name>
```

**Reason:** Vault authentication requires ServiceAccount

### Pin Image Tags

```yaml
# Good
image:
  repository: myapp
  tag: v1.2.3

# Avoid
image:
  repository: myapp
  tag: latest
```

**Reason:** Reproducible deployments

### Configure Probes

```yaml
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

**Reason:** Automatic restart on failure, traffic routing

## Troubleshooting

### Pod Not Starting

**Check:**

```bash
# Pod status
kubectl get pods -n <namespace>

# Pod events
kubectl describe pod -n <namespace> <pod-name>

# Pod logs
kubectl logs -n <namespace> <pod-name>
```

**Common causes:**
- Image pull failure (check `imagePullSecrets`)
- Resource limits too low (OOMKilled)
- Liveness probe failing too quickly
- Volume mount issues

### Service Not Accessible

**Check:**

```bash
# Service endpoints
kubectl get endpoints -n <namespace> <service-name>

# Service details
kubectl describe svc -n <namespace> <service-name>

# Test from within cluster
kubectl run -it --rm debug --image=busybox --restart=Never -- \
  wget -O- http://<service-name>:<port>
```

**Common causes:**
- Service selector doesn't match pod labels
- Port mismatch (service port vs container port)
- Readiness probe failing (no ready pods)

### Volume Mount Failing

**Check:**

```bash
# PVC status
kubectl get pvc -n <namespace>

# PVC details
kubectl describe pvc -n <namespace> <pvc-name>
```

**Common causes:**
- StorageClass not available
- Insufficient cluster storage
- Access mode incompatible with node count

## Related Documentation

- [GETTING_STARTED.md](GETTING_STARTED.md) - Tutorial using summon
- [BOOKRACK.md](BOOKRACK.md) - Book/chapter/spell structure
- [LIBRARIAN.md](LIBRARIAN.md) - ArgoCD deployment
- [MICROSPELL.md](MICROSPELL.md) - Opinionated wrapper
- [EXAMPLES_INDEX.md](EXAMPLES_INDEX.md) - All summon examples

## Examples Location

`charts/summon/examples/` - 19 comprehensive examples

**Quick access:**
- Basic: `basic-deployment.yaml`
- Production: `complex-production.yaml`
- Storage: `deployment-with-storage.yaml`
- Secrets: `deployment-with-vault-secrets.yaml`
- StatefulSet: `statefulset-with-storage.yaml`
- Job: `basic-job.yaml`
- CronJob: `basic-cronjob.yaml`
