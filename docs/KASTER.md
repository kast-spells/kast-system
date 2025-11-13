# Kaster

Orchestration chart that serves as the package manager for [glyphs](GLYPHS.md). Kaster coordinates multiple glyphs by iterating glyph definitions and invoking templates.

## Overview

Kaster is the central orchestration mechanism in kast-system that:
- Iterates over glyph definitions in spell configuration
- Invokes appropriate glyph templates (vault, istio, certManager, etc.)
- Passes context (spellbook, chapter, lexicon) to glyphs
- Generates Kubernetes resources from glyph definitions
- Enables composition of complex infrastructure patterns

**Pattern:** Infrastructure Orchestration via Glyphs

**Location:** `charts/kaster/`

**Deployment:** Automatically added as multi-source by [Librarian](LIBRARIAN.md) when spell has `glyphs:` field

## Architecture

```
┌─────────────────────────────────────────────────────┐
│ Spell YAML (glyphs configuration)                  │
│ - glyphs.vault, glyphs.istio, etc.                 │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│ Librarian                                           │
│ - Detects `glyphs:` field in spell                 │
│ - Adds kaster as additional source                 │
│ - Passes spellbook/chapter/lexicon context         │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│ Kaster Chart                                        │
│ - Iterates glyph definitions by name               │
│ - Invokes glyph templates                          │
│ - Passes $root and $glyphDefinition                │
└──────────────────────┬──────────────────────────────┘
                       │
        ┌──────────────┴──────────────┐
        │                             │
┌───────▼──────────┐      ┌──────────▼────────────┐
│ Vault Glyph      │      │ Istio Glyph           │
│ - vault.secret   │      │ - istio.virtualService│
│ - vault.prolicy  │      │ - istio.gateway       │
└────────┬─────────┘      └──────────┬────────────┘
         │                           │
         └──────────────┬────────────┘
                        │
        ┌───────────────▼───────────────┐
        │   Kubernetes Resources        │
        │ - VaultSecret, Policy         │
        │ - VirtualService, Gateway     │
        └───────────────────────────────┘
```

## How Kaster Works

### 1. Glyph Detection

[Librarian](LIBRARIAN.md) scans spell for glyph definitions:

```yaml
# Spell
glyphs:
  vault:                    # Vault glyph definitions
    app-secret:             # Resource name
      type: secret
  istio:                    # Istio glyph definitions
    app-vs:                 # Resource name
      type: virtualService
```

### 2. Multi-Source Addition

[Librarian](LIBRARIAN.md) adds kaster as additional source:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
spec:
  sources:
    # Source 1: Main chart (summon)
    - repoURL: https://github.com/kast-spells/kast-system.git
      path: ./charts/summon
      helm:
        values: |
          name: my-app
          # ...

    # Source 2: Kaster (glyphs) - ADDED AUTOMATICALLY
    - repoURL: https://github.com/kast-spells/kast-system.git
      path: ./charts/kaster
      helm:
        values: |
          glyphs:
            vault:
              app-secret:               # Resource name
                type: secret
            istio:
              app-vs:                   # Resource name
                type: virtualService
          spellbook:
            name: my-book
          chapter:
            name: production
          lexicon:
            - name: vault-server
              type: vault
              url: https://vault.prod.svc:8200
```

### 3. Glyph Iteration

Kaster template iterates over each glyph type:

```go
{{- range $chartName, $_ := $root.Subcharts }}
  {{- range $glyphName, $glyph := index $root.Values.glyphs $chartName }}
    {{- $glyphWithName := merge $glyph (dict "name" $glyphName) }}
    {{- include (printf "%s.%s" $chartName $glyph.type) (list $root $glyphWithName) }}
  {{- end }}
{{- end }}
```

**Example:**

```yaml
glyphs:
  vault:                        # $chartName = "vault"
    app-secret:                 # $glyphName = "app-secret"
      type: secret              # $glyph.type = "secret"
      # Template invoked: "vault.secret"

    app-policy:                 # $glyphName = "app-policy"
      type: prolicy             # $glyph.type = "prolicy"
      # Template invoked: "vault.prolicy"

  istio:                        # $chartName = "istio"
    app-vs:                     # $glyphName = "app-vs"
      type: virtualService      # $glyph.type = "virtualService"
      # Template invoked: "istio.virtualService"
