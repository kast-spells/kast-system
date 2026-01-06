# Glyphs - Infrastructure as Code Templates

Comprehensive guide to the glyph system in runik. Glyphs are reusable Helm named templates that generate Kubernetes resources for infrastructure integration.

## Overview

**Glyph:** Reusable Helm template that generates one or more Kubernetes resources based on input parameters.

**Purpose:**
- Encapsulate infrastructure patterns (vault, istio, certificates, databases)
- Provide consistent interfaces across deployments
- Enable composition of complex systems from simple definitions
- Reduce YAML duplication and boilerplate
- Use infrastructure discovery via [Lexicon](LEXICON.md)

**Core Concept:** "Spell once, use everywhere"

## Architecture

```
┌─────────────────────────────────────────────────────┐
│ Spell Configuration (glyphs definition)             │
│ - Declarative infrastructure requirements          │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│ Kaster Orchestrator                                 │
│ - Iterates glyph definitions                        │
│ - Invokes glyph templates                           │
│ - Passes context (spellbook, chapter, lexicon)     │
└──────────────────────┬──────────────────────────────┘
                       │
        ┌──────────────┴──────────────┐
        │                             │
┌───────▼──────────┐      ┌──────────▼────────────┐
│ Glyph Templates  │      │ Runic Indexer         │
│ - Named templates│      │ - Infrastructure      │
│ - Resource gen   │      │   discovery           │
└────────┬─────────┘      │ - Lexicon queries     │
         │                └──────────┬────────────┘
         │                           │
         └──────────────┬────────────┘
                        │
        ┌───────────────▼───────────────┐
        │   Kubernetes Resources        │
        │ - Deployments, Services       │
        │ - CRDs (VaultSecret, etc.)    │
        │ - Configuration (ConfigMaps)  │
        └───────────────────────────────┘
```

**See [Kaster](KASTER.md) for orchestration details and [Lexicon](LEXICON.md) for infrastructure discovery.**

## Key Concepts

### 1. Glyph Definition

User-facing configuration that declares infrastructure requirements using a **map structure** where the key is the resource name:

```yaml
glyphs:
  vault:                        # Glyph package name
    database-creds:             # Resource name (map key)
      type: secret              # Template type within package
      format: env               # Glyph-specific parameters
      keys: [username, password]
```

**IMPORTANT:** Glyphs use a map structure (not a list). The resource name is the map key, not a `name:` field inside the definition.

### 2. Glyph Template

Helm named template that generates Kubernetes resources:

```go
{{- define "vault.secret" -}}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1 }}
---
apiVersion: redhatcop.redhat.io/v1alpha1
kind: VaultSecret
metadata:
  name: {{ $glyphDefinition.name }}
spec:
  # Generate VaultSecret based on $glyphDefinition
{{- end }}
```

### 3. Glyph Package

Collection of related templates organized in a chart:

```
charts/glyphs/vault/
├── Chart.yaml
├── templates/
│   ├── secret.tpl           # vault.secret template
│   ├── prolicy.tpl          # vault.prolicy template
│   ├── crypto-key.tpl       # vault.cryptoKey template
│   └── _helpers.tpl
└── examples/
    ├── secrets.yaml
    └── prolicy-test.yaml
```

### 4. Runic Indexer

Query system for discovering infrastructure from [Lexicon](LEXICON.md):

```go
{{- $vaults := get (include "runicIndexer.runicIndexer"
     (list $root.Values.lexicon
           $glyphDefinition.selector
           "vault"
           $root.Values.chapter.name) | fromJson) "results" }}
```

**Pattern:** Glyphs use runic indexer to find infrastructure (vault servers, databases, gateways) from lexicon based on selectors or defaults. See [Lexicon](LEXICON.md) for query patterns.

## How Glyphs Work

### Step 1: Declaration in Spell

User declares infrastructure requirements:

```yaml
name: my-app

glyphs:
  vault:
    app-config:                 # Resource name as map key
      type: secret
      keys: [api_key]

  istio:
    app-routing:                # Resource name as map key
      type: virtualService
      hosts: [app.example.com]
```

