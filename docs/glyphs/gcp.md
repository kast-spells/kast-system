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
    my-bucket:
      type: s3
```

## Testing

```bash
make glyphs gcp
```

## Examples Location

`charts/glyphs/gcp/examples/`
