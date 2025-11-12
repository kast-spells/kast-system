# CertManager Glyph

Certificate management via cert-manager integration.

## Templates

- `certManager.certificate` - Certificate resource
- `certManager.dns-endpoint-sourced` - DNS endpoint from certificate
- `certManager.clusterIssuer` - ClusterIssuer resource

## Generated Resources

- `Certificate` (cert-manager.io/v1)
- `DNSEndpoint` (externaldns.k8s.io/v1alpha1)
- `ClusterIssuer` (cert-manager.io/v1)

## Parameters

### Certificate (`certManager.certificate`)

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Certificate name |
| `dnsNames` | array | DNS names for certificate |
| `issuerName` | string | Issuer reference |
| `secretName` | string | Target secret name |

## Examples

### Certificate

```yaml
glyphs:
  certManager:
    - type: certificate
      name: example-cert
      dnsNames:
        - example.com
        - "*.example.com"
      issuerName: letsencrypt-prod
```

## Testing

```bash
make glyphs certManager
```

## Examples Location

`charts/glyphs/certManager/examples/`
