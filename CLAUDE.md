# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

kast-system is a Test-Driven Development (TDD) Kubernetes deployment framework built around Helm charts, described as "Kubernetes arcane spelling technology". The project uses a modular architecture with reusable Helm template components called "glyphs" and follows strict TDD practices for reliability and correctness.

## Quick Reference

### Key Concepts (30-Second Overview)

- **Glyphs**: Reusable Helm template libraries for specific K8s resources (vault, istio, certManager, etc.)
- **Summon**: Primary chart for workloads (Deployment, StatefulSet, Job, CronJob, DaemonSet)
- **Kaster**: Glyph orchestrator - renders glyphs into K8s resources
- **Librarian**: Transforms bookrack/ into ArgoCD Applications (Apps of Apps pattern)
- **Books**: Configuration hierarchy: Book → Chapters → Spells (YAML files)
- **Spells**: Individual YAML files in bookrack/ that become ArgoCD Applications
- **Lexicon**: Infrastructure registry for dynamic resource discovery (gateways, vaults, databases)
- **Runic Indexer**: Query engine for lexicon with label matching
- **Trinkets**: Specialized charts (microspell, tarot, covenant)

### Common Commands

```bash
# TDD Workflow
make tdd-red          # Write test, expect failure
make tdd-green        # Implement, expect success
make tdd-refactor     # Improve code, still passing

# Testing
make test             # Comprehensive TDD tests
make test-all         # All tests (comprehensive + snapshots + glyphs)
make test-status      # Show testing coverage
make glyphs vault     # Test specific glyph
make test-covenant    # Test covenant books

# Development
make create-example CHART=summon EXAMPLE=my-test
make inspect-chart CHART=summon EXAMPLE=basic-deployment
make generate-snapshots CHART=summon
make lint             # Helm lint all charts
```

### File Locations

```
charts/glyphs/           # Glyph source of truth
charts/summon/           # Workload chart
charts/kaster/           # Glyph orchestrator
charts/trinkets/         # Specialized charts
librarian/               # ArgoCD Apps of Apps
bookrack/                # Configuration books
  <book>/index.yaml      # Book metadata
  <book>/<chapter>/      # Chapter with spells
  <book>/_lexicon/       # Infrastructure registry
tests/scripts/           # Validation scripts
output-test/             # Generated test outputs
```

### Decision Tree: Which Chart to Use?

```
Need to deploy workload (container)? → summon
Need infrastructure (Vault, Istio, Certs)? → kaster + glyphs
Need Argo Events workflows? → tarot
Need identity management (Keycloak)? → covenant
Need to orchestrate multiple charts? → librarian + bookrack
```

## TDD Development Philosophy

**kast-system is built TDD-first.** Every feature, template, and glyph follows the Red-Green-Refactor cycle:

1. **🔴 RED**: Write failing tests/examples first - define expected behavior
2. **🟢 GREEN**: Implement minimal code to make tests pass  
3. **🔵 REFACTOR**: Improve code while maintaining test coverage

### Core TDD Commands

```bash
# TDD Workflow Commands
make tdd-red         # Run tests expecting failures (Red phase)
make tdd-green       # Run tests expecting success (Green phase)
make tdd-refactor    # Run tests after refactoring (Blue phase)

# Testing Status & Discovery
make test-status     # Show testing status for all charts/glyphs/trinkets (automatic discovery)

# Core Testing
make test            # Run comprehensive TDD tests (rendering + resource completeness)
make test-all        # Run ALL tests (comprehensive + snapshots + glyphs + tarot)
make test-comprehensive  # Test rendering + resource completeness (original TDD)
make test-snapshots  # Test snapshots + K8s schema validation (helm dry-run)
make test-syntax     # Quick syntax validation

# Snapshot Testing
make generate-snapshots CHART=<name>     # Generate snapshots for chart
make update-snapshot CHART=<name> EXAMPLE=<example>  # Update specific snapshot
make update-all-snapshots                # Update all snapshots
make show-snapshot-diff CHART=<name> EXAMPLE=<example>  # Show diff

# Validation
make validate-completeness  # Ensure all expected resources are generated
make lint                  # Helm lint all charts

# Glyph Testing (Automatic Discovery)
make glyphs <name>         # Test specific glyph (e.g., make glyphs vault)
make test-glyphs-all       # Test all glyphs automatically
make list-glyphs           # List all available glyphs
make generate-expected GLYPH=<name>     # Generate expected outputs for glyph
make show-glyph-diff GLYPH=<name> EXAMPLE=<example>  # Show diff

# Development Helpers
make create-example CHART=summon EXAMPLE=my-test  # Create new test
make inspect-chart CHART=summon EXAMPLE=basic-deployment  # Debug output
make watch          # Auto-run tests on file changes
make clean-output-tests    # Clean generated test outputs
```

## Project Structure

