# PostgreSQL Glyph

CloudNativePG (CNPG) integration for managed PostgreSQL database clusters in Kubernetes.

## Templates

### Database Cluster
- `postgresql.cluster` - PostgreSQL cluster with replication, backup, and HA

## Generated Resources

- `Cluster` (postgresql.cnpg.io/v1) - CloudNativePG Cluster resource
- `ConfigMap` (optional) - Post-initialization SQL scripts (when `postInitSQL.create` or `postInitApp.create` is true)

## Parameters

### Cluster (`postgresql.cluster`)

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Cluster name (defaults to release name) |
| `description` | string | Human-readable cluster description |
| `image` | object | Container image configuration (repository, name, tag) |
| `instances` | int | Number of PostgreSQL instances (default: 1) |
| `startDelay` | int | Delay in seconds before starting instance (default: 3600) |
| `stopDelay` | int | Delay in seconds before stopping instance (default: 1800) |
| `primaryUpdateStrategy` | string | Update strategy: `unsupervised` or `supervised` |

### Database Bootstrap

| Field | Type | Description |
|-------|------|-------------|
| `dbName` | string | Initial database name (defaults to release name) |
| `userName` | string | Initial database owner username (defaults to release name) |
| `secret` | string | Name of secret containing user credentials |
| `superuser.enabled` | bool | Enable superuser access (default: true) |
| `superuserSecret` | string | Name of secret for superuser credentials |

### Managed Roles

| Field | Type | Description |
|-------|------|-------------|
| `roles` | array | List of PostgreSQL roles to manage |
| `roles[].name` | string | Role name |
| `roles[].ensure` | string | `present` or `absent` |
| `roles[].connectionLimit` | int | Max concurrent connections (-1 = unlimited) |
| `roles[].inherit` | bool | Inherit privileges from parent roles |
| `roles[].login` | bool | Allow role to login |
| `roles[].superuser` | bool | Grant superuser privileges |
| `roles[].createdb` | bool | Allow creating databases |
| `roles[].createrole` | bool | Allow creating roles |
| `roles[].passwordSecret` | object | Secret containing role password |

### Post-Initialization

| Field | Type | Description |
|-------|------|-------------|
| `postInitSQL` | object | SQL executed outside transaction (for CREATE DATABASE) |
| `postInitSQL.type` | string | `cm` (ConfigMap) |
| `postInitSQL.name` | string | ConfigMap name |
| `postInitSQL.key` | string | ConfigMap key containing SQL |
| `postInitSQL.create` | bool | Auto-create ConfigMap (requires summon templates) |
| `postInitSQL.content` | string | SQL content (when create=true) |
| `postInitApp` | object | SQL executed in transaction (for application schema) |
| `postInitApp.type` | string | `cm` (ConfigMap) |
| `postInitApp.name` | string | ConfigMap name |
| `postInitApp.key` | string | ConfigMap key containing SQL |
| `postInitApp.create` | bool | Auto-create ConfigMap (requires summon templates) |
| `postInitApp.content` | string | SQL content (when create=true) |
| `postInitApp.database` | string | Target database for SQL execution |
| `postInitApp.owner` | string | Database owner for SQL execution |

### Storage

| Field | Type | Description |
|-------|------|-------------|
| `storage.size` | string | PVC size (default: "1Gi") |
| `storage.storageClass` | string | StorageClass name |

### Resources & Scheduling

| Field | Type | Description |
|-------|------|-------------|
| `resources` | object | CPU/memory requests and limits |
| `affinity` | object | Pod affinity/anti-affinity rules |

### PostgreSQL Configuration

| Field | Type | Description |
|-------|------|-------------|
| `postgresql` | object | PostgreSQL configuration parameters |
| `postgresql.parameters` | map | PostgreSQL server parameters (e.g., max_connections, shared_buffers) |

## Examples

### Minimal Cluster

```yaml
glyphs:
  postgresql:
    my-database:
      type: cluster
      instances: 1
```

