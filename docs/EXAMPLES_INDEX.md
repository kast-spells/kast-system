# Examples Index

Complete index of all examples in runik-system organized by category and complexity.

## Quick Navigation

- [Books](#books) - Complete deployment examples
- [Summon](#summon-chart-examples) - Base workload deployments (19 examples)
- [Glyphs](#glyph-examples) - Infrastructure templates
- [Trinkets](#trinket-examples) - Opinionated wrappers
- [By Use Case](#examples-by-use-case)
- [By Complexity](#examples-by-complexity)

## Books

Complete book examples with multiple chapters and spells.

### example-tdd-book

**Location:** `bookrack/example-tdd-book/`

**Purpose:** Comprehensive TDD testing and documentation

**Structure:**
```
bookrack/example-tdd-book/
├── index.yaml                      # Book configuration
├── _lexicon/
│   └── infrastructure.yaml         # Infrastructure registry
├── infrastructure/                 # Infrastructure chapter
│   ├── vault-comprehensive-test.yaml
│   ├── istio-gateway.yaml
│   ├── cert-manager.yaml
│   └── rune-fallback-test.yaml
└── applications/                   # Applications chapter
    ├── example-api.yaml
    ├── complex-microservice.yaml
    ├── external-chart-example.yaml
    ├── rune-multi-workload.yaml
    └── rune-simple-fallback.yaml
```

**Examples:**

| File | Description | Features |
|------|-------------|----------|
| `infrastructure/vault-comprehensive-test.yaml` | Complete vault integration | Policies, secrets, random passwords, crypto keys |
| `infrastructure/istio-gateway.yaml` | Istio gateway setup | Gateway, VirtualService |
| `infrastructure/cert-manager.yaml` | Certificate management | Certificate issuers |
| `applications/example-api.yaml` | Simple API service | Summon + Istio routing |
| `applications/complex-microservice.yaml` | Full-featured service | Summon + Vault + Istio + Runes (PostgreSQL, Redis) |
| `applications/external-chart-example.yaml` | External Helm chart | Using bitnami/redis with glyphs |

**Deploy:**
```bash
helm install example-tdd-book librarian --set name=example-tdd-book
```

## Summon Chart Examples

**Location:** `charts/summon/examples/`

**Count:** 19 examples

**Purpose:** Base workload chart for Kubernetes deployments

### Basic Examples

| File | Description | Resources |
|------|-------------|-----------|
| `basic-deployment.yaml` | Minimal deployment | Deployment, Service |
| `basic-job.yaml` | One-time job | Job |
| `basic-cronjob.yaml` | Scheduled job | CronJob |
| `statefulset-with-storage.yaml` | StatefulSet with PVC | StatefulSet, Service, PVC |

**Use for:** Learning summon basics

**Test:**
```bash
make test CHART=summon EXAMPLE=basic-deployment
helm template test charts/summon -f charts/summon/examples/basic-deployment.yaml
```

### Storage Examples

| File | Description | Features |
|------|-------------|----------|
| `deployment-with-storage.yaml` | Deployment with PVC | Deployment, PVC, volumeMounts |
| `pv-showcase.yaml` | All volume types | emptyDir, configMap, secret, PVC |
| `pv-pvc-naming-explained.yaml` | PVC naming patterns | Dynamic PVC creation |
| `pv-with-runic-indexer.yaml` | PVC from lexicon | Runic indexer integration |

**Use for:** Learning volume management

### Secrets & Configuration Examples

| File | Description | Features |
|------|-------------|----------|
| `deployment-with-secrets-env.yaml` | Secrets as env vars | envFrom, secretRef |
| `deployment-with-vault-secrets.yaml` | Vault integration | VaultSecret CRD |
| `deployment-with-external-secrets.yaml` | External Secrets Operator | ExternalSecret CRD |
| `deployment-with-config-checksums.yaml` | Auto-restart on config change | Checksum annotations |
| `configmap-yaml-mount.yaml` | ConfigMap as YAML file | volumeMount, YAML content |
| `configmap-json-mount.yaml` | ConfigMap as JSON file | volumeMount, JSON content |
| `configmap-unified-contenttype.yaml` | Multiple content types | Mixed content in ConfigMap |

**Use for:** Learning secrets and configuration management

### Advanced Examples

| File | Description | Features |
|------|-------------|----------|
| `complex-production.yaml` | Production-ready deployment | HPA, resources, probes, volumes |
| `deployment-with-s3-csi.yaml` | S3 storage via CSI | CSI driver, S3 bucket mount |
| `test-rolling-update.yaml` | Rolling update strategy | updateStrategy, maxSurge |
| `test-feature-must-exist.yaml` | TDD feature validation | Feature existence testing |

**Use for:** Production patterns

## Glyph Examples

Infrastructure templates organized by glyph type.

### Vault Glyph (12 examples)

**Location:** `charts/glyphs/vault/examples/`

| File | Description | Templates Used |
|------|-------------|----------------|
| `secrets.yaml` | Basic secret sync | vault.secret, vault.prolicy |
| `random-secrets.yaml` | Random password generation | vault.randomSecret |
| `crypto-key.yaml` | SSH/TLS keypair generation | vault.cryptoKey |
| `prolicy-test.yaml` | Policy with password access | vault.prolicy, vault.customPasswordPolicy |
| `path-variants.yaml` | All path types | book, chapter, namespace, absolute |
| `format-variants.yaml` | All output formats | plain, env, json, yaml, b64 |
| `custom-password-policies.yaml` | Custom password policies | vault.customPasswordPolicy |
| `advanced-custom-policies.yaml` | Complex policy config | extraPolicy hierarchy |
| `advanced-options.yaml` | Advanced features | Multiple secrets, selectors |
| `edge-cases.yaml` | Boundary conditions | Empty values, nil checks |

**Test:**
```bash
make glyphs vault
make show-glyph-diff GLYPH=vault EXAMPLE=secrets
```

### Istio Glyph (2 examples)

**Location:** `charts/glyphs/istio/examples/`

| File | Description |
|------|-------------|
| `gateway.yaml` | Gateway + VirtualService |
| `virtual-service.yaml` | VirtualService only |

### Argo Events Glyph (5 examples)

**Location:** `charts/glyphs/argo-events/examples/`

| File | Description |
|------|-------------|
| `basic-eventbus.yaml` | Event bus setup |
| `github-eventsource.yaml` | GitHub webhook integration |
| `sensor-basic.yaml` | Basic sensor |
| `workflow-trigger.yaml` | Trigger Argo Workflow |
| `complete-pipeline.yaml` | EventBus + EventSource + Sensor |

### Cert-Manager Glyph (2 examples)

**Location:** `charts/glyphs/certManager/examples/`

| File | Description |
|------|-------------|
| `certificate.yaml` | Certificate resource |
| `dns-endpoint.yaml` | DNS endpoint for external-dns |

### Other Glyphs

| Glyph | Examples | Location |
|-------|----------|----------|
| Common | 2 | `charts/glyphs/common/examples/` |
| Crossplane | 2 | `charts/glyphs/crossplane/examples/` |
| FreeForm | 2 | `charts/glyphs/freeForm/examples/` |
| GCP | 3 | `charts/glyphs/gcp/examples/` |
| Keycloak | Not documented | - |
| Runic System | 3 | `charts/glyphs/runic-system/examples/` |
| S3 | Not documented | - |

## Trinket Examples

Opinionated wrappers around base charts.

### Tarot (14 examples)

**Location:** `charts/trinkets/tarot/examples/`

**Purpose:** CI/CD workflow orchestration

| File | Description | Pattern |
|------|-------------|---------|
| `minimal-workflow.yaml` | Simplest workflow | Single card |
| `basic-workflow.yaml` | Build + test + deploy | 3-card reading |
| `multi-step-workflow.yaml` | Complex pipeline | Multiple positions |
| `docker-build-push.yaml` | Docker image workflow | Build, push to registry |
| `github-integration.yaml` | GitHub webhook trigger | Event-driven |
| `vault-secrets.yaml` | Secrets in workflow | Vault integration |
| `card-library.yaml` | Reusable card definitions | Global cards |

**Test:**
```bash
cd charts/trinkets/tarot
helm template test . -f examples/basic-workflow.yaml
```

**See:** [TAROT.md](TAROT.md) for complete documentation

### Microspell (8 examples)

**Location:** `charts/trinkets/microspell/examples/`

**Purpose:** Opinionated microservice deployments

| File | Description | Features |
|------|-------------|----------|
| `basic-microservice.yaml` | Simple microservice | Auto-configured deployment |
| `advanced-microservice.yaml` | Production microservice | Vault, Istio, monitoring |
| `staging-microservice.yaml` | Staging environment | Environment-specific config |
| `vault-secrets-comprehensive.yaml` | All vault features | Multiple secret types |
| `volumes-comprehensive.yaml` | All volume types | PVC, ConfigMap, Secret |
| `statefulset-redis-cluster.yaml` | StatefulSet workload | Redis cluster pattern |
| `job-data-processor.yaml` | Job workload | One-time processing |
| `cronjob-backup-scheduler.yaml` | CronJob workload | Scheduled backups |

**Test:**
```bash
cd charts/trinkets/microspell
helm template test . -f examples/basic-microservice.yaml
```

**See:** [MICROSPELL.md](MICROSPELL.md) for complete documentation

### Covenant (In Development)

**Location:** `charts/trinkets/covenant/examples/`

**Status:** Early development

**Purpose:** Advanced deployment patterns

## Examples by Use Case

### Deploy Simple Application

**Minimal example:**
```
charts/summon/examples/basic-deployment.yaml
```

**With routing:**
```
bookrack/example-tdd-book/applications/example-api.yaml
```

### Secrets Management

**Vault secrets:**
```
charts/glyphs/vault/examples/secrets.yaml
charts/summon/examples/deployment-with-vault-secrets.yaml
```

**External Secrets:**
```
charts/summon/examples/deployment-with-external-secrets.yaml
```

### Storage & Volumes

**Persistent storage:**
```
charts/summon/examples/deployment-with-storage.yaml
charts/summon/examples/statefulset-with-storage.yaml
```

**All volume types:**
```
charts/summon/examples/pv-showcase.yaml
```

### Service Mesh (Istio)

**Gateway + routing:**
```
charts/glyphs/istio/examples/gateway.yaml
bookrack/example-tdd-book/infrastructure/istio-gateway.yaml
```

**Application with routing:**
```
bookrack/example-tdd-book/applications/example-api.yaml
```

### CI/CD Workflows

**Build pipeline:**
```
charts/trinkets/tarot/examples/docker-build-push.yaml
```

**Complete workflow:**
```
charts/trinkets/tarot/examples/basic-workflow.yaml
```

### Database Deployments

**PostgreSQL with application:**
```
bookrack/example-tdd-book/applications/complex-microservice.yaml
```

**Redis cluster:**
```
charts/trinkets/microspell/examples/statefulset-redis-cluster.yaml
```

### Multi-Source Deployments

**Application + Database + Cache:**
```
bookrack/example-tdd-book/applications/complex-microservice.yaml
```

**External chart with glyphs:**
```
bookrack/example-tdd-book/applications/external-chart-example.yaml
```

## Examples by Complexity

### Beginner

**Start here:**

1. `charts/summon/examples/basic-deployment.yaml` - Minimal deployment
2. `bookrack/example-tdd-book/applications/example-api.yaml` - Simple app with routing
3. `charts/glyphs/vault/examples/secrets.yaml` - Basic secret

**Learn:** Core concepts, deployment structure

### Intermediate

**Next steps:**

1. `charts/summon/examples/complex-production.yaml` - Production patterns
2. `charts/summon/examples/deployment-with-storage.yaml` - Volume management
3. `charts/glyphs/vault/examples/random-secrets.yaml` - Password generation
4. `charts/trinkets/microspell/examples/basic-microservice.yaml` - Microservice pattern

**Learn:** Resources, storage, secrets, microservices

### Advanced

**Deep dive:**

1. `bookrack/example-tdd-book/applications/complex-microservice.yaml` - Multi-source deployment
2. `charts/glyphs/vault/examples/advanced-custom-policies.yaml` - Policy hierarchy
3. `charts/trinkets/tarot/examples/multi-step-workflow.yaml` - Complex CI/CD
4. `charts/summon/examples/pv-with-runic-indexer.yaml` - Lexicon integration

**Learn:** Multi-source, hierarchy, workflows, lexicon

## Testing Examples

```bash
# Test single summon example
make test CHART=summon EXAMPLE=basic-deployment
helm template test charts/summon -f charts/summon/examples/basic-deployment.yaml

# Test all summon examples
make test CHART=summon

# Test glyph
make glyphs vault

# Test specific glyph example
helm template test charts/kaster \
  -f charts/glyphs/vault/examples/secrets.yaml

# Test book
helm template tutorial-book librarian --set name=example-tdd-book --debug

# Deploy example book
helm install example-tdd-book librarian --set name=example-tdd-book
```

## Creating New Examples

### For Testing (TDD)

```bash
# Create test example
make create-example CHART=summon EXAMPLE=my-test

# Edit the example
vim charts/summon/examples/my-test.yaml

# Run TDD cycle
make tdd-red      # Should fail
# Implement feature
make tdd-green    # Should pass

# Generate snapshot
make generate-snapshots CHART=summon
```

### For Documentation

```yaml
# charts/summon/examples/my-feature.yaml

# Clear description comment
# Shows: <what this demonstrates>
# Uses: <what features are used>

name: my-feature
namespace: default

# Minimal but complete configuration
image:
  repository: nginx
  tag: alpine

# Feature being demonstrated
myNewFeature:
  enabled: true
  config: value
```

**Guidelines:**

- Clear purpose in comment
- Minimal but complete
- One concept per example
- Realistic values
- Valid YAML

## Documentation Cross-References

**By Topic:**

- **Getting Started:** [GETTING_STARTED.md](GETTING_STARTED.md)
- **Book Structure:** [BOOKRACK.md](BOOKRACK.md)
- **Deployment:** [LIBRARIAN.md](LIBRARIAN.md)
- **Vault Secrets:** [VAULT.md](VAULT.md)
- **Glyphs:** [GLYPHS_REFERENCE.md](GLYPHS_REFERENCE.md)
- **Trinkets:**
  - [SUMMON.md](SUMMON.md)
  - [MICROSPELL.md](MICROSPELL.md)
  - [TAROT.md](TAROT.md)

## Summary

**Total Examples:** 60+ across charts, glyphs, and trinkets

**Categories:**
- 📚 Books: 1 complete example (example-tdd-book)
- 📦 Summon: 19 examples (workloads, storage, secrets)
- 🎭 Glyphs: 30+ examples (vault, istio, argo-events, etc.)
- 🔮 Trinkets: 22 examples (tarot, microspell)

**Quick Access:**
- Beginner: Start with `charts/summon/examples/basic-deployment.yaml`
- Book: Deploy `bookrack/example-tdd-book/`
- Vault: Explore `charts/glyphs/vault/examples/`
- CI/CD: Check `charts/trinkets/tarot/examples/`

**Next Steps:** Choose an example matching your use case, test it, modify it, make it yours.
