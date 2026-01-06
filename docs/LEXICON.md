# Infrastructure Discovery with Lexicon & Runic Indexer

The lexicon and runic indexer form the foundation of kast's intelligent infrastructure discovery system. This system enables [glyphs](GLYPHS.md) to automatically find and connect to appropriate infrastructure resources based on labels, selectors, and intelligent fallback mechanisms.

## Overview

Instead of hardcoding infrastructure references, runik uses a **lexicon** (registry of available resources) combined with a **runic indexer** (selection algorithm) to dynamically discover the right infrastructure components at deployment time.

### Key Benefits

- **Environment Awareness**: Different resources for dev/staging/prod automatically
- **Intelligent Fallbacks**: Always finds something that works via defaults  
- **Label-Based Selection**: Flexible matching via key-value selectors
- **Type Safety**: Only returns resources of the requested type
- **Hierarchical Configuration**: Book-wide and chapter-specific overrides

## Lexicon Structure

The lexicon is a list of infrastructure resources defined with labels for selection in the [bookrack structure](BOOKRACK.md):

```yaml
# bookrack/my-book/_lexicon/infrastructure.yaml
lexicon:
  - name: external-gateway
    type: istio-gw
    labels:
      access: external
      environment: production
      default: book
    gateway: istio-system/external-gateway
    baseURL: myapp.com
    
  - name: internal-gateway  
    type: istio-gw
    labels:
      access: internal
      environment: production
      default: chapter
    chapter: production
    gateway: istio-system/internal-gateway
    baseURL: internal.myapp.com
    
  - name: vault-server
    type: vault
    labels:
      environment: production
      default: book
    url: https://vault.production.svc:8200
    authPath: kubernetes
    secretPath: secret
    
  - name: prod-eventbus
    type: eventbus
    labels:
      type: jetstream
      environment: production
      default: book
    jetstream:
      version: "2.10.1"
      replicas: 5
```

### Lexicon Entry Structure

Each lexicon entry contains:

- **`name`**: Unique identifier for the resource
- **`type`**: Resource type (used for filtering by runic indexer)
- **`labels`**: Key-value pairs for selection and defaults
- **Additional fields**: Resource-specific configuration (gateway, url, etc.)

### Special Labels

#### Default Hierarchy
The [hierarchy system](HIERARCHY_SYSTEMS.md) uses special labels for intelligent fallbacks:
- **`default: book`**: Global fallback for the entire book
- **`default: chapter`**: Chapter-specific fallback
- **No default**: Must be explicitly selected

#### Common Selection Labels
- **`environment`**: dev, staging, production
- **`access`**: internal, external, private
- **`region`**: us-west-2, eu-central-1
- **`tier`**: primary, secondary, backup

## Runic Indexer Algorithm

The runic indexer implements intelligent resource selection with fallback behavior:

```helm
{{- $resources := get (include "runicIndexer.runicIndexer" (list $lexicon $selectors $type $chapter) | fromJson) "results" }}
```

### Parameters

1. **`$lexicon`**: List of available resources from Values.lexicon
2. **`$selectors`**: Key-value pairs to match (e.g., `{access: external, environment: production}`)
3. **`$type`**: Resource type to filter (e.g., `istio-gw`, `vault`, `eventbus`)
4. **`$chapter`**: Current chapter name for fallback resolution

### Selection Process

#### Phase 1: Type Filtering
```helm
{{- if eq $currentGlyph.type $type -}}
```
Only considers resources matching the requested type.

#### Phase 2: Exact Label Matching
```helm
{{- range $selector, $value := $selectors -}}
  {{- if eq (index $currentGlyph.labels $selector) $value -}}
    {{- $results = append $results $currentGlyph -}}
  {{- end -}}
{{- end -}}
```
Finds resources where ALL selector labels match exactly.

#### Phase 3: Smart Fallbacks
If no exact matches found:

1. **Chapter Default**: Resources with `default: chapter` + matching chapter name
2. **Book Default**: Resources with `default: book` (global fallback)

```helm
{{- if eq (index $currentGlyph.labels "default") "chapter" -}}
  {{- if eq $currentGlyph.chapter $chapter -}}
    {{- $chapterDefault = append $chapterDefault $currentGlyph -}}
  {{- end -}}
{{- else if eq (index $currentGlyph.labels "default") "book" -}}
  {{- $bookDefault = append $bookDefault $currentGlyph -}}
{{- end -}}
```

### Return Format

Returns JSON object with `results` array:
```json
{
  "results": [
    {
      "name": "external-gateway",
      "type": "istio-gw", 
      "gateway": "istio-system/external-gateway",
      "baseURL": "myapp.com",
      "labels": {"access": "external", "environment": "production"}
    }
  ]
}
```

## Infrastructure Discovery Patterns

### Gateway Selection (Istio)

Istio [glyphs](GLYPHS.md) use the runic indexer to discover appropriate gateways based on selectors.

**Lexicon Definition:**
```yaml
lexicon:
  - name: external-gateway
    type: istio-gw
    labels:
      access: external
      default: book
    gateway: istio-system/external-gateway
    baseURL: myapp.com
```

**Glyph Usage:**
```yaml
glyphs:
  istio:
    my-service:
      type: virtualService
      enabled: true
      selector:
        access: external
      # Runic indexer finds external-gateway
```

**Template Implementation (within [Kaster](KASTER.md) orchestration):**
```helm
{{- $gateways := get (include "runicIndexer.runicIndexer" (list $root.Values.lexicon $glyphDefinition.selector "istio-gw" $root.Values.chapter.name) | fromJson) "results" }}
{{- range $gateway := $gateways }}
spec:
  gateways:
    - {{ $gateway.gateway }}
  hosts:
    - myservice.{{ $gateway.baseURL }}
{{- end }}
```