### Step 2: Kaster Detection

Librarian detects `glyphs:` field and adds [Kaster](KASTER.md) as multi-source:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
spec:
  sources:
    - path: ./charts/summon        # Main application
    - path: ./charts/kaster        # Glyphs orchestrator (auto-added)
      helm:
        values: |
          glyphs:              # Glyph definitions passed
            vault: {...}
            istio: {...}
          spellbook: {...}     # Context passed
          chapter: {...}
          lexicon: [...]
```

See [Kaster](KASTER.md) for orchestration mechanics.

### Step 3: Glyph Iteration

[Kaster](KASTER.md) iterates over glyph definitions and invokes templates:

```go
{{- range $glyphName, $glyphMap := .Values.glyphs }}
  {{- range $resourceName, $glyphDefinition := $glyphMap }}
    {{- $templateName := printf "%s.%s" $glyphName $glyphDefinition.type }}
    {{- include $templateName (list $ (merge (dict "name" $resourceName) $glyphDefinition)) }}
  {{- end }}
{{- end }}
```

### Step 4: Template Execution

Each glyph template:
1. Receives `$root` (chart context) and `$glyphDefinition` (user config with resource name)
2. Queries lexicon via runic indexer (if needed) - see [Lexicon](LEXICON.md)
3. Generates Kubernetes resources
4. Returns YAML manifests

### Step 5: Resource Deployment

ArgoCD deploys generated resources to Kubernetes:
- VaultSecret resources (see [Vault Integration](VAULT.md))
- Istio VirtualServices
- Certificate requests
- Custom resources

## Glyph Categories

### Infrastructure Integration

**Purpose:** Connect applications to infrastructure services

**Glyphs:**
- **vault** - Secrets management, authentication, policies (see [Vault Integration](VAULT.md))
- **istio** - Service mesh, routing, security
- **certManager** - TLS certificates, DNS records
- **argo-events** - Event-driven workflows

**Usage Pattern:**
```yaml
glyphs:
  vault:
    app-policy:                 # Resource name as map key
      type: prolicy             # Create policy
    app-secret:                 # Resource name as map key
      type: secret              # Sync secrets
  istio:
    app-routing:                # Resource name as map key
      type: virtualService      # Configure routing
```

**Documentation:**
- [Vault Integration](VAULT.md) - Vault integration
- [docs/glyphs/istio.md](glyphs/istio.md) - Istio integration
- [docs/glyphs/certmanager.md](glyphs/certmanager.md) - Certificate management
- [docs/glyphs/argo-events.md](glyphs/argo-events.md) - Event workflows

### Cloud Providers

**Purpose:** Provision cloud resources declaratively

**Glyphs:**
- **gcp** - Google Cloud Platform resources
- **crossplane** - Multi-cloud resource provisioning
- **s3** - S3-compatible storage

**Usage Pattern:**
```yaml
glyphs:
  gcp:
    my-bucket:                  # Resource name as map key
      type: bucket              # Create GCS bucket
    my-sa:                      # Resource name as map key
      type: serviceAccount      # Create GCP SA
    app-identity:               # Resource name as map key
      type: workloadIdentity    # Bind K8s SA to GCP SA
```

**Documentation:**
- [docs/glyphs/gcp.md](glyphs/gcp.md)
- [docs/glyphs/crossplane.md](glyphs/crossplane.md)
- [docs/glyphs/s3.md](glyphs/s3.md)

### Database Management

**Purpose:** Database provisioning and access management

**Glyphs:**
- **postgresql** - Cloud-hosted PostgreSQL clusters
- **vault** (databaseEngine) - Dynamic database credentials

**Usage Pattern:**
```yaml
glyphs:
  postgresql:
    app-db:                     # Resource name as map key
      type: cluster             # Create PostgreSQL cluster
      replicas: 3

  vault:
    postgres-engine:            # Resource name as map key
      type: databaseEngine      # Dynamic credentials
      roles:
        - name: readonly
          dbName: myapp
