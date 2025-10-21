# Hierarchy Systems

Kast uses hierarchy systems across multiple components where specific configuration overrides general configuration. This pattern enables inheritance, defaults, and scope-based overrides.

## Core Concept

Hierarchy systems follow the principle: **specificity wins**. More specific configuration overrides more general configuration.

```
General (Wide Scope) → Specific (Narrow Scope)
└─ Most specific wins
```

This enables:
- Sensible defaults at broad levels
- Overrides at specific levels
- Inheritance without duplication
- Scope-based configuration

## Hierarchy Systems in Kast

### 1. Values Merging Hierarchy

Configuration values merge from general to specific:

```
Global Defaults
  ↓
Book-level (index.yaml)
  ↓
Chapter-level (chapter index.yaml)
  ↓
Spell-level (spell.yaml)
  ↓
Rune-level (rune definition in spell)
```

**Example:**

```yaml
# Book index.yaml
summon:
  repository: https://github.com/kast-spells/kast-system.git
  revision: v1.0.0
values:
  image:
    pullPolicy: Always
  replicas: 1

# Chapter index.yaml (override)
summon:
  revision: v1.1.0  # Override book revision
values:
  replicas: 2       # Override book replicas

# Spell.yaml (override)
name: my-app
image:
  repository: nginx
  tag: alpine
replicas: 3          # Override chapter replicas

# Result: Spell gets revision v1.1.0, replicas 3, pullPolicy Always
```

**Details:** See [BOOKRACK.md](BOOKRACK.md)

---

### 2. Vault Path Hierarchy

Vault secret paths follow book → chapter → namespace hierarchy:

```
Book Scope:     kv/data/<spellbook>/publics/<secret-name>
  ↓
Chapter Scope:  kv/data/<spellbook>/<chapter>/publics/<secret-name>
  ↓
Namespace Scope: kv/data/<spellbook>/<chapter>/<namespace>/publics/<secret-name>
```

**Path Resolution:**

| Spell Declaration | Resolved Vault Path |
|-------------------|---------------------|
| `path: "book"` | `kv/data/mybook/publics/secret-name` |
| `path: "chapter"` | `kv/data/mybook/chapter1/publics/secret-name` |
| Default | `kv/data/mybook/chapter1/namespace1/publics/secret-name` |
| `path: "/custom/path"` | `kv/data/custom/path` (absolute) |

**Specificity:**
- Namespace scope: Most specific, accessible only by that workload
- Chapter scope: Shared across all spells in chapter
- Book scope: Shared across all chapters in book

**Details:** See [VAULT.md](VAULT.md)

---

### 3. Lexicon Defaulting Hierarchy

Lexicon entries support fallback selection:

```
Explicit Selector Match (Exact labels match)
  ↓
Chapter Default (default: chapter + matching chapter)
  ↓
Book Default (default: book)
```

**Example:**

```yaml
lexicon:
  # Explicit selection - used if selector matches
  - name: production-gateway
    type: istio-gw
    labels:
      environment: production
      access: external
    gateway: istio-system/prod-gw

  # Chapter default - used if no exact match in this chapter
  - name: staging-gateway
    type: istio-gw
    labels:
      default: chapter
      environment: staging
    chapter: staging
    gateway: istio-system/staging-gw

  # Book default - used if no other matches
  - name: default-gateway
    type: istio-gw
    labels:
      default: book
    gateway: istio-system/default-gw
```

**Selection Process:**

```yaml
# Glyph with selector
glyphs:
  istio:
    my-service:
      type: virtualService
      selector:
        environment: production
        access: external

# Resolution:
# 1. Try exact match: environment=production AND access=external
#    → Finds: production-gateway ✓
# 2. If no match: Try chapter default for current chapter
# 3. If no match: Try book default
```

**Details:** See [LEXICON.md](LEXICON.md)

---

### 4. Trinket Values Hierarchy

Trinket chart values inherit from book and chapter:

```
Trinket Chart Defaults
  ↓
Book index.yaml (trinket section)
  ↓
Chapter index.yaml (trinket section)
  ↓
Spell values
```

**Example:**

```yaml
# Book index.yaml
microspell:
  repository: https://github.com/kast-spells/kast-system.git
  path: charts/trinkets/microspell
  revision: v1.0.0
values:
  service:
    type: ClusterIP
  infrastructure:
    prolicy:
      enabled: true

# Chapter index.yaml
microspell:
  revision: v1.1.0
values:
  service:
    type: LoadBalancer  # Override book default

# Spell
name: my-service
trinket: microspell
service:
  port: 8080            # Merge with chapter service config
```

**Result:** Spell gets microspell v1.1.0, service type LoadBalancer (from chapter), port 8080 (from spell), prolicy enabled (from book).

---

### 5. Secret Injection Hierarchy (Tarot)

Tarot secret configuration merges from workflow to card to reading:

```
Workflow-level (tarot.secrets)
  ↓
Card definition (cards[].secrets)
  ↓
Reading-level (tarot.reading.<card>.secrets)
```

**Example:**

```yaml
# Workflow level - shared by all cards
secrets:
  registry-auth:
    type: vault-secret
    path: secret/registry
    keys: [username, password]

envs:
  REGISTRY_URL: registry.company.com

cards:
  # Card level - specific to this card definition
  - name: docker-build
    labels: {stage: build}
    secrets:
      build-cache:
        type: vault-secret
        path: secret/build-cache
    envs:
      BUILD_TOOL: docker

tarot:
  reading:
    build:
      selectors: {stage: build}
      position: action
      # Reading level - overrides card defaults
      envs:
        BUILD_TOOL: buildah  # Override card env
```

**Result for 'build' reading:**
- Gets registry-auth (workflow level)
- Gets build-cache (card level)
- REGISTRY_URL=registry.company.com (workflow)
- BUILD_TOOL=buildah (reading override)