### Vault Server Discovery

The [Vault integration](VAULT.md) uses the runic indexer to discover Vault servers dynamically.

**Lexicon Definition:**
```yaml
lexicon:
  - name: production-vault
    type: vault
    labels:
      environment: production
      default: book
    url: https://vault.prod.svc:8200
    authPath: kubernetes
    secretPath: secret
```

**Glyph Usage:**
```yaml
glyphs:
  vault:
    my-secret:
      type: secret
      selector:
        environment: production
      # Runic indexer finds production-vault
```

### EventBus Selection (Argo Events)

Argo Events [glyphs](GLYPHS.md) discover EventBus resources based on type and environment selectors.

**Lexicon Definition:**
```yaml
lexicon:
  - name: production-eventbus
    type: eventbus
    labels:
      type: jetstream
      environment: production
      default: book
    jetstream:
      version: "2.10.1"
      replicas: 5
```

**Glyph Usage:**
```yaml
glyphs:
  argo-events:
    my-sensor:
      type: sensor
      selector:
        type: jetstream
        environment: production
      # Runic indexer finds production-eventbus
```

## Selection Examples

### Exact Match
```yaml
# Selector
selector:
  access: external
  environment: production

# Matches lexicon entry with:
labels:
  access: external
  environment: production
  # Additional labels ignored
```

### Fallback to Chapter Default
```yaml
# Selector
selector:
  access: unknown  # No match found

# Falls back to:
labels:
  default: chapter
chapter: production  # Must match current chapter
```

### Fallback to Book Default
```yaml
# Selector  
selector:
  access: unknown  # No exact match
  
# No chapter defaults found, falls back to:
labels:
  default: book  # Global fallback
```

### Empty Selector (Default Only)
```yaml
# Empty selector: {}
# Goes directly to defaults:
# 1. Chapter default for current chapter
# 2. Book default if no chapter default
```

## Best Practices

### Lexicon Organization

#### Use Meaningful Names
```yaml
# Good
- name: external-production-gateway
- name: vault-production-server
- name: jetstream-eventbus

# Avoid
- name: gateway1
- name: server
- name: bus
```

#### Structure Labels Hierarchically
```yaml
labels:
  # Environment (broadest)
  environment: production
  # Access level (medium)
  access: external  
  # Specific features (narrowest)
  ssl: enabled
  region: us-west-2
```

#### Design Default Strategy
```yaml
# Book default: Org-wide standard
labels:
  default: book
  
# Chapter default: Environment-specific
labels:
  default: chapter
  environment: production
chapter: production

# No default: Must be explicitly selected
labels:
  access: admin-only
```

### Selector Design

#### Start Broad, Get Specific
```yaml
# Development: Use broad selectors
selector:
  environment: dev
  
# Production: Use specific selectors  
selector:
  environment: production
  region: us-west-2
  tier: primary
```

#### Using Fallbacks
```yaml
# Try specific first
selector:
  environment: production
  region: us-west-2
  
# Fallback to broader match via defaults
# Book default will catch cases where region doesn't match
```

### Template Integration

#### Always Handle Multiple Results
```helm
{{- $resources := get (include "runicIndexer.runicIndexer" (...)) "results" }}
{{- range $resource := $resources }}
  # Process each result
{{- end }}
```

#### Provide Explicit Override
```helm
{{- if $glyphDefinition.explicitResource }}
  # Use explicit value
{{- else }}
  # Use runic indexer
{{- end }}
```

## Extending the System

### Adding New Resource Types

1. **Define lexicon entries** with new type:
```yaml
lexicon:
  - name: my-database
    type: database
    labels:
      engine: postgres
      tier: primary
      default: book
    connectionString: postgres://...
```

2. **Create glyph templates** that use the type:
```helm
{{- $databases := get (include "runicIndexer.runicIndexer" (list $root.Values.lexicon $glyphDefinition.selector "database" $root.Values.chapter.name) | fromJson) "results" }}
```

3. **Document expected fields** for the resource type

### Creating Custom Selection Logic

```helm
{{- define "myGlyph.findSpecialResource" }}
{{- $root := index . 0 }}
{{- $selectors := index . 1 }}

{{- /* Add custom logic here */}}
{{- $enhancedSelectors := merge $selectors (dict "special" "true") }}

{{- include "runicIndexer.runicIndexer" (list $root.Values.lexicon $enhancedSelectors "my-type" $root.Values.chapter.name) }}
{{- end }}
```

### Integration Patterns

#### Book-Level Lexicon
Lexicon entries are typically defined at the [book level](BOOKRACK.md) for organization-wide infrastructure:
```yaml
# bookrack/my-book/_lexicon/infrastructure.yaml
lexicon:
  - name: book-wide-resource
    type: shared-service
    labels:
      default: book
```

#### Chapter-Level Overrides
Chapter-specific resources follow the [hierarchy system](HIERARCHY_SYSTEMS.md) for environment-specific configuration:
```yaml
# In chapter values
lexicon:
  - name: chapter-specific-resource  
    type: shared-service
    labels:
      default: chapter
      environment: staging
    chapter: staging
```

#### Combining Multiple Sources
```helm
{{- $allLexicons := concat $root.Values.lexicon $root.Values.chapter.lexicon $root.Values.global.lexicon }}
{{- $resources := get (include "runicIndexer.runicIndexer" (list $allLexicons $selectors $type $chapter) | fromJson) "results" }}
```

This infrastructure discovery system provides the foundation for building intelligent, adaptive Kubernetes deployments that automatically select appropriate infrastructure resources based on context, environment, and explicit requirements while gracefully falling back to sensible defaults.