```

**Documentation:**
- [Vault Integration](VAULT.md) (databaseEngine section)

### Identity & Access

**Purpose:** Authentication, authorization, identity management

**Glyphs:**
- **keycloak** - OIDC/SAML identity provider
- **vault** (oidc-auth, kube-auth) - Authentication backends

**Usage Pattern:**
```yaml
glyphs:
  keycloak:
    myapp-realm:                # Resource name as map key
      type: realm               # Create realm
    myapp-client:               # Resource name as map key
      type: client              # OIDC client
      clientId: myapp
```

**Documentation:**
- [docs/glyphs/keycloak.md](glyphs/keycloak.md)
- [Vault Integration](VAULT.md) (authentication section)

### System Utilities

**Purpose:** Common patterns and utilities

**Glyphs:**
- **common** - Shared utilities (labels, names, annotations)
- **freeForm** - Pass-through YAML
- **runic-system** - Runic indexer and discovery

**Usage Pattern:**
```yaml
# common glyph (used by other glyphs, not directly)
labels:
  {{- include "common.labels" $root | nindent 4 }}

# freeForm glyph (for arbitrary resources)
glyphs:
  freeForm:
    custom-config:              # Resource name as map key
      type: resource
      yaml: |
        apiVersion: v1
        kind: ConfigMap
        metadata:
          name: custom-config
```

**Documentation:**
- [docs/glyphs/common.md](glyphs/common.md)
- [docs/glyphs/freeform.md](glyphs/freeform.md)
- [docs/glyphs/runic-system.md](glyphs/runic-system.md)

## Common Patterns

### Pattern 1: Infrastructure Discovery

**Use [Lexicon](LEXICON.md) for environment-aware configuration:**

```yaml
# Lexicon (in book _lexicon/)
lexicon:
  - name: production-vault
    type: vault
    url: https://vault.prod.svc:8200
    labels:
      environment: production
      default: chapter
    chapter: production

# Spell (automatically finds production-vault in production chapter)
glyphs:
  vault:
    app-secret:                 # Resource name as map key
      type: secret
      # Uses chapter default vault automatically via runic indexer
```

**Benefits:**
- Same spell works across environments
- Infrastructure changes don't require spell updates
- Centralized infrastructure configuration in [Lexicon](LEXICON.md)

### Pattern 2: Multi-Glyph Composition

**Combine glyphs to build complete infrastructure:**

```yaml
name: payment-service

glyphs:
  # Authentication & Authorization
  vault:
    payment-policy:             # Resource name as map key
      type: prolicy
      serviceAccount: payment-service
    database-creds:             # Resource name as map key
      type: secret
      keys: [username, password]
    stripe-api-key:             # Resource name as map key
      type: secret
      keys: [api_key]

  # Service Mesh
  istio:
    payment-api:                # Resource name as map key
      type: virtualService
      hosts: [payments.example.com]
      circuitBreaking:
        enabled: true

  # TLS Certificates
  certManager:
    payment-tls:                # Resource name as map key
      type: certificate
      dnsNames: [payments.example.com]
      issuerRef:
        name: letsencrypt-prod
