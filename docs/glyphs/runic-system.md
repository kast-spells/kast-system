# Runic System Glyph

Infrastructure discovery system via runic indexer.

## Templates

- `runicIndexer.runicIndexer` - Lexicon query function

## Function

**Pattern:**
```go
{{- $results := get (include "runicIndexer.runicIndexer"
     (list $lexicon $selectors $type $chapter) | fromJson) "results" }}
```

**Parameters:**
1. `$lexicon` - Array of lexicon entries
2. `$selectors` - Map of label selectors
3. `$type` - Resource type to filter
4. `$chapter` - Current chapter name

**Returns:** JSON with `results` array containing matching resources.

## Selection Algorithm

1. **Type Filter:** Only resources matching `$type`
2. **Exact Match:** All selector labels match exactly
3. **Fallback:** Chapter default (`default: chapter`) for current chapter
4. **Fallback:** Book default (`default: book`)

## Examples

### Query Vault Server

```go
{{- $vaults := get (include "runicIndexer.runicIndexer"
     (list $root.Values.lexicon
           (dict "environment" "production")
           "vault"
           $root.Values.chapter.name) | fromJson) "results" }}

{{- range $vault := $vaults }}
url: {{ $vault.url }}
{{- end }}
```

### Query Gateway

```go
{{- $gateways := get (include "runicIndexer.runicIndexer"
     (list $root.Values.lexicon
           (dict "access" "external")
           "istio-gw"
           $root.Values.chapter.name) | fromJson) "results" }}
```

## Lexicon Entry Structure

```yaml
lexicon:
  - name: resource-name
    type: resource-type
    labels:
      selector-key: selector-value
      default: book|chapter
    # Resource-specific fields
```

## Documentation

See [LEXICON.md](../LEXICON.md) for complete documentation.

## Testing

Tested indirectly via glyph tests that use lexicon.

## Examples Location

Examples in glyphs that use runic indexer (vault, istio, argo-events, etc.)
