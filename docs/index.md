# runik-system Documentation

Welcome to **runik-system** - Kubernetes Arcane Spelling Technology, a Test-Driven Development framework for Helm-based deployments.

## What is runik-system?

runik-system is a comprehensive GitOps framework that combines:

- **Glyphs**: Reusable Helm templates for infrastructure (Vault, Istio, Cert-Manager, etc.)
- **Kaster**: Orchestration chart that coordinates multiple glyphs
- **Summon**: Base chart for workload deployments (Deployment, StatefulSet, Job, etc.)
- **Librarian**: ArgoCD App of Apps orchestrator
- **Bookrack**: Configuration management with book/chapter/spell hierarchy
- **TDD Testing**: Comprehensive test-driven development workflow

## Quick Links

!!! tip "New to runik-system?"
    Start with the [Navigation Guide](NAVIGATION.md) for a holistic overview and learning paths.

**Get Started:**

- [🧭 Navigation Guide](NAVIGATION.md) - Holistic documentation map
- [🚀 Getting Started Tutorial](GETTING_STARTED.md) - Zero to production
- [📖 Glossary](GLOSSARY.md) - Key terminology

**Core Components:**

- [Summon](SUMMON.md) - Workload deployment chart
- [Kaster](KASTER.md) - Glyph orchestration
- [Librarian](LIBRARIAN.md) - ArgoCD Apps of Apps
- [Bookrack](BOOKRACK.md) - Configuration management

**Development:**

- [Testing Guide](TESTING.md) - TDD methodology
- [TDD Commands](TDD_COMMANDS.md) - Command reference

## Architecture Overview

```
Book (bookrack/)
  ├─ index.yaml          # Book metadata
  └─ chapters/
      └─ spell.yaml      # Application config
          ↓
Librarian (ArgoCD)
  ├─ Reads spell files
  └─ Generates Applications
          ↓
Helm Charts
  ├─ Kaster → Glyphs → Resources
  ├─ Summon → Workloads
  └─ Trinkets → Patterns
          ↓
Kubernetes Cluster
```

## Key Features

### 🎯 Test-Driven Development

All features follow strict TDD methodology:

```bash
make tdd-red      # Write failing test
make tdd-green    # Implement feature
make tdd-refactor # Improve code
```

### 🔧 Infrastructure as Code

Glyphs provide reusable templates for:

- **Vault**: Secrets management
- **Istio**: Service mesh
- **Cert-Manager**: TLS certificates
- **PostgreSQL**: Managed databases
- **S3**: Object storage
- [And more...](GLYPHS_REFERENCE.md)

### 📚 GitOps Ready

Designed for ArgoCD-first deployment:

- Book/chapter/spell configuration hierarchy
- Automatic multi-source detection
- Lexicon-based infrastructure discovery
- Environment-specific overrides

### 🧪 Comprehensive Testing

- Syntax validation
- Resource completeness checks
- Snapshot testing
- Kubernetes schema validation
- Automatic component discovery

## Quick Start

```bash
# Clone repository
git clone https://github.com/runik-spells/runik-system.git
cd runik-system

# Run tests
make test

# TDD workflow
make create-example CHART=summon EXAMPLE=my-app
make tdd-red      # Should fail
# Edit templates
make tdd-green    # Should pass
```

## Documentation Structure

!!! info "Navigation"
    Use the navigation menu on the left to explore documentation by topic.

    For a guided learning experience, see [Navigation Guide](NAVIGATION.md).

**By Experience Level:**

- **Beginners**: Getting Started → Glossary → Summon
- **Intermediate**: Core Components → Glyphs → Testing
- **Advanced**: Glyph Development → Trinkets → Hierarchy Systems

**By Use Case:**

- **Deploy simple app**: Getting Started → Summon
- **Infrastructure integration**: Glyphs → Kaster → Lexicon
- **Multiple applications**: Bookrack → Librarian
- **Development & testing**: Testing → TDD Commands

## Project Philosophy

### TDD First

Every feature, template, and glyph follows Test-Driven Development:

1. **RED**: Write failing test (define expected behavior)
2. **GREEN**: Implement minimal code to pass
3. **REFACTOR**: Improve while maintaining tests

### Simple and Human

- No marketing fluff
- Direct technical language
- Working examples
- Compact and scannable

### Holistic Design

Components work together seamlessly:

- Configuration hierarchy (book → chapter → spell)
- Infrastructure discovery (lexicon + runic indexer)
- Template reusability (glyphs)
- Automatic orchestration (librarian)

## Community

- **GitHub**: [runik-spells/runik-system](https://github.com/runik-spells/runik-system)
- **License**: GNU GPL v3

## Next Steps

Choose your path:

!!! success "I want to deploy my first application"
    → [Getting Started Tutorial](GETTING_STARTED.md)

!!! info "I want to understand the architecture"
    → [Navigation Guide](NAVIGATION.md) → Path 2

!!! warning "I want to develop and test features"
    → [Testing Guide](TESTING.md) → [TDD Commands](TDD_COMMANDS.md)

!!! tip "I want to integrate infrastructure"
    → [Glyphs Overview](GLYPHS.md) → [Glyphs Reference](GLYPHS_REFERENCE.md)
