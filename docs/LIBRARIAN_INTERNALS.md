# Librarian Internals: Technical Deep Dive

Understanding librarian's internal mechanisms helps debug issues and optimize your bookrack structure.

**Related:** [Librarian Guide](LIBRARIAN.md) | [Bootstrapping Guide](BOOTSTRAPPING.md)

---

## Table of Contents

1. [Two-Pass Processing System](#two-pass-processing-system)
2. [Multi-Source Detection](#multi-source-detection)
3. [Configuration Hierarchy](#configuration-hierarchy)
4. [Lexicon System](#lexicon-system)
5. [Values Passed to Charts](#values-passed-to-charts)
6. [Cluster Selection via Runic Indexer](#cluster-selection-via-runic-indexer)
7. [Sync Policies Configuration](#sync-policies-configuration)
8. [Debugging Librarian](#debugging-librarian)
9. [Architecture Summary](#architecture-summary)

---

## Two-Pass Processing System

Librarian uses a **two-pass architecture** to consolidate configuration and generate ArgoCD Applications:

### PASS 1: Consolidate Appendix (Configuration Collection)

```
1. Read book index.yaml → book.appendix
2. For each chapter:
   - Read chapter/index.yaml → merge chapter.appendix
   - For each spell in chapter:
     - Read spell.yaml → merge spell.appendix
3. Result: $globalAppendix (consolidated configuration)
```

### PASS 2: Generate Applications (ArgoCD Resource Creation)

```
For each chapter:
  For each spell:
    1. Detect needed trinkets (vault, istio, tarot, etc.)
    2. Build final appendix: global < chapterLocal < fileLocal
    3. Generate ArgoCD Application with:
       - Source 1: defaultTrinket (summon) or custom chart
       - Sources 2..N: Detected trinkets (kaster, tarot, etc.)
       - Values: spell + globalAppendix + lexicon + cards
    4. Apply sync policies and destination
```

### Why Two Passes?

- **Pass 1** ensures all configuration is available before generating any Application
- **Pass 2** can make decisions based on complete context (e.g., trinket detection, cluster selection)

---

## Multi-Source Detection

Each spell generates an ArgoCD Application with **multiple sources** automatically:

### Source 1 (Primary - Always Present)

- **If spell has `chart:` or `path:`** → uses that custom chart
- **Otherwise** → uses `defaultTrinket` (typically summon)

### Sources 2..N (Trinkets - Dynamically Detected)

Librarian scans each spell for registered trinket keys and adds sources automatically:

```yaml
# spell.yaml
name: my-app

image:
  name: nginx
  tag: "1.25"

vault:              # ← Librarian detects this key
  my-secret:
    path: secret/data/app

istio:              # ← And this key
  my-vs:
    hosts: [app.example.com]
```

**Generated Application has 3 sources:**
1. **summon** (workload) - Deployment, Service, etc.
2. **kaster** (vault glyph) - VaultSecret resource
3. **kaster** (istio glyph) - VirtualService resource

### How Trinket Detection Works

1. Book `index.yaml` registers trinkets with keys:
   ```yaml
   trinkets:
     kaster-vault:
       key: vault        # Detection key
       path: ./charts/kaster
   ```
2. Librarian checks if spell has `vault:` key
3. If found, adds kaster source with only vault data
4. Kaster chart receives `values.vault:` and renders VaultSecret

---

## Configuration Hierarchy

Configuration merges in specific order (later overrides earlier):

### defaultTrinket (workload chart)

```
book.defaultTrinket < chapter.defaultTrinket
```

### trinkets (glyph registrations)

```
book.trinkets < chapter.trinkets
```

### appendix (shared configuration)

```
book.appendix < chapter.appendix < spell.appendix
```

### localAppendix (override mechanism)

```
chapter.localAppendix < spell.localAppendix
```

- Overrides globalAppendix for specific scopes
- Useful for chapter/spell-specific infrastructure

### appParams (ArgoCD sync policies)

```
book.appParams < chapter.appParams < spell.appParams
```

### Example Hierarchy

```yaml
# book/index.yaml
appendix:
  cluster:
    environment: production    # ← Base value

# book/staging/index.yaml
localAppendix:
  cluster:
    environment: staging       # ← Chapter override

# book/staging/api.yaml
localAppendix:
  cluster:
    name: staging-us-west      # ← Spell override

# Final values for staging/api spell:
cluster:
  environment: staging         # From chapter
  name: staging-us-west        # From spell
```

---

## Lexicon System

Librarian processes and distributes lexicon (infrastructure registry) to all charts:

### Input (book appendix)

```yaml
appendix:
  lexicon:
    - name: vault-prod
      type: vault
      labels:
        default: book
        environment: production
      address: https://vault.vault.svc:8200

    - name: external-gateway
      type: istio-gw
      labels:
        access: external
        default: book
      gateway: istio-system/external-gateway
```

### Processing

1. Librarian consolidates lexicon from book + chapters + spells
2. Ensures each entry has a `.name` field
3. Converts to dictionary keyed by name

### Distribution

```yaml
# Passed to ALL sources (summon, kaster, tarot, runes)
values:
  lexicon:
    vault-prod:
      name: vault-prod
      type: vault
      labels: {...}
      address: https://vault...
    external-gateway:
      name: external-gateway
      type: istio-gw
      ...
```

### Usage in Charts

- Charts use `runicIndexer` to query lexicon with label selectors
- Example: Istio glyph searches `type: istio-gw` + `access: external`
- Returns matching infrastructure configuration

**See also:** [Lexicon Guide](LEXICON.md)

---

## Values Passed to Charts

### To defaultTrinket (summon)

```yaml
# Spell definition (cleaned)
name: my-app
image:
  name: nginx
  tag: "1.25"
ports: [...]
service: {...}
# (vault:, istio:, runes:, appParams: removed)

# Book context
spellbook:
  name: my-book
  chapters: [...]
  # (appParams, summon, kaster, appendix removed)

# Chapter context
chapter:
  name: applications

# Infrastructure
lexicon: {...}
cards: {...}      # Tarot cards if present
```

### To trinkets (kaster, tarot, etc.)

```yaml
# ONLY the trinket key data
vault:
  my-secret:
    path: secret/data/app

# Same book context
spellbook: {...}
chapter: {...}
lexicon: {...}
cards: {...}     # Only for tarot trinket
```

### To runes (additional charts)

```yaml
# Rune values
values: {...}

# Same book context
spellbook: {...}
chapter: {...}
lexicon: {...}
cards: {...}
```

---

## Cluster Selection via Runic Indexer

Librarian uses runicIndexer for dynamic cluster selection:

### Spell with cluster selector

```yaml
name: my-app

image:
  name: nginx
  tag: "1.25"

clusterSelector:
  labels:
    region: us-west
    environment: production
```

### Lexicon with clusters

```yaml
appendix:
  lexicon:
    - name: prod-us-west
      type: k8s-cluster
      labels:
        region: us-west
        environment: production
      clusterURL: https://k8s-prod-usw.example.com
```

### Librarian Process

1. Detects `clusterSelector` in spell
2. Queries lexicon: `type: k8s-cluster` + spell labels
3. Finds matching cluster(s)
4. Sets Application `destination.server` to matched clusterURL

**Hierarchy:** `book.clusterSelector < chapter.clusterSelector < spell.clusterSelector`

---

## Sync Policies Configuration

Sync policies cascade through hierarchy:

### Default (librarian values.yaml)

```yaml
appParams:
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
    retry:
      limit: 2
```

### Override in book

```yaml
# book/index.yaml
appParams:
  disableAutoSync: true    # Disable auto-sync for entire book
```

### Override in spell

```yaml
# spell.yaml
appParams:
  syncPolicy:
    automated:
      prune: false         # Keep resources on deletion
  customFinalizers:
    - resources-finalizer.argocd.argoproj.io/background
```

---

## Debugging Librarian

### View Generated Application

```bash
# Get Application manifest
kubectl get application -n argocd my-book-applications-nginx -o yaml

# Check sources
kubectl get application -n argocd my-book-applications-nginx \
  -o jsonpath='{.spec.sources}' | jq

# View values passed to charts
kubectl get application -n argocd my-book-applications-nginx \
  -o jsonpath='{.spec.sources[0].helm.values}'
```

### Common Debugging Scenarios

**Missing trinket source?**
```bash
# Check trinkets registered in book
cat bookrack/my-book/index.yaml | grep -A 10 trinkets

# Verify spell has the trinket key
cat bookrack/my-book/applications/api.yaml | grep -E "vault:|istio:|tarot:"
```

**Appendix not merging correctly?**
```bash
# View final appendix in Application values
kubectl get application -n argocd my-book-applications-nginx \
  -o jsonpath='{.spec.sources[0].helm.values}' | yq .lexicon
```

**Cluster selection not working?**
```bash
# Check clusterSelector and lexicon
kubectl get application -n argocd my-book-applications-nginx \
  -o jsonpath='{.spec.destination.server}'

# Should match lexicon entry clusterURL
```

---

## Architecture Summary

```
┌─────────────────────────────────────────────────────────┐
│ LIBRARIAN INTERNAL FLOW                                 │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  1. READ BOOKRACK STRUCTURE                             │
│     bookrack/my-book/index.yaml                         │
│     bookrack/my-book/applications/*.yaml                │
│                                                          │
│  2. PASS 1: CONSOLIDATE APPENDIX                        │
│     book.appendix                                        │
│       → chapter.appendix (merge)                         │
│         → spell.appendix (merge)                         │
│           → $globalAppendix                              │
│                                                          │
│  3. PASS 2: GENERATE APPLICATIONS                       │
│     For each spell:                                      │
│       ├─ Detect trinkets (vault, istio, tarot, etc.)    │
│       ├─ Build final appendix (global + local)          │
│       ├─ Generate multi-source spec:                    │
│       │   ├─ Source 1: defaultTrinket or custom chart   │
│       │   └─ Sources 2..N: Detected trinkets            │
│       ├─ Apply sync policies (book < chapter < spell)   │
│       └─ Select cluster via runicIndexer                │
│                                                          │
│  4. OUTPUT: ArgoCD Applications                         │
│     apiVersion: argoproj.io/v1alpha1                    │
│     kind: Application                                    │
│     spec:                                                │
│       sources: [summon, kaster, ...]                    │
│       destination: {server, namespace}                  │
│       syncPolicy: {automated, retry}                    │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### Key Insights

- **Two-pass** ensures complete context before generation
- **Multi-source** enables modular glyph composition
- **Trinket detection** happens automatically via registered keys
- **Configuration hierarchy** allows flexible overrides
- **Lexicon** provides dynamic infrastructure discovery
- **Runic indexer** enables label-based matching

This architecture enables the declarative, composable, GitOps workflow that kast-system provides.

---

**Back to:** [Bootstrapping Guide](BOOTSTRAPPING.md) | [Librarian Guide](LIBRARIAN.md)