```

### 4. Template Invocation

For each glyph, kaster calls the corresponding template:

```go
{{- include "vault.secret" (list $root $glyphDefinition) }}
```

**Parameters passed:**
- `$root` (index 0): Chart root context with Values, Release, Chart
- `$glyphDefinition` (index 1): Individual glyph configuration

### 5. Resource Generation

Glyph templates generate Kubernetes resources:

```yaml
# vault.secret template generates:
---
apiVersion: redhatcop.redhat.io/v1alpha1
kind: VaultSecret
metadata:
  name: app-secret
spec:
  vaultSecretDefinitions:
    - # ...

---
apiVersion: v1
kind: Secret
metadata:
  name: app-secret
# Synced from Vault
```

## Glyph Structure

### Glyph Definition

```yaml
glyphs:
  <glyph-name>:                  # Glyph package (vault, istio, etc.)
    <resource-name>:             # Resource identifier (becomes map key)
      type: <template-type>      # Template to invoke
      # Additional glyph-specific parameters
```

### Template Naming Convention

Template names follow pattern: `<glyph-name>.<type>`

**Examples:**
- `vault.secret` - Creates Vault secret
- `vault.prolicy` - Creates Vault policy
- `istio.virtualService` - Creates VirtualService
- `istio.gateway` - Creates Gateway
- `certManager.certificate` - Creates Certificate

### Standard Parameters

All glyphs receive:

| Parameter | Description | Source |
|-----------|-------------|--------|
| `$root.Values.spellbook` | Book metadata | Librarian |
| `$root.Values.chapter` | Chapter metadata | Librarian |
| `$root.Values.lexicon` | Infrastructure registry | Book _lexicon + appendix |
| `$root.Release.Name` | Spell name | Helm |
| `$root.Release.Namespace` | Deployment namespace | Helm |
| `$glyphDefinition.*` | Glyph configuration | Spell |

## Context Propagation

See [Hierarchy Systems](HIERARCHY_SYSTEMS.md) for detailed information on how context flows through the system.

### Spellbook Context

```yaml
spellbook:
  name: my-book               # Book name
  prolicy:                    # Book-level vault policy
    extraPolicy: []
```

**Usage in glyphs:**

```go
{{- $bookName := $root.Values.spellbook.name }}
# Used in vault paths, resource labels, etc.
```

### Chapter Context

```yaml
chapter:
  name: production            # Chapter name
  prolicy:                    # Chapter-level vault policy
    extraPolicy: []
```

**Usage in glyphs:**

```go
{{- $chapterName := $root.Values.chapter.name }}
# Used in lexicon defaults, vault paths, etc.
```

### Lexicon Context

```yaml
lexicon:
  - name: production-vault
    type: vault
    url: https://vault.prod.svc:8200
    labels:
      environment: production
      default: chapter
```

**Usage in glyphs:**

```go
{{- $vaults := get (include "runicIndexer.runicIndexer"
     (list $root.Values.lexicon
           $glyphDefinition.selector
           "vault"
           $root.Values.chapter.name) | fromJson) "results" }}
