# Vault Glyph

HashiCorp Vault integration for secrets management, authentication, and policy enforcement.

## Templates

### Secret Management
- `vault.secret` - ExternalSecret for secrets sync
- `vault.randomSecret` - Generate random passwords
- `vault.cryptoKey` - SSH/TLS keypair generation

### Database Engines (Dynamic Credentials)
- `vault.secretEngineMount` - Mount secret engines (database, pki, kv)
- `vault.postgresqlDBEngine` - PostgreSQL dynamic credentials
- `vault.mongoDBEngine` - MongoDB dynamic credentials

### Authentication & Policies
- `vault.prolicy` - Vault policy + K8s auth role
- `vault.kube-auth` - Kubernetes authentication
- `vault.oidc-auth` - OIDC authentication

### Password Policies
- `vault.customPasswordPolicy` - Custom password policies
- `vault.defaultPasswordPolicy` - Standard password policies

### Infrastructure
- `vault.server` - Deploy Vault server

## Generated Resources

- `VaultSecret` (redhatcop.redhat.io/v1alpha1) - Sync secrets from Vault to K8s
- `Policy` (redhatcop.redhat.io/v1alpha1) - Vault policy definitions
- `KubernetesAuthEngineRole` (redhatcop.redhat.io/v1alpha1) - K8s auth roles
- `RandomSecret` (redhatcop.redhat.io/v1alpha1) - Random password generation
- `SecretEngineMount` (redhatcop.redhat.io/v1alpha1) - Mount secret engines
- `DatabaseSecretEngineConfig` (redhatcop.redhat.io/v1alpha1) - Database connection config
- `DatabaseSecretEngineRole` (redhatcop.redhat.io/v1alpha1) - Database role definitions
- `PasswordPolicy` (redhatcop.redhat.io/v1alpha1) - Password policy definitions
- `Job` (for cryptoKey generation) - One-time key generation jobs

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

### Secret Engine Mount (`vault.secretEngineMount`)

| Field | Type | Description |
|-------|------|-------------|
| `mountType` | string | Engine type (required: "database", "pki", "kv", etc.) |
| `path` | string | Mount path (optional, defaults to `{mountType}-{book}-{chapter}`) |
| `description` | string | Human-friendly description (optional) |
| `config` | map | Mount configuration overrides (optional) |
| `options` | map | Mount type-specific options (optional) |
| `serviceAccount` | string | ServiceAccount for Vault auth (optional) |

**Default paths by mountType:**
- `database`: `database-{book}-{chapter}`
- `pki`: `pki-{book}-{chapter}`
- `kv`: `kv-{book}-{chapter}`

**Example:**
```yaml
- type: secretEngineMount
  mountType: database
  description: "Database secrets engine for dynamic credentials"
```

### PostgreSQL Database Engine (`vault.postgresqlDBEngine`)

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Engine name |
| `postgresSelector` | map | Selector to find postgres entries in lexicon |
| `serviceAccount` | string | ServiceAccount for Vault auth |
| `databaseMount` | string | Custom mount path (default: `database-{book}-{chapter}`) |

**Lexicon postgres entry fields:**

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | PostgreSQL instance name |
| `host` | string | PostgreSQL hostname |
| `port` | int | PostgreSQL port (default 5432) |
| `database` | string | Database name (use "*" for all) |
| `credentialsSecret` | string | K8s Secret name with admin credentials |
| `vaultSecretPath` | string | Vault KV path for admin credentials (alternative to credentialsSecret) |
| `databaseMount` | string | Custom mount path (overrides glyph-level setting) |
| `labels` | map | Labels for selector matching |

**Generated resources:**
- `DatabaseSecretEngineConfig` - Connection configuration
- `DatabaseSecretEngineRole` (2x) - `{name}-read-write` and `{name}-read-only`

### MongoDB Database Engine (`vault.mongoDBEngine`)

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Engine name |
| `mongoSelector` | map | Selector to find mongodb entries in lexicon |
| `serviceAccount` | string | ServiceAccount for Vault auth |
| `databaseMount` | string | Custom mount path (default: `database-{book}-{chapter}`) |

**Lexicon mongodb entry fields:**

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | MongoDB instance name |
| `host` | string | MongoDB hostname |
| `port` | int | MongoDB port (default 27017) |
| `database` | string | Database name (default "admin") |
| `credentialsSecret` | string | K8s Secret name with admin credentials |
| `vaultSecretPath` | string | Vault KV path for admin credentials (alternative to credentialsSecret) |
| `databaseMount` | string | Custom mount path (overrides glyph-level setting) |
| `labels` | map | Labels for selector matching |

