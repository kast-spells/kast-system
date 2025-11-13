# Glyph Development Guide

Guide for creating new glyphs in kast-system. Glyphs are reusable Helm named templates that generate Kubernetes resources.

## Overview

**Glyph:** Reusable Helm template that generates one or more Kubernetes resources based on input parameters.

**Purpose:**
- Encapsulate infrastructure patterns (vault, istio, certificates)
- Provide consistent interfaces across deployments
- Enable composition of complex systems from simple definitions
- Reduce YAML duplication

For a complete reference of all available glyphs, see [GLYPHS.md](GLYPHS.md).

**Architecture:**

```
┌─────────────────────────────────────────────────────┐
│ Spell (glyphs.myglyph configuration)                │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│ Kaster Chart                                        │
│ - Iterates glyph definitions                        │
│ - Invokes glyph templates                           │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│ Glyph Templates (charts/glyphs/<name>/templates/)   │
│ - Named templates                                   │
│ - Generate K8s resources                            │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│ Kubernetes Resources                                │
│ - Deployments, Services, CRDs, etc.                 │
└─────────────────────────────────────────────────────┘
```

For details on how the [Kaster](KASTER.md) chart orchestrates glyphs, see the Kaster documentation.

## Glyph Structure

### Directory Layout

```
charts/glyphs/<glyph-name>/
├── Chart.yaml              # Helm chart metadata
├── templates/              # Template files
│   ├── _helpers.tpl       # Optional: Helper functions
│   ├── resource1.tpl      # Resource template 1
│   ├── resource2.tpl      # Resource template 2
│   └── resource3.tpl      # Resource template 3
└── examples/               # TDD test cases
    ├── basic.yaml         # Basic example
    ├── advanced.yaml      # Advanced example
    └── edge-cases.yaml    # Edge cases
```

**Key Files:**

| File | Purpose |
|------|---------|
| `Chart.yaml` | Helm chart metadata (name, version, description) |
| `templates/*.tpl` | Named template definitions |
| `examples/*.yaml` | Test cases for TDD validation |

### Chart.yaml

**Template:**

```yaml
apiVersion: v2
name: <glyph-name>
description: <Short description of glyph purpose>
version: 1.0.0
home: https://github.com/kast-spells
sources:
  - https://github.com/kast-spells/kast-system
maintainers:
  - name: Your Name
    email: your.email@example.com
```

**Example:**

```yaml
apiVersion: v2
name: database
description: Database integration glyph for PostgreSQL and MySQL
version: 1.0.0
home: https://github.com/kast-spells
sources:
  - https://github.com/kast-spells/kast-system
maintainers:
  - name: Platform Team
    email: platform@example.com
```

### Template Files

**Naming Convention:** `<resource-type>.tpl` or `<glyph-feature>.tpl`

**Examples:**
- `deployment.tpl` - Generates Deployment
- `service.tpl` - Generates Service
- `secret.tpl` - Generates Secret
- `custom-resource.tpl` - Generates CRD instance

## Template Patterns

### Named Template Definition

**Pattern:**

```go
{{- define "<glyph-name>.<template-name>" -}}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1 }}
---
apiVersion: <api-version>
kind: <resource-kind>
metadata:
  name: {{ default (include "common.name" $root) $glyphDefinition.name }}
  labels:
    {{- include "common.labels" $root | nindent 4 }}
spec:
  # Resource specification using $glyphDefinition fields
{{- end }}
```

**Breakdown:**

1. **Template Name:** `<glyph-name>.<template-name>`
   - Must be unique across all glyphs
   - Convention: `glyph-name.resource-type` or `glyph-name.feature`

2. **Parameter Extraction:**
   ```go
   {{- $root := index . 0 -}}           # Chart root context
   {{- $glyphDefinition := index . 1 }} # Glyph instance configuration
   ```

3. **Resource Generation:**
   - Use `$root` for chart metadata (Release.Name, Chart.Version, etc.)
   - Use `$glyphDefinition` for user configuration

### Copyright Header

**All templates must include:**

```go
{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
*/}}
```

### Parameter Access

