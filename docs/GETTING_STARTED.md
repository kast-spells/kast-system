# Getting Started

Complete tutorial to deploy your first application with kast-system.

## Prerequisites

**Required:**
- Kubernetes cluster (1.20+)
- kubectl configured
- Helm 3.8+
- ArgoCD installed in cluster

**Optional:**
- Git repository for GitOps
- Vault for secrets management
- Istio for service mesh

## Quick Start

Deploy a simple application in 5 minutes:

```bash
# 1. Clone kast-system
git clone https://github.com/kast-spells/kast-system.git
cd kast-system

# 2. Create your first spell
cat > bookrack/my-book/production/my-app.yaml <<EOF
name: my-app
image:
  repository: nginx
  tag: alpine
service:
  enabled: true
  port: 80
EOF

# 3. Deploy with librarian
helm install my-book librarian --set name=my-book

# 4. Check ArgoCD
kubectl get application -n argocd my-app
argocd app get my-app

# 5. Access application
kubectl get svc -n my-app
```

**Result:** Nginx running in Kubernetes managed by ArgoCD.

## Tutorial: From Zero to Production

### Step 1: Create Book Structure

**Book:** Top-level organization (team, product, project). See [Bookrack](BOOKRACK.md) for complete details on the book/chapter/spell structure.

```bash
# Create book directory
mkdir -p bookrack/tutorial-book/{_lexicon,development,production}

# Create book configuration
cat > bookrack/tutorial-book/index.yaml <<EOF
name: tutorial-book
description: "Getting started tutorial book"

# Deployment sequence
chapters:
  - development
  - production

# ArgoCD configuration
projectName: tutorial-project
argocdNamespace: argocd

# Global app parameters
appParams:
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true

# Default chart (summon)
defaultTrinket:
  repository: https://github.com/kast-spells/kast-system.git
  path: ./charts/summon
  revision: main

# Trinkets for multi-source
trinkets:
  kaster:
    key: glyphs
    repository: https://github.com/kast-spells/kast-system.git
    path: ./charts/kaster
    revision: main
EOF
```

**What this does:**
- Creates book `tutorial-book`
- Defines two chapters: `development` and `production`
- Configures ArgoCD to auto-sync applications
- Sets summon as default chart

### Step 2: Create First Spell (Simple Application)

**Spell:** Single application deployment. Spells use the [Summon](SUMMON.md) chart by default for containerized workloads.

```bash
# Create simple web application
cat > bookrack/tutorial-book/development/web-app.yaml <<EOF
name: web-app
namespace: web-app

# Container configuration
image:
  repository: nginx
  tag: alpine
  pullPolicy: IfNotPresent

# Service configuration
service:
  enabled: true
  type: ClusterIP
  ports:
    - port: 80
      name: http

# Resources
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 200m
    memory: 256Mi

# Environment variables
envs:
  ENVIRONMENT: development
  LOG_LEVEL: debug
EOF
```

**What this creates:**
- Deployment with nginx:alpine
- ClusterIP Service on port 80
- ResourceQuota limits
- Environment variables

### Step 3: Deploy with Librarian

The [Librarian](LIBRARIAN.md) reads your book structure and generates ArgoCD Applications for each spell.

```bash
# Deploy book to ArgoCD
helm install tutorial-book librarian --set name=tutorial-book

# Verify Application created
kubectl get application -n argocd web-app

# Check Application status
argocd app get web-app
```

**Expected output:**

```
NAME      CLUSTER                         NAMESPACE  PROJECT          STATUS  HEALTH   SYNCPOLICY  CONDITIONS
web-app   https://kubernetes.default.svc  web-app    tutorial-project Synced  Healthy  Auto-Prune  <none>
```

### Step 4: Verify Deployment

```bash
# Check resources in namespace
kubectl get all -n web-app

# Check pod status
kubectl get pods -n web-app

# Check service
kubectl get svc -n web-app

# Access application (if using port-forward)
kubectl port-forward -n web-app svc/web-app 8080:80
curl http://localhost:8080
```

**Expected resources:**
- Deployment: `web-app`
- Pod: `web-app-xxxxxxxxx-xxxxx`
- Service: `web-app`
- ServiceAccount: `web-app`