**Generated resources:**
- `DatabaseSecretEngineConfig` - Connection configuration
- `DatabaseSecretEngineRole` (2x) - `{name}-read-write` and `{name}-read-only`

## Examples

### Basic Secret

```yaml
glyphs:
  vault:
    database-creds:
      type: secret
      format: env
      keys: [username, password]
```

### Random Password

```yaml
glyphs:
  vault:
    api-credentials:
      type: secret
      format: env
      random: true
      randomKey: api-password
      passPolicyName: strong-password
```

### Vault Policy

```yaml
glyphs:
  vault:
    app-policy:
      type: prolicy
      serviceAccount: my-app
      extraPolicy:
        - path: databases/static/mydb/*
          capabilities: [read]
```

### SSH Keypair

```yaml
glyphs:
  vault:
    deploy-key:
      type: cryptoKey
      algorithm: ed25519
      comment: "Deployment key"
```

### Database Dynamic Credentials (Complete Example)

```yaml
lexicon:
  # Vault server
  - type: vault
    url: http://vault.vault.svc:8200
    namespace: vault
    serviceAccount: vault
    authPath: the-yaml-life
    secretPath: secret
    labels:
      default: book

  # PostgreSQL with Vault-managed admin credentials
  - type: postgres
    name: main-postgres
    host: postgres.database.svc.cluster.local
    port: 5432
    database: postgres
    vaultSecretPath: "chapter"  # Admin creds from Vault
    labels:
      app: postgres

glyphs:
  vault:
    # Step 1: Mount the database secrets engine
    db-mount:
      type: secretEngineMount
      mountType: database
      description: "Database secrets engine for PostgreSQL dynamic credentials"

    # Step 2: Configure database engine
    postgres-engine:
      type: postgresqlDBEngine
      postgresSelector:
        app: postgres
      serviceAccount: vault

    # Step 3: Create policy (auto-generates database credential access)
    myapp-policy:
      type: prolicy
      serviceAccount: myapp

    # Step 4: Application consumes dynamic credentials
    myapp-db-credentials:
      type: secret
      generationType: "database"       # Database engine mode
      databaseEngine: "main-postgres"  # Engine name from lexicon
      databaseRole: "read-write"       # or "read-only"
      path: "chapter"                  # Optional, defaults to "chapter"
      format: env
      serviceAccount: myapp
      refreshPeriod: 30m               # Refresh before TTL expires
      keys:
        - username
        - password
```

**Generated path**: `secret/{book}/{chapter}/publics/main-postgres/creds/main-postgres-read-write`

**Application deployment**:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  template:
    spec:
      serviceAccountName: myapp
      containers:
      - name: app
        env:
        - name: DB_USERNAME
          valueFrom:
            secretKeyRef:
              name: myapp-db-credentials
              key: USERNAME
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: myapp-db-credentials
              key: PASSWORD
```

**How it works:**
1. SecretEngineMount enables database engine at `database-mybook-prod`
2. DatabaseSecretEngineConfig connects engine to PostgreSQL
3. VaultSecret requests credentials from `database-mybook-prod/creds/postgres-read-write`
4. Vault creates temporary PostgreSQL user: `v-kubernet-read-wri-abc123`
5. Credentials synced to K8s Secret `myapp-db-credentials`
6. Vault automatically revokes user after TTL (~1h)
7. VaultSecret renews before expiration (every 30m)

## Generation Types

### KV Secrets (`generationType: "kv"` - default)

Standard Vault KV v2 secrets with `/data/` prefix:

```yaml
glyphs:
  vault:
    api-credentials:
      type: secret
      generationType: "kv"  # Optional, this is the default
      format: env
      path: "chapter"
      keys:
        - api-key
        - api-secret
```

**Path**: `secret/data/{book}/{chapter}/publics/api-credentials`

### Database Credentials (`generationType: "database"`)

Dynamic credentials from database secrets engine:

```yaml
glyphs:
  vault:
    db-credentials:
      type: secret
      generationType: "database"
      databaseEngine: "postgres"       # Required: name from lexicon
      databaseRole: "read-write"       # Required: "read-write" or "read-only"
      databaseMount: "database-custom" # Optional: override mount path
      format: env
      serviceAccount: myapp
      refreshPeriod: 30m
      keys:
        - username
        - password