```

**Result:** Complete infrastructure stack from declarative configuration

### Pattern 3: Hierarchical Configuration

**Use spellbook/chapter context for scoping:**

```yaml
# Book-level vault policy (all chapters inherit)
spellbook:
  prolicy:
    extraPolicy:
      - path: shared/certificates/*
        capabilities: [read]

# Chapter-level vault policy (production only)
chapter:
  prolicy:
    extraPolicy:
      - path: production/database/*
        capabilities: [read, list]

# Spell-level vault policy (application-specific)
glyphs:
  vault:
    app-policy:                 # Resource name as map key
      type: prolicy
      extraPolicy:
        - path: applications/payment/secrets
          capabilities: [create, read, update]
```

**Result:** Policy merges book + chapter + spell extraPolicy

### Pattern 4: Conditional Infrastructure

**Enable infrastructure based on environment:**

```yaml
# Development
name: my-app
glyphs:
  vault:
    dev-credentials:            # Resource name as map key
      type: secret
      # Development uses simpler auth

# Production
name: my-app
glyphs:
  vault:
    prod-credentials:           # Resource name as map key
      type: secret
      # Production uses mTLS

  istio:
    app-routing:                # Resource name as map key
      type: virtualService
      # Only production has external routing
      hosts: [app.production.com]

  certManager:
    app-tls:                    # Resource name as map key
      type: certificate
      # Only production has TLS certificates
      dnsNames: [app.production.com]
```

### Pattern 5: Secret Injection

**Inject secrets at different scopes:**

```yaml
glyphs:
  vault:
    # Book-level (shared across all chapters)
    registry-credentials:       # Resource name as map key
      type: secret
      path: book
      keys: [username, password]

    # Chapter-level (shared within chapter)
    database-credentials:       # Resource name as map key
      type: secret
      path: chapter
      keys: [host, port, database]

    # Namespace-level (application-specific)
    app-private-key:            # Resource name as map key
      type: secret
      # Default path (namespace-scoped)
      keys: [private_key]
```

**See [HIERARCHY_SYSTEMS.md](HIERARCHY_SYSTEMS.md) for path hierarchy details**

## Glyph Template Anatomy

### Basic Structure

```go
{{/*runik - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

glyph-name.template-type description

Parameters:
- $root: Chart root context (index . 0)
- $glyphDefinition: Configuration (index . 1)
  - name: Resource name (injected from map key)
  - field1: Description (optional)

Example:
  glyph-name:
    my-resource:              # Map key becomes name
      type: template-type
      field1: value
*/}}

{{- define "glyph-name.template-type" -}}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1 }}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ $glyphDefinition.name }}
  labels:
    {{- include "common.labels" $root | nindent 4 }}
data:
  field1: {{ $glyphDefinition.field1 }}
{{- end }}
```

### Parameter Extraction

```go
{{- define "myglyph.resource" -}}
{{- $root := index . 0 -}}           # Chart context
{{- $glyphDefinition := index . 1 }} # User configuration (includes name from map key)

# Access root context
{{- $spellbookName := $root.Values.spellbook.name }}
{{- $chapterName := $root.Values.chapter.name }}
{{- $namespace := $root.Release.Namespace }}

# Access glyph definition
{{- $resourceName := $glyphDefinition.name }}  # Injected from map key
{{- $enabled := default true $glyphDefinition.enabled }}
{{- $replicas := default 1 $glyphDefinition.replicas }}
{{- end }}
```

### Runic Indexer Integration

```go
{{- define "myglyph.resource" -}}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1 }}

{{/* Query lexicon for infrastructure (see LEXICON.md) */}}
{{- $results := get (include "runicIndexer.runicIndexer"
     (list $root.Values.lexicon
           (default dict $glyphDefinition.selector)
           "resource-type"
           $root.Values.chapter.name) | fromJson) "results" }}

{{- range $resource := $results }}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ $glyphDefinition.name }}
data:
  url: {{ $resource.url }}
  namespace: {{ $resource.namespace }}
{{- end }}
{{- end }}
```

**See [Lexicon](LEXICON.md) for runic indexer query patterns.**

### Common Glyph Integration

```go
{{- define "myglyph.resource" -}}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1 }}
---
apiVersion: v1
kind: Service
metadata:
  name: {{ include "common.name" $root }}
  labels:
    {{- include "common.labels" $root | nindent 4 }}
  annotations:
    {{- include "common.annotations" $root | nindent 4 }}
spec:
  selector:
    {{- include "common.selectorLabels" $root | nindent 4 }}
{{- end }}
```

## Glyph Testing

### TDD Workflow

**1. RED - Write failing test:**

```bash
# Create example
cat > charts/glyphs/myglyph/examples/basic.yaml <<EOF
lexicon:
  - name: test-resource
    type: mytype
    url: http://test.svc
    labels:
      default: book

glyphs:
  myglyph:
    test-resource:              # Map key is resource name
      type: resource
EOF

