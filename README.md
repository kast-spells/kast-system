# kast-system

> Kubernetes Arcane Spelling Technology - A TDD-Driven Helm Framework for GitOps

kast-system is a modular Helm-based framework that unifies application and infrastructure deployment through a single, elegant spell system. Built with Test-Driven Development principles, it ensures reliability and correctness at every level.

## TDD-First Development

kast-system is built using comprehensive Test-Driven Development practices:

- **🔴 Red**: Write failing tests first (examples with expected behavior)
- **🟢 Green**: Implement features to make tests pass
- **🔵 Refactor**: Improve code while maintaining test coverage

### Quick TDD Workflow

```bash
# 1. Write a failing test first
make create-example CHART=summon EXAMPLE=my-feature
# Edit the example to define expected behavior

# 2. Run tests to see failure (Red phase)
make tdd-red

# 3. Implement the feature to make tests pass
# Edit templates/values to support the new feature

# 4. Verify implementation works (Green phase)  
make tdd-green

# 5. Refactor and ensure tests still pass (Refactor phase)
make tdd-refactor
```

## Core Architecture

kast-system consists of three core Helm charts working in harmony:

### 📚 Librarian - The Orchestrator
The librarian is an ArgoCD App of Apps that reads your spellbook and orchestrates deployments:
- Scans chapters for spells (YAML files)
- Loads the lexicon (shared infrastructure catalog)
- Determines deployment strategy for each spell
- Generates ArgoCD applications with appropriate sources

### 🏗️ Kaster - The Infrastructure Caster
Kaster handles infrastructure deployments when spells include glyphs:
- Processes glyph definitions (istio, certManager, vault, etc.)
- Creates infrastructure resources using lexicon references
- Manages cross-cutting concerns like gateways and certificates

### 🪄 Summon - The Application Summoner
Summon simplifies application deployment with sensible defaults:
- Transforms minimal YAML into complete Kubernetes deployments
- Handles workloads, services, storage, and scaling
- Provides a clean interface for common patterns

## The Spell System

The genius of kast-system is that **everything is a spell**. A spell can:

