# FreeForm Glyph

Pass-through YAML for arbitrary Kubernetes resources.

## Templates

- `freeForm.manifest` - Raw YAML manifest

## Generated Resources

Any Kubernetes resource defined in `definition` field.

## Parameters

| Field | Type | Description |
|-------|------|-------------|
| `type` | string | Must be "manifest" |
| `definition` | object | Raw Kubernetes resource YAML |

## Examples

### ConfigMap

```yaml
glyphs:
  freeForm:
    - type: manifest
      definition:
        apiVersion: v1
        kind: ConfigMap
        metadata:
          name: custom-config
        data:
          key: value
```

### Custom CRD

```yaml
glyphs:
  freeForm:
    - type: manifest
      definition:
        apiVersion: example.com/v1
        kind: CustomResource
        metadata:
          name: my-custom-resource
        spec:
          field: value
```

## Use Cases

- Custom CRDs not covered by other glyphs
- Experimental resources
- One-off configurations
- Resources requiring exact control

## Testing

```bash
make glyphs freeForm
```

## Examples Location

`charts/glyphs/freeForm/examples/`