# Verify test fails (template doesn't exist)
make glyphs myglyph
# Output: ❌ myglyph-basic (template not found)
```

**2. GREEN - Implement template:**

```bash
# Create template
cat > charts/glyphs/myglyph/templates/resource.tpl <<'EOF'
{{- define "myglyph.resource" -}}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1 }}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ $glyphDefinition.name }}
data:
  test: value
{{- end }}
EOF

# Verify test passes
make glyphs myglyph
# Output: ✅ myglyph-basic
```

**3. REFACTOR - Generate expected output:**

```bash
# Lock in expected output
make generate-expected GLYPH=myglyph

# Verify diff validation
make glyphs myglyph
# Output: ✅ myglyph-basic (output matches expected)
```

**See [Glyph Development](GLYPH_DEVELOPMENT.md) for complete TDD workflow and [TDD Commands](TDD_COMMANDS.md) for testing commands.**

### Testing Commands

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

# Clean test outputs
make clean-output-tests
```

**See [TDD Commands](TDD_COMMANDS.md) for complete command reference.**

## Best Practices

### Design for Reusability

**Good (reusable):**
```yaml
glyphs:
  vault:
    app-secret:                 # Map key is resource name
      type: secret
      selector: {environment: production}  # Environment-aware via lexicon
```

**Avoid (hardcoded):**
```yaml
glyphs:
  vault:
    app-secret:                 # Map key is resource name
      type: secret
      vaultURL: https://vault.prod.svc:8200  # Hardcoded
```

### Use Lexicon for Discovery

**Use runic indexer with [Lexicon](LEXICON.md):**
```yaml
# Lexicon defines infrastructure
lexicon:
  - name: production-db
    type: database
    host: postgres.prod.svc
    labels:
      environment: production
      default: chapter

# Glyph discovers automatically
glyphs:
  database:
    app-connection:             # Map key is resource name
      type: connection
      # Finds production-db in production chapter via runic indexer
```

### Validate Inputs

```go
{{- define "myglyph.resource" -}}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1 }}

{{/* Validate required fields */}}
{{- if not $glyphDefinition.name }}
  {{- fail "myglyph.resource requires 'name' field (injected from map key)" }}
{{- end }}

{{- if not (hasKey $glyphDefinition "type") }}
  {{- fail "myglyph.resource requires 'type' field" }}
{{- end }}
{{- end }}
```

### Provide Sensible Defaults

```go
# Always provide defaults for optional fields
enabled: {{ default true $glyphDefinition.enabled }}
replicas: {{ default 1 $glyphDefinition.replicas }}
format: {{ default "plain" $glyphDefinition.format }}
```

### Document Parameters

```go
{{/*
myglyph.resource creates a ConfigMap

Parameters:
- $root: Chart root context (index . 0)
- $glyphDefinition: Configuration (index . 1)
  - name: ConfigMap name (injected from map key)
  - enabled: Enable resource (optional, default: true)
  - data: ConfigMap data (optional)

Example:
  myglyph:
    my-config:              # Map key becomes name
      type: resource
      enabled: true
      data:
        key: value
*/}}
```

### Test Thoroughly

```
examples/
├── basic.yaml              # Minimal configuration
├── advanced.yaml           # All features
├── edge-cases.yaml         # Boundary conditions
├── lexicon-integration.yaml  # With runic indexer
└── multi-resource.yaml     # Multiple instances
```

**See [Glyph Development](GLYPH_DEVELOPMENT.md) for testing best practices.**

## Creating New Glyphs

### Quick Start

```bash
# 1. Create structure
mkdir -p charts/glyphs/myglyph/{templates,examples}

# 2. Create Chart.yaml
cat > charts/glyphs/myglyph/Chart.yaml <<EOF
apiVersion: v2
name: myglyph
description: My custom glyph
version: 1.0.0
EOF

# 3. Create test (RED)
cat > charts/glyphs/myglyph/examples/basic.yaml <<EOF
glyphs:
  myglyph:
    test-resource:              # Map key is resource name
      type: resource
EOF

# 4. Run test (expect failure)
make glyphs myglyph

# 5. Create template (GREEN)
cat > charts/glyphs/myglyph/templates/resource.tpl <<'EOF'
{{- define "myglyph.resource" -}}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1 }}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ $glyphDefinition.name }}
{{- end }}
EOF

# 6. Run test (expect success)
make glyphs myglyph

# 7. Generate expected output (REFACTOR)
make generate-expected GLYPH=myglyph
```

