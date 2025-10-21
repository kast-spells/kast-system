# Postgres Cloud Glyph

Cloud-hosted PostgreSQL database management.

## Templates

- `postgres-cloud.postgres-cg` - PostgreSQL cluster

## Generated Resources

Cloud provider database CRDs.

## Examples

```yaml
glyphs:
  postgres-cloud:
    - type: postgres-cg
      name: production-db
      version: "15"
      instances: 3
```

## Testing

```bash
make glyphs postgres-cloud
```

## Examples Location

`charts/glyphs/postgres-cloud/examples/`
