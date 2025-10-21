# Vault Glyph

HashiCorp Vault integration for secrets management, authentication, and policy enforcement.

## Templates

- `vault.secret` - ExternalSecret for secrets sync
- `vault.randomSecret` - Generate random passwords
- `vault.cryptoKey` - SSH/TLS keypair generation
- `vault.prolicy` - Vault policy + K8s auth role
- `vault.kube-auth` - Kubernetes authentication
- `vault.databaseEngine` - Database credential engine
- `vault.mongoDBEngine` - MongoDB credential engine
- `vault.oidc-auth` - OIDC authentication
- `vault.customPasswordPolicy` - Custom password policies
- `vault.defaultPasswordPolicy` - Standard password policies
- `vault.server` - Deploy Vault server

## Generated Resources

- `VaultSecret` (redhatcop.redhat.io/v1alpha1)
- `Policy` (redhatcop.redhat.io/v1alpha1)
- `KubernetesAuthEngineRole` (redhatcop.redhat.io/v1alpha1)
- `RandomSecret` (redhatcop.redhat.io/v1alpha1)
- `DatabaseSecretEngine` (redhatcop.redhat.io/v1alpha1)
- `Job` (for cryptoKey generation)

## Parameters

### Secret (`vault.secret`)

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Secret name |
| `format` | string | Output format (env/json/yaml/b64/plain) |
| `keys` | array | Keys to extract from vault |
| `staticData` | map | Additional static key-value pairs |
| `path` | string | Vault path scope (book/chapter/default/absolute) |
| `random` | bool | Generate random password |
| `randomKey` | string | Key name for random password |
| `passPolicyName` | string | Password policy name |

### Policy (`vault.prolicy`)

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Policy name |
| `serviceAccount` | string | K8s ServiceAccount to bind |
| `extraPolicy` | array | Additional policy paths |

### CryptoKey (`vault.cryptoKey`)

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Key name |
| `algorithm` | string | ed25519 or rsa |
| `bits` | int | RSA key size (default 4096) |
| `domain` | string | Domain for DKIM keys |

## Examples

### Basic Secret

```yaml
glyphs:
  vault:
    - type: secret
      name: database-creds
      format: env
      keys: [username, password]
```

### Random Password

```yaml
glyphs:
  vault:
    - type: secret
      name: api-credentials
      format: env
      random: true
      randomKey: api-password
      passPolicyName: strong-password
```

### Vault Policy

```yaml
glyphs:
  vault:
    - type: prolicy
      name: app-policy
      serviceAccount: my-app
      extraPolicy:
        - path: databases/static/mydb/*
          capabilities: [read]
```

### SSH Keypair

```yaml
glyphs:
  vault:
    - type: cryptoKey
      name: deploy-key
      algorithm: ed25519
      comment: "Deployment key"
```

## Vault Path Hierarchy

| Path Type | Pattern |
|-----------|---------|
| Book | `kv/data/<spellbook>/publics/<name>` |
| Chapter | `kv/data/<spellbook>/<chapter>/publics/<name>` |
| Namespace | `kv/data/<spellbook>/<chapter>/<namespace>/publics/<name>` |
| Absolute | Custom path |

See [VAULT.md](../VAULT.md) for complete documentation.

## Testing

```bash
make glyphs vault
make generate-expected GLYPH=vault
```

## Examples Location

`charts/glyphs/vault/examples/`
