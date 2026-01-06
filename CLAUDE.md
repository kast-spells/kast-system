# CLAUDE.md

TDD Kubernetes deployment framework using Helm charts with reusable template components called "glyphs".

## Quick Reference

### Core Concepts
- **Glyphs**: Reusable Helm template libraries (vault, istio, certManager, etc.)
- **Summon**: Workload chart (Deployment, StatefulSet, Job, CronJob, DaemonSet)
- **Kaster**: Glyph orchestrator
- **Librarian**: Transforms bookrack/ into ArgoCD Applications
- **Books**: Config hierarchy: Book → Chapters → Spells
- **Lexicon**: Infrastructure registry (gateways, vaults, databases)
- **Runic Indexer**: Lexicon query engine with label matching
- **Trinkets**: Specialized charts (microspell, tarot, covenant)

### Common Commands

```bash
# TDD Workflow
make tdd-red          # Write test, expect failure
make tdd-green        # Implement, expect success
make tdd-refactor     # Improve code, still passing

# Testing
make test                    # Comprehensive tests
make test-all                # Everything (comprehensive + snapshots)
make test syntax glyph vault # Syntax validation
make glyphs vault           # Test specific glyph

# Development
make create-example CHART=summon EXAMPLE=my-test
make generate-snapshots CHART=summon
make lint
```

### File Structure

```
charts/glyphs/       # Source of truth for glyphs
charts/summon/       # Workload chart
charts/kaster/       # Glyph orchestrator
charts/trinkets/     # Specialized charts
librarian/           # ArgoCD Apps of Apps
bookrack/            # Configuration books
  <book>/index.yaml  # Book metadata
  <book>/<chapter>/  # Spells (YAML files)
  <book>/_lexicon/   # Infrastructure registry
tests/core/          # Test handlers
output-test/         # Generated outputs (gitignored)
```

### Decision Tree

```
Container workload? → summon
  + Need infra (vault, istio)? → define vault:, istio: directly
Infrastructure only? → kaster (vault:, istio: only)
Argo Events? → tarot
Identity/SSO? → covenant
External chart (bitnami, etc.)? → use chart:
  + Need infra? → use glyphs: wrapper
```

### Glyph Usage Quick Guide

```
Spell with image:             Spell with external chart:
━━━━━━━━━━━━━━━              ━━━━━━━━━━━━━━━━━━━━━━━━━
image: myorg/app:v1           chart: nginx
                              repository: bitnami
vault:
  secret:                     glyphs:
                                vault:
istio:                            secret:
  route:                        istio:
                                  route:
━━━━━━━━━━━━━━━              ━━━━━━━━━━━━━━━━━━━━━━━━━
Direct types                  Wrapper required
```

## TDD Development

runik-system follows strict TDD: Red → Green → Refactor

### TDD Cycle

```bash
# 1. RED - Write failing test
make create-example CHART=summon EXAMPLE=new-feature
# Edit examples/new-feature.yaml
make tdd-red  # Celebrates failure

# 2. GREEN - Implement minimal code
# Edit templates
make tdd-green  # Must pass

# 3. REFACTOR - Improve code
make tdd-refactor  # Runs full suite
```

**Key difference**: `tdd-red` uses `|| echo` so failures exit 0, `tdd-green/tdd-refactor` fail on errors.

### Glyph TDD Workflow

```bash
# Edit charts/glyphs/vault/examples/new-feature.yaml
make glyphs vault  # Should fail (red)
# Implement templates
make glyphs vault  # Should pass (green)
make generate-expected GLYPH=vault  # Lock expected output
```

## Architecture

### Glyphs System

**Source of truth**: `charts/glyphs/` contains all definitions
**Distribution**: Copied to consuming charts via rsync (GitHub Actions)
**NOT Helm dependencies**: Copied files, not Chart.yaml deps

**Available Glyphs**:
- Core: common, summon, runic-system
- Security: vault, keycloak
- Storage: s3, postgresql
- Networking: istio, certManager
- Events: argo-events
- Cloud: gcp, crossplane
- Utility: freeForm, trinkets

**Invocation** - Two valid forms:

**When to use each form:**
- **Direct types** (vault:, istio:) → when using `image:` (summon/defaultTrinket)
- **Wrapper `glyphs:`** → when using `chart:` + `repository:` (external charts)

