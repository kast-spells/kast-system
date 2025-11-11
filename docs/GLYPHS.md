# Glyphs - Infrastructure as Code Templates

Comprehensive guide to the glyph system in kast. Glyphs are reusable Helm named templates that generate Kubernetes resources for infrastructure integration.

## Overview

**Glyph:** Reusable Helm template that generates one or more Kubernetes resources based on input parameters.

**Purpose:**
- Encapsulate infrastructure patterns (vault, istio, certificates, databases)
- Provide consistent interfaces across deployments
- Enable composition of complex systems from simple definitions
- Reduce YAML duplication and boilerplate
- Leverage infrastructure discovery via lexicon

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

## Key Concepts

### 1. Glyph Definition

User-facing configuration that declares infrastructure requirements:

```yaml
glyphs:
  vault:                        # Glyph package name
    - type: secret              # Template type within package
      name: database-creds      # Resource name
      format: env               # Glyph-specific parameters
      keys: [username, password]
```

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

Query system for discovering infrastructure from lexicon:

```go
{{- $vaults := get (include "runicIndexer.runicIndexer"
     (list $root.Values.lexicon
           $glyphDefinition.selector
           "vault"
           $root.Values.chapter.name) | fromJson) "results" }}
```

**Pattern:** Glyphs use runic indexer to find infrastructure (vault servers, databases, gateways) from lexicon based on selectors or defaults.

## How Glyphs Work

### Step 1: Declaration in Spell

User declares infrastructure requirements:

```yaml
name: my-app

glyphs:
  vault:
    - type: secret
      name: app-config
      keys: [api_key]

  istio:
    - type: virtualService
      name: app-routing
      hosts: [app.example.com]
```

### Step 2: Kaster Detection

Librarian detects `glyphs:` field and adds kaster as multi-source:

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
            vault: [...]
            istio: [...]
          spellbook: {...}     # Context passed
          chapter: {...}
          lexicon: [...]
```

### Step 3: Glyph Iteration

Kaster iterates over glyph definitions and invokes templates:

```go
{{- range $glyphName, $glyphList := .Values.glyphs }}
  {{- range $glyphDefinition := $glyphList }}
    {{- $templateName := printf "%s.%s" $glyphName $glyphDefinition.type }}
    {{- include $templateName (list $ $glyphDefinition) }}
  {{- end }}
{{- end }}
```

### Step 4: Template Execution

Each glyph template:
1. Receives `$root` (chart context) and `$glyphDefinition` (user config)
2. Queries lexicon via runic indexer (if needed)
3. Generates Kubernetes resources
4. Returns YAML manifests

### Step 5: Resource Deployment

ArgoCD deploys generated resources to Kubernetes:
- VaultSecret resources
- Istio VirtualServices
- Certificate requests
- Custom resources

## Glyph Categories

### Infrastructure Integration

**Purpose:** Connect applications to infrastructure services

**Glyphs:**
- **vault** - Secrets management, authentication, policies
- **istio** - Service mesh, routing, security
- **certManager** - TLS certificates, DNS records
- **argo-events** - Event-driven workflows

**Usage Pattern:**
```yaml
glyphs:
  vault:
    - type: prolicy         # Create policy
    - type: secret          # Sync secrets
  istio:
    - type: virtualService  # Configure routing
```

**Documentation:**
- [VAULT.md](VAULT.md) - Vault integration
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
    - type: bucket          # Create GCS bucket
    - type: serviceAccount  # Create GCP SA
    - type: workloadIdentity  # Bind K8s SA to GCP SA
```

**Documentation:**
- [docs/glyphs/gcp.md](glyphs/gcp.md)
- [docs/glyphs/crossplane.md](glyphs/crossplane.md)
- [docs/glyphs/s3.md](glyphs/s3.md)

### Database Management

**Purpose:** Database provisioning and access management