```

See [LEXICON.md](LEXICON.md) for details on runic indexer.

## Available Glyphs

Kaster orchestrates these glyph packages:

### 1. Vault

**Location:** `charts/glyphs/vault/`

**Templates:**
- `vault.secret` - Sync secrets from Vault
- `vault.prolicy` - Create Vault policy + auth role
- `vault.cryptoKey` - Generate keypairs
- `vault.randomSecret` - Generate random passwords
- `vault.customPasswordPolicy` - Password policies
- `vault.kube-auth` - Kubernetes auth backend
- `vault.databaseEngine` - Dynamic database credentials
- `vault.oidc-auth` - OIDC authentication
- `vault.server` - Vault server deployment (dev)

**Documentation:** [VAULT.md](VAULT.md), [docs/glyphs/vault.md](glyphs/vault.md)

### 2. Istio

**Location:** `charts/glyphs/istio/`

**Templates:**
- `istio.virtualService` - Traffic routing
- `istio.gateway` - Ingress/egress
- `istio.destinationRule` - Load balancing, circuit breaking
- `istio.serviceEntry` - External service registration

**Documentation:** [docs/glyphs/istio.md](glyphs/istio.md)

### 3. CertManager

**Location:** `charts/glyphs/certManager/`

**Templates:**
- `certManager.certificate` - TLS certificates
- `certManager.issuer` - Certificate issuer
- `certManager.clusterIssuer` - Cluster-wide issuer
- `certManager.dnsEndpoint` - DNS record creation
- `certManager.dnsEndpointSourced` - DNS from secret (DKIM)

**Documentation:** [docs/glyphs/certmanager.md](glyphs/certmanager.md)

### 4. Argo Events

**Location:** `charts/glyphs/argo-events/`

**Templates:**
- `argo-events.eventSource` - Event sources (webhooks, Kafka, etc.)
- `argo-events.sensor` - Event triggers
- `argo-events.eventBus` - Event bus (NATS/JetStream)

**Documentation:** [docs/glyphs/argo-events.md](glyphs/argo-events.md)

### 5. Crossplane

**Location:** `charts/glyphs/crossplane/`

**Templates:**
- `crossplane.composition` - Cloud resource compositions
- `crossplane.compositeResourceDefinition` - CRD definitions
- `crossplane.claim` - Resource claims

**Documentation:** [docs/glyphs/crossplane.md](glyphs/crossplane.md)

### 6. GCP

**Location:** `charts/glyphs/gcp/`

**Templates:**
- `gcp.bucket` - GCS buckets
- `gcp.serviceAccount` - GCP service accounts
- `gcp.workloadIdentity` - Workload identity binding

**Documentation:** [docs/glyphs/gcp.md](glyphs/gcp.md)

### 7. Postgres Cloud

**Location:** `charts/glyphs/postgres-cloud/`

**Templates:**
- `postgres-cloud.cluster` - PostgreSQL cluster
- `postgres-cloud.database` - Database provisioning

**Documentation:** [docs/glyphs/postgres-cloud.md](glyphs/postgres-cloud.md)

### 8. Keycloak

**Location:** `charts/glyphs/keycloak/`

**Templates:**
- `keycloak.realm` - Keycloak realm
- `keycloak.client` - OIDC/SAML clients
- `keycloak.user` - User provisioning
- `keycloak.group` - Group management

**Documentation:** [docs/glyphs/keycloak.md](glyphs/keycloak.md)

### 9. Common

**Location:** `charts/glyphs/common/`

**Utility templates** (not invoked via kaster iteration):
- `common.name` - Resource name generation
- `common.labels` - Standard labels
- `common.selectorLabels` - Pod selectors
- `common.annotations` - Standard annotations
- `common.serviceAccountName` - ServiceAccount name

**Documentation:** [docs/glyphs/common.md](glyphs/common.md)

### 10. FreeForm

**Location:** `charts/glyphs/freeForm/`

**Templates:**
- `freeForm.resource` - Pass-through YAML

**Documentation:** [docs/glyphs/freeform.md](glyphs/freeform.md)

## Usage Patterns

### Basic Glyphs

```yaml
name: my-app

glyphs:
  vault:
    app-config:                 # Resource name
      type: secret
      keys: [api_key, database_url]
```

**Result:** [VaultSecret](VAULT.md) resource syncing to K8s Secret

### Multi-Glyph Composition

```yaml
name: my-app

glyphs:
  # Secrets management
  vault:
    app-policy:                 # Resource name
      type: prolicy
      serviceAccount: my-app
    app-secrets:                # Resource name
      type: secret
      keys: [password]

  # Service mesh
  istio:
    app-vs:                     # Resource name
      type: virtualService
      hosts: [app.example.com]

  # TLS certificates
  certManager:
    app-tls:                    # Resource name
      type: certificate
      dnsNames: [app.example.com]
