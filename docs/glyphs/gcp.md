# GCP Glyph

Google Cloud Platform resource management.

## Templates

- `gcp.s3` - GCS storage resources

## Generated Resources

GCP-specific CRDs via Crossplane or Config Connector.

## Examples

```yaml
glyphs:
  gcp:
    - type: s3
      name: my-bucket
```

## Testing

```bash
make glyphs gcp
```

## Examples Location

`charts/glyphs/gcp/examples/`