**Glyphs:**
- **postgres-cloud** - Cloud-hosted PostgreSQL clusters
- **vault** (databaseEngine) - Dynamic database credentials

**Usage Pattern:**
```yaml
glyphs:
  postgres-cloud:
    - type: cluster         # Create PostgreSQL cluster
      name: app-db
      replicas: 3

  vault:
    - type: databaseEngine  # Dynamic credentials
      name: postgres-engine
      roles:
        - name: readonly
          dbName: myapp
```

**Documentation:**
- [docs/glyphs/postgres-cloud.md](glyphs/postgres-cloud.md)
- [VAULT.md](VAULT.md) (databaseEngine section)

### Identity & Access

**Purpose:** Authentication, authorization, identity management

**Glyphs:**
- **keycloak** - OIDC/SAML identity provider
- **vault** (oidc-auth, kube-auth) - Authentication backends

**Usage Pattern:**
```yaml
glyphs:
  keycloak:
    - type: realm           # Create realm
      name: myapp-realm
    - type: client          # OIDC client
      name: myapp-client
      clientId: myapp
```

**Documentation:**
- [docs/glyphs/keycloak.md](glyphs/keycloak.md)
- [VAULT.md](VAULT.md) (authentication section)

### System Utilities

**Purpose:** Common patterns and utilities

**Glyphs:**
- **common** - Shared utilities (labels, names, annotations)
- **freeForm** - Pass-through YAML
- **default-verbs** - Utility templates
- **runic-system** - Runic indexer and discovery

**Usage Pattern:**
```yaml
# common glyph (used by other glyphs, not directly)
labels:
  {{- include "common.labels" $root | nindent 4 }}

# freeForm glyph (for arbitrary resources)
glyphs:
  freeForm:
    - type: resource
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

**Use lexicon for environment-aware configuration:**

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
    - type: secret
      name: app-secret
      # Uses chapter default vault automatically
```

**Benefits:**
- Same spell works across environments
- Infrastructure changes don't require spell updates
- Centralized infrastructure configuration

### Pattern 2: Multi-Glyph Composition

**Combine glyphs to build complete infrastructure:**

```yaml
name: payment-service

glyphs:
  # Authentication & Authorization
  vault:
    - type: prolicy
      serviceAccount: payment-service
    - type: secret
      name: database-creds
      keys: [username, password]
    - type: secret
      name: stripe-api-key
      keys: [api_key]

  # Service Mesh
  istio:
    - type: virtualService
      name: payment-api
      hosts: [payments.example.com]
      circuitBreaking:
        enabled: true

  # TLS Certificates
  certManager:
    - type: certificate
      name: payment-tls
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
    - type: prolicy
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
    - type: secret
      name: dev-credentials
      # Development uses simpler auth

# Production
name: my-app
glyphs:
  vault:
    - type: secret
      name: prod-credentials
      # Production uses mTLS

  istio:
    - type: virtualService
      # Only production has external routing
      hosts: [app.production.com]

  certManager:
    - type: certificate
      # Only production has TLS certificates
      dnsNames: [app.production.com]
```

### Pattern 5: Secret Injection

**Inject secrets at different scopes:**

```yaml
glyphs:
  vault:
    # Book-level (shared across all chapters)
    - type: secret
      name: registry-credentials
      path: book
      keys: [username, password]

    # Chapter-level (shared within chapter)
    - type: secret
      name: database-credentials
      path: chapter
      keys: [host, port, database]

    # Namespace-level (application-specific)
    - type: secret
      name: app-private-key
      # Default path (namespace-scoped)
      keys: [private_key]
```

**See [HIERARCHY_SYSTEMS.md](HIERARCHY_SYSTEMS.md) for path hierarchy details**

## Glyph Template Anatomy

### Basic Structure

