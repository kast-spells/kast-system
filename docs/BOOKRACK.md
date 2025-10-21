# Bookrack

Configuration management system for kast. Bookrack organizes deployments using a book/chapter/spell pattern that maps to organization/environment/application structure.

## Overview

Bookrack provides:
- Hierarchical configuration (book → chapter → spell)
- GitOps-ready directory structure
- Values inheritance and overrides
- Infrastructure registry (lexicon)
- Deployment sequencing (chapters)
- Multi-environment management

**Pattern:** Configuration as Directory Structure

**Location:** `bookrack/` directory

## Directory Structure

```
bookrack/
├── <book-name>/                    # Book (organization/team/project)
│   ├── index.yaml                  # Book configuration
│   ├── _lexicon/                   # Infrastructure registry
│   │   ├── infrastructure.yaml     # Lexicon entries
│   │   ├── clusters.yaml           # Cluster definitions
│   │   └── databases.yaml          # Database connections
│   ├── <chapter-name>/             # Chapter (environment/phase)
│   │   ├── index.yaml              # Chapter configuration
│   │   ├── spell1.yaml             # Application definition
│   │   ├── spell2.yaml             # Application definition
│   │   └── spell3.yaml             # Application definition
│   ├── <chapter-name-2>/
│   │   ├── index.yaml
│   │   └── ...
│   └── <chapter-name-3>/
│       ├── index.yaml
│       └── ...
└── <book-name-2>/
    ├── index.yaml
    └── ...
```

### Structure Concepts

**Book:** Top-level organization unit
- Represents: Team, project, product, organization
- Contains: Multiple chapters
- Defines: Global configuration, trinkets, lexicon

**Chapter:** Deployment environment or phase
- Represents: Environment (staging, production), phase (infra, apps)
- Contains: Multiple spells
- Defines: Environment-specific overrides

**Spell:** Single application or infrastructure deployment
- Represents: Microservice, database, infrastructure component
- Contains: Application configuration
- Defines: Workload-specific configuration

## Book index.yaml

**Purpose:** Define book-wide configuration inherited by all chapters and spells.

**Location:** `bookrack/<book-name>/index.yaml`

**Complete Specification:**

```yaml
# Book identity
name: my-book                        # Required: Book name
description: "Book description"      # Optional: Documentation

# Deployment sequence
chapters:                            # Required: Ordered list
  - infrastructure                   # Chapter 1 (deployed first)
  - platform                         # Chapter 2
  - applications                     # Chapter 3

# ArgoCD configuration
projectName: my-project              # Optional: ArgoCD project (default: book name)
argocdNamespace: argocd              # Optional: ArgoCD namespace (default: argocd)

# Global application parameters
appParams:                           # Optional: Default ArgoCD sync config
  cleanDefinition: false
  noHelm: false
  disableAutoSync: false
  skipCrds: false
  bookData: false                    # Pass book/chapter/lexicon to charts
  syncPolicy:
    managedNamespaceMetadata:
      labels:                        # Namespace labels
        managed-by: kast
      annotations:                   # Namespace annotations
        owner: platform-team
    automated:
      prune: true                    # Auto-delete removed resources
      selfHeal: true                 # Auto-sync on drift
      allowEmpty: false              # Prevent deleting all resources
    syncOptions:
      - CreateNamespace=true
      - PrunePropagationPolicy=foreground
      - PruneLast=true
    retry:
      limit: 2
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
  ignoreDifferences: []              # Ignore diffs on specific fields
  customFinalizers: []               # ArgoCD finalizers
  annotations: {}                    # Application annotations

# Default chart (summon)
defaultTrinket:                      # Optional: Chart for spells without chart/path
  repository: https://github.com/kast-spells/kast-system.git
  path: ./charts/summon
  revision: v1.0.0
  chart: null                        # Alternative to path
  values: {}                         # Default values

# Trinkets registry
trinkets:                            # Optional: Additional charts (multi-source)
  kaster:
    key: glyphs                      # Trigger: spell has "glyphs:" field
    repository: https://github.com/kast-spells/kast-system.git
    path: ./charts/kaster
    revision: v1.0.0
    values: {}                       # Default values for this trinket
  tarot:
    key: tarot                       # Trigger: spell has "tarot:" field
    repository: https://github.com/kast-spells/kast-system.git
    path: ./charts/trinkets/tarot
    revision: v1.0.0
  microspell:
    key: microspell
    repository: https://github.com/kast-spells/kast-system.git
    path: ./charts/trinkets/microspell
    revision: v1.0.0

# Cluster targeting
clusterSelector:                     # Optional: Default cluster targeting
  environment: production
  region: us-west

# Global appendix (propagated to all spells)
appendix:                            # Optional: Global context
  lexicon: []                        # Infrastructure registry entries
  cards: []                          # Tarot card definitions

# Data for implicit spell values
# Any fields here are merged into defaultTrinket.values
image:
  pullPolicy: Always
resources:
  limits:
    memory: 256Mi
```

