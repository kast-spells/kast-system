# Documentation Navigation

Holistic guide to kast-system documentation. Follow the learning paths below based on your goals.

## Quick Links

**Bootstrap Cluster:** [Bootstrapping](BOOTSTRAPPING.md) ← Start here for fresh clusters
**Get Started:** [Getting Started](GETTING_STARTED.md)
**Core Concepts:** [Glossary](GLOSSARY.md)
**Main README:** [../README.md](../README.md)
**Development:** [Testing](TESTING.md) → [TDD Commands](TDD_COMMANDS.md)

---

## Documentation Map

```
┌─────────────────────────────────────────────────────────────┐
│                    ENTRY POINT                              │
├─────────────────────────────────────────────────────────────┤
│ BOOTSTRAPPING.md   → Cluster setup with ArgoCD (from zero) │
│ BOOTSTRAPPING_TROUBLESHOOTING.md → Bootstrap issues guide  │
│ GETTING_STARTED.md → Complete tutorial (zero to production) │
│ README.md          → Architecture overview, quick start     │
│ GLOSSARY.md        → Terminology reference                  │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                  CORE COMPONENTS                            │
├─────────────────────────────────────────────────────────────┤
│ SUMMON.md          → Workload deployment chart             │
│ KASTER.md          → Glyph orchestration                   │
│ LIBRARIAN.md       → ArgoCD Apps of Apps                   │
│ BOOKRACK.md        → Configuration management              │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│              ADVANCED INFRASTRUCTURE                        │
├─────────────────────────────────────────────────────────────┤
│ GLYPHS.md          → Glyph system overview                 │
│ GLYPH_DEVELOPMENT.md → Create new glyphs                   │
│ LEXICON.md         → Infrastructure discovery              │
│ VAULT.md           → Secrets management                    │
│ HIERARCHY_SYSTEMS.md → Configuration inheritance           │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                    TRINKETS                                 │
├─────────────────────────────────────────────────────────────┤
│ MICROSPELL.md      → Microservices pattern                 │
│ TAROT.md           → Workflow automation                   │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│              DEVELOPMENT & TESTING                          │
├─────────────────────────────────────────────────────────────┤
│ TESTING.md         → TDD methodology, test architecture    │
│ TDD_COMMANDS.md    → Command reference                     │
│ EXAMPLES_INDEX.md  → All examples catalog                  │
│ CODING_STANDARDS.md → Code conventions (root)              │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                   REFERENCES                                │
├─────────────────────────────────────────────────────────────┤
│ GLYPHS_REFERENCE.md → All available glyphs                 │
│ applicationset-guide.md → ArgoCD ApplicationSets           │
│ applicationset-quick-reference.md → Quick cheat sheet      │
│ glyphs/*.md        → Individual glyph docs                 │
└─────────────────────────────────────────────────────────────┘
```

---

## Learning Paths

### Path 0: Bootstrap Fresh Cluster (30-45 minutes)
**Start here if you don't have ArgoCD installed**
1. [Bootstrapping](BOOTSTRAPPING.md) - Cluster setup with ArgoCD
2. [Getting Started](GETTING_STARTED.md) - First application deployment

### Path 1: Deploy Your First App (30 minutes)
**Start here if you already have ArgoCD installed**
1. [Getting Started](GETTING_STARTED.md) - Tutorial
2. [Bookrack](BOOKRACK.md) - Configuration structure
3. [Summon](SUMMON.md) - Workload chart basics

### Path 2: Understand Architecture (1 hour)
1. [README.md](../README.md) - System overview
2. [Glossary](GLOSSARY.md) - Key terminology
3. [Librarian](LIBRARIAN.md) - How deployment works
4. [Kaster](KASTER.md) - Glyph orchestration
5. [Hierarchy Systems](HIERARCHY_SYSTEMS.md) - Configuration patterns

### Path 3: Infrastructure Integration (2 hours)
1. [Glyphs](GLYPHS.md) - Infrastructure as code
2. [Lexicon](LEXICON.md) - Service discovery
3. [Vault](VAULT.md) - Secrets management
4. [Glyphs Reference](GLYPHS_REFERENCE.md) - Available integrations

### Path 4: Development & Testing (2 hours)
1. [Testing](TESTING.md) - TDD workflow
2. [TDD Commands](TDD_COMMANDS.md) - Command reference
3. [Glyph Development](GLYPH_DEVELOPMENT.md) - Create new glyphs
4. [Examples Index](EXAMPLES_INDEX.md) - Learn from examples

