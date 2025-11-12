# Librarian

ArgoCD App-of-Apps orchestrator for kast-system. Librarian transforms book/chapter/spell structure into ArgoCD Applications with automatic multi-source detection.

## Overview

Librarian is a Helm chart that:
- Reads book configuration from `bookrack/`
- Generates ArgoCD `Application` resources
- Coordinates multi-source deployments (trinkets)
- Propagates context (lexicon, cards, book/chapter metadata)
- Manages deployment targeting (clusters, namespaces)

**Pattern:** App of Apps (ArgoCD ApplicationSet alternative)

**Location:** `librarian/` chart

## Architecture

```
┌─────────────────────────────────────────────────────┐
│ Librarian Helm Chart                                │
│ - Reads bookrack/ files                             │
│ - Generates ArgoCD Applications                     │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│ Book Structure (bookrack/)                          │
│ ├─ index.yaml (book config)                         │
│ ├─ chapter1/                                        │
│ │  ├─ index.yaml (chapter config)                   │
│ │  ├─ spell1.yaml (application)                     │
│ │  └─ spell2.yaml (application)                     │
│ └─ _lexicon/ (infrastructure registry)              │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│ ArgoCD Applications                                 │
│ - One Application per spell                         │
│ - Multi-source for trinkets                         │
│ - Sync policies configured                          │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│ Kubernetes Resources                                │
│ - Deployed via Helm charts                          │
│ - Managed by ArgoCD                                 │
└─────────────────────────────────────────────────────┘
```

## Book Structure

### Directory Layout

```
bookrack/
├── <book-name>/
│   ├── index.yaml               # Book configuration
│   ├── _lexicon/                # Infrastructure registry
│   │   ├── infrastructure.yaml  # Lexicon entries
│   │   └── clusters.yaml        # Cluster definitions
│   ├── <chapter-name>/
│   │   ├── index.yaml           # Chapter configuration
│   │   ├── spell1.yaml          # Application definition
│   │   ├── spell2.yaml          # Application definition
│   │   └── spell3.yaml          # Application definition
│   └── <chapter-name-2>/
│       ├── index.yaml
│       └── ...
```

### Book index.yaml

**Purpose:** Define book-wide configuration.

**Structure:**

```yaml
name: my-book
description: "Book description"

# Chapters define deployment sequence
chapters:
  - infrastructure  # Deploy first
  - applications   # Deploy second

# ArgoCD configuration
projectName: my-project
argocdNamespace: argocd

# Global app parameters (inherited by all spells)
appParams:
  cleanDefinition: false
  noHelm: false
  disableAutoSync: false
  skipCrds: false
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
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

# Default trinket (summon) - used when spell has no chart/path
defaultTrinket:
  repository: https://github.com/kast-spells/kast-system.git
  path: ./charts/summon
  revision: v1.0.0

# Trinkets registry (for multi-source detection)
trinkets:
  kaster:
    key: glyphs          # Trigger: spell has "glyphs:" field
    repository: https://github.com/kast-spells/kast-system.git
    path: ./charts/kaster
    revision: v1.0.0
  tarot:
    key: tarot           # Trigger: spell has "tarot:" field
    repository: https://github.com/kast-spells/kast-system.git
    path: ./charts/trinkets/tarot
    revision: v1.0.0
  microspell:
    key: microspell      # Trigger: spell has "microspell:" field
    repository: https://github.com/kast-spells/kast-system.git
    path: ./charts/trinkets/microspell
    revision: v1.0.0

# Default cluster targeting
clusterSelector:
  environment: production

# Global appendix (lexicon, cards) - merged with chapter/spell appendix
appendix:
  lexicon:
    - name: production-vault
      type: vault
      url: https://vault.production.svc:8200
      labels:
        environment: production
```

**Key Fields:**

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Book name (defaults to release name) |
| `chapters` | array | Ordered list of chapter names |
| `projectName` | string | ArgoCD project name |
| `argocdNamespace` | string | ArgoCD namespace (default: argocd) |
| `appParams` | object | Global app parameters |
| `defaultTrinket` | object | Default chart (summon) |
| `trinkets` | map | Trinket registry for multi-source |
| `clusterSelector` | map | Default cluster targeting |
| `appendix` | object | Global lexicon/cards |

