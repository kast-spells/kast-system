# Common Glyph

Shared utility templates used by all glyphs.

## Templates

- `common.name` - Resource naming with prefixes/suffixes
- `common.labels` - Standard Kubernetes labels
- `common.annotations` - Standard Kubernetes annotations
- `common.validation` - Input validation helpers
- `common.infra-labels` - Infrastructure labels

## Usage Pattern

Common templates are invoked differently than other glyphs:

```go
{{- include "common.name" $root }}
{{- include "common.labels" $root | nindent 4 }}
```

**Note:** Direct context passing (`$root`), not list pattern.

## Functions

### common.name

Generates resource name with optional prefix/suffix.

**Input:** `$root` context

**Output:** String name

### common.labels

Generates standard Kubernetes labels:
- `app.kubernetes.io/name`
- `app.kubernetes.io/instance`
- `app.kubernetes.io/version`
- `app.kubernetes.io/managed-by`
- Custom labels from values

**Input:** `$root` context

**Output:** YAML label block

### common.annotations

Generates standard annotations plus custom annotations from values.

**Input:** `$root` context

**Output:** YAML annotation block

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