### Path 5: Advanced Patterns (3 hours)
1. [Microspell](MICROSPELL.md) - Microservice patterns
2. [Tarot](TAROT.md) - Workflow automation
3. [ApplicationSet Guide](applicationset-guide.md) - ArgoCD patterns
4. [Hierarchy Systems](HIERARCHY_SYSTEMS.md) - Advanced config

---

## By Use Case

### "I'm starting from scratch with a fresh Kubernetes cluster"
→ [Bootstrapping](BOOTSTRAPPING.md) → [Getting Started](GETTING_STARTED.md)

### "I want to deploy a simple container"
→ [Getting Started](GETTING_STARTED.md) → [Summon](SUMMON.md)

### "I need to integrate with Vault/Istio/Cert-Manager"
→ [Glyphs](GLYPHS.md) → [Kaster](KASTER.md) → [Glyphs Reference](GLYPHS_REFERENCE.md)

### "I'm organizing multiple applications"
→ [Bookrack](BOOKRACK.md) → [Librarian](LIBRARIAN.md)

### "I want to develop and test new features"
→ [Testing](TESTING.md) → [TDD Commands](TDD_COMMANDS.md)

### "I need to create a new glyph"
→ [Glyph Development](GLYPH_DEVELOPMENT.md) → [Testing](TESTING.md)

### "I'm setting up GitOps with ArgoCD"
→ [Librarian](LIBRARIAN.md) → [ApplicationSet Guide](applicationset-guide.md)

---

## Component Relationships

### Data Flow: Configuration → Deployment
```
Bookrack (YAML files)
    ↓
Librarian (reads books)
    ↓
ArgoCD Applications (generated)
    ↓
Helm Charts (summon/kaster/trinkets)
    ↓
Kubernetes Resources (deployed)
```

**Docs:** [Bookrack](BOOKRACK.md) → [Librarian](LIBRARIAN.md) → [Summon](SUMMON.md)/[Kaster](KASTER.md)

### Template Flow: Glyphs → Resources
```
Glyph Definition (YAML)
    ↓
Kaster (orchestrates)
    ↓
Glyph Template (invoked)
    ↓
Lexicon (queries infrastructure)
    ↓
K8s Resource (generated)
```

**Docs:** [Glyphs](GLYPHS.md) → [Kaster](KASTER.md) → [Lexicon](LEXICON.md)

### Development Flow: TDD Cycle
```
Write Example (test)
    ↓
Run tdd-red (should fail)
    ↓
Implement Feature
    ↓
Run tdd-green (should pass)
    ↓
Refactor
    ↓
Run tdd-refactor (still pass)
```

**Docs:** [Testing](TESTING.md) → [TDD Commands](TDD_COMMANDS.md)

---

## Cross-Cutting Concerns

### Configuration Hierarchy
Appears in: Bookrack, Vault paths, Lexicon defaults
**Doc:** [Hierarchy Systems](HIERARCHY_SYSTEMS.md)

### Infrastructure Discovery
Used by: Glyphs, Vault, Istio, Cert-Manager
**Doc:** [Lexicon](LEXICON.md)

### Test-Driven Development
Applies to: All charts, glyphs, trinkets
**Doc:** [Testing](TESTING.md)

---

## Documentation Principles

1. **Start simple:** Getting Started → Core components → Advanced
2. **Learn by doing:** Every doc includes examples
3. **Follow flows:** Data flow, template flow, development flow
4. **Cross-reference:** Related docs linked explicitly
5. **Stay current:** Docs tested with real code

---

## Quick Command Reference

```bash
# Get started
make test                    # Run tests
make help                    # Show all commands

# Development
make tdd-red                 # Write failing test
make tdd-green               # Implement feature
make tdd-refactor            # Improve code

# Testing
make test syntax glyph vault # Quick syntax check
make test all glyph         # Comprehensive glyph tests
```

See [TDD Commands](TDD_COMMANDS.md) for complete reference.

---

## Contributing to Documentation

1. Keep it simple and human
2. Include working examples
3. Update cross-references
4. Test all commands
5. Follow TDD approach
6. No marketing/fluff

See [CODING_STANDARDS.md](CODING_STANDARDS.md) for conventions.
