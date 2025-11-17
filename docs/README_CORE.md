# Core Components Overview

This page provides a high-level overview of kast-system's core components and how they interact.

## Architecture

kast-system consists of four main components that work together to provide a complete GitOps deployment framework:

```
┌─────────────────────────────────────────────────────────┐
│                    BOOKRACK                             │
│           (Configuration Management)                    │
│  Book → Chapters → Spells                               │
└────────────────┬────────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────────────────────┐
│                   LIBRARIAN                             │
│         (ArgoCD App of Apps Orchestrator)               │
│  Reads books → Generates ArgoCD Applications            │
└────────────────┬────────────────────────────────────────┘
                 ↓
        ┌────────┴────────┐
        ↓                 ↓
┌──────────────┐    ┌──────────────┐
│    SUMMON    │    │   KASTER     │
│   (Workload) │    │  (Glyphs)    │
└──────────────┘    └──────────────┘
        │                 │
        └────────┬────────┘
                 ↓
┌─────────────────────────────────────────────────────────┐
│              KUBERNETES RESOURCES                       │
│  Deployments, Services, Secrets, VirtualServices, etc.  │
└─────────────────────────────────────────────────────────┘
```

## Component Responsibilities

### [Bookrack](BOOKRACK.md) - Configuration Management

**Purpose:** Organize deployment configurations using a book/chapter/spell hierarchy

**Key Concepts:**
- **Book**: Deployment context (environment, team, cluster)
- **Chapter**: Logical grouping (infrastructure, services, monitoring)
- **Spell**: Individual YAML file = 1 ArgoCD Application

**Structure:**
```
bookrack/
├── my-book/
│   ├── index.yaml           # Book metadata, trinkets
│   ├── _lexicon/            # Infrastructure registry
│   ├── infrastructure/      # Chapter
│   │   └── vault.yaml       # Spell
│   └── services/            # Chapter
│       └── api.yaml         # Spell
```

**Responsibilities:**
- Configuration hierarchy (book < chapter < spell)
- Lexicon (infrastructure registry)
- Chart version management
- Default values

---

### [Librarian](LIBRARIAN.md) - ArgoCD Orchestrator

**Purpose:** Transform bookrack structure into ArgoCD Applications

**Process:**
1. **Read** books from bookrack/
2. **Consolidate** appendix (shared configuration)
3. **Detect** deployment strategy (simple/infrastructure/multi-source)
4. **Generate** ArgoCD Application resources

**Deployment Strategies:**
- **Simple**: Has `name`, `image` → Uses Summon
- **Infrastructure**: Has `glyphs` → Uses Kaster
- **Multi-source**: Has `runes` → Multiple charts
- **External**: Has `chart`, `repository` → Direct chart

**Output:** ArgoCD Application with multi-source configuration

---

### [Summon](SUMMON.md) - Workload Chart

**Purpose:** Deploy containerized workloads with comprehensive Kubernetes features

**Workload Types:**
- **Deployment**: Stateless applications
- **StatefulSet**: Stateful with persistent identity
- **Job**: One-time batch jobs
- **CronJob**: Scheduled jobs
- **DaemonSet**: One pod per node

**Features:**
- Container configuration (image, env, ports)
- Storage (PVC, ConfigMap, Secret volumes)
- Networking (Service, Ingress)
- Health (probes)
- Scaling (HPA, replicas)
- Security (ServiceAccount, SecurityContext)

**Example:**
```yaml
# Simple deployment spell
name: my-app
image:
  repository: nginx
  tag: alpine
service:
  enabled: true
  port: 80
```

---

### [Kaster](KASTER.md) - Glyph Orchestrator

**Purpose:** Coordinate glyphs to generate infrastructure resources

**How it works:**
1. Receives glyph definitions in `values.glyphs`
2. For each glyph, includes the appropriate template
3. Passes context and definition to glyph
4. Glyph renders Kubernetes resources

