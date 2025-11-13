# Vault Integration

HashiCorp Vault integration for secrets management, authentication, and cryptographic operations in kast.

## Overview

The [vault glyph](GLYPHS.md) provides:
- Secret synchronization from Vault to Kubernetes Secrets
- Automatic policy generation with path-based access control
- Random password generation with custom policies
- Cryptographic keypair generation (Ed25519, RSA)
- Kubernetes authentication to Vault
- Database credential engines
- OIDC authentication

Implementation uses [vault-operator](https://github.com/redhat-cop/vault-config-operator) CRDs for declarative Vault configuration.

## Architecture

### Components

```
┌─────────────────────────────────────────────────────┐
│ Spell (glyphs.vault configuration)                  │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│ Vault Glyph Templates                               │
│ - Generate vault-operator CRDs                      │
│ - Query lexicon for vault server via runic indexer │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│ Vault-Operator CRDs                                 │
│ - VaultSecret (sync secrets)                        │
│ - Policy (HCL policies)                             │
│ - KubernetesAuthEngineRole (auth bindings)          │
│ - RandomSecret (password generation)                │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│ HashiCorp Vault                                     │
│ - KV secrets engine                                 │
│ - Kubernetes auth backend                           │
│ - Policy enforcement                                │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│ Kubernetes Secret                                   │
│ - Automatically synced from Vault                   │
│ - Used by Pods via envFrom/volumeMounts             │
└─────────────────────────────────────────────────────┘
```

### Vault Server Discovery

Vault server configuration is stored in [lexicon](LEXICON.md) and queried via runic indexer:

```yaml
lexicon:
  - name: production-vault
    type: vault
    url: https://vault.production.svc:8200
    namespace: vault
    authPath: kubernetes
    secretPath: kv
    labels:
      environment: production
      default: chapter
    chapter: production

  - name: default-vault
    type: vault
    url: https://vault.vault.svc:8200
    namespace: vault
    authPath: kubernetes
    secretPath: kv
    labels:
      default: book
```

Glyph definitions can specify selector to choose vault server:

```yaml
glyphs:
  vault:
    app-secret:
      type: secret
      selector:
        environment: production  # Selects production-vault
```

See [LEXICON.md](LEXICON.md) for lexicon details.

## Authentication

### Kubernetes Auth Pattern

Vault authentication uses Kubernetes ServiceAccount tokens:

1. Pod starts with ServiceAccount
2. vault-operator reads ServiceAccount token
3. Token sent to Vault kubernetes auth backend
4. Vault validates token with Kubernetes TokenReview API
5. Vault returns token with policies attached

**Authentication Flow:**

```
Pod → SA Token → vault-operator → Vault K8s Auth → TokenReview API
                                        ↓
                                  Vault Token (with policies)
                                        ↓
                                  Read Secret
```

### Service Account Configuration

Each spell gets a ServiceAccount that authenticates to Vault:

```yaml
glyphs:
  vault:
    app-policy:
      type: prolicy
      serviceAccount: my-app  # Binds policy to this SA
```

Vault policy allows this ServiceAccount to read secrets at specific paths.

## Path Hierarchy System

Vault secret paths follow a hierarchy that controls access scope.

### Path Resolution Algorithm

The `generateSecretPath` template resolves paths based on `path` field:

| Path Value | Resolved Vault Path | Scope |
|------------|---------------------|-------|
| `"book"` | `kv/data/<spellbook>/publics/<name>` | Shared across all chapters |
| `"chapter"` | `kv/data/<spellbook>/<chapter>/publics/<name>` | Shared within chapter |
| Default (empty) | `kv/data/<spellbook>/<chapter>/<namespace>/publics/<name>` | Namespace-specific |
| `"/custom/path"` | `kv/data/custom/path` | Absolute path |

**Implementation:**

```go
{{- define "generateSecretPath" }}
  {{- if eq $path "book" }}
    {{- printf "%s/data/%s/%s/%s"
              $vaultConf.secretPath
              $root.Values.spellbook.name
              $internalPath
              $name }}
  {{- else if eq $path "chapter" }}
    {{- printf "%s/data/%s/%s/%s/%s"
                $vaultConf.secretPath
                $root.Values.spellbook.name
                $root.Values.chapter.name
                $internalPath
                $name  }}
  {{- else if hasPrefix "/" $path }}
    {{- printf "%s/data%s" $vaultConf.secretPath $path }}
  {{- else }}
    {{- printf "%s/data/%s/%s/%s/%s/%s"
          $vaultConf.secretPath
          $root.Values.spellbook.name
          $root.Values.chapter.name
          $root.Release.Namespace
          $internalPath
          $name  }}
  {{- end }}
{{- end }}
```

### Path Examples

**Book-level secret (shared across chapters):**

```yaml
glyphs:
  vault:
    database-readonly:
      type: secret
      path: book
      keys: [username, password]

# Resolves to: kv/data/my-book/publics/database-readonly
```

**Chapter-level secret (shared within chapter):**

```yaml
glyphs:
  vault:
    api-credentials:
      type: secret
      path: chapter
      keys: [api_key, api_secret]

# Resolves to: kv/data/my-book/production/publics/api-credentials
```

**Namespace-level secret (most specific):**

```yaml
glyphs:
  vault:
    app-secret:
      type: secret
      # No path - defaults to namespace scope
      keys: [private_key]

# Resolves to: kv/data/my-book/production/my-app/publics/app-secret
```

**Absolute path (custom location):**

```yaml
glyphs:
  vault:
    shared-config:
      type: secret
      path: /infrastructure/shared
      keys: [config]

# Resolves to: kv/data/infrastructure/shared
```

### Private vs Public Paths

The `private` field controls path segment (defaults to "publics"):

```yaml
glyphs:
  vault:
    internal-key:
      type: secret
      private: privates  # Uses "privates" instead of "publics"
      keys: [key]

# Resolves to: kv/data/my-book/production/my-app/privates/internal-key
```

**Use case:** Separate public (shared) from private (restricted) secrets within same hierarchy.

## Policy System

### Automatic Policy Generation

The `vault.prolicy` template generates:
1. **Vault Policy** - HCL policy defining path access
2. **KubernetesAuthEngineRole** - Binds policy to ServiceAccount

**Generated Policy Structure:**

```hcl
# Namespace-specific paths (read/write)
path "kv/data/<spellbook>/<chapter>/<namespace>/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
path "kv/metadata/<spellbook>/<chapter>/<namespace>/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Chapter publics (read-only)
path "kv/data/<spellbook>/<chapter>/publics/*" {
  capabilities = ["read", "list"]
}

# Book publics (read-only)
path "kv/data/<spellbook>/publics/*" {
  capabilities = ["read", "list"]
}

# Pipelines (read-only, for CI/CD)
path "kv/data/<spellbook>/pipelines/*" {
  capabilities = ["read", "list"]
}

# Password policies (read-only, for random generation)
path "sys/policies/password/*" {
  capabilities = ["read", "list"]
}
```

### Policy Hierarchy

Policies inherit and merge extraPolicy from multiple scopes:

```
Book-level extraPolicy (spellbook.prolicy.extraPolicy)
  ↓
Chapter-level extraPolicy (chapter.prolicy.extraPolicy)
  ↓
Lexicon vault entry extraPolicy
  ↓
Glyph definition extraPolicy
```

**Most specific wins.** All extraPolicy entries are merged into final policy.

### Extra Policy

Add custom policy paths via `extraPolicy`:

```yaml
glyphs:
  vault:
    database-app:
      type: prolicy
      serviceAccount: database-app
      extraPolicy:
        # Read database static credentials
        - path: databases/static/postgres/*
          capabilities: [read]

        # Read dynamic database credentials
        - path: database/creds/readonly
          capabilities: [read]

        # Write to specific KV path
        - path: kv/data/applications/myapp/cache
          capabilities: [create, read, update, delete]
```

### Policy Examples

**Basic application policy:**

```yaml
glyphs:
  vault:
    web-app:
      type: prolicy
      serviceAccount: web-app

# Automatically gets:
# - Read/write to kv/data/<book>/<chapter>/<namespace>/*
# - Read to chapter and book publics
# - Read password policies
```

**Policy with database access:**

```yaml
glyphs:
  vault:
    api-service:
      type: prolicy
      serviceAccount: api-service
      extraPolicy:
        - path: database/creds/api-role
          capabilities: [read]
        - path: pki/issue/api-domain
          capabilities: [create, update]
```

**Policy at book level (inherited by all chapters):**

```yaml
# book/index.yaml
spellbook:
  prolicy:
    extraPolicy:
      - path: kv/data/organization/shared/*
        capabilities: [read, list]

# All spells in all chapters can read organization/shared/*
```

## Secret Types

### Format Types

Secrets support 5 output formats:

| Format | Description | Use Case |
|--------|-------------|----------|
| `plain` | Keys as-is | Standard K8s secrets |
| `env` | Uppercase with underscores | Environment variables (envFrom) |
| `json` | JSON-encoded | Single JSON blob |
| `yaml` | YAML-encoded | Configuration files |
| `b64` | Base64-encoded | Binary data |

### Plain Format

Keys preserved as-is:

```yaml
glyphs:
  vault:
    database-creds:
      type: secret
      format: plain
      keys: [username, password, host]
```

**Generated K8s Secret:**

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: database-creds
data:
  username: <base64-value>
  password: <base64-value>
  host: <base64-value>
```

### Env Format

Keys converted to SCREAMING_SNAKE_CASE for environment variables:

```yaml
glyphs:
  vault:
    api-config:
      type: secret
      format: env
      keys: [api-key, api-secret, base-url]
```

**Generated K8s Secret:**

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: api-config
data:
  API_KEY: <base64-value>
  API_SECRET: <base64-value>
  BASE_URL: <base64-value>
```

**Usage in Pod:**

```yaml
envFrom:
  - secretRef:
      name: api-config
```

### JSON Format

Entire secret as JSON:

```yaml
glyphs:
  vault:
    config-blob:
      type: secret
      format: json
      key: config.json  # Output key name
```

**Generated K8s Secret:**

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: config-blob
data:
  config.json: <base64-json>
```

### YAML Format

Entire secret as YAML:

```yaml
glyphs:
  vault:
    app-config:
      type: secret
      format: yaml
      key: config.yaml
```

### Static Data Merging

Add static key-value pairs to secrets:

```yaml
glyphs:
  vault:
    database-creds:
      type: secret
      format: env
      keys: [password]
      staticData:
        DB_HOST: postgres.default.svc
        DB_PORT: "5432"
        DB_NAME: myapp
```

**Result:** Vault password + static host/port/name in single secret.

## Random Secrets

### Password Generation

Generate random passwords with custom policies:

```yaml
glyphs:
  vault:
    admin-creds:
      type: secret
      format: env
      random: true
      randomKey: admin_password
      passPolicyName: strong-password
      staticData:
        admin_username: admin
```

**Workflow:**

1. `vault.randomSecret` creates `RandomSecret` CRD
2. vault-operator generates password using Vault password policy
3. Stores password in Vault at secret path
4. `VaultSecret` syncs to K8s Secret
5. Pod consumes as environment variable or file

### Password Policies

Define custom password policies:

```yaml
glyphs:
  vault:
    strong-password:
      type: customPasswordPolicy
      policy: |
        length = 24
        rule "charset" {
          charset = "abcdefghijklmnopqrstuvwxyz"
          min-chars = 6
        }
        rule "charset" {
          charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
          min-chars = 6
        }
        rule "charset" {
          charset = "0123456789"
          min-chars = 6
        }
        rule "charset" {
          charset = "!@#$%^&*"
          min-chars = 6
        }

    user-password:
      type: secret
      format: plain
      randomKey: password
      passPolicyName: strong-password
```

**Built-in policy:** `simple-password-policy` (default)

### Multiple Random Keys

Generate multiple random passwords in one secret:

```yaml
glyphs:
  vault:
    multi-creds:
      type: secret
      format: env
      randomKeys: [api_key, webhook_secret, encryption_key]
      staticData:
        api_version: v2
```

**Generated Secret:**

```yaml
API_KEY: <random>
WEBHOOK_SECRET: <random>
ENCRYPTION_KEY: <random>
API_VERSION: v2
```

## Cryptographic Keys

### Keypair Generation

Generate Ed25519 or RSA keypairs:

```yaml
glyphs:
  vault:
    ssh-deploy-key:
      type: cryptoKey
      algorithm: ed25519
      comment: "Deployment key for GitOps"
```

**Process:**

1. Creates Kubernetes Job with vault and openssh-client
2. Job generates keypair locally
3. Authenticates to Vault with ServiceAccount
4. Stores private + public keys in Vault
5. Creates VaultSecret to sync keys to K8s

**Stored in Vault:**

```json
{
  "private_key": "<base64-encoded-private-key>",
  "public_key": "ssh-ed25519 AAAAC3... comment",
  "public_key_base64": "AAAAC3...",
  "algorithm": "ed25519",
  "created_at": "2025-10-20T12:00:00Z"
}
```

**K8s Secret:**

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: ssh-deploy-key
data:
  private_key: <base64>
  public_key: <base64>
  public_key_base64: <base64>
  algorithm: <base64>
```

### RSA Keys

```yaml
glyphs:
  vault:
    tls-key:
      type: cryptoKey
      algorithm: rsa
      bits: 4096
```

### DKIM Keys

Generate DKIM keys for email:

```yaml
glyphs:
  vault:
    mail-dkim:
      type: cryptoKey
      algorithm: ed25519
      domain: example.com
      comment: "DKIM for example.com"
```

**Integration with certManager:**

```yaml
glyphs:
  certManager:
    dkim-dns:
      type: dnsEndpointSourced
      sourceSecret: mail-dkim
      sourceKey: public_key_base64
      dnsRecordFormat: "v=DKIM1; k=ed25519; p=%s"
      dnsName: default._domainkey.example.com
      recordType: TXT
      targets: []
```

**Result:** DNS record created from public key in secret.

## Vault Glyph Types

### 1. vault.secret

Syncs secrets from Vault to Kubernetes.

**Parameters:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Secret name |
| `format` | string | No | Output format (plain/env/json/yaml/b64) |
| `keys` | array | No | Keys to extract |
| `staticData` | map | No | Static key-value pairs |
| `path` | string | No | Path scope (book/chapter/default/absolute) |
| `random` | bool | No | Generate random password |
| `randomKey` | string | No | Key name for random password |
| `randomKeys` | array | No | Multiple random keys |
| `passPolicyName` | string | No | Password policy |
| `serviceAccount` | string | No | Override ServiceAccount |
| `role` | string | No | Override Vault role |
| `refreshPeriod` | string | No | Sync interval (default: 3m0s) |
| `annotations` | map | No | Secret annotations |
| `labels` | map | No | Secret labels |
| `secretType` | string | No | K8s secret type (default: Opaque) |

**Example:** See [Path Examples](#path-examples)

### 2. vault.prolicy

Creates Vault policy and Kubernetes auth role.

**Parameters:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | No | Policy name (defaults to spell name) |
| `nameOverride` | string | No | Override policy name |
| `serviceAccount` | string | Yes | ServiceAccount to bind |
| `extraPolicy` | array | No | Additional policy paths |
| `selector` | map | No | Vault server selector |

**Generated Resources:**
- `Policy` (Vault HCL policy)
- `KubernetesAuthEngineRole` (SA → policy binding)

**Example:** See [Policy Examples](#policy-examples)

### 3. vault.cryptoKey

Generates cryptographic keypairs.

**Parameters:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Key name |
| `algorithm` | string | No | ed25519 or rsa (default: ed25519) |
| `bits` | int | No | RSA key size (default: 4096) |
| `domain` | string | No | Domain annotation |
| `comment` | string | No | SSH key comment |

**Generated Resources:**
- Kubernetes Job (keypair generation)
- VaultSecret (sync to K8s)
- ServiceAccount, Role, RoleBinding

**Example:** See [Cryptographic Keys](#cryptographic-keys)

### 4. vault.randomSecret

Generates random passwords stored in Vault.

**Usually invoked automatically by `vault.secret` with `random: true`.**

**Parameters:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Secret name |
| `randomKey` | string | No | Key name (default: password) |
| `passPolicyName` | string | No | Password policy |
| `path` | string | No | Vault path scope |

### 5. vault.customPasswordPolicy

Creates custom password policy in Vault.

**Parameters:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Policy name |
| `policy` | string | Yes | HCL policy definition |

**Example:** See [Password Policies](#password-policies)

### 6. vault.kube-auth

Configures Kubernetes authentication backend.

**Parameters:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Auth backend name |
| `clusterSelector` | map | Yes | Lexicon selector for k8s cluster |
| `createRemoteRBAC` | bool | No | Create ServiceAccount and RBAC |
| `serviceAccount` | string | No | Override ServiceAccount |

**Generated Resources:**
- `AuthEngineMount`
- `KubernetesAuthEngineConfig`
- `KubernetesAuthEngineRole`
- ServiceAccount, ClusterRole, ClusterRoleBinding (if createRemoteRBAC)

### 7. vault.databaseEngine

Configures dynamic database credentials.

**Parameters:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Engine name |
| `databaseType` | string | Yes | Database type (postgresql, mysql, etc.) |
| `connectionURL` | string | Yes | Database connection string |
| `username` | string | Yes | Database admin username |
| `password` | string | Yes | Database admin password |
| `roles` | array | Yes | Database roles configuration |

### 8. vault.mongoDBEngine

Configures dynamic MongoDB credentials.

Similar to `databaseEngine` but for MongoDB.

### 9. vault.oidc-auth

Configures OIDC authentication backend.

**Parameters:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Auth backend name |
| `oidcDiscoveryURL` | string | Yes | OIDC discovery URL |
| `oidcClientID` | string | Yes | Client ID |
| `oidcClientSecret` | string | Yes | Client secret |

### 10. vault.defaultPasswordPolicy

Creates default password policy (simple-password-policy).

**No parameters required.**

### 11. vault.server

Deploys Vault server (development mode).

**Parameters:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | No | Server name |
| `storage` | string | No | Storage backend (file/raft) |
| `replicas` | int | No | Number of replicas |

**Use for development only. Production Vault should be deployed separately.**

## Integration Patterns

### With Summon

[Summon](SUMMON.md) workloads automatically use vault secrets:

```yaml
name: web-app
image:
  repository: nginx
  tag: alpine

glyphs:
  vault:
    web-app-policy:
      type: prolicy
      serviceAccount: web-app

    app-config:
      type: secret
      format: env
      keys: [database_url, api_key]
```

**Result:**
1. ServiceAccount `web-app` created
2. Vault policy grants access to secrets
3. Secret `app-config` synced to K8s
4. Pod can mount secret as env vars or volume

### With Istio

Combine vault secrets with Istio VirtualService:

```yaml
glyphs:
  vault:
    oauth-client:
      type: secret
      format: env
      keys: [client_id, client_secret]

  istio:
    api-service:
      type: virtualService
      hosts: [api.example.com]
      routes:
        - destination: api-service
```

### With Argo Events

Use vault secrets in Argo Workflows triggered by events:

```yaml
glyphs:
  vault:
    github-webhook:
      type: secret
      format: env
      keys: [webhook_secret]

  argo-events:
    github-events:
      type: eventSource
      github:
        webhookSecret:
          name: github-webhook
          key: WEBHOOK_SECRET
```

### Multi-Environment Pattern

Use [lexicon](LEXICON.md) + selectors for environment-specific vaults:

```yaml
# Book lexicon
lexicon:
  - name: staging-vault
    type: vault
    url: https://vault.staging.svc:8200
    labels:
      environment: staging
      default: chapter
    chapter: staging

  - name: production-vault
    type: vault
    url: https://vault.production.svc:8200
    labels:
      environment: production
      default: chapter
    chapter: production

# Spell (works in both environments)
glyphs:
  vault:
    database-creds:
      type: secret
      # Automatically uses chapter default vault
      keys: [username, password]
```

**Result:** Same spell works in staging and production with different vault servers.

## Troubleshooting

### Secret Not Syncing

**Symptoms:** VaultSecret exists but K8s Secret not created.

**Check:**

```bash
# Check VaultSecret status
kubectl describe vaultsecret <name>

# Check vault-operator logs
kubectl logs -n vault-operator deployment/vault-config-operator

# Check Vault access
vault login
vault kv get <path>
```

**Common causes:**
- ServiceAccount lacks Vault policy
- Vault path doesn't exist
- vault-operator misconfigured

### Authentication Failures

**Symptoms:** `permission denied` errors in vault-operator logs.

**Check:**

```bash
# Verify KubernetesAuthEngineRole
kubectl get kubernetesauthenginerole <name> -o yaml

# Verify Policy
kubectl get policy <name> -o yaml

# Test authentication manually
export SA_TOKEN=$(kubectl create token <service-account>)
vault write auth/kubernetes/login role=<role> jwt=$SA_TOKEN
```

**Common causes:**
- ServiceAccount not bound to role
- Role not associated with policy
- Kubernetes auth backend misconfigured

### Path Resolution Issues

**Symptoms:** Secret path not found.

**Debug path resolution:**

```bash
# Template spell and check VaultSecret path
helm template my-app charts/summon -f spell.yaml | grep "path:"

# Check expected vs actual
# Book: kv/data/<book>/publics/<name>
# Chapter: kv/data/<book>/<chapter>/publics/<name>
# Namespace: kv/data/<book>/<chapter>/<namespace>/publics/<name>

# Check if secret exists in Vault
vault kv get <path>
```

### Random Secret Not Generating

**Symptoms:** RandomSecret created but password not in Vault.

**Check:**

```bash
# Check RandomSecret status
kubectl describe randomsecret <name>

# Check password policy exists
vault read sys/policies/password/<policy-name>

# Check vault-operator has policy access
vault token capabilities sys/policies/password/<policy-name>
```

**Common causes:**
- Password policy doesn't exist
- Policy not accessible by vault-operator ServiceAccount
- Invalid policy syntax

### CryptoKey Job Failures

**Symptoms:** cryptoKey Job fails to generate keys.

**Check:**

```bash
# Check Job logs
kubectl logs job/<name>-keygen

# Check Job status
kubectl describe job/<name>-keygen

# Common errors:
# - Vault authentication failed
# - Path already exists (expected, not an error)
# - Network connectivity to Vault
```

### Policy Too Restrictive

**Symptoms:** Application can't read secrets it should access.

**Debug policy:**

```bash
# Get effective policy
kubectl get policy <name> -o yaml

# Check policy in Vault
vault policy read <name>

# Test access with token
vault token capabilities <path>

# Add extraPolicy if needed
```

**Solution:** Add extraPolicy to prolicy glyph definition.

### Vault Server Not Found

**Symptoms:** `no vault server found` during rendering.

**Check:**

```bash
# Verify lexicon has vault entry
helm template charts/summon -f spell.yaml --debug | grep -A 10 lexicon:

# Check selector matches lexicon labels
# Glyph selector: {environment: production}
# Lexicon labels: {environment: production}  # Must match exactly

# Check chapter default
# Lexicon labels: {default: chapter}
# Lexicon chapter: <current-chapter>

# Check book default
# Lexicon labels: {default: book}
```

**Solution:** Add vault entry to lexicon or fix selector.

## Best Practices

### Secret Scoping

**Use appropriate path scope for each secret:**

- **Namespace scope (default):** Application-specific secrets
- **Chapter scope:** Environment-wide secrets (staging, production)
- **Book scope:** Organization-wide secrets (CA certificates, registries)
- **Absolute paths:** External/shared infrastructure

### Policy Design

**Follow principle of least privilege:**

```yaml
# Good: Specific paths
extraPolicy:
  - path: database/creds/readonly
    capabilities: [read]

# Avoid: Overly broad
extraPolicy:
  - path: database/*
    capabilities: [create, read, update, delete, list]
```

### Password Policies

**Create reusable password policies:**

```yaml
# Book level - available to all chapters
glyphs:
  vault:
    org-standard-password:
      type: customPasswordPolicy
      policy: |
        length = 16
        rule "charset" {
          charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        }
```

### Rotation

**Enable automatic secret rotation:**

```yaml
glyphs:
  vault:
    api-key:
      type: secret
      refreshPeriod: 1h  # Sync every hour
      keys: [key]
```

Combine with Vault lease TTL for automatic rotation.

### Monitoring

**Monitor secret sync status:**

```bash
# Check all VaultSecrets
kubectl get vaultsecrets --all-namespaces

# Check for errors
kubectl get vaultsecrets -o json | jq '.items[] | select(.status.conditions[].status == "False")'
```

### Testing

**Test vault integration:**

```bash
# Generate test output
make glyphs vault

# Check specific example
make inspect-chart CHART=kaster EXAMPLE=vault/secrets

# Show diff if output changed
make show-glyph-diff GLYPH=vault EXAMPLE=secrets
```

## Related Documentation

- [GLYPHS.md](GLYPHS.md) - Glyph system architecture and overview
- [KASTER.md](KASTER.md) - Glyph orchestration and rendering
- [BOOKRACK.md](BOOKRACK.md) - Spell configuration and book structure
- [GLYPHS_REFERENCE.md](GLYPHS_REFERENCE.md) - All available glyphs
- [LEXICON.md](LEXICON.md) - Infrastructure discovery system
- [HIERARCHY_SYSTEMS.md](HIERARCHY_SYSTEMS.md#2-vault-path-hierarchy) - Vault path hierarchy details
- [docs/glyphs/vault.md](glyphs/vault.md) - Vault glyph template reference
- [Vault Config Operator](https://github.com/redhat-cop/vault-config-operator) - CRD documentation

## Examples

See `charts/glyphs/vault/examples/` for comprehensive examples:

- `secrets.yaml` - Basic secret sync
- `random-secrets.yaml` - Password generation
- `crypto-key.yaml` - Keypair generation
- `prolicy-test.yaml` - Policy with extraPolicy
- `path-variants.yaml` - All path types
- `format-variants.yaml` - All output formats
- `custom-password-policies.yaml` - Custom password policies
- `advanced-custom-policies.yaml` - Complex policy configurations