**Form 1: With summon (defaultTrinket)** - Direct glyph types:
```yaml
image: myorg/app:v1  # Using summon

# Define glyphs directly - librarian strips from summon, passes to kaster
vault:
  my-secret:
    path: secret/data/my-app

istio:
  my-service:
    selector:
      access: external
```

**Form 2: With external chart** - Wrapper glyphs:
```yaml
repository: https://charts.bitnami.com/bitnami
chart: nginx  # External chart

# Wrapper prevents passing to bitnami chart, librarian extracts for kaster
glyphs:
  vault:
    my-secret:
      path: secret/data/my-app
  istio:
    my-service:
      selector:
        access: external
```

**Why two forms?**
- Summon understands and processes glyph types → librarian can strip them
- External charts don't understand vault:, istio: → wrapper isolates them

**Testing**: CRITICAL - Glyphs tested through kaster ONLY
```bash
make glyphs vault  # ✓ Correct
helm template charts/glyphs/vault  # ✗ Fails (missing deps)
```

### Runic System

**Lexicon** (_lexicon/):
```yaml
lexicon:
  - name: external-gateway
    type: istio-gw
    labels:
      access: external
      default: book
    gateway: istio-system/external-gateway
```

**Runic Indexer**: Dynamic infrastructure lookup via label selectors
- Resolution: Match labels → prefer default: book/chapter → fallback

**Common Types**: istio-gw, cert-issuer, database, vault, eventbus, k8s-cluster

### Book Pattern

**Hierarchy**: Book → Chapters → Spells

**Book Structure** (index.yaml):
```yaml
name: my-book
chapters:
  - infrastructure
  - applications

defaultTrinket:  # Usually summon
  repository: https://github.com/runik-spells/runik-system.git
  path: ./charts/summon

trinkets:
  vault-trinket:
    key: vault    # Registers glyph type
  istio-trinket:
    key: istio
  certManager-trinket:
    key: certManager
  # One trinket per glyph type
  tarot:
    key: tarot

appendix:
  lexicon: [...]
```

**Merging**: Book < Chapter < Spell (later overrides)

**Spell Detection**:
- Has `image:` → summon (renders workload)
  - Glyph types (vault:, istio:, etc.) defined directly → librarian strips from summon, adds kaster
- Has `chart:` + `repository:` → external chart
  - Use `glyphs:` wrapper to prevent passing to external chart → librarian adds kaster
- ONLY glyph types (no image/chart) → kaster only (pure infrastructure)
- Has `tarot:` → adds tarot source
- Has `runes:` → adds additional charts

### Librarian (Apps of Apps)

**Two-pass processing**:
1. Consolidate appendix (book + chapters + spells)
2. Generate ArgoCD Applications with merged context

**Output**: ArgoCD Application resources with multi-source specs

### Summon Chart

**Workload Types**: Deployment (default), StatefulSet, Job, CronJob, DaemonSet

**Key Features**:
- Container config: image, command, args, ports, env
- Storage: PVC, ConfigMap, Secret with auto-naming
- Networking: Service, Ingress
- Health: probes
- Scaling: HPA, PodDisruptionBudget
- Security: ServiceAccount, SecurityContext
- ContentType: Unified ConfigMap/Secret handling

**Example** (uses defaults):
```yaml
image: myorg/api:v1.0

service:
  enabled: true

volumes:
  config:
    type: configMap
    contentType: env
    data:
      API_URL: https://api.example.com
```

### Kaster Chart

Orchestrates glyphs:
1. Receives glyph type definitions (vault:, istio:, etc.) from librarian
2. Librarian strips glyph keys from summon values, passes to kaster
3. Includes glyph template for each type
4. Passes (list $root $definition) to glyph
5. Glyph renders K8s resources

**When to use Kaster**:
- Testing glyphs: `make glyphs <name>` (ONLY correct way to test glyphs)
- Auto-added by librarian: When spell has glyph type keys (vault:, istio:, etc.)
- Pure infrastructure: Spells with ONLY glyph types (no workload/image)

### Trinkets

**Microspell**: Opinionated microservice abstraction over summon
**Tarot**: Argo Events workflows (EventSource, Sensor, EventBus)
**Covenant**: Identity management (Keycloak + Vault)
- Two-stage: main (ApplicationSet + Realm) + per-chapter (Clients, Users, Groups)

## Testing System