### Step 5: Add Infrastructure (Glyphs)

Now let's add vault secrets and istio routing. [Glyphs](GLYPHS.md) are reusable templates for infrastructure resources, orchestrated by the [Kaster](KASTER.md) chart.

#### 5.1: Create Lexicon

**Lexicon:** Infrastructure registry for dynamic resource discovery. See [Lexicon](LEXICON.md) for query patterns and label matching.

```bash
# Create lexicon entries
cat > bookrack/tutorial-book/_lexicon/infrastructure.yaml <<EOF
lexicon:
  # Vault server
  - name: dev-vault
    type: vault
    url: http://vault.vault.svc:8200
    namespace: vault
    authPath: kubernetes
    secretPath: kv
    labels:
      environment: development
      default: chapter
    chapter: development

  # Istio Gateway
  - name: external-gateway
    type: istio-gw
    gateway: istio-system/gateway
    labels:
      access: external
      default: book
EOF
```

#### 5.2: Update Spell with Glyphs

```bash
# Update web-app with infrastructure
cat > bookrack/tutorial-book/development/web-app.yaml <<EOF
name: web-app
namespace: web-app

# Container configuration
image:
  repository: nginx
  tag: alpine

service:
  enabled: true
  type: ClusterIP
  ports:
    - port: 80
      name: http

# Infrastructure integration (see VAULT.md for complete secret management patterns)
glyphs:
  # Vault secrets
  vault:
    web-app-policy:
      type: prolicy
      serviceAccount: web-app

    app-config:
      type: secret
      format: env
      path: chapter
      keys:
        - api_key
        - database_url

  # Istio routing
  istio:
    web-app-vs:
      type: virtualService
      http:
        - match:
            - uri:
                prefix: /
          route:
            - destination:
                host: web-app
                port:
                  number: 80
      hosts:
        - app.example.com
      gateways:
        - external-gateway
EOF
```

**What this adds:**
- Vault policy for ServiceAccount
- Vault secret synced to K8s Secret
- Istio VirtualService for external access

#### 5.3: Update Deployment

```bash
# Librarian automatically detects changes
# Trigger ArgoCD sync
argocd app sync web-app

# Or wait for auto-sync (configured in appParams)
```

### Step 6: Add Production Environment

Chapter configurations inherit from the book and can override settings. See [Hierarchy Systems](HIERARCHY_SYSTEMS.md) for how values merge across book/chapter/spell levels.

```bash
# Create production chapter config
cat > bookrack/tutorial-book/production/index.yaml <<EOF
name: production

# Production overrides
appParams:
  disableAutoSync: true  # Manual sync in production
  syncPolicy:
    retry:
      limit: 5

# Production defaults
defaultTrinket:
  values:
    replicas: 3
    resources:
      limits:
        memory: 512Mi
        cpu: 500m
EOF

# Create production spell (same as dev, different config)
cat > bookrack/tutorial-book/production/web-app.yaml <<EOF
name: web-app
namespace: web-app-prod

# Production configuration
image:
  repository: nginx
  tag: "1.25.3"  # Pinned version
  pullPolicy: Always

service:
  enabled: true
  type: ClusterIP
  ports:
    - port: 80
      name: http

# Higher resources (inherits from chapter)
replicas: 5

# Production environment
envs:
  ENVIRONMENT: production
  LOG_LEVEL: warn

# Same glyphs as development
glyphs:
  vault:
    web-app-policy:
      type: prolicy
      serviceAccount: web-app

    app-config:
      type: secret
      format: env
      path: chapter
      keys:
        - api_key
        - database_url

  istio:
    web-app-vs:
      type: virtualService
      http:
        - match:
            - uri:
                prefix: /
          route:
            - destination:
                host: web-app
                port:
                  number: 80
      hosts:
        - app.production.com
      gateways:
        - external-gateway
EOF

# Update book deployment (picks up new chapter)
helm upgrade tutorial-book librarian --set name=tutorial-book

# Manually sync production (disableAutoSync: true)
argocd app sync web-app-prod
```