```go
{{- define "myglyph.myresource" -}}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1 }}

# Access glyph definition fields
name: {{ $glyphDefinition.name }}
enabled: {{ default true $glyphDefinition.enabled }}
replicas: {{ default 1 $glyphDefinition.replicas }}

# Access root context
release: {{ $root.Release.Name }}
namespace: {{ $root.Release.Namespace }}
chapter: {{ $root.Values.chapter.name }}

# Use common templates
labels:
  {{- include "common.labels" $root | nindent 2 }}
{{- end }}
```

### Default Values

**Pattern:** Use `default` function for optional fields

```go
# Simple default
replicas: {{ default 1 $glyphDefinition.replicas }}

# Default with type
enabled: {{ default true $glyphDefinition.enabled }}

# Default from root values
image: {{ default $root.Values.defaultImage $glyphDefinition.image }}

# Conditional default
timeout: {{ default (ternary 300 60 $glyphDefinition.production) $glyphDefinition.timeout }}
```

### Conditional Resources

**Pattern:** Only generate resource if condition met

```go
{{- if $glyphDefinition.enabled }}
---
apiVersion: v1
kind: ConfigMap
# ...
{{- end }}

# Multiple conditions
{{- if and $glyphDefinition.enabled (not $glyphDefinition.external) }}
# ...
{{- end }}
```

## Common Glyph Integration

Common glyph provides shared utility templates. For details, see [glyphs/common.md](glyphs/common.md).

### Available Templates

| Template | Purpose |
|----------|---------|
| `common.name` | Generate resource name |
| `common.labels` | Standard Kubernetes labels |
| `common.selectorLabels` | Pod selector labels |
| `common.annotations` | Standard annotations |
| `common.serviceAccountName` | ServiceAccount name |

### Usage Pattern

**Different from other glyphs:** Pass `$root` directly (not list)

```go
{{- define "myglyph.resource" -}}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1 }}
---
apiVersion: v1
kind: Service
metadata:
  name: {{- include "common.name" $root }}
  labels:
    {{- include "common.labels" $root | nindent 4 }}
  annotations:
    {{- include "common.annotations" $root | nindent 4 }}
spec:
  selector:
    {{- include "common.selectorLabels" $root | nindent 4 }}
{{- end }}
```

### Name Generation

```go
# Basic name
name: {{ include "common.name" $root }}

# Override from glyph definition
name: {{ default (include "common.name" $root) $glyphDefinition.name }}

# With suffix
name: {{ include "common.name" $root }}-{{ $glyphDefinition.suffix }}
```

## Runic Indexer Integration

Query lexicon for infrastructure resources. For comprehensive documentation on the lexicon system, see [LEXICON.md](LEXICON.md).

### Pattern

```go
{{- $results := get (include "runicIndexer.runicIndexer"
     (list $root.Values.lexicon
           (default dict $glyphDefinition.selector)
           "resource-type"
           $root.Values.chapter.name) | fromJson) "results" }}

{{- range $resource := $results }}
  # Use $resource fields
  url: {{ $resource.url }}
  namespace: {{ $resource.namespace }}
{{- end }}
```

### Parameters

1. **$root.Values.lexicon** - Lexicon array from values
2. **$glyphDefinition.selector** - Label selectors (map)
3. **"resource-type"** - Resource type to filter (string)
4. **$root.Values.chapter.name** - Current chapter name

### Selection Algorithm

1. **Exact match:** All selector labels match lexicon entry
2. **Chapter default:** Entry with `default: chapter` + matching chapter
3. **Book default:** Entry with `default: book`

### Example

```go
{{- define "myglyph.resource" -}}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1 }}

{{/* Query lexicon for database */}}
{{- $databases := get (include "runicIndexer.runicIndexer"
     (list $root.Values.lexicon
           (default dict $glyphDefinition.selector)
           "database"
           $root.Values.chapter.name) | fromJson) "results" }}

{{- range $db := $databases }}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ $glyphDefinition.name }}-config
data:
  DB_HOST: {{ $db.host }}
  DB_PORT: {{ $db.port | quote }}
  DB_NAME: {{ $db.database }}
{{- end }}
{{- end }}
```

**Spell usage:**

