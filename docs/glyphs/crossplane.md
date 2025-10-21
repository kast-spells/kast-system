# Crossplane Glyph

Cloud resource provisioning via Crossplane.

## Templates

- `crossplane.provider` - Provider configuration

## Generated Resources

- `Provider` (pkg.crossplane.io/v1)
- Various cloud provider CRDs

## Examples

```yaml
glyphs:
  crossplane:
    - type: provider
      name: aws-provider
      package: crossplane/provider-aws
```

## Testing

```bash
make glyphs crossplane
```

## Examples Location

`charts/glyphs/crossplane/examples/`