**Auto-discovery**: System discovers all charts/glyphs/trinkets with examples/

### Test Layers

1. **Syntax**: `make test-syntax` - Helm template validation
2. **Comprehensive**: `make test-comprehensive` - Resource completeness
3. **Snapshots**: `make test-snapshots` - Output comparison + K8s schema
4. **Glyphs**: `make test-glyphs-all` - All glyphs via kaster
5. **Covenant**: `make test-covenant` - Identity & access

### Test Status

```bash
make test-status  # Shows current coverage
```

Legend:
- **[COMPLETE]**: Examples + Snapshots
- **[PARTIAL]**: Examples only
- **[MISSING]**: No examples

### Modular Architecture

**Dispatcher**: `bash tests/core/test-dispatcher.sh [MODE] [TYPE] [COMPONENTS...]`

**Modes**: syntax, comprehensive, snapshots, all
**Types**: glyph, trinket, chart, spell, book

**Handlers**:
- `test-glyph.sh`: Glyphs via kaster (NEVER directly)
- `test-trinket.sh`: Trinkets
- `test-chart.sh`: Main charts
- `test-spell.sh`: Individual spells
- `test-book.sh`: Books (detects covenant vs regular)

## Covenant Testing

**IMPORTANT**: Covenant chart in `runik-system/covenant/` (source of truth), books in separate repos.

**Two-stage Architecture**:
- **Main** (no chapterFilter): ApplicationSet + KeycloakRealm + Vault policies
- **Per-Chapter** (with chapterFilter): KeycloakClient, KeycloakUser, KeycloakGroup, VaultSecret

```bash
make list-covenant-books
make test-covenant-all-chapters BOOK=covenant-tyl  # RECOMMENDED
make test-covenant-chapter BOOK=covenant-tyl CHAPTER=tyl
```

**Main generates**: ApplicationSet, KeycloakRealm, ServiceAccount, Policy
**Per-Chapter generates**: KeycloakClient, KeycloakUser, KeycloakGroup, VaultSecret, RandomSecret, Job

## Integration Flow

```
bookrack/ (config)
  ↓
librarian (two-pass: consolidate appendix → generate apps)
  ↓
ArgoCD (multi-source: summon + kaster + tarot + runes)
  ↓
Helm (render templates with merged context)
  ↓
K8s cluster (final resources)
```

### Example Flow

**Spell** (bookrack/my-book/prod/api.yaml) - Using summon:
```yaml
name: api
image: myorg/api:v1

service:
  enabled: true

# Direct glyph types (Form 1: summon case)
vault:
  db-creds:
    path: secret/data/prod/db

istio:
  api:
    selector:
      access: external
```

**Librarian processing**:
- Detects `image:` → uses summon (defaultTrinket)
- Detects `vault:`, `istio:` keys → strips from summon values, auto-adds kaster source
- Merges book/chapter/spell config
- Consolidates lexicon

**ArgoCD deployment**:
- Source 1 (summon): Deployment + Service + ServiceAccount
  - Receives: image, service (vault:, istio: stripped)
- Source 2 (kaster): VaultSecret + VirtualService (auto-added)
  - Receives: vault:, istio: definitions only
  - Istio glyph queries lexicon for gateway

**Result**: Deployment, Service, ServiceAccount, VaultSecret, VirtualService

---

**Alternative: Using external chart** (bookrack/my-book/prod/nginx.yaml):
```yaml
name: nginx-bitnami

# External chart
repository: https://charts.bitnami.com/bitnami
chart: nginx
revision: 18.2.6

values:
  replicaCount: 2

# Wrapper glyphs (Form 2: external chart case)
glyphs:
  istio:
    nginx-vs:
      selector:
        access: external
      hosts:
        - nginx.example.com
```

**Librarian processing**:
- Detects `chart:` + `repository:` → uses external chart (bitnami/nginx)
- Detects `glyphs:` wrapper → auto-adds kaster source
- `glyphs:` NOT passed to bitnami chart values

**ArgoCD deployment**:
- Source 1 (bitnami/nginx): Deployment + Service (from bitnami chart)
  - Receives: values (replicaCount, etc.) - NO glyphs
- Source 2 (kaster): VirtualService (auto-added)
  - Receives: glyphs.istio definition only

**Result**: Deployment (bitnami), Service (bitnami), VirtualService (kaster)

## Development Guidelines