```yaml
lexicon:
  - name: production-db
    type: database
    host: postgres.prod.svc
    port: 5432
    database: myapp
    labels:
      environment: production
      default: book

glyphs:
  myglyph:
    app-config:
      type: resource
      name: app-config
      selector:
        environment: production
```

## TDD Workflow

Glyphs are developed using Test-Driven Development. For complete testing command reference, see [TDD_COMMANDS.md](TDD_COMMANDS.md).

### Red-Green-Refactor Cycle

**1. RED PHASE - Write failing test**

```bash
# Create example defining expected behavior
cat > charts/glyphs/myglyph/examples/basic.yaml <<EOF
glyphs:
  myglyph:
    test-resource:
      type: resource
      name: test-resource
      enabled: true
      replicas: 2
EOF

# Verify test fails (glyph doesn't exist yet)
make glyphs myglyph
# Expected: ❌ myglyph-basic (template not found)
```

**2. GREEN PHASE - Implement minimal feature**

```bash
# Create template
cat > charts/glyphs/myglyph/templates/resource.tpl <<EOF
{{- define "myglyph.resource" -}}
{{- \$root := index . 0 -}}
{{- \$glyphDefinition := index . 1 }}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ default (include "common.name" \$root) \$glyphDefinition.name }}
data:
  replicas: {{ default 1 \$glyphDefinition.replicas | quote }}
{{- end }}
EOF

# Verify test passes
make glyphs myglyph
# Expected: ✅ myglyph-basic (rendered successfully)
```

**3. REFACTOR PHASE - Improve implementation**

```bash
# Add validation, error handling, documentation
# Run tests to ensure behavior unchanged
make glyphs myglyph
```

### Example Structure

**Comprehensive test coverage:**

```
charts/glyphs/myglyph/examples/
├── basic.yaml           # Minimal configuration
├── advanced.yaml        # All features enabled
├── edge-cases.yaml      # Boundary conditions
├── validation.yaml      # Input validation
└── integration.yaml     # With other glyphs
```

**Example Content:**

```yaml
# basic.yaml - Minimal test
glyphs:
  myglyph:
    basic-test:
      type: resource
      name: basic-test

# advanced.yaml - Full features
glyphs:
  myglyph:
    advanced-test:
      type: resource
      name: advanced-test
      enabled: true
      replicas: 3
      resources:
        limits:
          memory: 512Mi
      annotations:
        custom: value

# edge-cases.yaml - Boundary conditions
glyphs:
  myglyph:
    edge-case-1:
      type: resource
      name: edge-case-1
      enabled: false  # Test disabled resource

    edge-case-2:
      type: resource
      name: edge-case-2
      replicas: 0     # Test zero replicas
```

### Testing Commands

```bash
# Test specific glyph
make glyphs myglyph

# Generate expected outputs
make generate-expected GLYPH=myglyph

# Show differences
make show-glyph-diff GLYPH=myglyph EXAMPLE=basic

# Update specific snapshot
make update-snapshot CHART=kaster EXAMPLE=glyphs-myglyph-basic

# Test all glyphs
make test-glyphs-all
```

## Step-by-Step Guide

### Create New Glyph

**Step 1: Create directory structure**

```bash
mkdir -p charts/glyphs/database/{templates,examples}
```

**Step 2: Create Chart.yaml**

```bash
cat > charts/glyphs/database/Chart.yaml <<EOF
apiVersion: v2
name: database
description: Database integration glyph for connection management
version: 1.0.0
home: https://github.com/kast-spells
sources:
  - https://github.com/kast-spells/kast-system
maintainers:
  - name: Platform Team
    email: platform@example.com
EOF
```

**Step 3: Write failing test (RED)**

```bash
cat > charts/glyphs/database/examples/basic.yaml <<EOF
lexicon:
  - name: test-database
    type: database
    host: postgres.default.svc
    port: 5432
    database: testdb
    labels:
      default: book

glyphs:
  database:
    app-db-config:
      type: connection
      name: app-db-config
EOF

# Test (should fail)
make glyphs database
```

**Step 4: Implement template (GREEN)**