**Example:**
```yaml
# Infrastructure spell
glyphs:
  vault:
    my-secret:
      type: secret
      path: secret/data/my-app
  istio:
    my-service:
      type: virtualService
      selector:
        access: external
```

**Generated Resources:**
- VaultSecret (via vault glyph)
- VirtualService (via istio glyph)
- Certificate (via certManager glyph)
- etc.

---

## Data Flow

### Simple Application Deployment

```
1. Create spell in bookrack/
   my-book/services/api.yaml:
     name: api
     image: myapp:v1

2. Librarian reads spell
   - Detects: simple application (has name + image)
   - Strategy: Use Summon chart

3. Generates ArgoCD Application
   - Source: summon chart
   - Values: from spell

4. ArgoCD syncs
   - Pulls summon chart
   - Renders with values
   - Applies to cluster

5. Summon generates
   - Deployment (api)
   - Service (api)
   - ServiceAccount (api)
```

### Infrastructure Deployment

```
1. Create spell with glyphs
   my-book/infrastructure/vault.yaml:
     glyphs:
       vault:
         my-secret:
           type: secret
           path: secret/data/app

2. Librarian reads spell
   - Detects: infrastructure (has glyphs)
   - Strategy: Use Kaster chart

3. Generates ArgoCD Application
   - Source: kaster chart
   - Values: glyph definitions

4. ArgoCD syncs
   - Pulls kaster chart
   - Renders with glyph definitions

5. Kaster orchestrates
   - Iterates glyphs
   - Invokes vault glyph template
   - Queries lexicon for vault server

6. Vault glyph generates
   - VaultSecret custom resource
```

### Multi-Source Deployment

```
1. Create spell with workload + glyphs
   my-book/services/api.yaml:
     name: api
     image: myapp:v1
     glyphs:
       vault:
         db-creds:
           type: secret

2. Librarian reads spell
   - Detects: workload + infrastructure
   - Strategy: Multi-source (summon + kaster)

3. Generates ArgoCD Application
   - Source 1: summon (workload)
   - Source 2: kaster (glyphs)

4. ArgoCD syncs both sources
   - Renders summon → Deployment
   - Renders kaster → VaultSecret

5. Resources deployed
   - Deployment references VaultSecret
   - All resources in same namespace
```

## Component Relationships

### Lexicon + Runic Indexer

**Shared system** across all components:

- **Lexicon**: Infrastructure registry in `Values.lexicon`
- **Runic Indexer**: Query engine with label matching
- **Used by**: Glyphs to discover infrastructure dynamically

**Example:**
```yaml
# In bookrack/my-book/_lexicon/
lexicon:
  - name: prod-vault
    type: vault
    url: https://vault.prod.svc
    labels:
      environment: production
      default: book

# In spell with istio glyph
glyphs:
  istio:
    my-service:
      selector:
        access: external
        environment: production
      # Runic indexer finds matching gateway from lexicon
```

### Configuration Hierarchy

**Bookrack** implements hierarchy where specific overrides general:

```
Book defaults
  ↓ (merged with)
Chapter overrides
  ↓ (merged with)
Spell configuration
  = Final values
```

**Applied by**: Librarian when generating Applications

### Template Reusability

**Glyphs** provide reusable templates used by:

- **Kaster**: Orchestrates multiple glyphs
- **Summon**: Can reference glyph-generated resources
- **Trinkets**: Wrap glyphs with opinionated patterns

## Next Steps

Dive deeper into each component:

- [Bookrack Details](BOOKRACK.md) - Configuration patterns
- [Librarian Details](LIBRARIAN.md) - App generation
- [Summon Details](SUMMON.md) - Workload features
- [Kaster Details](KASTER.md) - Glyph orchestration
- [Glyphs Overview](GLYPHS.md) - Template system

Or explore specific use cases:

- [Deploy simple app](GETTING_STARTED.md)
- [Infrastructure integration](GLYPHS.md)
- [Multiple applications](BOOKRACK.md)