**Details:** See [TAROT.md](TAROT.md)

---

### 6. Glyph Definition Hierarchy (Kaster)

When using multiple glyph sources, definitions can come from different scopes:

```
Global card registry (cards[])
  ↓
Book lexicon glyph definitions
  ↓
Chapter-specific glyph definitions
  ↓
Spell glyph definitions
```

**Example:**

```yaml
# Book _lexicon/glyphs.yaml
cards:
  - name: standard-git-clone
    labels: {scm: git}
    container:
      image: alpine/git:latest

# Chapter chapter1/glyphs.yaml
cards:
  - name: chapter-git-clone
    labels: {scm: git, chapter: chapter1}
    container:
      image: alpine/git:v2.40  # Override image

# Spell
name: my-app
glyphs:
  tarot:
    my-workflow:
      reading:
        checkout:
          selectors: {scm: git, chapter: chapter1}
          # Uses chapter-git-clone (more specific)
```

---

## Common Patterns

### Override Specificity

```yaml
# Most general
global_value: default

# More specific - wins over global
book_value: override1

# Most specific - wins over all
spell_value: override2

# Result: spell_value is used
```

### Merge vs Replace

**Primitive values (strings, numbers, booleans):** Replace

```yaml
# Book
replicas: 1

# Spell
replicas: 3

# Result: 3 (replaced)
```

**Objects:** Deep merge

```yaml
# Book
image:
  pullPolicy: Always
  tag: latest

# Spell
image:
  repository: nginx

# Result:
# image:
#   repository: nginx
#   pullPolicy: Always
#   tag: latest
```

**Arrays:** Replace (not merge)

```yaml
# Book
env:
  - KEY1=value1

# Spell
env:
  - KEY2=value2

# Result: Only KEY2=value2 (array replaced)
```

### Fallback Chain

```yaml
# Try specific first
selector: {environment: production, region: us-west}

# If no match, try chapter default
selector: {default: chapter, chapter: production}

# If no match, try book default
selector: {default: book}

# If no match, error or empty result
```

---

## Practical Applications

### 1. Environment Separation

```yaml
# Book: shared infrastructure
lexicon:
  - name: default-vault
    type: vault
    labels: {default: book}

# Chapter 'staging'
lexicon:
  - name: staging-vault
    type: vault
    labels: {default: chapter}
    chapter: staging

# Chapter 'production'
lexicon:
  - name: production-vault
    type: vault
    labels: {default: chapter}
    chapter: production

# Spells in each chapter automatically use their chapter vault
```

### 2. Progressive Overrides

```yaml
# Book: conservative defaults
values:
  resources:
    limits:
      memory: 256Mi
      cpu: 100m

# Chapter 'production': more resources
values:
  resources:
    limits:
      memory: 1Gi
      cpu: 500m

# Specific spell: high resource needs
resources:
  limits:
    memory: 4Gi
    cpu: 2
```

### 3. Shared Secrets with Private Overrides

```yaml
# Book vault path: shared database credentials
glyphs:
  vault:
    - type: secret
      path: book
      name: database-readonly

# Chapter vault path: chapter-specific credentials
glyphs:
  vault:
    - type: secret
      path: chapter
      name: database-readwrite

# Namespace vault path: app-specific credentials
glyphs:
  vault:
    - type: secret
      name: app-private-key
      # Default path (namespace-specific)
```

---

## Best Practices

### Design Hierarchies for Reuse

Place most common configuration at broadest scope:

```yaml
# Book: Organization-wide standards
values:
  image:
    pullPolicy: Always
  securityContext:
    runAsNonRoot: true

# Chapter: Environment-specific
values:
  replicas: 3  # Production needs more replicas

# Spell: Application-specific
image:
  repository: myapp
```

### Use Explicit When Needed

Don't rely on hierarchy when explicitness is clearer:

```yaml
# Good: Explicit for critical config
vault:
  path: /production/critical-secrets

# Avoid: Implicit via complex hierarchy
# (requires understanding book → chapter → namespace resolution)
```

### Document Hierarchy Decisions

```yaml
# Good: Document why hierarchy used
# Inherits image.pullPolicy from book (org standard)
# Overrides replicas for production chapter
name: my-app
replicas: 5
```

---

## Troubleshooting Hierarchy Issues

### Check Effective Configuration

Use helm template to see final merged values:

```bash
helm template test charts/summon -f book/index.yaml -f chapter/index.yaml -f spell.yaml --debug
```

### Trace Hierarchy Path

```bash
# Book defaults
cat book/index.yaml | yq '.values.replicas'  # → 1

# Chapter override
cat book/chapter1/index.yaml | yq '.values.replicas'  # → 2

# Spell override
cat book/chapter1/spell.yaml | yq '.replicas'  # → 3

# Winner: 3 (most specific)
```

### Common Issues

**Issue:** Value not overriding as expected

**Solution:** Check if using correct field path and structure

```yaml
# Wrong: Different paths
# Book
image:
  tag: latest

# Spell (doesn't merge)
images:
  tag: v1.0

# Correct: Same paths
# Spell
image:
  tag: v1.0
```

---

## Summary

Hierarchy systems in kast enable:

1. **Inheritance:** Broad defaults inherited by specific configurations
2. **Overrides:** Specific configurations override general ones
3. **Scoping:** Different configurations for different contexts
4. **Fallbacks:** Graceful degradation when specific config unavailable
5. **DRY:** Define once at appropriate level, reuse everywhere

**Pattern:** General → Specific, Most Specific Wins

**Application:** Values, Vault paths, Lexicon, Trinkets, Secrets, Glyphs

**Documentation:** See component-specific docs for detailed hierarchy behavior.