```

**Result:** [Policy](VAULT.md), Secret, VirtualService, Certificate all generated

### Infrastructure Glyph (No Workload)

```yaml
name: vault-setup

# No image/workload - pure infrastructure

glyphs:
  vault:
    team-policy:                # Resource name
      type: prolicy
      serviceAccount: team-sa
      extraPolicy:
        - path: database/creds/*
          capabilities: [read]

    strong-passwords:           # Resource name
      type: customPasswordPolicy
      policy: |
        length = 24
        rule "charset" {
          charset = "abcdefghijklmnopqrstuvwxyz"
          min-chars = 6
        }
```

**Result:** [Vault policy](VAULT.md) and password policy (no pods)

### Lexicon-Driven Glyph

```yaml
# Lexicon
lexicon:
  - name: production-gateway
    type: istio-gw
    gateway: istio-system/prod-gw
    labels:
      environment: production
      default: chapter
    chapter: production

# Spell
glyphs:
  istio:
    app-vs:                     # Resource name
      type: virtualService
      selector:
        environment: production  # Selects production-gateway
      hosts: [app.example.com]
```

**Result:** VirtualService uses production-gateway from [lexicon](LEXICON.md)

## Testing Glyphs

### Via Kaster (Recommended)

**CRITICAL:** Glyphs must be tested through kaster, not directly.

```bash
# Test specific glyph
make glyphs vault

# Test all glyphs
make test-glyphs-all

# List available glyphs
make list-glyphs

# Generate expected outputs
make generate-expected GLYPH=vault

# Show differences
make show-glyph-diff GLYPH=vault EXAMPLE=secrets
```

### Creating Glyph Tests

**1. Create example:**

```bash
# Create test case
cat > charts/glyphs/vault/examples/my-test.yaml <<EOF
lexicon:
  - name: test-vault
    type: vault
    url: http://vault.vault.svc:8200
    namespace: vault
    authPath: kubernetes
    secretPath: kv
    labels:
      default: book

glyphs:
  vault:
    test-secret:                # Resource name
      type: secret
      keys: [password]
EOF
```

**2. Run test (expect failure - RED):**

```bash
make glyphs vault
# Should show: ❌ vault-my-test
```

**3. Fix/implement feature (GREEN):**

```bash
# Edit glyph templates
# Run test again
make glyphs vault
# Should show: ✅ vault-my-test
```

**4. Generate expected output:**

```bash
make generate-expected GLYPH=vault
```

## Kaster Configuration

### Values Structure

```yaml
# Automatically populated by Librarian
glyphs:
  <glyph-name>:
    <resource-name>:            # Resource identifier
      type: <template-type>
      # Glyph-specific config

spellbook:
  name: <book-name>
  prolicy:
    extraPolicy: []

chapter:
  name: <chapter-name>
  prolicy:
    extraPolicy: []

lexicon:
  - name: <resource-name>
    type: <resource-type>
    # Lexicon entry fields
```

### Chart.yaml

```yaml
apiVersion: v2
name: kaster
description: Glyph orchestration chart for kast-system
version: 1.0.0
dependencies: []  # Glyphs are static symlinks, not dependencies
```

**Important:** Dependencies field is empty. Glyphs are included via static symlinks, not Helm dependencies.

## Troubleshooting

### Glyph Not Invoked

**Symptoms:** Glyph definition in spell but no resources generated.

**Check:**

```bash
# 1. Verify glyph detected by librarian
helm template my-book librarian --set name=my-book \
  | yq '.spec.sources[] | select(.path | contains("kaster"))'

# 2. Verify glyph configuration passed
helm template my-book librarian --set name=my-book \
  | yq '.spec.sources[] | select(.path | contains("kaster")) | .helm.values.glyphs'

# 3. Test glyph rendering
make glyphs <glyph-name>
```

**Common causes:**
- Typo in glyph name (must match directory name)
- Typo in type (must match template name)
- Template not defined in glyph

### Template Not Found

**Symptoms:** `template "<glyph>.<type>" not found`

**Check:**

```bash
# Verify template exists
ls charts/glyphs/<glyph-name>/templates/

# Check template definition
grep -r "define.*<glyph-name>.<type>" charts/glyphs/<glyph-name>/
```

**Solution:** Create missing template or fix type in spell

### Context Not Available

**Symptoms:** `can't evaluate field X in type interface {}`

**Check:**

```bash
# Verify context passed by librarian
helm template my-book librarian --set name=my-book \
  | yq '.spec.sources[] | select(.path | contains("kaster")) | .helm.values' \
  | yq '.spellbook, .chapter, .lexicon'
```

**Common causes:**
- Librarian not passing context (check bookData flag)
- Accessing non-existent field
- Incorrect parameter extraction in template

### Resources Not Created

**Symptoms:** Kaster renders but K8s resources not created.

**Check:**

```bash
# Check ArgoCD Application manifests
argocd app manifests <app-name>

# Verify resources in cluster
kubectl get <resource-type> -n <namespace>

# Check ArgoCD sync status
argocd app get <app-name>
```

**Common causes:**
- ArgoCD sync failed
- CRD not installed (e.g., VaultSecret CRD)
- Resource created in wrong namespace
- Invalid resource spec

## Best Practices

### Glyph Selection

**Use specific glyphs for specific purposes:**

```yaml
# Good: Specific glyphs
glyphs:
  vault:
    - type: secret        # Vault integration
  istio:
    - type: virtualService  # Service mesh
  certManager:
    - type: certificate   # TLS certificates

# Avoid: Trying to do everything in one glyph
glyphs:
  freeForm:
    - type: resource
      yaml: |
        # Entire manifests here - loses kast benefits
```

### Lexicon Integration

**Use lexicon for infrastructure discovery:**

```yaml
# Good: Selector-based (environment-aware)
glyphs:
  vault:
    - type: secret
      selector:
        environment: production

# Avoid: Hardcoded (not portable)
glyphs:
  vault:
    - type: secret
      vaultURL: https://vault.prod.svc:8200  # Hard to change
```

### Context Usage

**Leverage spellbook/chapter context:**

```yaml
# Automatically uses book name in vault paths
glyphs:
  vault:
    - type: secret
      path: book  # Resolves to: kv/data/<spellbook>/publics/secret
```

### Testing

**Always test glyphs via kaster:**

```bash
# Correct: Test through kaster
make glyphs vault

# Incorrect: Direct rendering (will fail)
helm template charts/glyphs/vault  # Missing dependencies!
```

## Related Documentation

- [GLYPHS.md](GLYPHS.md) - Comprehensive glyph overview
- [GLYPH_DEVELOPMENT.md](GLYPH_DEVELOPMENT.md) - Creating new glyphs
- [GLYPHS_REFERENCE.md](GLYPHS_REFERENCE.md) - All available glyphs
- [LEXICON.md](LEXICON.md) - Infrastructure registry
- [LIBRARIAN.md](LIBRARIAN.md) - Multi-source orchestration
- [VAULT.md](VAULT.md) - Vault glyph details
- [docs/glyphs/](glyphs/) - Individual glyph documentation

## Examples

See glyph examples in:
- `charts/glyphs/*/examples/` - Per-glyph examples
- `bookrack/example-tdd-book/infrastructure/` - Real-world glyph usage
- `charts/kaster/examples/` - Kaster orchestration examples

## Summary

**Kaster:**
- Orchestrates glyphs (vault, istio, certManager, etc.)
- Iterates glyph definitions from spell
- Invokes glyph templates with context
- Generates Kubernetes resources
- Automatically added by Librarian when `glyphs:` present

**Pattern:** Infrastructure as Code via Glyph Composition

**Testing:** Use `make glyphs <name>` to test via kaster

**Extensibility:** Create new glyphs in `charts/glyphs/<name>/`