```bash
cat > charts/glyphs/database/templates/connection.tpl <<'EOF'
{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.

database.connection creates ConfigMap with database connection info.
Queries lexicon for database entry via runic indexer.

Parameters:
- $root: Chart root context (index . 0)
- $glyphDefinition: Connection configuration (index . 1)
  - name: ConfigMap name (required)
  - selector: Lexicon selector (optional, uses default if not specified)
  - prefix: Environment variable prefix (optional, default: DB_)

Example:
  database:
    app-db-config:
      type: connection
      name: app-db-config
      selector:
        environment: production
*/}}

{{- define "database.connection" -}}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1 }}

{{/* Query lexicon for database */}}
{{- $databases := get (include "runicIndexer.runicIndexer"
     (list $root.Values.lexicon
           (default dict $glyphDefinition.selector)
           "database"
           $root.Values.chapter.name) | fromJson) "results" }}

{{- range $db := $databases }}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ default (include "common.name" $root) $glyphDefinition.name }}
  labels:
    {{- include "common.labels" $root | nindent 4 }}
data:
  {{ default "DB_" $glyphDefinition.prefix }}HOST: {{ $db.host }}
  {{ default "DB_" $glyphDefinition.prefix }}PORT: {{ $db.port | quote }}
  {{ default "DB_" $glyphDefinition.prefix }}NAME: {{ $db.database }}
{{- end }}
{{- end }}
EOF

# Test (should pass)
make glyphs database
```

**Step 5: Generate expected output**

```bash
make generate-expected GLYPH=database
```

**Step 6: Add more test cases**

```bash
# Advanced example
cat > charts/glyphs/database/examples/advanced.yaml <<EOF
lexicon:
  - name: postgres-primary
    type: database
    host: postgres.prod.svc
    port: 5432
    database: production
    labels:
      environment: production
      tier: primary
      default: chapter
    chapter: production

glyphs:
  database:
    primary-db-config:
      type: connection
      name: primary-db-config
      selector:
        environment: production
        tier: primary
      prefix: PRIMARY_

    readonly-db-config:
      type: connection
      name: readonly-db-config
      selector:
        environment: production
        tier: readonly
      prefix: READONLY_
EOF

# Test
make glyphs database
```

**Step 7: Document glyph**

```bash
# Create documentation
cat > docs/glyphs/database.md <<EOF
# Database Glyph

Database integration for connection management.

## Templates

- \`database.connection\` - ConfigMap with connection info

## Parameters

| Field | Type | Description |
|-------|------|-------------|
| \`name\` | string | ConfigMap name |
| \`selector\` | map | Lexicon selector |
| \`prefix\` | string | Environment variable prefix |

## Examples

See \`charts/glyphs/database/examples/\`
EOF
```

**Step 8: Update references**

```bash
# Add to GLYPHS_REFERENCE.md
echo "- [database](glyphs/database.md) - Database connection management" >> docs/GLYPHS_REFERENCE.md
```

## Best Practices

### Template Design

**Single Responsibility:**

```go
# Good: One template per resource type
{{- define "myglyph.deployment" -}}    # Generates Deployment
{{- define "myglyph.service" -}}       # Generates Service
{{- define "myglyph.configmap" -}}     # Generates ConfigMap

# Avoid: One template generating multiple unrelated resources
{{- define "myglyph.everything" -}}    # Generates Deployment + Service + ConfigMap
```

**Parameter Validation:**

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

{{/* Validate value constraints */}}
{{- if and $glyphDefinition.replicas (lt ($glyphDefinition.replicas | int) 0) }}
  {{- fail "replicas must be >= 0" }}
{{- end }}
# ...
{{- end }}
```

**Sensible Defaults:**

```go
# Provide defaults for all optional fields
enabled: {{ default true $glyphDefinition.enabled }}
replicas: {{ default 1 $glyphDefinition.replicas }}
timeout: {{ default 300 $glyphDefinition.timeout }}
resources:
  limits:
    memory: {{ default "256Mi" ($glyphDefinition.resources).limits.memory }}
```

### Documentation

**Template Documentation:**

```go
{{/*
myglyph.resource creates a custom resource.

Parameters:
- $root: Chart root context (index . 0)
- $glyphDefinition: Resource configuration (index . 1)
  - name: Resource name (required)
  - enabled: Enable resource (optional, default: true)
  - replicas: Number of replicas (optional, default: 1)

Example:
  myglyph:
    my-resource:
      type: resource
      name: my-resource
      enabled: true
      replicas: 3
*/}}
{{- define "myglyph.resource" -}}
# ...
{{- end }}
```

**Inline Comments:**

```go
{{/* Query lexicon for vault server */}}
{{- $vaultServer := get (include "runicIndexer.runicIndexer" ...) }}