### Chapter index.yaml

**Purpose:** Override book configuration for specific chapter.

**Structure:**

```yaml
name: production
description: "Production environment"

# Override book appParams
appParams:
  disableAutoSync: true  # Manual sync for production

# Override defaultTrinket
defaultTrinket:
  revision: v1.2.0  # Use newer version in production

# Chapter-specific trinkets
trinkets:
  kaster:
    revision: v1.2.0  # Override book trinket revision

# Chapter cluster targeting
clusterSelector:
  environment: production
  region: us-west

# Chapter-specific appendix
appendix:
  lexicon:
    - name: production-db
      type: database
      host: prod-db.example.com
      labels:
        environment: production
        default: chapter

# localAppendix - NOT merged to globalAppendix, only available in this chapter
localAppendix:
  lexicon:
    - name: staging-only-resource
      type: service
      url: http://staging.example.com
```

**Hierarchy:**

```
Book appParams → Chapter appParams → Spell appParams
Book defaultTrinket → Chapter defaultTrinket
Book trinkets → Chapter trinkets (merged by key)
Book appendix → Chapter appendix → Spell appendix (global merge)
Chapter localAppendix (chapter-only, not propagated to book)
```

### Spell YAML

**Purpose:** Define single application deployment.

**Structure:**

```yaml
name: my-app
namespace: default  # Optional, defaults to spell name

# Spell values (passed to chart)
image:
  repository: nginx
  tag: alpine

service:
  enabled: true
  port: 80

# Infrastructure integration
glyphs:
  vault:
    - type: secret
      name: app-secret
  istio:
    - type: virtualService
      name: my-app-vs

# Additional charts
runes:
  - name: postgresql
    repository: https://charts.bitnami.com/bitnami
    chart: postgresql
    revision: 12.8.0

# Spell-specific appParams
appParams:
  syncPolicy:
    automated:
      prune: false  # Override for this spell

# Spell-specific appendix
appendix:
  lexicon:
    - name: app-specific-resource
      type: service
```