**Required Fields:**
- `name` or use release name as default
- `chapters` (at least one chapter)

**All other fields optional with sensible defaults.**

## Chapter index.yaml

**Purpose:** Override book configuration for specific chapter.

**Location:** `bookrack/<book-name>/<chapter-name>/index.yaml`

**Complete Specification:**

```yaml
# Chapter identity
name: production                     # Optional: Chapter name (defaults to directory name)
description: "Production environment"  # Optional: Documentation

# Override ArgoCD project
projectName: production-project      # Optional: Override book projectName

# Override app parameters
appParams:                           # Optional: Merge with book appParams
  disableAutoSync: true              # Manual sync for production
  syncPolicy:
    retry:
      limit: 5                       # More retries in production

# Override default trinket
defaultTrinket:                      # Optional: Override book defaultTrinket
  revision: v1.2.0                   # Use different version
  values:
    replicas: 3                      # Production defaults

# Override trinkets
trinkets:                            # Optional: Override specific trinkets
  kaster:
    revision: v1.2.0                 # Update kaster version
  tarot:
    values:
      timeout: 3600                  # Longer timeouts in production

# Override cluster targeting
clusterSelector:                     # Optional: Override book clusterSelector
  environment: production
  region: us-west

# Chapter appendix (merged to global)
appendix:                            # Optional: Chapter-specific context
  lexicon:
    - name: production-vault
      type: vault
      url: https://vault.prod.svc:8200
      labels:
        environment: production
        default: chapter

# Chapter-local appendix (NOT merged to global)
localAppendix:                       # Optional: Chapter-only context
  lexicon:
    - name: staging-only-resource
      type: service
      url: http://staging.example.com

# Implicit spell values (merged to defaultTrinket.values)
replicas: 3
resources:
  limits:
    memory: 1Gi
```

**Merge Behavior:**

| Field | Merge Type |
|-------|------------|
| `appParams` | Deep merge |
| `defaultTrinket` | Deep merge |
| `trinkets` | Deep merge by key |
| `clusterSelector` | Replace |
| `appendix` | Concatenate arrays, merge objects |
| `localAppendix` | Chapter-only (not propagated) |
| Implicit values | Deep merge to `defaultTrinket.values` |

**All fields optional.** Chapter inherits book configuration by default.

## Spell YAML

**Purpose:** Define single application or infrastructure deployment.

**Location:** `bookrack/<book-name>/<chapter-name>/spell-name.yaml`

**File Naming:** Lowercase with hyphens (e.g., `api-service.yaml`, `vault-setup.yaml`)

**Complete Specification:**

```yaml
# Spell identity
name: my-app                         # Required: Spell name
namespace: default                   # Optional: K8s namespace (defaults to spell name)
description: "Application description"  # Optional: Documentation

# Deployment strategy - choose ONE:

# Strategy 1: Use defaultTrinket (summon)
# (no chart/path/repository specified)
image:
  repository: nginx
  tag: alpine
service:
  enabled: true

# Strategy 2: Use external chart
repository: https://charts.bitnami.com/bitnami
chart: redis
revision: 17.11.3
values:
  auth:
    enabled: false

# Strategy 3: Use custom path
repository: https://github.com/company/charts.git
path: ./custom-chart
revision: main
values:
  config: value

# Trinket triggers (multi-source detection)
glyphs:                              # Triggers kaster trinket
  vault:
    - type: secret
      name: app-secret
  istio:
    - type: virtualService
      name: app-vs

tarot:                               # Triggers tarot trinket
  reading:
    build:
      selectors: {stage: build}
      position: action

microspell:                          # Triggers microspell trinket
  secrets:
    database:
      type: vault-secret

# Additional charts (runes)
runes:                               # Optional: Additional Helm charts
  - name: postgresql
    repository: https://charts.bitnami.com/bitnami
    chart: postgresql
    revision: 12.8.0
    values:
      auth:
        database: myapp
    appParams:                       # Rune-specific appParams
      skipCrds: true
      ignoreDifferences:
        - group: apps
          kind: StatefulSet

# Cluster targeting
clusterSelector:                     # Optional: Override chapter clusterSelector
  environment: staging
  region: eu-west

# App parameters
appParams:                           # Optional: Override chapter appParams
  syncPolicy:
    automated:
      prune: false                   # Don't auto-prune this app
  annotations:
    notifications.argoproj.io/subscribe.on-sync-failed.slack: alerts

# Spell appendix (merged to global)
appendix:                            # Optional: Spell-specific context
  lexicon:
    - name: app-database
      type: database
      host: db.example.com

# Spell-local appendix (NOT merged to global)
localAppendix:                       # Optional: Spell-only context
  lexicon:
    - name: local-cache
      type: service
      url: http://localhost:6379

# Implicit values (for defaultTrinket or custom chart)
# Any fields not recognized above are passed to chart
replicas: 2
resources:
  limits:
    cpu: 500m
    memory: 512Mi
envs:
  LOG_LEVEL: info
volumes:
  data:
    type: pvc
    size: 10Gi
```