1. **Deploy your own applications** (using summon's simplified interface)
2. **Deploy external Helm charts** (by specifying repository/chart/path)
3. **Deploy infrastructure components** (using glyphs with kaster)
4. **Combine multiple deployment strategies** (using runes for additional charts)

### Spell Types by Example

#### 1. Simple Application Spell (Summon)
```yaml
# Just define the basics - summon handles the rest
name: my-api
namespace: services
image:
  repository: myorg/api
  tag: v1.0.0
service:
  enabled: true
autoscaling:
  enabled: true
  minReplicas: 2
```

#### 2. External Chart Spell (Direct)
```yaml
# Deploy any Helm chart from any repository
name: prometheus
namespace: monitoring
repository: https://prometheus-community.github.io/helm-charts
chart: kube-prometheus-stack
revision: 51.3.0
values:
  grafana:
    adminPassword: secret
```

#### 3. Infrastructure Spell with Glyphs (Kaster)
```yaml
# Use glyphs for infrastructure concerns
name: api-gateway
namespace: services
image:
  repository: nginx
  tag: latest
glyphs:
  istio:
    - type: virtualService
      selector:
        access: external  # References lexicon
      domains:
        - api.example.com
  certManager:
    - type: certificate
      dnsNames:
        - api.example.com
```

#### 4. Complex Spell with Runes (Multi-Source)
```yaml
# Combine your app with additional charts
name: wordpress-site
namespace: websites
image:
  repository: wordpress
  tag: latest
glyphs:
  istio:
    - type: virtualService
      selector:
        access: external
      domains:
        - blog.example.com
runes:
  - name: mariadb
    repository: https://charts.bitnami.com/bitnami
    chart: mariadb
    revision: 11.5.7
    values:
      auth:
        database: wordpress
```

## TDD Testing System

kast-system includes a comprehensive TDD testing system that validates both syntax and semantic correctness:

### Testing Commands

```bash
# TDD Workflow
make tdd-red         # Run tests expecting failures (Red phase)
make tdd-green       # Run tests expecting success (Green phase)  
make tdd-refactor    # Run tests after refactoring (Blue phase)

# Core Testing
make test            # Run comprehensive TDD tests
make test-all        # Run all tests including glyph validation
make test-syntax     # Quick syntax validation

# Glyph Testing (New!)
make glyphs <name>         # Test specific glyph (e.g., make glyphs vault)
make test-glyphs-all       # Test all glyphs through kaster system
make list-glyphs           # List all available glyphs

# Output Validation
make generate-expected GLYPH=<name>     # Generate expected outputs for glyph
make show-glyph-diff GLYPH=<name> EXAMPLE=<example>  # Show diff between actual and expected
make clean-output-tests    # Clean generated output test files

# Validation
make validate-completeness  # Ensure all expected resources are generated
make lint                  # Helm lint all charts

# Development
make create-example CHART=summon EXAMPLE=my-test  # Create new test
make inspect-chart CHART=summon EXAMPLE=basic-deployment  # Debug output
make watch          # Auto-run tests on file changes
```

### Test Validation Levels

1. **Syntax Validation**: Does the Helm template render without errors?
2. **Resource Completeness**: Are all expected K8s resources present?
3. **Configuration-Driven**: Validates PVCs when `volumes.*.type=pvc`, Services when `service.enabled=true`, etc.
4. **Chart-Specific Logic**: StatefulSets vs Deployments, autoscaling resources, etc.

### Example Test Results
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

## Glyph Testing System

kast-system includes a powerful dynamic glyph testing system that allows you to test specific glyphs without needing predefined rules for each one.

### Quick Glyph Testing

```bash
# Test a specific glyph
make glyphs vault
make glyphs istio
make glyphs certManager

# List available glyphs
make list-glyphs

# Test all glyphs
make test-glyphs-all
```

### Output Validation with Diff Testing

The system supports diff-based validation to ensure glyph outputs remain consistent:

```bash
# 1. Generate expected outputs for a glyph
make generate-expected GLYPH=vault

# 2. Run tests - now includes diff validation
make glyphs vault

# 3. Show differences when tests fail
make show-glyph-diff GLYPH=vault EXAMPLE=secrets
```

### Example Glyph Test Output

```
🎭 Testing vault glyphs...
  Testing secrets...
    ✅ vault-secrets (output matches expected)
  Testing random-secrets...
    ❌ vault-random-secrets (output differs from expected)
    Run: diff output-test/vault/random-secrets.yaml output-test/vault/random-secrets.expected.yaml
  Testing lexicon...
    ✅ vault-lexicon (rendered successfully, no expected output to compare)
    💡 To add output validation, create: output-test/vault/lexicon.expected.yaml
```

### Glyph Testing Directory Structure

The system creates an `output-test/` directory with the following structure:

```
output-test/
├── vault/
│   ├── secrets.yaml                # Actual rendered output
│   ├── secrets.expected.yaml       # Expected output for comparison
│   ├── random-secrets.yaml         # Actual output
│   └── random-secrets.expected.yaml # Expected output
├── istio/
│   ├── virtual-service-basic.yaml
│   └── virtual-service-basic.expected.yaml
└── certManager/
    ├── basic-certificate.yaml
    └── basic-certificate.expected.yaml
```

### TDD Workflow for Glyphs

When developing new glyph features, follow this TDD approach:

```bash
# 1. Create example for new glyph feature (Red phase)
# Edit charts/glyphs/vault/examples/new-feature.yaml

# 2. Test to see failure
make glyphs vault
# Should show: ❌ vault-new-feature (rendering failed)

# 3. Implement glyph feature (Green phase)
# Edit glyph templates in charts/glyphs/vault/templates/

# 4. Test to see success
make glyphs vault  
# Should show: ✅ vault-new-feature (rendered successfully)

# 5. Generate expected output for future validation
make generate-expected GLYPH=vault

# 6. Verify diff validation works
make glyphs vault
# Should show: ✅ vault-new-feature (output matches expected)
```

## Key Concepts

### 📖 Books (Spellbooks)
Books represent deployment contexts - environments, clients, or clusters:
```yaml
# boockrack/production/index.yaml
name: production
chapters:
  - intro      # Core infrastructure
  - services   # Applications
  - monitoring # Observability
kaster:
  repository: ghcr.io/kast-spells/kaster
  version: 0.1.0
summon:
  repository: ghcr.io/kast-spells/summon
  version: 0.1.0
```

### 🎯 Runes
Runes are additional Helm charts deployed alongside your spell. They enable:
- Deploying dependent services (databases, caches)
- Adding monitoring/logging sidecars
- Extending functionality without modifying the main spell

### 📜 Lexicon
The lexicon provides environment-specific infrastructure references:
```yaml
# boockrack/production/_lexicon/gateways.yaml
lexicon:
  - name: external-gateway
    type: istio-gw
    labels:
      access: external
      default: book
    gateway: istio-system/external-gateway
  
  - name: postgres-cluster
    type: database
    labels:
      engine: postgres
      tier: production
    connectionString: postgres.production.svc:5432
```

## Development Workflow

### 1. TDD Approach - Adding a New Feature

```bash
# 1. Create a failing test first (Red)
make create-example CHART=summon EXAMPLE=redis-sidecar
# Edit charts/summon/examples/redis-sidecar.yaml with expected configuration

# 2. Run tests to confirm failure
make tdd-red
# Should show: ❌ summon-redis-sidecar (expectations failed)

# 3. Implement the feature (Green)
# Edit summon templates to support redis sidecar configuration

# 4. Verify tests pass
make tdd-green
# Should show: ✅ summon-redis-sidecar

# 5. Refactor if needed
make tdd-refactor
```

### 2. Testing During Development

```bash
# Quick syntax check during development
make test-syntax

# Full validation including resource completeness
make test

# Test specific chart and example
make inspect-chart CHART=summon EXAMPLE=basic-deployment

# Debug with verbose output
make debug-chart CHART=summon EXAMPLE=complex-production

# Auto-run tests on file changes
make watch
```

### 3. Pre-commit Validation

```bash
# Run all tests before committing
make test-all

# Validate resource completeness
make validate-completeness

# Lint all charts
make lint
```

## Examples-Driven Documentation

Each chart includes comprehensive examples that serve dual purposes:
- **Documentation**: Show how to use features
- **Tests**: Validate that features work correctly

```
charts/summon/examples/
├── basic-deployment.yaml       # Simple app deployment
├── complex-production.yaml     # Full-featured with autoscaling
├── deployment-with-storage.yaml # PVC volumes
└── statefulset-with-storage.yaml # Persistent workloads

charts/trinkets/microspell/examples/
├── basic-microservice.yaml     # Simple microservice
└── advanced-microservice.yaml  # With secrets and routing
```

## How Librarian Orchestrates

The librarian's magic happens through intelligent source generation:

1. **Spell with repository/chart/path** → Direct ArgoCD source
2. **Spell with just application config** → Summon source
3. **Spell with glyphs** → Kaster source (+ Summon if needed)
4. **Spell with runes** → Multiple sources

## Getting Started

### 1. Set Up TDD Environment

```bash
# Clone and enter the kast-system repository
git clone https://github.com/yourorg/kast-system.git
cd kast-system

# Verify TDD system works
make test

# See available TDD commands
make help
```

### 2. Create Your First Feature (TDD Style)

```bash
# Write a failing test first
make create-example CHART=summon EXAMPLE=my-feature

# Edit the example with your desired configuration
# Run to see it fail (Red phase)
make tdd-red

# Implement the feature to make it pass (Green phase)
# Edit templates and run
make tdd-green

# Clean up implementation (Refactor phase)
make tdd-refactor
```

### 3. Create Your Spellbook

```bash
mkdir -p boockrack/my-env/{_lexicon,chapters/{intro,services}}
```

### 4. Define Your Book
```yaml
# boockrack/my-env/index.yaml
name: my-env
chapters:
  - intro
  - services
kaster:
  repository: ghcr.io/kast-spells/kaster
  version: 0.1.0
summon:
  repository: ghcr.io/kast-spells/summon
  version: 0.1.0
```

### 5. Deploy the Librarian
```bash
helm install librarian ./librarian \
  --set spellbook.name=my-env \
  --set spellbook.repository=https://github.com/yourorg/kast-system \
  -n argocd
```

## Why kast-system?

1. **TDD-First**: Comprehensive testing ensures reliability and correctness
2. **Unified Interface**: Deploy ArgoCD, databases, and your apps with the same spell format
3. **Smart Routing**: Librarian automatically determines how to deploy each spell
4. **Environment Parity**: Promote spells between environments with confidence
5. **Maximum Flexibility**: Use any Helm chart from any repository
6. **GitOps Native**: Everything is declarative and version controlled
7. **Modular Design**: Use only what you need, extend as you grow
8. **Test Coverage**: Every feature has examples that double as tests

## Contributing

kast-system follows strict TDD practices:

1. **Write tests first** - Create examples showing desired behavior
2. **Run tests to see failures** - Use `make tdd-red`
3. **Implement features** - Make tests pass with `make tdd-green`
4. **Refactor safely** - Maintain test coverage with `make tdd-refactor`
5. **Validate completeness** - Ensure all expected resources are generated

See [CLAUDE.md](./CLAUDE.md) for detailed development guidelines.

## License

GNU GPL v3 - see LICENSE file

---

**Copyright (C) 2023 namenmalkv@gmail.com**