{{/* Generate ConfigMap for each database */}}
{{- range $db := $databases }}
  {{/* Use primary database host */}}
  host: {{ $db.host }}
{{- end }}
```

### Testing

**Comprehensive Examples:**

```
examples/
├── basic.yaml          # Minimal valid configuration
├── advanced.yaml       # All features enabled
├── production.yaml     # Production-like configuration
├── edge-cases.yaml     # Boundary conditions (empty, zero, nil)
├── validation.yaml     # Invalid inputs (should fail)
└── integration.yaml    # Integration with other glyphs
```

**Test Coverage:**

- ✅ Required fields
- ✅ Optional fields with defaults
- ✅ All conditional branches
- ✅ Integration with runic indexer
- ✅ Integration with common glyph
- ✅ Edge cases (empty values, nil, zero)

### Naming Conventions

**Template Names:**

```
# Pattern: <glyph-name>.<resource-type>
vault.secret          # ✅ Clear and specific
vault.prolicy         # ✅ (note: prolicy is correct spelling in kast)
istio.gateway         # ✅
istio.virtualService  # ✅ CamelCase for multi-word

# Avoid:
vault.create-secret   # ❌ Redundant verb
v.secret             # ❌ Abbreviation
vaultSecret          # ❌ Missing separator
```

**File Names:**

```
# Pattern: <resource-type>.tpl or <feature>.tpl
secret.tpl           # ✅
virtual-service.tpl  # ✅
_helpers.tpl         # ✅ Prefix with _ for helpers

# Avoid:
Secret.tpl           # ❌ Capital letter
secret-template.tpl  # ❌ Redundant suffix
```

### Error Handling

**Graceful Failures:**

```go
{{/* Query lexicon */}}
{{- $databases := get (include "runicIndexer.runicIndexer" ...) "results" }}

{{/* Check if any results */}}
{{- if not $databases }}
  {{- fail (printf "No database found matching selector: %v" $glyphDefinition.selector) }}
{{- end }}

{{/* Validate configuration */}}
{{- if and $glyphDefinition.tls.enabled (not $glyphDefinition.tls.secretName) }}
  {{- fail "tls.enabled requires tls.secretName" }}
{{- end }}
```

**Informative Messages:**

```go
# Good
{{- fail "vault.secret requires 'keys' field when format is 'env'" }}

# Avoid
{{- fail "invalid configuration" }}  # Too vague
{{- fail "error" }}                  # No context
```

## Common Patterns

### Multi-Resource Glyph

**Pattern:** Glyph that generates multiple related resources

```go
{{/* Main resource */}}
{{- define "myglyph.deployment" -}}
---
apiVersion: apps/v1
kind: Deployment
# ...
{{- end }}

{{/* Supporting resource */}}
{{- define "myglyph.service" -}}
---
apiVersion: v1
kind: Service
# ...
{{- end }}

{{/* Invocation - both templates called */}}
{{ include "myglyph.deployment" (list $root $glyphDefinition) }}
{{ include "myglyph.service" (list $root $glyphDefinition) }}
```

### Conditional Sub-Resources

**Pattern:** Generate additional resources based on configuration

```go
{{- define "myglyph.resource" -}}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1 }}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ $glyphDefinition.name }}
# ...

{{/* Conditionally generate Secret */}}
{{- if $glyphDefinition.credentials }}
---
apiVersion: v1
kind: Secret
metadata:
  name: {{ $glyphDefinition.name }}-creds
stringData:
  username: {{ $glyphDefinition.credentials.username }}
  password: {{ $glyphDefinition.credentials.password }}
{{- end }}
{{- end }}
```

### Helper Templates

**Pattern:** Reusable logic within glyph

```go
{{/* Helper: Generate connection string */}}
{{- define "myglyph.connectionString" -}}
{{- $db := . }}
{{- printf "postgresql://%s:%s/%s" $db.host ($db.port | toString) $db.database }}
{{- end }}