**Required Fields:**
- `name`

**Deployment Strategy (choose one):**
- **Implicit (defaultTrinket):** No `chart`, `path`, or `repository` → uses book `defaultTrinket`
- **External chart:** Specify `repository` + `chart` + `revision`
- **Custom path:** Specify `repository` + `path` + `revision`

**All other fields optional.**

## Lexicon Directory

**Purpose:** Store infrastructure registry shared across book.

**Location:** `bookrack/<book-name>/_lexicon/`

**Convention:** Directory name starts with underscore (`_`) to distinguish from chapters.

### Lexicon File Structure

**Multiple YAML files allowed:**

```
bookrack/my-book/_lexicon/
├── infrastructure.yaml      # Core infrastructure
├── clusters.yaml            # Kubernetes clusters
├── databases.yaml           # Database connections
├── certificates.yaml        # Certificate issuers
└── custom.yaml             # Custom resources
```

**Files merged:** All `lexicon:` arrays concatenated.

### Lexicon Entry Format

```yaml
lexicon:
  - name: resource-name               # Required: Unique name
    type: resource-type               # Required: Type (vault, istio-gw, database, etc.)
    labels:                           # Required: Selector labels
      environment: production
      default: book                   # Optional: Fallback behavior
    # Type-specific fields
    url: https://resource.example.com
    namespace: default
    # ... other fields
```

**Common Types:**

| Type | Purpose | Required Fields |
|------|---------|-----------------|
| `vault` | Vault server | `url`, `namespace`, `authPath`, `secretPath` |
| `istio-gw` | Istio Gateway | `gateway` |
| `cert-issuer` | Certificate issuer | `issuer` |
| `database` | Database connection | `host`, `port` |
| `k8s-cluster` | Kubernetes cluster | `clusterURL` |
| `k8s` | Kubernetes cluster (alias) | `apiServer`, `caCert` |

**Example:**

```yaml
# bookrack/my-book/_lexicon/infrastructure.yaml
lexicon:
  # Vault servers
  - name: production-vault
    type: vault
    url: https://vault.prod.svc:8200
    namespace: vault
    authPath: kubernetes
    secretPath: kv
    labels:
      environment: production
      default: chapter
    chapter: production

  - name: default-vault
    type: vault
    url: https://vault.vault.svc:8200
    namespace: vault
    authPath: kubernetes
    secretPath: kv
    labels:
      default: book

  # Istio Gateways
  - name: external-gateway
    type: istio-gw
    labels:
      access: external
      default: book
    gateway: istio-system/external-gateway

  # Certificate Issuers
  - name: letsencrypt-staging
    type: cert-issuer
    labels:
      environment: staging
      default: chapter
    issuer: letsencrypt-staging
    chapter: staging

  - name: letsencrypt-prod
    type: cert-issuer
    labels:
      environment: production
      default: chapter
    issuer: letsencrypt-prod
    chapter: production

  # Kubernetes Clusters
  - name: prod-us-west
    type: k8s-cluster
    clusterURL: https://prod-us-west.example.com
    labels:
      environment: production
      region: us-west
      default: chapter
    chapter: production

  - name: staging-us-west
    type: k8s-cluster
    clusterURL: https://staging-us-west.example.com
    labels:
      environment: staging
      region: us-west
      default: chapter
    chapter: staging

  # Databases
  - name: postgres-primary
    type: database
    host: postgres.data.svc.cluster.local
    port: 5432
    labels:
      engine: postgres
      tier: primary
      default: book
```