### Core Principles
- **TDD mandatory**: Write examples before code
- **Defaults over definition**: runik uses sensible defaults, don't over-specify
- **GitOps-first**: No manual kubectl
- **GNU GPL v3**: Copyright headers required

### TDD Rules

**DO**:
- Write tests first
- Run tdd-red (verify failure)
- Minimal implementation
- Refactor safely
- Use examples as docs

**DON'T**:
- Skip red phase
- Implement without tests
- Break existing tests
- Over-specify (use defaults)
- Commit failing tests

### When Adding Features

1. Create example (minimal config)
2. `make tdd-red`
3. Implement templates
4. `make tdd-green`
5. Refactor
6. `make tdd-refactor`
7. `make generate-snapshots`

### When Modifying Glyphs

1. Add example to `charts/glyphs/<name>/examples/`
2. `make glyphs <name>` (should fail)
3. Edit `charts/glyphs/<name>/templates/`
4. `make glyphs <name>` (should pass)
5. `make generate-expected GLYPH=<name>`

### Pre-commit

```bash
make test-all
make lint
```

## Important Notes

### Glyph Architecture
- **Source**: charts/glyphs/ (single source of truth)
- **Distribution**: rsync during GitHub Actions (not symlinks)
- **Testing**: Through kaster ONLY (`make glyphs <name>`)
- **Dependencies**: Copied files, not Chart.yaml deps

### Book System
- **Spells**: YAML files → ArgoCD Applications
- **Detection**: Librarian detects chart needs:
  - `image:` → summon + glyph types (vault:, istio:) stripped and passed to kaster
  - `chart:` + `repository:` → external chart + `glyphs:` wrapper passed to kaster
  - ONLY glyph types (no image/chart) → kaster only (pure infrastructure)
  - `tarot:`, `runes:` → additional sources
- **Merging**: Book < Chapter < Spell

### Validation
- **Resource completeness**: Expected K8s resources generated
- **Configuration-driven**: `workload.enabled=true` → must generate Deployment/StatefulSet
- **Auto-discovery**: Tests discover charts/glyphs/trinkets with examples/

### Multi-Repo Sync
- **GitHub Actions**: Auto-sync to runik-spells org
- **Versioning**: Independent per chart via git tags
- **Rsync**: `rsync -avL` follows symlinks

## Common Patterns

**Pattern 1: Summon + Glyphs** (direct glyph types):
```yaml
name: my-api
image: myorg/app:v1

service:
  enabled: true

# Direct glyph types - librarian strips from summon, passes to kaster
vault:
  db-creds:
    path: secret/data/db

istio:
  my-api-vs:
    selector:
      access: external
    hosts:
      - api.example.com
```
**Result**: Source 1 (summon: Deployment + Service) + Source 2 (kaster: VaultSecret + VirtualService)

**Pattern 2: External Chart + Glyphs** (wrapper required):
```yaml
name: nginx-bitnami

# External chart
repository: https://charts.bitnami.com/bitnami
chart: nginx
revision: 18.2.6

values:
  replicaCount: 2
  service:
    port: 80

# Wrapper glyphs: prevents passing to bitnami chart
glyphs:
  istio:
    nginx-vs:
      selector:
        access: external
      hosts:
        - nginx.example.com
```
**Result**: Source 1 (bitnami/nginx: Deployment + Service) + Source 2 (kaster: VirtualService)

**Pattern 3: Pure Infrastructure** (kaster only):
```yaml
name: tls-cert

# No image/chart → kaster only
certManager:
  tls:
    dnsNames: [app.example.com]

vault:
  secrets:
    path: secret/data/infra
```
**Result**: Kaster only (Certificate + VaultSecret)

## Getting Started

```bash
# Verify TDD
make test

# Check coverage
make test-status

# List glyphs
make list-glyphs

# Create feature (TDD)
make create-example CHART=summon EXAMPLE=my-feature
make tdd-red
# Implement
make tdd-green
make generate-snapshots CHART=summon

# Glyph development
# Edit charts/glyphs/vault/examples/new.yaml
make glyphs vault  # Red
# Implement
make glyphs vault  # Green
make generate-expected GLYPH=vault
```

---

**Note**: `prolicy` is correct (role + policy, not a typo)

**TDD Philosophy**: Write tests first, implement minimally, refactor safely. Examples are both documentation and tests.
