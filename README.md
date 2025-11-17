# kast-system

Kubernetes Arcane Spelling Technology - Test-Driven Development framework for Helm-based deployments.

## Architecture

### Core Components

**Glyphs** - Reusable Helm template library. Each glyph provides specific functionality (vault, istio, summon, certManager, etc.). Located in `charts/glyphs/`.

**Kaster** - Orchestration chart that coordinates multiple glyphs. Iterates through glyph definitions and invokes corresponding templates.

**Summon** - Base chart for workload deployment. Handles Deployment, StatefulSet, Service, PVC, HPA, and ServiceAccount resources.

**Librarian** - ArgoCD App of Apps orchestrator. Reads books from `bookrack/` and generates ArgoCD Applications automatically.

**Bookrack** - Configuration management using book/chapter/spell pattern. Books contain deployment contexts organized by chapters.

**Trinkets** - Opinionated wrappers around glyphs for specific use cases:
- **Microspell**: Microservices with Istio + Vault integration
- **Tarot**: Argo Workflows dynamic workflow generation
- **Covenant**: Identity and access management (Keycloak + Vault + RBAC)

### Data Flow

```
Book (bookrack/)
  ├─ index.yaml          # Book metadata, chart versions
  └─ chapters/
      └─ spell.yaml      # Application configuration
          ↓
Librarian (ArgoCD ApplicationSet)
  ├─ Reads spell files
  ├─ Detects deployment strategy
  └─ Generates ArgoCD Application
          ↓
ArgoCD Application
  ├─ Source 1: Helm chart (kaster/summon/trinket)
  └─ Source 2: Values from bookrack
          ↓
Helm Rendering
  ├─ Kaster → Iterates glyphs → Calls glyph templates
  ├─ Summon → Generates workload resources
  └─ Trinket → Wraps glyphs with opinionated config
          ↓
Kubernetes Resources
  └─ Deployed to cluster
```

### Component Relationships

**Glyphs ← Kaster**: Kaster orchestrates glyphs by iterating `Values.glyphs.<chart-name>` and calling `include "glyph.type"`.

**Glyphs ← Summon**: Summon workloads can reference glyph-generated resources (e.g., vault secrets).

**Glyphs ← Trinkets**: Trinkets include glyphs via symlinks in `charts/` directory and invoke templates directly.

**Lexicon**: Global registry in `Values.lexicon`. Glyphs use runic indexer to discover infrastructure (vault servers, gateways, databases) via label selectors.

**Runic Indexer**: Template function that queries lexicon entries matching label selectors. Returns infrastructure configuration for glyphs.

### Glyph Template Pattern

```go
{{- define "glyph.templateName" -}}
  {{- $root := index . 0 -}}              # Full chart context
  {{- $glyphDefinition := index . 1 -}}   # Glyph configuration

  # Query lexicon for infrastructure
  {{- $infrastructure := include "runicIndexer.runicIndexer"
       (list $root.Values.lexicon
             $glyphDefinition.selector
             "resource-type"
             $root.Values.chapter.name) | fromJson }}

  # Generate Kubernetes resources
  apiVersion: ...
  kind: ...
{{- end -}}
```

### Spell Deployment Strategies

Librarian detects deployment strategy from spell configuration:

1. **Simple Application**: Has `name`, `image` → Uses Summon chart
2. **Infrastructure**: Has `glyphs` → Uses Kaster chart
3. **Multi-Source**: Has `runes` → Multiple chart sources (Summon + Kaster + additional charts)
4. **External Chart**: Has `repository`, `chart` → Direct chart deployment

## Quick Start

```bash
# Test the system
make test

# TDD workflow
make create-example CHART=summon EXAMPLE=my-app
make tdd-red      # Write failing test
# Implement feature
make tdd-green    # Verify implementation
make tdd-refactor # Refactor safely
```

## Directory Structure

```
kast-system/
├── charts/
│   ├── glyphs/          # Reusable template library
│   │   ├── vault/       # Vault integration
│   │   ├── istio/       # Service mesh
│   │   ├── summon/      # Workload templates
│   │   └── ...
│   ├── kaster/          # Glyph orchestrator
│   ├── summon/          # Base workload chart
│   └── trinkets/        # Opinionated wrappers
│       ├── microspell/  # Microservices
│       ├── tarot/       # Argo Workflows
│       └── covenant/    # Identity management
├── librarian/           # ArgoCD App of Apps
├── bookrack/            # Configuration books
│   └── example-book/
│       ├── index.yaml   # Book metadata
│       └── chapter/     # Spell files
└── tests/               # TDD testing infrastructure
```

## Documentation

**Start Here:**
- [Documentation Navigation](docs/NAVIGATION.md) - Holistic guide with learning paths
- [Getting Started](docs/GETTING_STARTED.md) - Complete tutorial (zero to production)
- [Glossary](docs/GLOSSARY.md) - Terminology reference

**Core Components:**
- [Summon](docs/SUMMON.md) - Workload deployment
- [Kaster](docs/KASTER.md) - Glyph orchestration
- [Librarian](docs/LIBRARIAN.md) - ArgoCD Apps of Apps
- [Bookrack](docs/BOOKRACK.md) - Configuration management

**Development:**
- [Testing Guide](docs/TESTING.md) - TDD methodology
- [TDD Commands](docs/TDD_COMMANDS.md) - Command reference
- [Coding Standards](CODING_STANDARDS.md) - Code conventions
- [Claude Code](CLAUDE.md) - AI-assisted development

## Testing

kast-system uses comprehensive TDD testing:

```bash
make test                # Rendering + resource completeness
make test-all            # All tests (comprehensive + snapshots + glyphs)
make test-glyphs-all     # Test all glyphs
make test-status         # Show testing coverage
```

See [TDD Commands Reference](docs/TDD_COMMANDS.md) for complete testing workflow.

## Key Concepts

**Spell** - YAML file in bookrack chapter defining application deployment

**Chapter** - Logical grouping of spells in a book (e.g., intro, services, monitoring)

**Book** - Deployment context (environment, cluster, team)

**Glyph** - Named Helm template for specific functionality

**Rune** - Additional Helm chart deployed alongside main spell

**Lexicon** - Global infrastructure registry with label-based discovery

**Position** - Tarot card execution order (foundation, action, challenge, outcome)

## Development

All features follow TDD:

1. Write failing test (example)
2. Implement minimal feature
3. Verify test passes
4. Refactor

See [CLAUDE.md](CLAUDE.md) for detailed development guidelines.

## License

GNU GPL v3