```

**Default path**: `database-{book}-{chapter}/creds/{engine}-{role}`
**Example**: `database-mybook-prod/creds/postgres-read-write`

## Policies for Database Credentials

Applications need Vault policies to read database credentials. The `prolicy` glyph **automatically generates** database credential policies when it detects `postgres` or `mongodb` entries in the lexicon.

### Auto-Generated Database Policies

When `prolicy` detects database engines in lexicon, it automatically adds:

```hcl
path "database-{book}-{chapter}/creds/*" {
  capabilities = ["read"]
}
```

This gives applications access to ALL database credential roles in the chapter.

### Manual Policy Configuration

For fine-grained control or custom database mounts, use `extraPolicy`:

```yaml
glyphs:
  vault:
    # Policy for application to read database credentials
    # This will AUTO-GENERATE database credential access
    myapp-db-policy:
      type: prolicy
      serviceAccount: myapp
```

**Auto-Generated Policy** (when postgres in lexicon):
```hcl
# Auto-generated: access to password policies
path "sys/policies/password/*" {
  capabilities = ["read"]
}

# Auto-generated: database credentials (when postgres/mongodb in lexicon)
path "database-mybook-prod/creds/*" {
  capabilities = ["read"]
}
```

**For fine-grained control**, use `extraPolicy`:
```yaml
glyphs:
  vault:
    myapp-readonly-policy:
      type: prolicy
      serviceAccount: myapp-readonly
      extraPolicy:
        # Only allow read-only role
        - path: "database-mybook-prod/creds/main-postgres-read-only"
          capabilities: ["read"]
```

**Generated KubernetesAuthEngineRole**:
- Binds policy `myapp-db-policy` to ServiceAccount `myapp`
- Allows pods with SA `myapp` to authenticate and get database credentials

## Vault Path Hierarchy

Paths are generated by `generateSecretPath` helper with different prefixes based on `engineType`.

### KV Secrets (engineType="kv")

Includes `/data/` prefix for KV v2 API:

| Path Scope | Pattern | Example |
|------------|---------|---------|
| Book | `{secretPath}/data/{book}/publics/{name}` | `secret/data/mybook/publics/api-key` |
| Chapter | `{secretPath}/data/{book}/{chapter}/publics/{name}` | `secret/data/mybook/prod/publics/db-creds` |
| Namespace | `{secretPath}/data/{book}/{chapter}/{ns}/publics/{name}` | `secret/data/mybook/prod/myapp/publics/token` |
| Absolute | `{secretPath}/data{customPath}{name}` | `secret/data/custom/path/secret` |

### Database Engines (engineType="database")

No `/data/` prefix - these are mount points:

| Path Scope | Pattern | Example |
|------------|---------|---------|
| Book | `{secretPath}/{book}/publics/{engine}` | `secret/mybook/publics/postgres` |
| Chapter | `{secretPath}/{book}/{chapter}/publics/{engine}` | `secret/mybook/prod/publics/postgres` |
| Namespace | `{secretPath}/{book}/{chapter}/{ns}/publics/{engine}` | `secret/mybook/prod/myapp/publics/mongo` |

### Database Credentials Path

When using `generationType: "database"`, the path uses a configurable database mount:

```
{databaseMount}/creds/{engineName}-{roleName}
```

**Default mount**: `database-{book}-{chapter}`

**Example**: `database-mybook-prod/creds/postgres-read-write`

#### Custom Database Mount

Override the mount path in lexicon or glyph definition:

**In lexicon**:
```yaml
lexicon:
  - type: postgres
    name: main-postgres
    databaseMount: "database-shared"  # Custom mount
```

**In glyph**:
```yaml
glyphs:
  vault:
    - type: postgresqlDBEngine
      postgresSelector:
        app: postgres
      databaseMount: "database-prod"  # Override for this engine
```

**In credential consumption**:
```yaml
- type: secret
  name: db-creds
  generationType: "database"
  databaseEngine: "main-postgres"
  databaseRole: "read-write"
  databaseMount: "database-custom"  # Override for this secret
```

**Note**: The `prolicy` glyph uses the **default mount pattern** for auto-generated policies. If using custom mounts, add manual `extraPolicy` rules.

See [VAULT.md](../VAULT.md) for complete documentation.

## Testing

```bash
make glyphs vault
make generate-expected GLYPH=vault
```

## Examples Location

`charts/glyphs/vault/examples/`