This generates:
- 1 PostgreSQL instance
- Default database and user (named after release)
- 1Gi storage

### Production Cluster with HA

```yaml
glyphs:
  postgresql:
    production-db:
      type: cluster
      description: Production PostgreSQL cluster
      instances: 3
      primaryUpdateStrategy: supervised

      image:
        name: cloudnative-pg/postgresql
        repository: ghcr.io
        tag: "17.5"

      dbName: production_db
      userName: app-user
      secret: db-credentials

      storage:
        storageClass: fast-ssd
        size: 20Gi

      resources:
        limits:
          cpu: "2"
          memory: 4Gi
        requests:
          cpu: "1"
          memory: 2Gi

      postgresql:
        parameters:
          max_connections: "200"
          shared_buffers: "1GB"
          effective_cache_size: "3GB"
```

This generates:
- 3-instance PostgreSQL cluster with high availability
- Custom PostgreSQL configuration
- 20Gi fast SSD storage
- CPU/memory resource management

### Cluster with Custom Roles

```yaml
glyphs:
  postgresql:
    app-db:
      type: cluster
      instances: 2

      roles:
        - name: app-user
          ensure: present
          login: true
          createdb: true
          passwordSecret:
            name: app-user-password

        - name: readonly-user
          ensure: present
          login: true
          createdb: false
          passwordSecret:
            name: readonly-password
```

This generates:
- PostgreSQL cluster with 2 managed roles
- `app-user` with database creation privileges
- `readonly-user` without creation privileges

### Cluster with Initialization SQL

```yaml
glyphs:
  postgresql:
    initialized-db:
      type: cluster
      dbName: myapp_db
      userName: myapp_user

      postInitApp:
        database: myapp_db
        owner: myapp_user
        type: cm
        create: true
        content: |
          CREATE TABLE users (
            id SERIAL PRIMARY KEY,
            username VARCHAR(50) UNIQUE NOT NULL,
            email VARCHAR(100) UNIQUE NOT NULL
          );

          CREATE INDEX idx_users_email ON users(email);
```

This generates:
- PostgreSQL cluster with initial database schema
- Auto-created ConfigMap with SQL content
- Schema applied after database initialization

## Testing

Test this glyph through kaster:

```bash
# Test all postgresql examples
make glyphs postgresql

# Create new test example
cat > charts/glyphs/postgresql/examples/my-test.yaml <<EOF
glyphs:
  postgresql:
    test-cluster:
      type: cluster
      instances: 2
EOF

# Test specific example
make glyphs postgresql
```

## Integration with CloudNativePG

This glyph leverages CloudNativePG (CNPG) operator features:

- **High Availability**: Automatic failover and replication
- **Backup & Recovery**: Point-in-time recovery support
- **Connection Pooling**: Built-in PgBouncer integration (via CNPG)
- **Monitoring**: Prometheus metrics export
- **Rolling Updates**: Zero-downtime PostgreSQL upgrades

## Common Patterns

### Development Database
```yaml
postgresql:
  dev-db:
    type: cluster
    instances: 1
    storage:
      size: 5Gi
```

### Production with Backup
```yaml
postgresql:
  prod-db:
    type: cluster
    instances: 3
    primaryUpdateStrategy: supervised
    storage:
      storageClass: fast-ssd
      size: 50Gi
    postgresql:
      parameters:
        max_connections: "500"
        shared_buffers: "4GB"
```

### Multi-Tenant Database
```yaml
postgresql:
  multi-tenant:
    type: cluster
    instances: 2
    roles:
      - name: tenant-a
        ensure: present
        login: true
        passwordSecret:
          name: tenant-a-password
      - name: tenant-b
        ensure: present
        login: true
        passwordSecret:
          name: tenant-b-password
```

## Notes

- CloudNativePG operator must be installed in the cluster
- Storage class must support ReadWriteOnce access mode
- For production: use `primaryUpdateStrategy: supervised` to control updates
- Post-init SQL with `create: true` requires summon chart templates
- Backup configuration is managed separately through CNPG ScheduledBackup resources
