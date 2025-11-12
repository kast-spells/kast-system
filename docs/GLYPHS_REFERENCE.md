# Glyphs Reference

Complete list of available glyphs in kast-system.

## What is a Glyph

Reusable Helm named template for specific functionality. Glyphs are invoked via kaster chart or directly in spells.

**Pattern:**
```go
{{- include "glyph-name.template-type" (list $root $glyphDefinition) }}
```

## Available Glyphs

### Infrastructure Integration

- [vault](glyphs/vault.md) - HashiCorp Vault integration (secrets, policies, auth)
- [istio](glyphs/istio.md) - Service mesh (gateways, virtual services)
- [certManager](glyphs/certmanager.md) - Certificate management
- [argo-events](glyphs/argo-events.md) - Event-driven workflows (event sources, sensors)

### Cloud Providers

- [gcp](glyphs/gcp.md) - Google Cloud Platform resources
- [crossplane](glyphs/crossplane.md) - Cloud resource provisioning

### Databases

- [postgres-cloud](glyphs/postgres-cloud.md) - Cloud-hosted PostgreSQL
- [s3](glyphs/s3.md) - S3-compatible storage

### Identity & Access

- [keycloak](glyphs/keycloak.md) - Identity provider (realms, clients, users)

### Workloads

- [summon](glyphs/summon.md) - Standard workload deployment

### System

- [runic-system](glyphs/runic-system.md) - Runic indexer and discovery system
- [common](glyphs/common.md) - Shared utilities (labels, names, annotations)
- [default-verbs](glyphs/default-verbs.md) - Utility templates
- [freeForm](glyphs/freeform.md) - Pass-through YAML manifests
- [trinkets](glyphs/trinkets.md) - Trinket orchestration glyph

## Usage

### Via Kaster

```yaml
glyphs:
  vault:
    - type: secret
      name: my-secret
      format: env
      keys: [username, password]

  istio:
    - type: virtualService
      name: my-service
      httpRules:
        - prefix: /
          port: 80
```

### Direct Chart Usage

Some glyphs are also available as standalone charts (summon, kaster).

## Testing

```bash
make test-glyphs-all         # Test all glyphs
make glyphs <name>            # Test specific glyph
make list-glyphs              # List available glyphs
```

## Development

See [GLYPH_DEVELOPMENT.md](GLYPH_DEVELOPMENT.md) for creating new glyphs.