**Lexicon Merge:** `_lexicon/*.yaml` files merged into book `appendix.lexicon` and propagated to all spells.

## Values Hierarchy

Values merge from book → chapter → spell with most specific winning.

### Merge Order

```
1. Book defaultTrinket.values
2. Book index.yaml implicit values
3. Chapter defaultTrinket.values
4. Chapter index.yaml implicit values
5. Spell YAML values
```

### Merge Rules

**Primitives (strings, numbers, booleans):** Replace

```yaml
# Book
replicas: 1

# Spell
replicas: 3

# Result: 3
```

**Objects:** Deep merge

```yaml
# Book
image:
  pullPolicy: Always
  imagePullSecrets:
    - name: registry-creds

# Spell
image:
  repository: nginx
  tag: alpine

# Result:
image:
  repository: nginx
  tag: alpine
  pullPolicy: Always
  imagePullSecrets:
    - name: registry-creds
```

**Arrays:** Replace (not merge)

```yaml
# Book
envs:
  - name: ENV
    value: production

# Spell
envs:
  - name: LOG_LEVEL
    value: info

# Result: Only spell envs
envs:
  - name: LOG_LEVEL
    value: info
```

**Workaround for array merging:** Use objects instead

```yaml
# Book (use object keys instead of array)
envsMap:
  ENV: production
  REGION: us-west

# Spell
envsMap:
  LOG_LEVEL: info

# Result: Merged
envsMap:
  ENV: production
  REGION: us-west
  LOG_LEVEL: info
```

### Example Hierarchy

```yaml
# Book index.yaml
defaultTrinket:
  values:
    image:
      pullPolicy: Always
    resources:
      limits:
        memory: 256Mi
        cpu: 100m
    replicas: 1

# Book index.yaml (implicit)
service:
  type: ClusterIP

# Chapter production/index.yaml
defaultTrinket:
  values:
    replicas: 3
    resources:
      limits:
        memory: 1Gi

# Chapter production/index.yaml (implicit)
resources:
  requests:
    memory: 512Mi

# Spell production/api-service.yaml
name: api-service
image:
  repository: api-service
  tag: v2.1.0
replicas: 5
resources:
  limits:
    cpu: 500m
envs:
  LOG_LEVEL: info

# Final values passed to summon:
name: api-service
image:
  repository: api-service          # From spell
  tag: v2.1.0                      # From spell
  pullPolicy: Always               # From book
replicas: 5                        # From spell (most specific)
resources:
  limits:
    memory: 1Gi                    # From chapter
    cpu: 500m                      # From spell
  requests:
    memory: 512Mi                  # From chapter
service:
  type: ClusterIP                  # From book
envs:
  LOG_LEVEL: info                  # From spell
```

## Naming Conventions

### Book Names

**Pattern:** `lowercase-with-hyphens`

**Examples:**
- `platform-infrastructure`
- `payment-services`
- `data-pipelines`

**Avoid:**
- CamelCase: `PlatformInfrastructure`
- Underscores: `platform_infrastructure`
- Spaces: `platform infrastructure`

### Chapter Names

**Pattern:** `lowercase-with-hyphens`

**Common Patterns:**

**By Environment:**
- `development`
- `staging`
- `production`

**By Phase:**
- `infrastructure`
- `platform`
- `applications`

**By Region:**
- `us-west`
- `eu-central`
- `ap-south`

**Combined:**
- `production-us-west`
- `staging-infrastructure`

**Avoid:**
- Abbreviations: `prod`, `stg`, `dev` (use full names)
- Numbers only: `phase1`, `phase2` (use descriptive names)

### Spell Names

**Pattern:** `lowercase-with-hyphens`

**Match Application/Service Name:**

```yaml
# Good
name: payment-service              # Spell file: payment-service.yaml
name: user-authentication          # Spell file: user-authentication.yaml
name: vault-setup                  # Spell file: vault-setup.yaml

# Avoid
name: PaymentService               # CamelCase
name: payment_service              # Underscores
name: svc-payment                  # Abbreviations
```

**Infrastructure Spells:**

```yaml
# Good patterns
name: istio-gateway
name: vault-policies
name: cert-manager-issuer
name: database-operator
```

### Lexicon File Names

**Pattern:** `lowercase-with-hyphens.yaml`

**Examples:**
- `infrastructure.yaml`
- `clusters.yaml`
- `databases.yaml`
- `certificate-issuers.yaml`
- `api-gateways.yaml`

