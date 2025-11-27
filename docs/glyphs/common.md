# Common Glyph

Shared utility templates used by all glyphs.

## Templates

- `common.name` - Resource naming with prefixes/suffixes
- `common.labels` - Official Kubernetes recommended labels
- `common.selectorLabels` - Labels for pod selection
- `common.annotations` - Standard Kubernetes annotations
- `common.infra.labels` - Kast infrastructure labels (spelbook/chapter/spell)
- `common.finops.labels` - FinOps/cost allocation labels (toggleable)
- `common.covenant.labels` - Covenant identity & access labels (toggleable)
- `common.all.labels` - Combined labels based on enabled toggles
- `common.validation` - Input validation helpers

## Usage Pattern

Common templates are invoked differently than other glyphs:

```go
{{- include "common.name" $root }}
{{- include "common.all.labels" $root | nindent 4 }}
{{- include "common.annotations" $root | nindent 4 }}
```

**Note:** Direct context passing (`$root`), not list pattern.

## Label System

### Label Categories

Kast uses a multi-tier labeling system:

1. **Official Kubernetes Labels** (always applied)
   - `app.kubernetes.io/name`
   - `app.kubernetes.io/instance`
   - `app.kubernetes.io/version`
   - `app.kubernetes.io/component`
   - `app.kubernetes.io/part-of`
   - `app.kubernetes.io/managed-by`

2. **Infrastructure Labels** (always applied)
   - `spelbook` - Book name
   - `chapter` - Chapter name
   - `spell` - Spell name

3. **FinOps Labels** (toggleable via `.Values.labels.finops.enabled`)
   - `team` - Team responsible
   - `owner` - Resource owner
   - `cost-center` - Cost center for chargeback
   - `department` - Department
   - `project` - Project name
   - `environment` - Environment (defaults to chapter)

4. **Covenant Labels** (toggleable via `.Values.labels.covenant.enabled`)
   - `covenant.kast.io/team` - Team name
   - `covenant.kast.io/owner` - Owner email
   - `covenant.kast.io/department` - Department
   - `covenant.kast.io/member` - Member identifier
   - `covenant.kast.io/organization` - Organization

## Functions

### common.name

Generates resource name with optional prefix/suffix.

**Input:** `$root` context

**Output:** String name

### common.labels

Generates official Kubernetes recommended labels.

**Input:** `$root` context

**Output:** YAML label block

**Labels:**
- `app.kubernetes.io/name` - Application name
- `app.kubernetes.io/instance` - Unique instance identifier
- `app.kubernetes.io/version` - Application version (if Chart.AppVersion set)
- `app.kubernetes.io/component` - Component within architecture (if .Values.component set)
- `app.kubernetes.io/part-of` - Larger application (uses .Values.spellbook.name)
- `app.kubernetes.io/managed-by` - Management tool (Helm)

### common.selectorLabels

Generates labels used for pod selection. These must remain stable.

**Input:** `$root` context

**Output:** YAML label block

**Labels:**
- `app.kubernetes.io/name`
- `app.kubernetes.io/instance`

### common.all.labels

Combines all label categories based on enabled toggles.

**Input:** `$root` context

**Output:** YAML label block with all enabled labels

**Includes:**
- Official Kubernetes labels (always)
- Infrastructure labels (always)
- FinOps labels (if enabled)
- Covenant labels (if enabled)

### common.finops.labels

Generates FinOps/cost allocation labels for tools like Kubecost.

**Input:** `$root` context

**Configuration:**
```yaml
labels:
  finops:
    enabled: true
    team: my-team
    owner: john.doe
    costCenter: engineering
    department: platform
    project: my-project
    environment: production  # Optional, defaults to chapter.name
```

**Output:** YAML label block

### common.covenant.labels

Generates Covenant identity & access management labels.

**Input:** `$root` context

**Configuration:**
```yaml
labels:
  covenant:
    enabled: true
    team: my-team
    owner: admin@company.com
    department: security
    member: service-account
    organization: my-org
```

**Output:** YAML label block

### common.annotations

Generates standard Kubernetes annotations plus custom annotations.

**Input:** `$root` context

**Configuration:**
```yaml
description: "Human-readable service description"
annotations:
  prometheus.io/scrape: "true"
  custom.io/key: "value"
```

**Output:** YAML annotation block

**Standard Annotations:**
- `kubernetes.io/description` - Human-readable description (if .Values.description set)
- Custom annotations from `.Values.annotations`

## Examples

### Usage in Glyph Template

```go
{{- define "myglyph.resource" -}}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{- include "common.name" $root }}
  labels:
    {{- include "common.labels" $root | nindent 4 }}
  annotations:
    {{- include "common.annotations" $root | nindent 4 }}
{{- end }}
```

## Testing

Common glyph is tested indirectly via other glyph tests.

## Examples Location

`charts/glyphs/common/examples/`
