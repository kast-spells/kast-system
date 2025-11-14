# Tarot - Dynamic Workflow Framework

Tarot transforms card-based configurations into Argo Workflow resources. Each workflow step is a "card" with defined positions and dependencies.

## Architecture

```
Tarot Reading YAML
    ↓
Card Resolver (name/selector/inline resolution)
    ↓
Secret Injector (Vault/K8s secrets)
    ↓
Dependency Resolver (position-based + explicit)
    ↓
Workflow Generator (container/dag/steps/suspend modes)
    ↓
Argo Workflow + RBAC Resources
```

## Card Resolution

### Three Resolution Types

1. **Registered Cards** - Pre-defined in global `cards` array
2. **Selector-Based** - Discovered via runic indexer label matching
3. **Inline** - Direct container definition in reading

### Resolution Flow

```
Card Definition Input
    ↓
Has name? → Lookup registered card → Found? → Use card
                                   → Not found → Try implicit selector
    ↓
Has selectors? → Runic indexer query → Label match → Select first match
    ↓
Has container? → Validate spec → Use directly
    ↓
Merge with overrides → Apply parameters → Inject secrets → Resolved card
```

## Execution Modes

### Container Mode
Single-pod execution. Use for simple workflows.

```yaml
tarot:
  executionMode: container
  reading:
    hello-world:
      container:
        image: busybox:latest
        command: ["echo", "Hello"]
```

### DAG Mode
Directed Acyclic Graph with dependencies. Use for complex workflows.

```yaml
tarot:
  executionMode: dag
  reading:
    checkout:
      position: foundation
    build:
      position: action
      depends: [checkout]
    test:
      position: challenge
      depends: [build]
```

### Steps Mode
Sequential execution with parallel support. Tasks in same position run in parallel.

```yaml
tarot:
  executionMode: steps
  reading:
    parallel-test-a:
      position: action
    parallel-test-b:
      position: action
    deploy:
      position: outcome
```

### Suspend Mode
Workflow with approval gates. Requires human intervention.

```yaml
tarot:
  executionMode: suspend
  reading:
    scan:
      position: foundation
    approval:
      container:
        image: approval/gate:latest
      suspend:
        duration: "24h"
        approvers: ["security@company.com"]
      position: challenge
    deploy:
      position: outcome
```

## Card Positions

Positions define execution order and automatic dependencies:

| Position | Auto-Dependencies | Use Case |
|----------|------------------|----------|
| foundation | None | Setup tasks |
| action | All foundation | Main execution |
| challenge | Foundation + action | Testing/validation |
| outcome | All previous | Cleanup/finalization |

## Configuration Reference

### Root Structure

```yaml
name: workflow-name                    # Required

# Global card registry
cards:
  - name: card-name
    container:
      image: image:tag
      command: [...]
    labels:
      key: value

# Global secrets
secrets:
  secret-name:
    type: vault-secret|k8s-secret
    path: vault/path
    keys: [key1, key2]

# Global environment
envs:
  VAR_NAME: value

# Tarot configuration
tarot:
  executionMode: container|dag|steps|suspend
  reading:
    card-name:
      selectors: {}      # Card selection
      container: {}      # Inline definition
      position: foundation|action|challenge|outcome
      depends: []        # Explicit dependencies
      with: {}           # Parameters
      envs: {}           # Card-specific environment
      secrets: {}        # Card-specific secrets

# Workflow settings
workflow:
  serviceAccount: service-account-name
  generateName: true
  arguments:
    parameters:
      - name: param-name
        value: param-value

# RBAC
rbac:
  enabled: true
  serviceAccount:
    name: sa-name
```

### Secret Types

#### Vault Secrets

```yaml
secrets:
  database-creds:
    type: vault-secret
    path: secret/database/production
    keys: [username, password]
    mount: /secrets/db
```

#### Kubernetes Secrets

```yaml
secrets:
  registry-auth:
    type: k8s-secret
    name: docker-registry-secret
    keys: [username, password]
```

### Card-Level Configuration

Cards can define their own secrets and parameters:

```yaml
cards:
  - name: push-image
    labels: {stage: push}
    secrets:
      harbor-creds:
        location: vault
        path: chapter
        keys: [HARBOR_USER, HARBOR_PASSWORD]
    envs:
      REGISTRY_URL: harbor.example.com
    container:
      image: quay.io/buildah/stable
      command: ["buildah", "push"]
```

Reading can override:

```yaml
tarot:
  reading:
    push:
      selectors: {stage: push}
      position: outcome
      envs:
        REGISTRY_URL: registry.company.com  # Override
```

## Dependency Resolution

### Position-Based Dependencies

```yaml
tarot:
  reading:
    setup:
      position: foundation      # No dependencies

    build:
      position: action          # Depends on: setup

    test:
      position: challenge       # Depends on: setup, build

    deploy:
      position: outcome         # Depends on: setup, build, test
```

### Explicit Dependencies