**Result:** Same application in production with:
- 5 replicas (vs 1 in dev)
- More resources (512Mi vs 256Mi)
- Pinned image version
- Manual sync required

### Step 7: Add Database with Runes

**Runes:** Additional Helm charts deployed with your spell in a multi-source ArgoCD Application. See [Librarian](LIBRARIAN.md) for multi-source configuration details.

```bash
# Update production app with PostgreSQL
cat > bookrack/tutorial-book/production/web-app.yaml <<EOF
name: web-app
namespace: web-app-prod

# Main application
image:
  repository: nginx
  tag: "1.25.3"

service:
  enabled: true

# Additional services via runes
runes:
  # PostgreSQL database
  - name: postgresql
    repository: https://charts.bitnami.com/bitnami
    chart: postgresql
    revision: 12.8.0
    values:
      auth:
        username: webapp
        password: changeme
        database: webapp_db
      primary:
        persistence:
          enabled: true
          size: 20Gi

  # Redis cache
  - name: redis
    repository: https://charts.bitnami.com/bitnami
    chart: redis
    revision: 17.11.3
    values:
      auth:
        enabled: false
      master:
        persistence:
          enabled: true
          size: 8Gi

# Environment variables
envs:
  ENVIRONMENT: production
  DATABASE_HOST: postgresql
  REDIS_HOST: redis-master

# Glyphs (same as before)
glyphs:
  vault:
    web-app-policy:
      type: prolicy
      serviceAccount: web-app
    app-config:
      type: secret
      format: env
      path: chapter
      keys:
        - api_key

  istio:
    web-app-vs:
      type: virtualService
      hosts:
        - app.production.com
EOF

# Deploy
argocd app sync web-app-prod
```

**Result:** ArgoCD Application with 3 sources:
1. Summon (main app)
2. PostgreSQL (rune)
3. Redis (rune)
4. Kaster (glyphs)

## Common Patterns

These patterns demonstrate how kast-system's [Hierarchy Systems](HIERARCHY_SYSTEMS.md) enable multi-level configuration inheritance and scope-based overrides.

### Pattern 1: Multi-Environment

**Same application, different configuration per environment:**

```
bookrack/my-book/
├── index.yaml              # Global config
├── _lexicon/
│   └── infrastructure.yaml # Shared infrastructure
├── development/
│   ├── index.yaml          # Dev overrides
│   └── my-app.yaml
├── staging/
│   ├── index.yaml          # Staging overrides
│   └── my-app.yaml
└── production/
    ├── index.yaml          # Production overrides
    └── my-app.yaml
```

**Book defaults → Chapter overrides → Spell config**

### Pattern 2: Microservices Monorepo

**Multiple services in one book:** Consider using [Microspell](MICROSPELL.md) for opinionated microservice deployments.

```
bookrack/microservices/
├── index.yaml
├── _lexicon/
├── infrastructure/
│   ├── vault.yaml
│   ├── istio-gateway.yaml
│   └── certificates.yaml
└── services/
    ├── api-gateway.yaml
    ├── user-service.yaml
    ├── payment-service.yaml
    └── notification-service.yaml
```

**All services share:**
- Same lexicon (vault, istio, certificates)
- Same ArgoCD project
- Same sync policies

### Pattern 3: External Chart with Glyphs

**Use existing Helm chart with kast glyphs:** Combine any Helm chart with kast infrastructure. See [Glyphs Reference](GLYPHS_REFERENCE.md) for all available glyphs.

```yaml
name: prometheus
repository: https://prometheus-community.github.io/helm-charts
chart: kube-prometheus-stack
revision: 48.3.1

# Prometheus values
values:
  prometheus:
    prometheusSpec:
      retention: 30d

# Add vault secret for alertmanager
glyphs:
  vault:
    alertmanager-config:
      type: secret
      format: yaml
      keys:
        - alertmanager.yml
```

**Result:** Prometheus from official chart + Vault integration

## Troubleshooting

### Application Not Created

**Check:**

```bash
# 1. Verify chapter in book
yq '.chapters' bookrack/tutorial-book/index.yaml

# 2. Verify spell file location
ls bookrack/tutorial-book/development/

# 3. Template librarian
helm template tutorial-book librarian --set name=tutorial-book --debug

# 4. Check ArgoCD logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller
```