## Best Practices

### Book Organization

**Single Responsibility:**

```
# Good: One book per team/product
bookrack/
├── payment-services/      # Payment team
├── user-services/         # User management team
└── platform/              # Platform team

# Avoid: Mixing unrelated services
bookrack/
└── everything/            # All services
```

**Logical Chapter Sequence:**

```yaml
chapters:
  - infrastructure     # CRDs, operators, vault
  - data-platform     # Databases, caches
  - applications      # Business services
  - edge              # Gateways, ingress
```

**Reason:** Dependencies deployed first.

### Lexicon Management

**Organize by Type:**

```
_lexicon/
├── infrastructure.yaml    # Vault, operators
├── networking.yaml        # Gateways, ingress
├── data.yaml             # Databases, queues
├── clusters.yaml         # Kubernetes clusters
└── certificates.yaml     # Certificate issuers
```

**Use Labels for Selection:**

```yaml
lexicon:
  - name: production-vault
    type: vault
    labels:
      environment: production    # Select by environment
      security-level: high       # Select by security
      region: us-west           # Select by region
      default: chapter          # Fallback behavior
```

### Values Inheritance

**Set Conservative Defaults at Book Level:**

```yaml
# Book index.yaml
defaultTrinket:
  values:
    resources:
      limits:
        memory: 256Mi
        cpu: 100m
    replicas: 1
    image:
      pullPolicy: IfNotPresent
```

**Override for Specific Environments:**

```yaml
# Chapter production/index.yaml
defaultTrinket:
  values:
    resources:
      limits:
        memory: 1Gi
        cpu: 500m
    replicas: 3
    image:
      pullPolicy: Always
```

**Override for Specific Applications:**

```yaml
# Spell: high-traffic-api.yaml
resources:
  limits:
    memory: 4Gi
    cpu: 2000m
replicas: 10
```

### Appendix vs LocalAppendix

**Use `appendix` for:**
- Shared infrastructure (vault, gateways)
- Organization-wide resources
- Cross-environment resources

```yaml
# Book appendix - available everywhere
appendix:
  lexicon:
    - name: organization-vault
      type: vault
      labels:
        default: book
```

**Use `localAppendix` for:**
- Environment-specific resources
- Chapter-only infrastructure
- Temporary resources

```yaml
# Chapter localAppendix - chapter-only
localAppendix:
  lexicon:
    - name: staging-debug-service
      type: service
      url: http://debug.staging.svc
```

### Spell File Organization

**One Spell Per File:**

```
# Good
applications/
├── payment-api.yaml
├── user-service.yaml
└── notification-worker.yaml

# Avoid
applications/
└── all-services.yaml    # Multiple spells in one file
```

**Reason:** Clear ArgoCD Application mapping, easier reviews.

**Descriptive Names:**

```
# Good
infrastructure/
├── vault-policies-setup.yaml
├── istio-external-gateway.yaml
└── cert-manager-letsencrypt.yaml

# Avoid
infrastructure/
├── setup1.yaml
├── gateway.yaml
└── certs.yaml
```

### Version Pinning

**Book Level - Stable Versions:**

```yaml
# Book index.yaml
defaultTrinket:
  revision: v1.0.0        # Pinned stable version

trinkets:
  kaster:
    revision: v1.0.0      # Pinned
```

**Chapter Level - Environment-Specific:**

```yaml
# Chapter staging/index.yaml
defaultTrinket:
  revision: feature/new-features    # Canary testing

# Chapter production/index.yaml
defaultTrinket:
  revision: v1.0.5                  # Stable production version
```

### Documentation

**Add Descriptions:**

```yaml
name: my-book
description: "Payment processing services - handles all payment transactions"

chapters:
  - infrastructure  # Vault, Istio, CertManager
  - databases      # PostgreSQL, Redis
  - services       # Payment APIs
```

**Comment Complex Configuration:**

```yaml
# Spell: payment-processor.yaml
name: payment-processor
description: "Main payment processing service - handles credit cards and bank transfers"

# Resource limits based on load testing (2024-10-15)
# Peak load: 10k req/sec, 4GB RAM
resources:
  limits:
    memory: 4Gi
    cpu: 2000m
```

## Common Patterns

### Multi-Environment

```
bookrack/my-product/
├── index.yaml             # Global config
├── _lexicon/
│   └── infrastructure.yaml  # Shared infrastructure
├── staging/
│   ├── index.yaml         # Staging overrides
│   ├── api-service.yaml
│   └── worker-service.yaml
└── production/
    ├── index.yaml         # Production overrides
    ├── api-service.yaml   # Same spells, different config
    └── worker-service.yaml
```