```yaml
tarot:
  reading:
    checkout:
      position: foundation

    build-frontend:
      position: action
      depends: [checkout]       # Only checkout

    build-backend:
      position: action
      depends: [checkout]       # Only checkout

    integration-test:
      position: challenge
      depends: [build-frontend, build-backend]  # Both builds
```

## RBAC Configuration

Tarot generates ServiceAccount, Role, and RoleBinding resources.

### Cluster-Level Permissions

```yaml
clusterRole:
  rules:
    - apiGroups: [argoproj.io]
      resources: [clusterworkflowtemplates]
      verbs: [get, list, watch]
    - apiGroups: [""]
      resources: [nodes]
      verbs: [get, list]
```

### Namespace-Level Permissions

```yaml
role:
  rules:
    - apiGroups: [argoproj.io]
      resources: [workflows]
      verbs: [get, list, watch, create, update, patch, delete]
    - apiGroups: [""]
      resources: [pods, secrets, persistentvolumeclaims, services]
      verbs: [get, list, watch, create, update, patch, delete]
```

### Vault Integration

```yaml
rbac:
  serviceAccount:
    annotations:
      vault.hashicorp.com/role: tarot-vault-role
```

## Examples

### Simple Container

```yaml
name: hello-tarot
tarot:
  executionMode: container
  reading:
    hello:
      container:
        image: busybox:latest
        command: ["echo", "Hello from Tarot"]
```

### CI/CD Pipeline

```yaml
name: ci-pipeline
secrets:
  github-token:
    type: vault-secret
    path: secret/github/ci
    keys: [token]

tarot:
  executionMode: dag
  reading:
    checkout:
      container:
        image: alpine/git:latest
        command: ["git", "clone", "https://github.com/org/repo.git"]
      position: foundation

    test:
      container:
        image: node:16
        command: ["npm", "test"]
      position: action
      depends: [checkout]

    build:
      container:
        image: quay.io/buildah/stable
        command: ["buildah", "bud", "-t", "app:latest", "."]
      position: action
      depends: [test]
```

### ML Pipeline with GPU

```yaml
name: ml-training
tarot:
  executionMode: dag
  reading:
    prepare-data:
      container:
        image: python:3.9
        command: ["python", "prepare.py"]
        resources:
          requests: {memory: 8Gi, cpu: 4}
      position: foundation

    train-model:
      container:
        image: pytorch/pytorch:latest
        command: ["python", "train.py"]
        resources:
          requests: {nvidia.com/gpu: 2, memory: 32Gi}
          limits: {nvidia.com/gpu: 2, memory: 32Gi}
      position: action
      depends: [prepare-data]
      nodeSelector:
        gpu: "true"
```

## Troubleshooting

### Card Resolution Failures

**Error**: `Card 'card-name' not found`

**Solutions**:
1. Register card globally in `cards` array
2. Use `selectors` instead of name
3. Define inline with `container`

### Template Rendering Errors

**Error**: `YAML parse error`

**Check**:
1. Indentation (spaces, not tabs)
2. Quoted strings with special characters
3. Valid YAML structure

**Debug**:
```bash
helm template test charts/trinkets/tarot -f config.yaml --debug
```

### Secret Access Issues

**Error**: `secrets forbidden`

**Solutions**:
1. Enable RBAC: `rbac.enabled: true`
2. Configure Vault annotations on ServiceAccount
3. Verify secret type: `vault-secret` not `vault`

### Dependency Cycles

**Error**: `dependency cycle detected`

**Solution**: Review dependency chain, use positions to avoid explicit dependencies where possible.

### Pods Pending

**Error**: `Insufficient resources`

**Solutions**:
1. Reduce resource requests
2. Add node selectors for specific node pools
3. Check cluster capacity

**Debug**:
```bash
kubectl describe pod <pod-name>
kubectl describe nodes
```

## Testing

```bash
# Render template
helm template test charts/trinkets/tarot -f examples/minimal-test.yaml

# Validate syntax
helm lint charts/trinkets/tarot

# Run comprehensive tests
make test-tarot

# Test specific example
helm template test charts/trinkets/tarot -f examples/simple-dag-test.yaml
```

## Template Functions

With `goTemplate: true` (Argo Workflows default):

```yaml
# String manipulation
name: '{{.app | lower}}'
name: '{{.app | replace "_" "-"}}'

# Conditionals
{{- if eq .environment "production" }}
replicas: 5
{{- else }}
replicas: 1
{{- end }}

# Defaults
namespace: '{{.namespace | default "default"}}'
```

## File Locations

- Templates: `charts/trinkets/tarot/templates/`
- Examples: `charts/trinkets/tarot/examples/`
- Values: `charts/trinkets/tarot/values.yaml`

## References

- [Argo Workflows Documentation](https://argoproj.github.io/argo-workflows/)
- [Helm Documentation](https://helm.sh/docs/)
- [Kast System Architecture](../README.md)