### Application Syncing but Failing

**Check:**

```bash
# 1. Check Application status
argocd app get web-app

# 2. Check generated manifests
argocd app manifests web-app

# 3. Check pod logs
kubectl logs -n web-app -l app.kubernetes.io/name=web-app

# 4. Describe resources
kubectl describe deployment -n web-app web-app
```

### Glyphs Not Working

**Check:** See [Kaster](KASTER.md) documentation for glyph orchestration details.

```bash
# 1. Verify lexicon merged
helm template tutorial-book librarian --set name=tutorial-book \
  | yq '.spec.sources[].helm.values.lexicon'

# 2. Verify kaster source added
helm template tutorial-book librarian --set name=tutorial-book \
  | yq '.spec.sources[] | select(.path | contains("kaster"))'

# 3. Check glyph templates
make glyphs vault
```

### Values Not Merging

**Check hierarchy:**

```bash
# Book defaultTrinket.values
yq '.defaultTrinket.values' bookrack/tutorial-book/index.yaml

# Chapter defaultTrinket.values
yq '.defaultTrinket.values' bookrack/tutorial-book/development/index.yaml

# Spell values
yq '.' bookrack/tutorial-book/development/web-app.yaml

# Final merged values
argocd app manifests web-app | yq 'select(.kind == "Deployment") | .spec.template.spec'
```

## Next Steps

### Learn Core Concepts

1. **[BOOKRACK.md](BOOKRACK.md)** - Book/chapter/spell structure
2. **[LIBRARIAN.md](LIBRARIAN.md)** - ArgoCD orchestration
3. **[HIERARCHY_SYSTEMS.md](HIERARCHY_SYSTEMS.md)** - Values merging
4. **[LEXICON.md](LEXICON.md)** - Infrastructure registry

### Explore Glyphs

1. **[VAULT.md](VAULT.md)** - Secrets management
2. **[GLYPHS_REFERENCE.md](GLYPHS_REFERENCE.md)** - All available glyphs
3. **[GLYPH_DEVELOPMENT.md](GLYPH_DEVELOPMENT.md)** - Create custom glyphs

### Advanced Topics

1. **Trinkets:**
   - [SUMMON.md](SUMMON.md) - Base workload chart
   - [MICROSPELL.md](MICROSPELL.md) - Opinionated microservice
   - [TAROT.md](TAROT.md) - CI/CD workflows

2. **Multi-Cluster:**
   - Define clusters in lexicon
   - Use `clusterSelector` in spells
   - Deploy to multiple regions

3. **GitOps Workflow:**
   - Commit book structure to Git
   - ArgoCD watches repository
   - Changes auto-deploy (or manual in production)

## Examples

**Complete working examples:**

```bash
# Explore example book
ls -la bookrack/example-tdd-book/

# Infrastructure examples
cat bookrack/example-tdd-book/infrastructure/vault-comprehensive-test.yaml
cat bookrack/example-tdd-book/infrastructure/istio-gateway.yaml

# Application examples
cat bookrack/example-tdd-book/applications/example-api.yaml
cat bookrack/example-tdd-book/applications/complex-microservice.yaml

# Deploy example book
helm install example-tdd-book librarian --set name=example-tdd-book
```

**See [EXAMPLES_INDEX.md](EXAMPLES_INDEX.md) for complete list.**

## Summary

**You learned:**

1. Create book structure (book/chapter/spell)
2. Deploy with librarian to ArgoCD
3. Add infrastructure with glyphs (vault, istio)
4. Use lexicon for infrastructure registry
5. Deploy to multiple environments
6. Add databases with runes
7. Troubleshoot common issues

**Key Concepts:**

- **Book:** Organization unit (team/product)
- **Chapter:** Environment (dev/staging/production)
- **Spell:** Application deployment
- **Glyphs:** Infrastructure templates (vault, istio)
- **Lexicon:** Infrastructure registry
- **Runes:** Additional Helm charts
- **Librarian:** ArgoCD orchestrator

**Next:** Explore [EXAMPLES_INDEX.md](EXAMPLES_INDEX.md) for more patterns.