**See [Glyph Development](GLYPH_DEVELOPMENT.md) for complete development guide.**

## Troubleshooting

### Glyph Not Invoked

**Check:**
```bash
# Verify kaster source added (see KASTER.md)
helm template my-book librarian --set name=my-book \
  | yq '.spec.sources[] | select(.path | contains("kaster"))'

# Verify glyph configuration passed
make glyphs <name>
```

**See [Kaster](KASTER.md) for orchestration troubleshooting.**

### Template Not Found

**Check:**
```bash
# Verify template exists
ls charts/glyphs/<name>/templates/

# Check template name
grep -r "define.*<name>.<type>" charts/glyphs/<name>/
```

### Lexicon Query Returns Empty

**Check:**
```bash
# Verify lexicon entry exists
yq '.lexicon[] | select(.type == "<type>")' \
  charts/glyphs/<name>/examples/test.yaml

# Check selector matches labels
# Selector: {environment: production}
# Labels: {environment: production}  # Must match
```

**See [Lexicon](LEXICON.md) for query troubleshooting.**

### Resources Not Created

**Check:**
```bash
# Check ArgoCD manifests
argocd app manifests <app-name>

# Verify CRDs installed
kubectl get crd | grep <resource-type>

# Check resource namespace
kubectl get <resource> -n <namespace>
```

## Related Documentation

- [Kaster](KASTER.md) - Glyph orchestration
- [Glyph Development](GLYPH_DEVELOPMENT.md) - Creating glyphs
- [GLYPHS_REFERENCE.md](GLYPHS_REFERENCE.md) - Complete glyph list
- [Lexicon](LEXICON.md) - Infrastructure discovery
- [TDD Commands](TDD_COMMANDS.md) - Testing commands
- [Vault Integration](VAULT.md) - Vault glyph details
- [docs/glyphs/](glyphs/) - Individual glyph documentation

## Examples

### Complete Infrastructure Stack

```yaml
name: production-app

glyphs:
  # Secrets & Authentication
  vault:
    app-policy:                 # Map key is resource name
      type: prolicy
      serviceAccount: production-app
      extraPolicy:
        - path: database/creds/app-role
          capabilities: [read]

    app-config:                 # Map key is resource name
      type: secret
      format: env
      keys: [api_key, webhook_secret]

    database-creds:             # Map key is resource name
      type: secret
      format: env
      keys: [username, password]

  # Service Mesh
  istio:
    app-routing:                # Map key is resource name
      type: virtualService
      hosts: [app.example.com]
      http:
        - match:
            - uri:
                prefix: /api
          route:
            - destination:
                host: production-app
                port:
                  number: 80
      circuitBreaking:
        enabled: true
        maxConnections: 100

  # TLS Certificates
  certManager:
    app-tls:                    # Map key is resource name
      type: certificate
      dnsNames:
        - app.example.com
        - api.example.com
      issuerRef:
        name: letsencrypt-prod
        kind: ClusterIssuer

  # Database
  postgresql:
    app-database:               # Map key is resource name
      type: cluster
      replicas: 3
      size: 100Gi
```

**See chart examples directories for more:**
- `charts/glyphs/*/examples/` - Glyph-specific examples
- `bookrack/example-tdd-book/infrastructure/` - Real-world usage
- `charts/summon/examples/` - Workload + glyph integration

## Summary

**Glyphs:**
- Reusable infrastructure templates
- Orchestrated by [Kaster](KASTER.md)
- Discovered via [Lexicon](LEXICON.md) and Runic Indexer
- Tested via [TDD methodology](TDD_COMMANDS.md)
- Composable and environment-aware

**Key Benefits:**
- Infrastructure as Code
- Environment portability
- Reduced boilerplate
- Consistent patterns
- Testable and maintainable

**Pattern:** Declare infrastructure requirements with map structure, glyphs handle implementation details.