### Multi-Region

```
bookrack/global-app/
├── index.yaml
├── _lexicon/
│   └── clusters.yaml      # All region clusters
├── us-west/
│   ├── index.yaml         # Region-specific config
│   └── api-service.yaml
├── eu-central/
│   ├── index.yaml
│   └── api-service.yaml
└── ap-south/
    ├── index.yaml
    └── api-service.yaml
```

### Phased Deployment

```
bookrack/platform/
├── index.yaml
chapters:
  - phase1-operators      # Deploy first
  - phase2-infrastructure # Deploy second
  - phase3-platform       # Deploy third
  - phase4-applications   # Deploy last
```

### Microservices Monorepo

```
bookrack/microservices/
├── index.yaml
├── _lexicon/
├── infrastructure/        # Shared infrastructure
│   ├── vault.yaml
│   ├── istio-gateway.yaml
│   └── certificates.yaml
└── services/             # All microservices
    ├── api-gateway.yaml
    ├── user-service.yaml
    ├── payment-service.yaml
    ├── notification-service.yaml
    └── order-service.yaml
```

## Troubleshooting

### Spell Not Deployed

**Symptoms:** Spell file exists but ArgoCD Application not created.

**Check:**

```bash
# 1. Verify chapter listed in book index
cat bookrack/my-book/index.yaml | yq '.chapters'

# 2. Verify spell in correct chapter directory
ls bookrack/my-book/<chapter>/

# 3. Check spell has valid name
yq '.name' bookrack/my-book/<chapter>/spell.yaml

# 4. Template librarian to debug
helm template my-book librarian --set name=my-book --debug
```

**Common Causes:**
- Chapter not in `chapters` array
- Spell file is `index.yaml` (reserved name)
- Invalid YAML syntax
- Missing `name` field

### Values Not Merging

**Symptoms:** Book/chapter values not appearing in spell.

**Debug:**

```bash
# Check merge hierarchy
helm template my-book librarian --set name=my-book --debug \
  | yq '.spec.sources[0].helm.values'

# Compare:
# 1. Book index.yaml
# 2. Book defaultTrinket.values
# 3. Chapter index.yaml
# 4. Chapter defaultTrinket.values
# 5. Spell values
```

**Common Causes:**
- Field path mismatch (e.g., `image` vs `images`)
- Arrays replace instead of merge
- Typo in field name

### Lexicon Not Available

**Symptoms:** Lexicon entries not found by glyphs.

**Check:**

```bash
# 1. Verify _lexicon files
ls bookrack/my-book/_lexicon/

# 2. Check lexicon merged to appendix
helm template my-book librarian --set name=my-book --debug \
  | yq '.spec.sources[0].helm.values.lexicon'

# 3. Verify selector matches labels
# Glyph selector: {environment: production}
# Lexicon labels: {environment: production}  # Must match
```

**Common Causes:**
- Typo in `_lexicon` directory name (must start with underscore)
- Invalid YAML in lexicon files
- Selector doesn't match lexicon labels

### Chapter Override Not Working

**Symptoms:** Chapter index.yaml values not overriding book values.

**Debug:**

```bash
# Check chapter index.yaml exists
cat bookrack/my-book/<chapter>/index.yaml

# Verify merge behavior
# Book: replicas: 1
# Chapter: replicas: 3
# Expected: 3

# Check field path matches
yq '.replicas' bookrack/my-book/index.yaml
yq '.defaultTrinket.values.replicas' bookrack/my-book/<chapter>/index.yaml
```

**Common Causes:**
- Different field paths in book vs chapter
- Chapter value in wrong location (should be in `defaultTrinket.values` or root)
- Expecting array merge (arrays replace, not merge)

## Related Documentation

- [LIBRARIAN.md](LIBRARIAN.md) - ArgoCD orchestration
- [HIERARCHY_SYSTEMS.md](HIERARCHY_SYSTEMS.md) - Values merging details
- [LEXICON.md](LEXICON.md) - Infrastructure registry
- [README.md](../README.md) - Architecture overview

## Examples

See `bookrack/example-tdd-book/` for comprehensive example:

- `index.yaml` - Book configuration with all features
- `_lexicon/infrastructure.yaml` - Infrastructure registry
- `infrastructure/` - Infrastructure spells
- `applications/` - Application spells
- Multiple deployment strategies demonstrated