{{/* Main template */}}
{{- define "myglyph.resource" -}}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1 }}

{{- $databases := get (include "runicIndexer.runicIndexer" ...) "results" }}
{{- range $db := $databases }}
---
apiVersion: v1
kind: ConfigMap
data:
  CONNECTION_STRING: {{ include "myglyph.connectionString" $db }}
{{- end }}
{{- end }}
```

## Troubleshooting

### Template Not Found

**Symptoms:** `template "myglyph.resource" not found`

**Check:**

1. Template defined with correct name
2. File in `charts/glyphs/myglyph/templates/`
3. Kaster invokes correct template name

```bash
# Check template definition
grep -r "define.*myglyph.resource" charts/glyphs/myglyph/

# Check kaster invocation
grep -r "include.*myglyph.resource" charts/kaster/
```

### Parameter Access Error

**Symptoms:** `can't evaluate field X in type interface {}`

**Cause:** Incorrect parameter extraction or nil value

**Fix:**

```go
# Check parameters extracted correctly
{{- $root := index . 0 -}}           # Must be index 0
{{- $glyphDefinition := index . 1 }} # Must be index 1

# Check field exists before access
{{- if $glyphDefinition.field }}
  value: {{ $glyphDefinition.field }}
{{- end }}

# Use default for optional fields
value: {{ default "default" $glyphDefinition.field }}
```

### Runic Indexer Returns Empty

**Symptoms:** No resources generated

**Check:**

```bash
# 1. Verify lexicon in example
yq '.lexicon' charts/glyphs/myglyph/examples/basic.yaml

# 2. Check selector matches labels
# Selector: {environment: production}
# Labels: {environment: production}  # Must match

# 3. Check type matches
# Query: "database"
# Lexicon: type: database  # Must match exactly

# 4. Verify default fallback
# Labels: {default: book}  # Fallback if no exact match
```

### Tests Failing

**Symptoms:** `make glyphs myglyph` shows errors

**Debug:**

```bash
# 1. Check rendering
make inspect-chart CHART=kaster EXAMPLE=glyphs-myglyph-basic

# 2. Show detailed errors
helm template test charts/kaster \
  -f charts/glyphs/myglyph/examples/basic.yaml \
  --debug

# 3. Compare with expected
make show-glyph-diff GLYPH=myglyph EXAMPLE=basic
```

## Related Documentation

- [GLYPHS.md](GLYPHS.md) - Complete glyph system overview and architecture
- [GLYPHS_REFERENCE.md](GLYPHS_REFERENCE.md) - All available glyphs reference
- [KASTER.md](KASTER.md) - Glyph orchestration and invocation patterns
- [LEXICON.md](LEXICON.md) - Runic indexer documentation and lexicon structure
- [TDD_COMMANDS.md](TDD_COMMANDS.md) - Complete testing command reference
- [glyphs/common.md](glyphs/common.md) - Common glyph utility templates
- [../CLAUDE.md](../CLAUDE.md) - TDD development philosophy and workflow

## Examples

See existing glyphs for reference:

- **Simple:** `charts/glyphs/freeForm/` - Pass-through YAML
- **Intermediate:** `charts/glyphs/istio/` - Gateway and VirtualService
- **Advanced:** `charts/glyphs/vault/` - 11 templates, runic indexer integration
- **Helper-based:** `charts/glyphs/common/` - Utility templates

## Summary

**Glyph Development Checklist:**

- [ ] Create directory structure (templates/, examples/)
- [ ] Write Chart.yaml with metadata
- [ ] Write failing test (RED phase)
- [ ] Implement minimal template (GREEN phase)
- [ ] Generate expected outputs
- [ ] Add comprehensive examples
- [ ] Document template parameters
- [ ] Add to GLYPHS_REFERENCE.md
- [ ] Create docs/glyphs/<name>.md
- [ ] Test with `make glyphs <name>`

**Remember:**
- Follow TDD: Red → Green → Refactor
- Use common glyph for labels and names
- Use runic indexer for lexicon queries
- Provide sensible defaults
- Validate required fields
- Document parameters and examples
- Test edge cases