**Spell Types:** See [Deployment Strategies](#deployment-strategies)

## Deployment Strategies

Librarian supports 4 spell deployment patterns:

### 1. Simple (defaultTrinket)

**Pattern:** Spell has NO `chart`, `path`, or `trinket` keys. Uses `defaultTrinket` (typically summon).

**Example:**

```yaml
# Book index.yaml
defaultTrinket:
  repository: https://github.com/kast-spells/kast-system.git
  path: ./charts/summon
  revision: v1.0.0

# spell.yaml
name: simple-app
image:
  repository: nginx
  tag: alpine
service:
  enabled: true
```

**Generated Application:**

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: simple-app
spec:
  sources:
    - repoURL: https://github.com/kast-spells/kast-system.git
      path: ./charts/summon
      targetRevision: v1.0.0
      helm:
        values: |
          name: simple-app
          image:
            repository: nginx
            tag: alpine
          service:
            enabled: true
          spellbook:
            name: my-book
          chapter:
            name: applications
          lexicon:
            # ... merged lexicon
```

**Use case:** Standard application deployments.

### 2. Infrastructure (Glyphs via Kaster)

**Pattern:** Spell has `glyphs:` field. Librarian detects this and adds kaster chart as second source.

**Example:**

```yaml
# Book index.yaml
trinkets:
  kaster:
    key: glyphs  # Trigger on "glyphs:" field
    repository: https://github.com/kast-spells/kast-system.git
    path: ./charts/kaster
    revision: v1.0.0

# spell.yaml
name: vault-setup
glyphs:
  vault:
    - type: prolicy
      name: app-policy
      serviceAccount: my-app
    - type: secret
      name: database-creds
      keys: [username, password]
```

**Generated Application:**

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: vault-setup
spec:
  sources:
    # Source 1: defaultTrinket (summon) - ALWAYS present
    - repoURL: https://github.com/kast-spells/kast-system.git
      path: ./charts/summon
      targetRevision: v1.0.0
      helm:
        values: |
          name: vault-setup
          spellbook: {...}
          chapter: {...}
          lexicon: [...]

    # Source 2: kaster (detected via "glyphs:" key)
    - repoURL: https://github.com/kast-spells/kast-system.git
      path: ./charts/kaster
      targetRevision: v1.0.0
      helm:
        values: |
          glyphs:
            vault:
              - type: prolicy
                name: app-policy
          spellbook: {...}
          chapter: {...}
          lexicon: [...]
```

**Use case:** Infrastructure resources (vault policies, istio routes, certificates).

### 3. Multi-Source (Multiple Trinkets)

**Pattern:** Spell has multiple trinket keys (e.g., `glyphs:` + `tarot:`). Librarian adds all matching trinkets as sources.

**Example:**

```yaml
# Book index.yaml
trinkets:
  kaster:
    key: glyphs
    repository: https://github.com/kast-spells/kast-system.git
    path: ./charts/kaster
    revision: v1.0.0
  tarot:
    key: tarot
    repository: https://github.com/kast-spells/kast-system.git
    path: ./charts/trinkets/tarot
    revision: v1.0.0

# spell.yaml
name: complex-app
image:
  repository: app
  tag: latest

# Infrastructure glyphs
glyphs:
  vault:
    - type: secret
      name: app-secret
  istio:
    - type: virtualService
      name: app-vs

# CI/CD workflow
tarot:
  reading:
    build:
      selectors: {stage: build}
      position: action
    deploy:
      selectors: {stage: deploy}
      position: outcome
```

**Generated Application:**

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: complex-app
spec:
  sources:
    # Source 1: defaultTrinket (summon)
    - repoURL: https://github.com/kast-spells/kast-system.git
      path: ./charts/summon
      targetRevision: v1.0.0
      helm:
        values: |
          name: complex-app
          image: {...}
          spellbook: {...}
          chapter: {...}
          lexicon: [...]

    # Source 2: kaster (glyphs)
    - repoURL: https://github.com/kast-spells/kast-system.git
      path: ./charts/kaster
      targetRevision: v1.0.0
      helm:
        values: |
          glyphs:
            vault: [...]
            istio: [...]
          spellbook: {...}
          chapter: {...}
          lexicon: [...]

    # Source 3: tarot (workflows)
    - repoURL: https://github.com/kast-spells/kast-system.git
      path: ./charts/trinkets/tarot
      targetRevision: v1.0.0
      helm:
        values: |
          tarot:
            reading: {...}
          spellbook: {...}
          chapter: {...}
          lexicon: [...]
          cards: [...]  # Cards passed to tarot
```

**Use case:** Complex applications with infrastructure + CI/CD.

### 4. External Chart (Direct)

**Pattern:** Spell specifies `chart:` or `path:` explicitly. Librarian uses that chart directly instead of defaultTrinket.

**Example:**

```yaml
# spell.yaml
name: external-app
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

# Can still use trinkets
glyphs:
  vault:
    - type: secret
      name: redis-password
```

**Generated Application:**

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: external-app
spec:
  sources:
    # Source 1: External chart (specified explicitly)
    - repoURL: https://charts.bitnami.com/bitnami
      chart: redis
      targetRevision: 17.11.3
      helm:
        values: |
          auth:
            enabled: false
          master:
            persistence:
              enabled: true
              size: 8Gi
          # bookData flag controls if context passed

    # Source 2: kaster (if glyphs present)
    - repoURL: https://github.com/kast-spells/kast-system.git
      path: ./charts/kaster
      targetRevision: v1.0.0
      helm:
        values: |
          glyphs:
            vault: [...]
```

**Use case:** External Helm charts (bitnami, prometheus, etc.).

**Note:** Set `appParams.bookData: true` to pass spellbook/chapter/lexicon context to external charts.

## Runes (Additional Charts)

**Runes** add extra Helm charts to a spell (additional sources).

**Example:**

```yaml
name: payment-service

# Main application (via summon)
image:
  repository: payment-service
  tag: v1.0.0

# Additional services via runes
runes:
  - name: redis-cache
    repository: https://charts.bitnami.com/bitnami
    chart: redis
    revision: 17.11.3
    values:
      auth:
        enabled: false

  - name: postgresql-db
    repository: https://charts.bitnami.com/bitnami
    chart: postgresql
    revision: 12.8.0
    values:
      auth:
        postgresPassword: dev-password
        database: payments

  # Rune with custom path
  - name: monitoring
    repository: https://github.com/company/charts.git
    path: ./monitoring
    revision: main
    values:
      app: payment-service
```

**Generated Application:**

```yaml
sources:
  # Source 1: defaultTrinket (payment-service)
  - repoURL: https://github.com/kast-spells/kast-system.git
    path: ./charts/summon
    ...

  # Source 2: rune (redis-cache)
  - repoURL: https://charts.bitnami.com/bitnami
    chart: redis
    targetRevision: 17.11.3
    helm:
      values: |
        auth:
          enabled: false

  # Source 3: rune (postgresql-db)
  - repoURL: https://charts.bitnami.com/bitnami
    chart: postgresql
    targetRevision: 12.8.0
    helm:
      values: |
        auth:
          postgresPassword: dev-password
          database: payments

  # Source 4: rune (monitoring)
  - repoURL: https://github.com/company/charts.git
    path: ./monitoring
    targetRevision: main
    helm:
      values: |
        app: payment-service
```

**Use case:** Deploy application with dependencies (databases, caches, sidecars).

**Rune appParams:**

```yaml
runes:
  - name: custom-chart
    repository: https://example.com/charts.git
    path: ./custom
    revision: v1.0.0
    appParams:
      noHelm: false        # Enable Helm rendering
      skipCrds: true       # Skip CRD installation
      bookData: true       # Pass book/chapter/lexicon context
      noOverite: false     # Don't merge appParams to spell appParams
      ignoreDifferences:   # Ignore specific diffs
        - group: apps
          kind: Deployment
          jsonPointers:
            - /spec/replicas
```

## Appendix System

**Appendix** propagates context (lexicon, cards) across book → chapter → spell hierarchy.

### Global Appendix

**Collected from:**
1. Book `appendix`
2. All chapter `appendix`
3. All spell `appendix`

**Merged using:** Deep merge (most specific wins)

**Passed to:** All charts as `lexicon:` and `cards:` values

**Example:**

```yaml
# Book index.yaml
appendix:
  lexicon:
    - name: production-vault
      type: vault
      url: https://vault.prod.svc:8200
      labels:
        default: book

# Chapter applications/index.yaml
appendix:
  lexicon:
    - name: staging-vault
      type: vault
      url: https://vault.staging.svc:8200
      labels:
        default: chapter
      chapter: applications

# Spell applications/api-service.yaml
appendix:
  lexicon:
    - name: api-db
      type: database
      host: api-db.example.com
      labels:
        app: api-service

# Result: All three lexicon entries available in api-service spell
```

**Global appendix available to:** ALL spells in ALL chapters

### Local Appendix

**Scope:** Chapter-only (not propagated to global)

**Use case:** Chapter-specific resources not needed by other chapters

**Example:**

```yaml
# Chapter staging/index.yaml
localAppendix:
  lexicon:
    - name: staging-only-service
      type: service
      url: http://staging.example.com
      labels:
        environment: staging

# Available in staging chapter spells ONLY
# NOT available in production chapter
```

**Hierarchy:**

```
Global Appendix = Book.appendix + Chapter.appendix + Spell.appendix
Chapter Appendix = Global Appendix + Chapter.localAppendix
Spell Appendix = Chapter Appendix + Spell.localAppendix
```

### Appendix Merge Behavior

**Objects:** Deep merge

```yaml
# Book appendix
lexicon:
  - name: vault
    url: https://vault.svc:8200
    labels:
      default: book

# Spell appendix
lexicon:
  - name: vault
    skipVerify: true  # Merges with book definition

# Result:
lexicon:
  - name: vault
    url: https://vault.svc:8200
    skipVerify: true
    labels:
      default: book
```

**Arrays:** Concatenate

```yaml
# Book appendix
lexicon:
  - name: vault-1

# Spell appendix
lexicon:
  - name: vault-2

# Result:
lexicon:
  - name: vault-1
  - name: vault-2
```

## Values Hierarchy

Values merge from book → chapter → spell:

```
Book defaultTrinket.values
  ↓
Book index.yaml (implicit values)
  ↓
Chapter defaultTrinket.values
  ↓
Chapter index.yaml (implicit values)
  ↓
Spell definition
```

**Example:**

```yaml
# Book index.yaml
defaultTrinket:
  values:
    image:
      pullPolicy: Always
    resources:
      limits:
        memory: 256Mi

# Chapter production/index.yaml
defaultTrinket:
  values:
    replicas: 3  # Override for production
    resources:
      limits:
        memory: 512Mi  # Override memory

# Spell production/api.yaml
name: api
image:
  repository: api-service
  tag: v1.0.0
replicas: 5  # Override chapter replicas

# Result (final values passed to summon):
name: api
image:
  repository: api-service
  tag: v1.0.0
  pullPolicy: Always  # From book
replicas: 5  # From spell (most specific)
resources:
  limits:
    memory: 512Mi  # From chapter
```

## Cluster Targeting

Librarian supports multi-cluster deployments via `clusterSelector` and lexicon.

### Cluster Selection

**Pattern:**

```yaml
# Lexicon (infrastructure.yaml)
lexicon:
  - name: production-cluster
    type: k8s-cluster
    clusterURL: https://prod-k8s.example.com
    labels:
      environment: production
      region: us-west

  - name: staging-cluster
    type: k8s-cluster
    clusterURL: https://staging-k8s.example.com
    labels:
      environment: staging
      region: us-west

# Book index.yaml
clusterSelector:
  environment: production  # Default for all spells

# Spell (override)
name: my-app
clusterSelector:
  environment: staging  # Deploy to staging cluster
```

**Cluster Resolution:**

```
Spell clusterSelector (if present)
  ↓
Chapter clusterSelector (if present)
  ↓
Book clusterSelector
  ↓
Default: https://kubernetes.default.svc (local cluster)
```

**Generated Application:**

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
spec:
  destination:
    server: https://staging-k8s.example.com  # Resolved via runicIndexer
    namespace: my-app
```

### Multi-Cluster Pattern

**Use case:** Deploy same spell to multiple clusters.

**Approach:** Create separate chapter per cluster

```yaml
# Book index.yaml
chapters:
  - production-us-west
  - production-eu-west

# Chapter production-us-west/index.yaml
clusterSelector:
  environment: production
  region: us-west

# Chapter production-eu-west/index.yaml
clusterSelector:
  environment: production
  region: eu-west

# Spell (same in both chapters)
name: api-service
image:
  repository: api
  tag: v1.0.0
```

**Result:** Two Applications created, one per cluster.

## ArgoCD Configuration

### App Parameters

Librarian translates `appParams` to ArgoCD Application spec:

**Structure:**

```yaml
appParams:
  # ArgoCD configuration
  cleanDefinition: false
  noHelm: false
  disableAutoSync: false
  skipCrds: false
  bookData: false          # Pass book/chapter/lexicon to charts

  # Sync policy
  syncPolicy:
    managedNamespaceMetadata:
      labels:
        managed-by: kast
      annotations:
        owner: platform-team
    automated:
      prune: true          # Auto-delete removed resources
      selfHeal: true       # Auto-sync on drift
      allowEmpty: false    # Prevent deleting all resources
    syncOptions:
      - CreateNamespace=true
      - PrunePropagationPolicy=foreground
      - PruneLast=true
      - ServerSideApply=true
    retry:
      limit: 2
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m

  # Ignore differences
  ignoreDifferences:
    - group: apps
      kind: Deployment
      jsonPointers:
        - /spec/replicas  # Ignore HPA-controlled replicas

  # Finalizers
  customFinalizers:
    - resources-finalizer.argocd.argoproj.io

  # Annotations
  annotations:
    notifications.argoproj.io/subscribe.on-sync-succeeded.slack: platform-alerts
```

**Mapping:**

| appParams Field | ArgoCD Application Field |
|----------------|--------------------------|
| `syncPolicy.automated` | `spec.syncPolicy.automated` |
| `syncPolicy.syncOptions` | `spec.syncPolicy.syncOptions` |
| `syncPolicy.retry` | `spec.syncPolicy.retry` |
| `syncPolicy.managedNamespaceMetadata` | `spec.syncPolicy.managedNamespaceMetadata` |
| `ignoreDifferences` | `spec.ignoreDifferences` |
| `customFinalizers` | `metadata.finalizers` |
| `annotations` | `metadata.annotations` |

### Sync Policies

**Automated sync:**

```yaml
appParams:
  syncPolicy:
    automated:
      prune: true      # Auto-delete removed resources
      selfHeal: true   # Auto-sync on cluster drift
```

**Manual sync:**

```yaml
appParams:
  disableAutoSync: true
```

**Sync options:**

```yaml
appParams:
  syncPolicy:
    syncOptions:
      - CreateNamespace=true            # Auto-create namespace
      - PrunePropagationPolicy=foreground  # Delete order
      - PruneLast=true                  # Prune after sync
      - ServerSideApply=true            # Use SSA
      - Validate=false                  # Skip validation
      - ApplyOutOfSyncOnly=true         # Only apply changed resources
```

### Ignore Differences

Ignore specific fields during sync:

```yaml
appParams:
  ignoreDifferences:
    # Ignore HPA-controlled replicas
    - group: apps
      kind: Deployment
      jsonPointers:
        - /spec/replicas

    # Ignore all metadata
    - group: "*"
      kind: "*"
      jsonPointers:
        - /metadata/labels
        - /metadata/annotations

    # Ignore entire resource
    - group: batch
      kind: Job
      name: one-time-migration
```

**Rune ignoreDifferences:**

```yaml
runes:
  - name: custom-chart
    repository: https://example.com
    chart: custom
    revision: v1.0.0
    appParams:
      ignoreDifferences:
        - group: apps
          kind: StatefulSet
          jsonPointers:
            - /spec/volumeClaimTemplates
```

**Result:** Merged with spell ignoreDifferences.

## Deploying Books

### Prerequisites

1. **ArgoCD installed** in cluster
2. **Librarian chart** available
3. **Book structure** in `bookrack/`

### Deployment

```bash
# Deploy single book
helm install my-book librarian --set name=my-book

# Deploy with custom ArgoCD namespace
helm install my-book librarian --set name=my-book --set argocdNamespace=gitops

# Deploy with custom project
helm install my-book librarian \
  --set name=my-book \
  --set projectName=custom-project

# Deploy without AppProject
helm install my-book librarian \
  --set name=my-book \
  --set projectDisabled=true

# Deploy from external repository
helm install my-book oci://registry.example.com/charts/librarian \
  --set name=my-book
```

### Multi-Book Deployment

Deploy multiple books to same ArgoCD:

```bash
# Book 1: infrastructure
helm install infrastructure librarian --set name=infrastructure

# Book 2: applications
helm install applications librarian --set name=applications

# Book 3: platform
helm install platform librarian --set name=platform
```

**Result:** Separate ArgoCD Applications per book.

## Troubleshooting

### Application Not Created

**Symptoms:** Spell file exists but ArgoCD Application not created.

**Check:**

```bash
# Check librarian deployment
helm template my-book librarian --debug

# Verify spell file matches chapter in book index
cat bookrack/my-book/index.yaml | yq '.chapters'
ls bookrack/my-book/

# Check spell has valid YAML
yq eval bookrack/my-book/chapter/spell.yaml
```

**Common causes:**
- Spell not in chapter listed in `chapters` array
- Invalid YAML syntax
- Spell file is `index.yaml` (skipped)

### Multi-Source Not Detected

**Symptoms:** Spell has `glyphs:` but kaster not added as source.

**Check:**

```bash
# Verify trinket registry
helm template my-book librarian --debug | grep -A 10 "trinkets:"

# Check trinket key matches spell field
# Trinket: key: glyphs
# Spell: glyphs: {...}  # Must match exactly
```

**Common causes:**
- Trinket not defined in book or chapter `trinkets`
- Trinket `key` doesn't match spell field
- Typo in trinket key or spell field

### Values Not Merging

**Symptoms:** Book/chapter values not appearing in spell.

**Check:**

```bash
# Template and inspect final values
helm template my-book librarian --debug | yq '.spec.sources[0].helm.values'

# Check merge order
# Book defaultTrinket.values
# Chapter defaultTrinket.values
# Spell definition

# Verify field paths match
# Book: image.pullPolicy
# Spell: image.pullPolicy  # Must match exactly
```

**Common causes:**
- Field path mismatch (e.g., `image` vs `images`)
- Arrays replace instead of merge
- Expecting merge behavior on primitives

### Cluster Not Resolved

**Symptoms:** Application deploys to wrong cluster or default.

**Check:**

```bash
# Verify lexicon has cluster
helm template my-book librarian --debug | grep -A 10 "k8s-cluster"

# Check clusterSelector matches lexicon labels
# Spell clusterSelector: {environment: production}
# Lexicon labels: {environment: production}

# Verify runic indexer query
# Should find exactly one cluster
```

**Common causes:**
- No matching cluster in lexicon
- Multiple clusters match selector (uses first)
- clusterSelector typo

### Sync Failing

**Symptoms:** ArgoCD Application syncing but failing.

**Check:**

```bash
# Check ArgoCD Application status
kubectl get application -n argocd my-app -o yaml

# Check sync errors
argocd app get my-app

# Check Helm rendering
argocd app manifests my-app

# Common issues:
# - Invalid chart values
# - Missing CRDs (add skipCrds: false)
# - Resource conflicts
# - Missing namespace
```

### Appendix Not Propagating

**Symptoms:** Lexicon entries not available in spell.

**Check:**

```bash
# Template and inspect lexicon
helm template my-book librarian --debug | yq '.spec.sources[0].helm.values' | yq '.lexicon'

# Verify appendix merge
# Book appendix → Chapter appendix → Spell appendix

# Check localAppendix scope
# Chapter localAppendix only available in that chapter
```

## Best Practices

### Book Organization

**Organize by lifecycle:**

```yaml
chapters:
  - infrastructure  # CRDs, operators, vault, istio
  - platform       # Shared services (databases, caches)
  - applications   # Business applications
```

**Reason:** Infrastructure must be deployed before applications depend on it.

### Trinket Registry

**Define trinkets at book level:**

```yaml
# Book index.yaml
trinkets:
  kaster:
    key: glyphs
    repository: https://github.com/kast-spells/kast-system.git
    path: ./charts/kaster
    revision: v1.0.0
```

**Override at chapter level only when needed:**

```yaml
# Chapter production/index.yaml
trinkets:
  kaster:
    revision: v1.2.0  # Use newer version in production
```

### App Parameters

**Set conservative defaults at book level:**

```yaml
# Book index.yaml
appParams:
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    retry:
      limit: 2
```

**Override for specific environments:**

```yaml
# Chapter production/index.yaml
appParams:
  disableAutoSync: true  # Manual sync in production
  syncPolicy:
    retry:
      limit: 5  # More retries in production
```

### Appendix vs LocalAppendix

**Use appendix for:**
- Organization-wide infrastructure (vault, gateways)
- Shared resources across chapters

**Use localAppendix for:**
- Environment-specific resources
- Chapter-only infrastructure

```yaml
# Book appendix - available everywhere
appendix:
  lexicon:
    - name: organization-vault
      type: vault

# Chapter localAppendix - chapter-only
localAppendix:
  lexicon:
    - name: staging-debug-tools
      type: service
```

### Rune Naming

**Use descriptive names:**

```yaml
# Good
runes:
  - name: postgresql-primary
  - name: redis-cache
  - name: prometheus-monitoring

# Avoid
runes:
  - name: db
  - name: cache
```

### Cluster Targeting

**Use labels for flexibility:**

```yaml
# Lexicon
lexicon:
  - name: prod-us-west
    type: k8s-cluster
    labels:
      environment: production
      region: us-west
      size: large

# Spell - target by attributes
clusterSelector:
  environment: production
  size: large
```

## Related Documentation

- [BOOKRACK.md](BOOKRACK.md) - Book/chapter/spell structure
- [HIERARCHY_SYSTEMS.md](HIERARCHY_SYSTEMS.md) - Values merging patterns
- [LEXICON.md](LEXICON.md) - Infrastructure registry
- [README.md](../README.md) - Architecture overview
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/) - ArgoCD concepts

## Examples

See `bookrack/example-tdd-book/` for comprehensive examples:

- `infrastructure/` - Infrastructure glyphs (vault, istio, cert-manager)
- `applications/` - Application deployments with runes
- `index.yaml` - Book configuration
- `_lexicon/` - Infrastructure registry