- **charts/** - Core Helm charts (all TDD-tested)
  - **glyphs/** - Reusable Helm template library (source of truth)
    - Individual glyphs: common, summon, vault, istio, certManager, crossplane, gcp, freeForm, argo-events, keycloak, postgres-cloud, s3, runic-system, default-verbs
    - Each glyph has: Chart.yaml, templates/, examples/ (for testing)
    - Copied to other charts via rsync during GitHub Actions sync
  - **kaster/** - Glyph orchestrator chart
    - Used for testing glyphs (primary use case)
    - Used for infrastructure deployments via glyphs
    - Contains copies of all glyphs in charts/ subdirectory
  - **summon/** - Primary workload chart for microservices/containers
    - Supports 5 workload types: Deployment, StatefulSet, Job, CronJob, DaemonSet
    - Contains copies of all glyphs in charts/ subdirectory
    - 17+ comprehensive examples for TDD
  - **trinkets/** - Specialized utility charts
    - **microspell/** - Microservice deployment abstraction
    - **tarot/** - Argo Events workflow definitions
    - **covenant/** - Identity & access management (Keycloak + Vault)
- **librarian/** - ArgoCD Apps of Apps orchestrator
  - Reads bookrack/ structure
  - Generates ArgoCD Applications from books/chapters/spells
  - Two-pass appendix consolidation system
  - Runic indexer for infrastructure discovery
- **bookrack/** - GitOps configuration management
  - Book → Chapters → Spells hierarchy
  - Books define: trinkets, defaults, appendix, cluster targeting
  - Spells are individual YAML files = ArgoCD Applications
  - _lexicon/ subdirectories contain infrastructure registry
- **tests/** - TDD testing infrastructure
  - **scripts/** - Validation and testing scripts (5 core scripts, 1,788 lines)
    - `validate-resource-completeness.sh` - Resource validation engine
    - `test-covenant-book.sh` - Covenant identity & access testing
    - `test-librarian-migration.sh` - Librarian ApplicationSet TDD (consolidated 4 scripts)
    - `test-tarot.sh` - Tarot workflow testing (extracted from Makefile)
    - `test-book-render.sh` - Book/spell rendering with librarian context
- **output-test/** - Generated test outputs (created automatically, gitignored)
  - **<chart-name>/** - Per-chart/glyph test results
    - **<example>.yaml** - Actual rendered output
    - **<example>.expected.yaml** - Expected output for diff validation

## Testing System Overview

kast-system uses a **dual testing approach** that automatically discovers all charts, glyphs, and trinkets:

### Testing Layers

1. **Syntax Validation** (`make test-syntax`)
   - Validates Helm template syntax
   - Fast feedback during development
   - No K8s cluster required

2. **Comprehensive Testing** (`make test-comprehensive`)
   - Rendering validation
   - Resource completeness checks
   - Validates expected K8s resources are generated

3. **Snapshot Testing** (`make test-snapshots`)
   - **Snapshot comparison**: Output matches expected YAML
   - **K8s schema validation**: `helm install --dry-run` validates against K8s API
   - Detects unintended changes and invalid values

4. **Glyph Testing** (`make test-glyphs-all`)
   - Tests all glyphs through kaster orchestration
   - Automatic discovery of glyphs with examples/
   - Snapshot-based validation

5. **Covenant Book Testing** (`make test-covenant`)
   - Tests covenant books (identity & access management)
   - Different from normal books: reads entire book structure, not individual spells
   - Validates Keycloak resources (Realm, Clients, Users, Groups)
   - Validates Vault secret generation for OIDC

### Current Testing Status

Run `make test-status` to see automatic discovery of all tests:

```bash
$ make test-status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Testing Status Report
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📦 Main Charts:
  ✅ summon: 17 examples (17 snapshots)
  ⚠️  kaster: 1 examples (no snapshots)
  ❌ librarian: NO examples/

🎭 Glyphs:
  ✅ argo-events: 5 examples (5 snapshots)
  ✅ vault: 11 examples (11 snapshots)
  ✅ istio: 2 examples (2 snapshots)
  ⚠️  certManager: 2 examples (no snapshots)
  ❌ keycloak: NO examples/
  ...

🔮 Trinkets:
  ⚠️  microspell: 8 examples (no snapshots)
  ⚠️  tarot: 14 examples (no snapshots)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Legend:
  ✅ = Examples + Snapshots complete
  ⚠️  = Examples exist, snapshots needed
  ❌ = No examples (needs TDD work)
```

## TDD Development Workflow

### Understanding the TDD Cycle Mechanics

The TDD commands (`tdd-red`, `tdd-green`, `tdd-refactor`) have different behaviors that enforce the Red-Green-Refactor cycle:

#### How `tdd-red` Works (Red Phase)

```makefile
tdd-red: ## TDD Red: Run tests expecting failures
	@echo "🔴 TDD RED: Running tests expecting failures..."
	@$(MAKE) test-comprehensive || echo "✅ Good! Tests are failing - now implement"
```

**Key mechanic:** Uses the `||` operator (logical OR)
- Runs `test-comprehensive`
- If tests **FAIL** → executes the echo message (celebrates failure!)
- If tests **PASS** → shows nothing special (unexpected at this phase)
- **Philosophy:** You're writing tests for features that don't exist yet, so failures are GOOD

**When to use:**
- After writing new test examples
- Before implementing new features
- To verify your test actually tests something (not a false positive)

#### How `tdd-green` Works (Green Phase)

```makefile
tdd-green: ## TDD Green: Run tests expecting success
	@echo "🟢 TDD GREEN: Running tests expecting success..."
	@$(MAKE) test-comprehensive
```

**Key mechanic:** No `||` operator - direct execution
- Runs `test-comprehensive`
- If tests **PASS** → exits successfully (good!)
- If tests **FAIL** → Make will exit with error code (bad!)
- **Philosophy:** You've implemented the feature, tests should now pass

**When to use:**
- After implementing features
- To verify your implementation works
- Before committing code

#### How `tdd-refactor` Works (Refactor Phase)

```makefile
tdd-refactor: ## TDD Refactor: Run tests after refactoring
	@echo "🔵 TDD REFACTOR: Running tests after refactoring..."
	@$(MAKE) test-all
```

**Key mechanic:** Runs the comprehensive test suite (`test-all`)
- Executes ALL tests (comprehensive + snapshots + glyphs)
- Ensures your refactoring didn't break anything
- **Philosophy:** Code improvement should not change behavior

**When to use:**
- After cleaning up code
- After optimizing implementations
- Before finalizing work

#### Comparison Table

| Command | What Runs | Expected Result | Exit Code if Fail |
|---------|-----------|-----------------|-------------------|
| `tdd-red` | `test-comprehensive` | Failures are OK | 0 (success) |
| `tdd-green` | `test-comprehensive` | Must pass | Non-zero (error) |
| `tdd-refactor` | `test-all` | Must pass | Non-zero (error) |

#### Live Example: Adding PodDisruptionBudget

```bash
# RED PHASE - Write test first
cat > charts/summon/examples/test-pod-disruption.yaml <<EOF
workload:
  enabled: true
  type: deployment
  replicas: 3

podDisruptionBudget:
  enabled: true
  minAvailable: 2
EOF

# Confirm test fails (feature doesn't exist yet)
make tdd-red
# Output: ❌ summon-test-pod-disruption (expectations failed)
#         ✅ Good! Tests are failing - now implement

# GREEN PHASE - Implement feature
# Edit charts/summon/templates/pod-disruption-budget.yaml
# Add template logic for PDB

# Verify test passes
make tdd-green
# Output: ✅ summon-test-pod-disruption

# REFACTOR PHASE - Improve implementation
# Clean up code, add comments, optimize
make tdd-refactor
# Output: All tests pass including snapshots and glyphs
```

### 1. Adding New Features (TDD Approach)

**ALWAYS follow this sequence:**

```bash
# 1. RED PHASE - Write failing test first
make create-example CHART=summon EXAMPLE=my-new-feature
# Edit charts/summon/examples/my-new-feature.yaml with expected configuration

# 2. Confirm test fails (should fail because feature doesn't exist yet)
make tdd-red
# Should show: ❌ summon-my-new-feature (expectations failed)

# 3. GREEN PHASE - Implement minimal code to make test pass
# Edit summon templates to support the new feature
# Add necessary template logic

# 4. Verify test passes
make tdd-green
# Should show: ✅ summon-my-new-feature

# 5. REFACTOR PHASE - Clean up implementation
# Improve code quality, add documentation, optimize
make tdd-refactor
# Should still show: ✅ summon-my-new-feature

# 6. SNAPSHOT PHASE - Lock in the expected output
make generate-snapshots CHART=summon
# Creates output-test/summon/my-new-feature.expected.yaml
```

### 2. TDD Workflow for Glyphs

**NEW: Dynamic glyph testing system allows testing specific glyphs without predefined rules:**

```bash
# 1. RED PHASE - Add new glyph feature example
# Edit charts/glyphs/vault/examples/new-feature.yaml with expected configuration

# 2. Test to see failure (Red)
make glyphs vault
# Should show: ❌ vault-new-feature (rendering failed)

# 3. GREEN PHASE - Implement glyph feature
# Edit glyph templates in charts/glyphs/vault/templates/

# 4. Test to see success (Green)
make glyphs vault
# Should show: ✅ vault-new-feature (rendered successfully)

# 5. Generate expected output for diff validation
make generate-expected GLYPH=vault

# 6. REFACTOR PHASE - Verify diff validation works
make glyphs vault
# Should show: ✅ vault-new-feature (output matches expected)
```

### 3. Glyph Output Validation System

The system now includes comprehensive diff-based validation:

```bash
# List available glyphs
make list-glyphs

# Test specific glyph with automatic example discovery
make glyphs vault
make glyphs istio
make glyphs certManager

# Generate expected outputs for comparison
make generate-expected GLYPH=vault

# Show differences when outputs change
make show-glyph-diff GLYPH=vault EXAMPLE=secrets

# Clean output test files
make clean-output-tests
```

### 4. Covenant Book Testing Workflow

**IMPORTANT**: Covenant chart lives in **proto-the-yaml-life repository**, not in kast-system. The testing infrastructure in kast-system points to the production covenant chart.

**Covenant books are different**: They don't have chapter/spell structure. Instead, the entire book is configuration data read by the covenant chart.

**Production Covenant Architecture**:
- **Two-stage deployment** using ApplicationSets
- **Main covenant** (no chapterFilter): Generates ApplicationSet + shared resources (KeycloakRealm, Vault policies)
- **Chapter covenants** (with chapterFilter): Generated by ApplicationSet, each renders resources for one chapter

```bash
# 1. List available covenant books (in proto-the-yaml-life)
make list-covenant-books

# 2. Test main covenant (generates ApplicationSet)
make test-covenant-book BOOK=covenant-tyl

# 3. Test specific chapter (as ApplicationSet would render it)
make test-covenant-chapter BOOK=covenant-tyl CHAPTER=tyl

# 4. Test all chapters (main + all chapter apps) - RECOMMENDED
make test-covenant-all-chapters BOOK=covenant-tyl

# 5. Debug covenant book rendering (full output)
make test-covenant-debug BOOK=covenant-tyl

# 6. Test all covenant books
make test-covenant

# 7. Add new integration to covenant book
# Edit: /home/namen/_home/the.yaml.life/proto-the-yaml-life/bookrack/covenant-tyl/conventions/integrations/my-app.yaml
enabled: true
clientId: my-app
webUrl: https://my-app.int.the.yaml.life
redirectUris:
  - https://my-app.int.the.yaml.life/oauth2/callback
secret: keycloak-client-my-app  # VaultSecret name
passPolicyName: simple-password-policy

# 8. Test to verify KeycloakClient and VaultSecret are generated
make test-covenant-all-chapters BOOK=covenant-tyl
```

**Covenant generates (Main - no chapterFilter):**
- `ApplicationSet`: Generates per-chapter covenant applications
- `KeycloakRealm`: Realm configuration (shared)
- `ServiceAccount`: For Vault access
- `Policy` + `KubernetesAuthEngineRole`: Vault RBAC

**Covenant generates (Per-Chapter - with chapterFilter):**
- `KeycloakClient`: One per integration file
- `KeycloakUser`: One per member file
- `KeycloakGroup`: One per chapter/chapel
- `VaultSecret`: OIDC client secrets (format: `env` with `CLIENT_SECRET` key)
- `RandomSecret`: Random password generators
- `Job`: Post-provisioning jobs (e.g., email provisioning)

### 5. Modifying Existing Features

```bash
# 1. Add test case for new behavior first
make create-example CHART=summon EXAMPLE=existing-feature-enhancement

# 2. Run tests to see current behavior
make test-comprehensive

# 3. Modify templates to support new behavior
# Edit relevant template files

# 4. Verify all tests pass (new and existing)
make test-comprehensive
```

### 6. TDD Testing Levels

The testing system validates multiple levels:

1. **Syntax Validation**: Does Helm template render without errors?
2. **Resource Completeness**: Are all expected K8s resources generated?
3. **Configuration-Driven Expectations**: 
   - `workload.enabled=true` → Should generate Deployment/StatefulSet
   - `service.enabled=true` → Should generate Service resource
   - `volumes.*.type=pvc` → Should generate PersistentVolumeClaim
   - `autoscaling.enabled=true` → Should generate HorizontalPodAutoscaler
4. **Chart-Specific Logic**: StatefulSet vs Deployment based on `workload.type`

### 4. Examples as Documentation and Tests

Every chart MUST have comprehensive examples that serve dual purposes:
- **Documentation**: Show users how to use features
- **Tests**: Validate that features work correctly

```
charts/summon/examples/
├── basic-deployment.yaml       # Simple deployment (tests core functionality)
├── complex-production.yaml     # Full-featured (tests autoscaling, volumes, etc.)
├── deployment-with-storage.yaml # Tests PVC volumes
└── statefulset-with-storage.yaml # Tests StatefulSet workloads

charts/trinkets/microspell/examples/
├── basic-microservice.yaml     # Simple microservice
└── advanced-microservice.yaml  # With secrets and routing
```

## Architecture and Patterns

### Glyphs System

The project uses a unique "glyphs" pattern where reusable Helm templates are organized as separate charts:

**What are Glyphs?**
- **Reusable template libraries** for specific Kubernetes resource types
- **Source of truth**: charts/glyphs/ directory contains all glyph definitions
- **Distribution**: Copied into consuming charts (summon, kaster) via rsync during GitHub Actions
- **Not Helm dependencies**: Glyphs are copied files, not Chart.yaml dependencies

**Available Glyphs:**
- **Core**: common (helpers), summon (workload helpers), runic-system (infrastructure discovery), default-verbs (RBAC)
- **Security**: vault (Vault secrets), keycloak (SSO/OIDC)
- **Storage**: s3 (object storage), postgres-cloud (managed databases)
- **Networking**: istio (service mesh), certManager (TLS certificates)
- **Events**: argo-events (event-driven workflows)
- **Cloud**: gcp (Google Cloud resources), crossplane (cloud provisioning)
- **Utility**: freeForm (raw YAML), trinkets (meta-glyph)

**Glyph Invocation Pattern:**
```yaml
# In a spell or values file
glyphs:
  vault:
    - type: secret
      name: my-secret
      path: secret/data/my-app
  istio:
    - type: virtualService
      name: my-service
      selector:
        access: external
```

**Template Naming Convention:**
- Named templates: `{{- define "glyph.type.tpl" -}}`
- Invocation: `{{- include "vault.secret" (list $root $definition) }}`
- Templates receive: (list $rootContext $glyphDefinition)

**Testing Glyphs:**
- **CRITICAL**: Glyphs MUST be tested through kaster, never directly
- Direct testing fails due to missing glyph dependencies
- Use: `make glyphs <name>` which renders via kaster + examples/
- **All glyphs must have examples/ for TDD**

### Runic System (Infrastructure Discovery)

**Lexicon**: Infrastructure registry defined in bookrack/<book>/_lexicon/
```yaml
lexicon:
  - name: external-gateway
    type: istio-gw
    labels:
      access: external
      environment: production
      default: book
    gateway: istio-system/external-gateway
```

**Runic Indexer**: Query engine for lexicon lookup
- Glyphs query using label selectors
- Resolution: Match labels → prefer default: book/chapter → fallback chain
- Available in templates via runic-system glyph
- Enables dynamic infrastructure discovery (gateways, vaults, databases, clusters)

**Common Lexicon Types:**
- istio-gw (Istio gateways)
- cert-issuer (Certificate issuers)
- database (Database connections)
- vault (Vault instances)
- eventbus (Argo Events buses)
- k8s-cluster (Target clusters)
- csi-config (Storage classes)

### Book Pattern (Configuration Management)

Configuration is organized as "books" in bookrack/:

**Hierarchy**: Book → Chapters → Spells
- **Book** (index.yaml): Deployment context, trinkets registry, global defaults, appendix
- **Chapter**: Logical grouping (intro/staging/production), optional index.yaml for overrides
- **Spell**: Individual YAML file = 1 ArgoCD Application

**Book Structure:**
```yaml
# bookrack/my-book/index.yaml
name: my-book
chapters:
  - infrastructure  # Deployed first
  - applications    # Deployed second

defaultTrinket:  # Default chart for spells
  repository: https://github.com/kast-spells/kast-system.git
  path: ./charts/summon
  revision: feature/coding-standards

trinkets:  # Multi-source chart detection
  kaster:
    key: glyphs  # Spell with .glyphs uses kaster
    repository: ...
    path: ./charts/kaster
  tarot:
    key: tarot   # Spell with .tarot uses tarot
    repository: ...
    path: ./charts/trinkets/tarot

appendix:  # Shared context (lexicon, etc.)
  lexicon:
    - name: prod-gateway
      type: istio-gw
```

**Spell Deployment Strategies:**
1. **Simple App** (uses defaultTrinket - usually summon)
2. **Infrastructure** (has .glyphs → uses kaster)
3. **Multi-source** (has .runes → multiple charts)
4. **External Chart** (has .chart/.repository)
5. **Covenant** (special: identity management)

**Configuration Merging Order**: Book < Chapter < Spell (later overrides earlier)

### Librarian (Apps of Apps Orchestrator)

**Purpose**: Transform bookrack/ structure into ArgoCD Applications

**Two-Pass Processing:**
1. **Pass 1 - Appendix Consolidation**: Gather all appendix from book + chapters + spells → global context
2. **Pass 2 - Application Generation**: For each spell, generate ArgoCD Application with merged context

**Trinket Detection**: Automatically determines which charts a spell needs:
- Check for .glyphs → add kaster chart
- Check for .tarot → add tarot chart
- Check for .runes → add additional charts
- Base: defaultTrinket (usually summon)

**Output**: ArgoCD Application resources with multi-source configuration

### Summon Chart (Workload Orchestrator)

**Purpose**: Primary chart for deploying containerized workloads with comprehensive Kubernetes features

**Workload Types** (via workload.type):
1. **Deployment** (default): Stateless applications with rolling updates
2. **StatefulSet**: Stateful applications with persistent identity and storage
3. **Job**: One-time batch jobs
4. **CronJob**: Scheduled recurring jobs
5. **DaemonSet**: One pod per node (e.g., monitoring agents, log collectors)

**Key Features**:
- **Container configuration**: image, command, args, ports, env
- **Storage**: PVC, ConfigMap, Secret volumes with automatic naming
- **Networking**: Service, Ingress with multiple hosts/paths
- **Health**: liveness, readiness, startup probes
- **Scaling**: replicas, HPA, PodDisruptionBudget
- **Scheduling**: nodeSelector, tolerations, affinity/anti-affinity
- **Security**: ServiceAccount, SecurityContext, PodSecurityContext
- **ContentType system**: Unified ConfigMap/Secret handling (env, file, json, yaml)

**Examples**: See charts/summon/examples/ for 17+ comprehensive examples covering all workload types and features

### Kaster Chart (Glyph Orchestrator)

**Purpose**: Orchestrate glyphs to generate infrastructure resources

**Primary Use Case**: Testing glyphs via `make glyphs <name>`

**Secondary Use Case**: Infrastructure deployments via bookrack spells with .glyphs

**How It Works**:
1. Receives glyph definitions in values.glyphs
2. For each glyph type, includes the glyph template
3. Passes (list $root $definition) to glyph
4. Glyph renders appropriate K8s resources

**Testing**: Always test glyphs through kaster, never directly

### Trinket Charts

**Microspell**:
- Abstraction layer over summon for microservices
- Simplified configuration with opinionated defaults
- 8+ examples for common microservice patterns

**Tarot**:
- Argo Events workflow definitions
- EventSource, Sensor, EventBus resources
- Event-driven automation
- 14+ examples for various event patterns

**Covenant**:
- Identity & access management (Keycloak + Vault)
- Keycloak realm/client/user/group management
- Vault OIDC secret generation
- Two-stage deployment (main + per-chapter)
- Special book structure (chapters = organizations)

### Template Conventions

- All templates must include copyright header with GNU GPL v3 license
- Use named templates for reusability: `{{- define "glyph.templateName" -}}`
- Follow naming conventions in charts/glyphs/STYLE_GUIDE.md
- Values should be namespaced under chart name
- **Every template must be testable through examples**

### GitOps Integration

- **ArgoCD-first**: Designed for GitOps deployment via ArgoCD
- **GitHub Actions**: Automatically sync components to separate repositories
  - charts/summon → kast-spells/summon repository
  - charts/kaster → kast-spells/kaster repository
  - charts/glyphs/* → individual glyph repositories
  - Uses rsync -avL to follow symlinks and copy actual content
- **Tagging**: Changes trigger automated versioning and releases
- **Multi-repo strategy**: Each chart can be versioned independently

## TDD Development Tips

### When Adding New Glyphs:
1. **Write example first** - Create examples/ directory with test cases
2. **Run TDD red phase** - Verify tests fail
3. **Implement minimal glyph** - Create basic template structure
4. **Make tests pass** - Implement full functionality
5. **Refactor** - Clean up and optimize

### When Modifying Existing Glyphs:
1. **Add test case first** - New example showing desired behavior
2. **Verify current behavior** - Run existing tests
3. **Modify templates** - Update template logic
4. **Ensure all tests pass** - Both new and existing functionality

### When Adding Template Logic:
1. **Parameter validation** - Check required values exist
2. **Resource completeness** - Generate all expected K8s resources
3. **Error handling** - Graceful fallbacks for optional features
4. **Documentation** - Comments explaining complex logic

### Testing During Development:

```bash
# Quick syntax validation during development
make test-syntax

# Full validation including resource completeness
make test

# Test specific chart and example
make inspect-chart CHART=summon EXAMPLE=basic-deployment

# Debug with verbose output  
make debug-chart CHART=summon EXAMPLE=complex-production

# Auto-run tests on file changes (useful during development)
make watch
```

### Pre-commit Validation:

```bash
# ALWAYS run before committing
make test-all

# Validate resource completeness
make validate-completeness

# Lint all charts
make lint
```

## Validation System

The TDD system includes comprehensive validation:

### Resource Completeness Validation
The validation script (`tests/scripts/validate-resource-completeness.sh`) checks:
- **Workload Resources**: Deployment when `workload.type=deployment`, StatefulSet when `workload.type=statefulset`
- **Service Resources**: Service when `service.enabled=true`
- **Storage Resources**: PVC resources when `volumes.*.type=pvc`
- **Scaling Resources**: HPA when `autoscaling.enabled=true`
- **Security Resources**: ServiceAccount when `serviceAccount.enabled=true`

### Chart-Specific Validations:
- **Summon**: Validates workload types, storage configurations, service configurations
- **Microspell**: Validates microservice patterns, secrets integration, routing
- **Kaster**: Validates glyph orchestration and resource generation

### Example Validation Output:
```
🧪 TDD: Comprehensive validation...
Testing chart: summon
  Validating basic-deployment...
    ✅ Workload resource present (deployment)
    ✅ Service resource present  
    ✅ ServiceAccount resource present
  ✅ summon-basic-deployment

  Validating complex-production...
    ✅ Workload resource present (deployment)
    ✅ Service resource present
    ✅ All 2 PVC resources present
    ✅ HorizontalPodAutoscaler resource present  
  ✅ summon-complex-production
```

## Important TDD Rules

### DO:
- **Write tests first** - Always create examples before implementing features
- **Run tdd-red** - Verify tests fail before implementing
- **Make minimal changes** - Implement just enough to make tests pass
- **Refactor safely** - Improve code while maintaining test coverage
- **Test resource completeness** - Ensure expected K8s resources are generated
- **Use examples as documentation** - Examples should be comprehensive and realistic

### DON'T:
- **Skip the red phase** - Always see tests fail first
- **Implement without tests** - Every feature needs examples
- **Break existing tests** - Ensure backward compatibility
- **Skip validation** - Always run comprehensive validation
- **Commit failing tests** - Fix all test failures before committing

## Testing Anti-Patterns to Avoid

❌ **Writing implementation first, then tests**
✅ **Write failing tests first, then implement**

❌ **Testing only syntax/rendering**  
✅ **Test resource completeness and expected behavior**

❌ **Single example per chart**
✅ **Multiple examples covering different scenarios**

❌ **Manual testing only**
✅ **Automated TDD testing with make commands**

❌ **Ignoring test failures**
✅ **Fix all failures before proceeding**

## Important Notes

### Core Principles
- **GitOps-first**: All Kubernetes resources managed through Helm templates + ArgoCD, avoid manual kubectl operations
- **TDD is mandatory**: All features must have tests/examples before implementation (Red-Green-Refactor)
- **GNU GPL v3 license**: Ensure all files have proper copyright headers
- **Style guide**: Follow conventions in charts/glyphs/STYLE_GUIDE.md

### Glyph System Architecture
- **Source of truth**: charts/glyphs/ contains all glyph definitions
- **Distribution mechanism**: Glyphs are copied (not symlinked) into consuming charts via rsync during GitHub Actions
- **NOT Helm dependencies**: Glyphs are copied files in charts/ subdirectory, not Chart.yaml dependencies
- **Testing**: CRITICAL - Glyphs MUST be tested through kaster, never directly
  - Use: `make glyphs <name>` which renders via kaster + examples/
  - Direct testing with `helm template charts/glyphs/<name>` will FAIL due to missing glyph dependencies

### Book and Spell System
- **Books are hierarchical**: Book → Chapters → Spells
- **Spells are YAML files**: Each spell file in bookrack/<book>/<chapter>/*.yaml becomes an ArgoCD Application
- **Trinket detection**: Librarian automatically detects which charts a spell needs based on keys (glyphs, tarot, runes)
- **Configuration merging**: Book defaults < Chapter overrides < Spell overrides
- **Testing books**: Use example-tdd-book or the-yaml-life book for realistic examples

### Infrastructure Discovery
- **Lexicon**: Infrastructure registry in bookrack/<book>/_lexicon/
- **Runic indexer**: Query engine for dynamic infrastructure lookup via label selectors
- **Resolution strategy**: Match labels → prefer default: book/chapter → fallback chain
- **Common use cases**: Gateway selection, certificate issuer selection, database connection lookup, cluster targeting

### Validation and Testing
- **Resource completeness validation is critical**: Ensure all expected K8s resources are generated based on configuration
- **Multi-layer testing**: Syntax → Comprehensive → Snapshots → Schema validation
- **Configuration-driven expectations**: workload.enabled=true → must generate Deployment/StatefulSet
- **Test discovery**: Testing system auto-discovers all charts/glyphs/trinkets with examples/

### Multi-Repository Sync
- **GitHub Actions**: Automatically sync charts to separate repositories
- **Versioning**: Independent versioning per chart via git tags
- **Rsync mechanism**: Uses `rsync -avL` to follow symlinks and copy content
- **Target repos**: kast-spells organization (summon, kaster, individual glyphs)

## Getting Started with TDD Development

```bash
# 1. Verify TDD system works
make test

# 2. See all available TDD commands  
make help

# 3. Explore available glyphs
make list-glyphs

# 4. Test specific glyph to understand current state
make glyphs vault

# 5. Create your first feature using TDD (for charts)
make create-example CHART=summon EXAMPLE=my-feature

# 6. Follow TDD cycle: Red -> Green -> Refactor
make tdd-red      # Should fail initially
# Implement feature
make tdd-green    # Should pass after implementation  
make tdd-refactor # Should still pass after cleanup

# 7. For glyph development, use the glyph TDD workflow:
# - Edit charts/glyphs/<name>/examples/new-feature.yaml
# - make glyphs <name>  # Red phase - should fail
# - Implement glyph templates
# - make glyphs <name>  # Green phase - should pass
# - make generate-expected GLYPH=<name>  # Lock in expected output
# - make glyphs <name>  # Refactor phase - should match expected
```

Remember: **TDD isn't just testing - it's a design methodology that leads to better, more reliable code.**

---

## Complete Integration Flow

Understanding how all components work together from configuration to deployment:

### Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. CONFIGURATION (bookrack/)                                    │
├─────────────────────────────────────────────────────────────────┤
│ Book (index.yaml)                                               │
│  ├─ Metadata: name, chapters, projectName                      │
│  ├─ Trinkets: kaster (glyphs), tarot, summon (defaultTrinket)  │
│  ├─ Defaults: appParams, syncPolicy                            │
│  └─ Appendix: lexicon (infrastructure registry)                │
│                                                                  │
│ Chapter (intro/, staging/, production/)                         │
│  ├─ Optional index.yaml (overrides book)                       │
│  └─ Spells: *.yaml files (individual applications)             │
│                                                                  │
│ Lexicon (_lexicon/infrastructure.yaml)                          │
│  └─ Infrastructure entries (gateways, vaults, databases)        │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│ 2. ORCHESTRATION (librarian)                                    │
├─────────────────────────────────────────────────────────────────┤
│ Pass 1: Appendix Consolidation                                  │
│  └─ Merge: book.appendix + chapter.appendix + spell.appendix   │
│                                                                  │
│ Pass 2: Application Generation                                  │
│  For each spell:                                                │
│   ├─ Detect trinkets needed (glyphs → kaster, tarot → tarot)   │
│   ├─ Build multi-source spec                                   │
│   ├─ Merge configuration (book < chapter < spell)              │
│   ├─ Add lexicon context                                       │
│   └─ Generate ArgoCD Application resource                      │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│ 3. DEPLOYMENT (ArgoCD)                                          │
├─────────────────────────────────────────────────────────────────┤
│ ArgoCD reads generated Application resources                    │
│  ├─ Sync policy: automated or manual                           │
│  ├─ Sources: primary + additional (multi-source)               │
│  └─ Destination: target cluster + namespace                    │
│                                                                  │
│ For each source:                                                │
│  ├─ Pull Helm chart from repository                            │
│  ├─ Merge values from Application spec                         │
│  └─ Render Helm templates                                      │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│ 4. RENDERING (Helm Charts)                                      │
├─────────────────────────────────────────────────────────────────┤
│ Source 1: Summon (defaultTrinket) - if no glyphs               │
│  ├─ Workload: Deployment/StatefulSet/Job/CronJob/DaemonSet     │
│  ├─ Service: ClusterIP/NodePort/LoadBalancer                   │
│  ├─ Storage: PVC/PV with naming conventions                    │
│  ├─ Config: ConfigMap/Secret with contentType system           │
│  └─ Scaling: HorizontalPodAutoscaler                           │
│                                                                  │
│ Source 2: Kaster (if glyphs present)                            │
│  └─ Orchestrates glyph invocations:                            │
│      For each glyph definition:                                 │
│       ├─ Include "glyph.type" template                         │
│       ├─ Pass: (list $root $definition)                        │
│       └─ Glyph renders specific K8s resources                  │
│                                                                  │
│ Glyphs (via Kaster):                                            │
│  ├─ vault: VaultSecret, VaultRole, VaultPolicy                 │
│  ├─ istio: VirtualService, DestinationRule, Gateway            │
│  ├─ certManager: Certificate, Issuer                           │
│  ├─ s3: Bucket, BucketPermission                               │
│  ├─ postgres-cloud: PostgresCluster, PostgresDatabase          │
│  ├─ keycloak: KeycloakRealm, KeycloakClient, KeycloakUser      │
│  ├─ argo-events: EventSource, Sensor, EventBus                 │
│  └─ runic-system: Infrastructure lookup via lexicon            │
│                                                                  │
│ Source 3: Tarot (if tarot present)                              │
│  └─ Argo Events workflow definitions                           │
│                                                                  │
│ Source N: Runes (if runes present)                              │
│  └─ Additional external charts (e.g., external-dns, monitoring)│
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│ 5. KUBERNETES CLUSTER                                           │
├─────────────────────────────────────────────────────────────────┤
│ Final K8s resources applied:                                    │
│  ├─ Workloads: Deployment, StatefulSet, Job, CronJob, DaemonSet│
│  ├─ Networking: Service, Ingress, VirtualService, Gateway      │
│  ├─ Storage: PVC, PV, StorageClass                             │
│  ├─ Config: ConfigMap, Secret                                  │
│  ├─ Security: ServiceAccount, Role, RoleBinding, NetworkPolicy │
│  ├─ Scaling: HPA, PDB                                          │
│  ├─ Certificates: Certificate, Issuer                          │
│  └─ Custom Resources: VaultSecret, PostgresCluster, etc.       │
└─────────────────────────────────────────────────────────────────┘
```

### Example: Complete Flow for a Microservice with Vault Secrets

**Step 1: Configuration (bookrack/my-book/production/api-service.yaml)**
```yaml
name: api-service
namespace: production

# Summon configuration (primary source)
image:
  repository: myorg/api-service
  tag: v1.2.3

service:
  enabled: true
  ports:
    - port: 8080
      name: http

# Glyphs configuration (kaster source)
glyphs:
  vault:
    - type: secret
      name: database-credentials
      path: secret/data/production/db
  istio:
    - type: virtualService
      name: api-service
      selector:
        access: external
        environment: production
```

**Step 2: Librarian Processing**
- Reads book/index.yaml → finds trinkets: kaster (for glyphs)
- Detects spell has .glyphs → adds kaster as source 2
- Consolidates appendix → includes lexicon with infrastructure
- Generates ArgoCD Application:
  ```yaml
  apiVersion: argoproj.io/v1alpha1
  kind: Application
  metadata:
    name: api-service
  spec:
    sources:
      - repoURL: https://github.com/kast-spells/kast-system.git
        path: charts/summon
        helm:
          values: |
            name: api-service
            image:
              repository: myorg/api-service
              tag: v1.2.3
            service:
              enabled: true
      - repoURL: https://github.com/kast-spells/kast-system.git
        path: charts/kaster
        helm:
          values: |
            glyphs:
              vault: [...]
              istio: [...]
  ```

**Step 3: ArgoCD Syncs**
- Pulls summon chart → renders Deployment + Service
- Pulls kaster chart → invokes glyphs

**Step 4: Helm Rendering**
- Summon renders:
  - Deployment: api-service
  - Service: api-service
  - ServiceAccount: api-service

- Kaster invokes glyphs:
  - vault glyph renders: VaultSecret for database-credentials
  - istio glyph:
    1. Queries lexicon for istio-gw with labels: access=external, environment=production
    2. Finds: external-gateway
    3. Renders: VirtualService pointing to external-gateway

**Step 5: K8s Resources Applied**
- Deployment/api-service
- Service/api-service
- ServiceAccount/api-service
- VaultSecret/database-credentials (custom resource)
- VirtualService/api-service (Istio custom resource)

### Key Integration Points

1. **Trinket Detection**: Librarian inspects spell for keys (glyphs, tarot, runes) to determine sources
2. **Appendix Consolidation**: Lexicon from all levels merged and passed to charts
3. **Multi-Source Rendering**: Each source rendered independently with shared context
4. **Runic Indexer**: Glyphs query lexicon dynamically for infrastructure (gateways, vaults, etc.)
5. **Resource Generation**: Multiple charts contribute resources to same application

### Common Patterns

**Pattern 1: Simple Microservice**
- Spell: image + service (no glyphs)
- Charts: summon only
- Resources: Deployment, Service

**Pattern 2: Microservice with Infrastructure**
- Spell: image + service + glyphs (vault, istio)
- Charts: summon + kaster
- Resources: Deployment, Service, VaultSecret, VirtualService

**Pattern 3: Complex Multi-Source**
- Spell: image + service + glyphs + runes
- Charts: summon + kaster + external charts
- Resources: Deployment, Service, glyphs resources, external chart resources

**Pattern 4: Pure Infrastructure**
- Spell: glyphs only (no image)
- Charts: kaster only
- Resources: Certificates, Secrets, Gateways (no workload)

---

## Testing Coverage Status (Auto-Discovered)

The testing system automatically discovers all charts, glyphs, and trinkets. Use `make test-status` to see current coverage.

### Fully Tested (✅ Examples + Snapshots)
**Main Charts:**
- summon: 17 examples with full snapshot coverage

**Glyphs:**
- argo-events: 5 examples
- vault: 11 examples
- istio: 2 examples
- common: 2 examples

### Needs Snapshots (⚠️ Examples exist, snapshots missing)
**Main Charts:**
- kaster: 1 example

**Glyphs:**
- certManager: 2 examples
- crossplane: 2 examples
- freeForm: 2 examples
- gcp: 3 examples
- runic-system: 3 examples

**Trinkets:**
- microspell: 8 examples
- tarot: 14 examples

**Action:** Run `make update-all-snapshots` to generate all missing snapshots.

### Needs TDD Work (❌ No examples/)
**Main Charts:**
- librarian: Infrastructure chart (may not need examples)

**Glyphs:**
- default-verbs: Utility glyph
- keycloak: Integration glyph
- postgres-cloud: Integration glyph
- trinkets: Meta glyph

**Trinkets:**
- covenant: New trinket (in development)

**Action:** Create examples/ directories and add test cases following TDD workflow.

### How to Improve Coverage

```bash
# 1. Check current status
make test-status

# 2. For items with examples but no snapshots
make update-all-snapshots

# 3. For items without examples, create them (TDD approach)
make create-example CHART=kaster EXAMPLE=basic-glyph
# Edit the example file
make tdd-red
# Implement feature
make tdd-green
make generate-snapshots CHART=kaster

# 4. Verify everything works
make test-all
```