```go
{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

glyph-name.template-type description

Parameters:
- $root: Chart root context (index . 0)
- $glyphDefinition: Configuration (index . 1)
  - name: Resource name (required)
  - field1: Description (optional)

Example:
  glyph-name:
    - type: template-type
      name: example
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
{{- $glyphDefinition := index . 1 }} # User configuration

# Access root context
{{- $spellbookName := $root.Values.spellbook.name }}
{{- $chapterName := $root.Values.chapter.name }}
{{- $namespace := $root.Release.Namespace }}

# Access glyph definition
{{- $resourceName := $glyphDefinition.name }}
{{- $enabled := default true $glyphDefinition.enabled }}
{{- $replicas := default 1 $glyphDefinition.replicas }}
{{- end }}
```

### Runic Indexer Integration

```go
{{- define "myglyph.resource" -}}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1 }}

{{/* Query lexicon for infrastructure */}}
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
    - type: resource
      name: test-resource
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

**See [TESTING.md](TESTING.md) for complete testing guide**

## Best Practices

### Design for Reusability

**Good (reusable):**
```yaml
glyphs:
  vault:
    - type: secret
      selector: {environment: production}  # Environment-aware
```

**Avoid (hardcoded):**
```yaml
glyphs:
  vault:
    - type: secret
      vaultURL: https://vault.prod.svc:8200  # Hardcoded
```

### Use Lexicon for Discovery

**Leverage runic indexer:**
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
    - type: connection
      # Finds production-db in production chapter
```

### Validate Inputs

```go
{{- define "myglyph.resource" -}}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1 }}

{{/* Validate required fields */}}
{{- if not $glyphDefinition.name }}
  {{- fail "myglyph.resource requires 'name' field" }}
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
  - name: ConfigMap name (required)
  - enabled: Enable resource (optional, default: true)
  - data: ConfigMap data (optional)

Example:
  myglyph:
    - type: resource
      name: my-config
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
    - type: resource
      name: test
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

**See [GLYPH_DEVELOPMENT.md](GLYPH_DEVELOPMENT.md) for complete guide**

## Troubleshooting

### Glyph Not Invoked

**Check:**
```bash
# Verify kaster source added
helm template my-book librarian --set name=my-book \
  | yq '.spec.sources[] | select(.path | contains("kaster"))'

# Verify glyph configuration passed
make glyphs <name>
```

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

- [KASTER.md](KASTER.md) - Glyph orchestration
- [GLYPH_DEVELOPMENT.md](GLYPH_DEVELOPMENT.md) - Creating glyphs
- [GLYPHS_REFERENCE.md](GLYPHS_REFERENCE.md) - Complete glyph list
- [LEXICON.md](LEXICON.md) - Infrastructure discovery
- [TESTING.md](TESTING.md) - Testing glyphs
- [VAULT.md](VAULT.md) - Vault glyph details
- [docs/glyphs/](glyphs/) - Individual glyph documentation

## Examples

### Complete Infrastructure Stack

```yaml
name: production-app

glyphs:
  # Secrets & Authentication
  vault:
    - type: prolicy
      serviceAccount: production-app
      extraPolicy:
        - path: database/creds/app-role
          capabilities: [read]

    - type: secret
      name: app-config
      format: env
      keys: [api_key, webhook_secret]

    - type: secret
      name: database-creds
      format: env
      keys: [username, password]

  # Service Mesh
  istio:
    - type: virtualService
      name: app-routing
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
    - type: certificate
      name: app-tls
      dnsNames:
        - app.example.com
        - api.example.com
      issuerRef:
        name: letsencrypt-prod
        kind: ClusterIssuer

  # Database
  postgres-cloud:
    - type: cluster
      name: app-database
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
- Orchestrated by Kaster
- Discovered via Runic Indexer
- Tested via TDD methodology
- Composable and environment-aware

**Key Benefits:**
- Infrastructure as Code
- Environment portability
- Reduced boilerplate
- Consistent patterns
- Testable and maintainable

**Pattern:** Declare infrastructure requirements, glyphs handle implementation details.
