# Trinkets

Opinionated Helm charts that wrap glyphs for specific use cases.

## Available Trinkets

### Microspell
Microservice deployment with Istio service mesh and Vault secrets integration.

**Features:**
- Automatic Istio VirtualService generation
- Vault policy and secret management
- Service mesh routing configuration
- Opinionated defaults for microservices

**Location:** `charts/trinkets/microspell/`

**Examples:** `charts/trinkets/microspell/examples/`

### Tarot
Dynamic Argo Workflow generation using card-based configuration.

**Features:**
- Card resolution (registered/selector/inline)
- Multiple execution modes (container/dag/steps/suspend)
- Secret injection (Vault/K8s)
- Position-based dependency resolution
- RBAC generation

**Location:** `charts/trinkets/tarot/`

**Examples:** `charts/trinkets/tarot/examples/`

**Documentation:** [docs/TAROT.md](../../docs/TAROT.md)

### Covenant
Identity and access management combining Keycloak, Vault, and RBAC.

**Features:**
- Keycloak realm and client management
- User and group provisioning
- Vault integration for credentials
- Kubernetes RBAC configuration

**Location:** `charts/trinkets/covenant/`

**Examples:** `charts/trinkets/covenant/examples/`

## Trinket vs Chart

**Chart (e.g., Summon):** Generic, flexible, requires explicit configuration.

**Trinket (e.g., Microspell):** Opinionated wrapper with sensible defaults for specific patterns.

## Usage

Trinkets are used via Librarian ApplicationSets by setting `trinket` field in spell configuration:

```yaml
# Use Microspell
name: my-service
trinket: microspell
repository: https://github.com/org/service
service:
  external: true
infrastructure:
  prolicy:
    enabled: true
```

```yaml
# Use Tarot
name: ci-pipeline
trinket: tarot
tarot:
  executionMode: dag
  reading:
    checkout:
      position: foundation
    build:
      position: action
```

Default trinket (if not specified) is Summon.
