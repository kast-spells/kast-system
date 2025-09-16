# Tarot System API Reference

Complete reference for all configuration options in the Tarot system.

## Configuration Schema

### Root Configuration

```yaml
# String: Unique identifier for the workflow
name: string

# Array: Global card registry
cards: []Card

# Object: Global secret definitions  
secrets: map[string]Secret

# Object: Global environment variables
envs: map[string]string

# Object: Tarot workflow configuration
tarot: TarotConfig

# Object: Workflow-specific settings
workflow: WorkflowConfig

# Object: Resource limits and requests
resources: ResourceConfig

# Object: Node selection criteria
nodeSelector: map[string]string

# Array: Node tolerations
tolerations: []Toleration

# Object: Pod affinity/anti-affinity
affinity: Affinity

# Object: Security context
securityContext: SecurityContext

# Object: RBAC configuration
rbac: RBACConfig
```

## Type Definitions

### Card

Represents a workflow task definition.

```yaml
Card:
  # String: Unique card identifier
  name: string

  # String: Card category/type (optional)
  type: string

  # Object: Container specification
  container: Container

  # Object: Script specification (alternative to container)
  script: Script

  # Object: Suspend specification (alternative to container)
  suspend: Suspend

  # Object: Resource specification (alternative to container) 
  resource: Resource

  # Object: Selection labels for runic indexer
  labels: map[string]string

  # Array: Volume definitions
  volumes: []Volume

  # Object: Environment variables
  envs: map[string]string

  # Object: Secrets configuration
  secrets: map[string]Secret
```

**Example:**
```yaml
cards:
  - name: git-clone
    type: scm
    labels:
      scm: git
      operation: clone
      default: cluster
    container:
      image: alpine/git:latest
      command: ["git"]
      args: ["clone"]
    envs:
      GIT_SSL_NO_VERIFY: "false"
```

### Container

Container execution specification.

```yaml
Container:
  # String: Container image (required)
  image: string

  # Array[string]: Container command
  command: []string

  # Array[string]: Container arguments
  args: []string

  # String: Working directory
  workingDir: string

  # Array: Environment variables
  env: []EnvVar

  # Array: Volume mounts
  volumeMounts: []VolumeMount

  # Object: Resource requirements
  resources: ResourceRequirements

  # Object: Security context
  securityContext: SecurityContext

  # Array: Ports to expose
  ports: []ContainerPort
```

**Example:**
```yaml
container:
  image: node:16-alpine
  command: ["npm"]
  args: ["test"]
  workingDir: /app
  resources:
    requests:
      memory: "512Mi"
      cpu: "250m"
    limits:
      memory: "1Gi" 
      cpu: "500m"
```

### Secret

Secret definition and configuration.

```yaml
Secret:
  # String: Secret type (required)
  type: "vault-secret" | "k8s-secret"

  # String: Vault path (for vault-secret type)
  path: string

  # String: Vault role (for vault-secret type)
  role: string

  # String: K8s secret name (for k8s-secret type)
  name: string

  # Array[string]: Secret keys to extract
  keys: []string

  # String: Volume mount path (optional)
  mount: string

  # Integer: Default file mode (optional)
  defaultMode: integer
```

**Examples:**
```yaml
# Vault secret
secrets:
  database-creds:
    type: vault-secret
    path: "secret/database/production"
    role: "tarot-runner"
    keys: ["username", "password", "connection_string"]
    mount: "/secrets/db"
    defaultMode: 0600

# Kubernetes secret
secrets:
  tls-cert:
    type: k8s-secret
    name: app-tls-certificate
    keys: ["tls.crt", "tls.key"]
    mount: "/certs"
```

### TarotConfig

Main Tarot system configuration.

```yaml
TarotConfig:
  # String: Workflow execution mode (required)
  executionMode: "container" | "dag" | "steps" | "suspend"

  # Object: Card reading (workflow definition)
  reading: map[string]CardReading

  # String: Cluster template reference (alternative to reading)
  template: string

  # Object: Template parameters (used with template)
  parameters: map[string]any
```

**Example:**
```yaml
tarot:
  executionMode: dag
  reading:
    checkout:
      selectors:
        scm: git
      position: foundation
    
    build:
      container:
        image: maven:3.8
        command: ["mvn", "clean", "package"]
      position: action
      depends: [checkout]
```

### CardReading

Individual card configuration within a reading.

```yaml
CardReading:
  # Object: Card selectors for runic indexer
  selectors: map[string]string

  # Object: Inline container definition
  container: Container

  # Object: Inline script definition  
  script: Script

  # Object: Inline suspend definition
  suspend: Suspend

  # Object: Inline resource definition
  resource: Resource

  # String: Card position in workflow
  position: "foundation" | "action" | "challenge" | "outcome"

  # Array[string]: Explicit dependencies
  depends: []string

  # Object: Parameter overrides
  with: map[string]any

  # Object: Card-specific environment variables
  envs: map[string]string

  # Object: Card-specific secrets
  secrets: map[string]Secret

  # Array: Card-specific volumes
  volumes: []Volume

  # Integer: Parallel execution limit
  parallelism: integer

  # Object: Node selection
  nodeSelector: map[string]string

  # Array: Tolerations
  tolerations: []Toleration

  # Object: Affinity rules
  affinity: Affinity
```

**Example:**
```yaml
tarot:
  reading:
    ml-training:
      container:
        image: tensorflow/tensorflow:2.8-gpu
        command: ["python", "train.py"]
        resources:
          requests:
            nvidia.com/gpu: "2"
          limits:
            nvidia.com/gpu: "2"
      position: action
      depends: [data-preparation]
      with:
        epochs: 100
        batch_size: 32
      nodeSelector:
        gpu-type: "v100"
      tolerations:
        - key: "gpu"
          operator: "Equal"
          value: "dedicated"
          effect: "NoSchedule"
```

### WorkflowConfig

Argo Workflow-specific configuration.

```yaml
WorkflowConfig:
  # String: Service account name
  serviceAccount: string

  # Boolean: Generate unique names
  generateName: boolean

  # Object: Workflow arguments
  arguments: Arguments

  # Object: Workflow labels
  labels: map[string]string

  # Object: Workflow annotations
  annotations: map[string]string

  # Integer: Active deadline in seconds
  activeDeadlineSeconds: integer

  # Object: Pod GC settings
  podGC: PodGC

  # String: Priority class
  priorityClassName: string

  # Object: Metadata
  metadata: Metadata
```

**Example:**
```yaml
workflow:
  serviceAccount: production-deployer
  generateName: true
  arguments:
    parameters:
      - name: environment
        value: "production"
      - name: version
        value: "v1.2.3"
  labels:
    environment: "production"
    team: "platform"
  annotations:
    change-request: "CHG-2024-001"
  activeDeadlineSeconds: 3600
```

### RBACConfig

Role-based access control configuration.

```yaml
RBACConfig:
  # Boolean: Enable RBAC resource creation
  enabled: boolean

  # Object: Service account configuration
  serviceAccount: ServiceAccount

  # Object: Cluster role configuration
  clusterRole: ClusterRole

  # Object: Role configuration
  role: Role

  # Array: Additional cluster roles
  additionalClusterRoles: []string

  # Array: Additional roles
  additionalRoles: []string
```

**Example:**
```yaml
rbac:
  enabled: true
  serviceAccount:
    name: tarot-enterprise
    annotations:
      vault.hashicorp.com/role: "enterprise-secrets"
      iam.gke.io/gcp-service-account: "tarot@project.iam.gserviceaccount.com"
  additionalClusterRoles:
    - "cluster-admin"  # Only for development
  additionalRoles:
    - "namespace-admin"
```

## Execution Modes

### Container Mode

Single container execution.

```yaml
tarot:
  executionMode: container
  reading:
    single-task:
      container:
        image: busybox:latest
        command: ["echo", "hello world"]
```

**Generated Workflow Structure:**
```yaml
spec:
  templates:
    - name: main
      container:
        image: busybox:latest
        command: ["echo", "hello world"]
```

### DAG Mode

Directed Acyclic Graph execution with dependencies.

```yaml
tarot:
  executionMode: dag
  reading:
    task-a:
      position: foundation
    task-b:
      position: action
      depends: [task-a]
    task-c:
      position: action  
      depends: [task-a]
    task-d:
      position: challenge
      depends: [task-b, task-c]
```

**Generated Workflow Structure:**
```yaml
spec:
  templates:
    - name: main
      dag:
        tasks:
          - name: task-a
            template: task-a
          - name: task-b
            template: task-b
            dependencies: [task-a]
          - name: task-c
            template: task-c
            dependencies: [task-a]
          - name: task-d
            template: task-d
            dependencies: [task-b, task-c]
```

### Steps Mode

Sequential step execution with parallel support.

```yaml
tarot:
  executionMode: steps
  reading:
    foundation-task:
      position: foundation
    parallel-task-a:
      position: action
    parallel-task-b:
      position: action
    final-task:
      position: outcome
```

**Generated Workflow Structure:**
```yaml
spec:
  templates:
    - name: main
      steps:
        - - name: foundation-task
            template: foundation-task
        - - name: parallel-task-a
            template: parallel-task-a
          - name: parallel-task-b
            template: parallel-task-b
        - - name: final-task
            template: final-task
```

### Suspend Mode

Workflow with approval gates and human intervention.

```yaml
tarot:
  executionMode: suspend
  reading:
    automated-task:
      container:
        image: automation:latest
      position: foundation
    
    approval-gate:
      container:
        image: approval/gate:latest
      suspend:
        duration: "24h"
        approvers: ["security@company.com"]
        message: "Approval required for production deployment"
      position: challenge
      depends: [automated-task]
    
    deployment:
      container:
        image: deploy:latest
      position: outcome
      depends: [approval-gate]
```

## Parameter Resolution

The Tarot system supports parameter resolution using a template syntax:

### Syntax

| Pattern | Description | Example |
|---------|-------------|---------|
| `{{workflow.parameters.name}}` | Workflow parameter | `{{workflow.parameters.environment}}` |
| `{{envs.VAR_NAME}}` | Environment variable | `{{envs.REGISTRY_URL}}` |
| `{{secrets.secret-name.key}}` | Secret value | `{{secrets.db-creds.username}}` |
| `{{workflow.creationTimestamp}}` | Workflow metadata | `{{workflow.creationTimestamp}}` |

### Example Usage

```yaml
envs:
  REGISTRY_URL: "registry.company.com"
  
secrets:
  database:
    type: vault-secret
    path: "secret/database"
    keys: ["username", "password"]

workflow:
  arguments:
    parameters:
      - name: image_tag
        value: "v1.0.0"

tarot:
  reading:
    deploy:
      container:
        image: "{{envs.REGISTRY_URL}}/app:{{workflow.parameters.image_tag}}"
        env:
          - name: DB_USERNAME
            value: "{{secrets.database.username}}"
          - name: DB_PASSWORD
            value: "{{secrets.database.password}}"
```

## Validation Rules

### Required Fields

1. **Root level:**
   - `name`: Workflow identifier
   - `tarot`: Tarot configuration

2. **Tarot level:**
   - `executionMode`: Must be one of: container, dag, steps, suspend
   - `reading` OR `template`: Either custom reading or template reference

3. **Card reading level:**
   - At least one of: `container`, `selectors`, or card name resolution
   - `position`: Required for DAG/steps modes

### Field Constraints

```yaml
# String length limits
name: 1-253 characters, DNS-1123 subdomain format

# Execution mode values
executionMode: ["container", "dag", "steps", "suspend"]

# Position values
position: ["foundation", "action", "challenge", "outcome"]

# Secret type values  
secrets.*.type: ["vault-secret", "k8s-secret"]

# Resource quantity format
resources.*.cpu: "100m", "0.5", "2"
resources.*.memory: "128Mi", "1Gi", "2G"
resources.*.storage: "1Gi", "10G", "100Ti"
```

### Common Validation Errors

```yaml
# ❌ Invalid execution mode
tarot:
  executionMode: "workflow"  # Should be: container|dag|steps|suspend

# ❌ Missing card definition
tarot:
  reading:
    undefined-card:
      position: foundation     # No container, selectors, or registered card

# ❌ Circular dependency
tarot:
  reading:
    task-a:
      depends: [task-b]
    task-b:
      depends: [task-a]

# ❌ Invalid secret type
secrets:
  my-secret:
    type: "hashicorp-vault"    # Should be: vault-secret

# ❌ Invalid resource format
resources:
  limits:
    memory: "1GB"              # Should be: "1Gi" (binary) or "1G" (decimal)
```

## Template Functions

### Available Functions

```yaml
# String manipulation
{{ "hello" | upper }}                    # HELLO
{{ "WORLD" | lower }}                    # world
{{ "  text  " | trim }}                  # text

# Encoding
{{ "value" | b64enc }}                   # dmFsdWU=
{{ "dmFsdWU=" | b64dec }}                # value

# JSON/YAML
{{ .Values | toJson }}                   # JSON string
{{ .Values | toYaml }}                   # YAML string
{{ "{'key': 'value'}" | fromJson }}      # Parsed object

# Conditionals
{{ if eq .Values.env "prod" }}production{{ else }}development{{ end }}

# Default values
{{ .Values.optional | default "default-value" }}
```

### Custom Tarot Functions

```yaml
# Value resolution (supports parameter templates)
{{ include "tarot.resolveValue" (list . "{{envs.MY_VAR}}") }}

# Secret name generation
{{ include "tarot.getSecretName" (list . $secretDef) }}

# Card resolution
{{ include "tarot.resolveCard" (list . $cardName $cardDef) }}
```

## Best Practices

### Configuration Organization

```yaml
# Group related configuration
name: my-workflow

# Global definitions first
envs: &global-envs
  LOG_LEVEL: info
  APP_ENV: production

secrets: &global-secrets
  registry:
    type: vault-secret
    path: "secret/registry"

cards: &global-cards
  - name: standard-git-clone
    # ... definition

# Tarot configuration
tarot:
  executionMode: dag
  reading:
    # Reference shared configs
    checkout:
      selectors: {name: standard-git-clone}
```

### Security Guidelines

```yaml
# Always enable RBAC in production
rbac:
  enabled: true

# Use least-privilege service accounts
workflow:
  serviceAccount: limited-access-sa

# Prefer Vault over K8s secrets for sensitive data
secrets:
  sensitive-data:
    type: vault-secret      # Preferred
    path: "secret/app/prod"

# Set resource limits
resources:
  limits:
    memory: "2Gi"
    cpu: "1"
  requests:
    memory: "1Gi"  
    cpu: "500m"

# Use security contexts
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 2000
```

### Performance Optimization

```yaml
# Use specific selectors
tarot:
  reading:
    my-task:
      selectors:
        name: exact-card-name     # Faster than generic selectors

# Minimize dependencies
tarot:
  reading:
    parallel-task-a:
      position: action           # Use positions instead of explicit depends
    parallel-task-b:
      position: action           # when possible

# Set appropriate resource requests
resources:
  requests:
    memory: "256Mi"              # Request what you need
    cpu: "100m"
```

---

*This API reference provides complete documentation for configuring the Tarot system. For practical examples, see the [examples/](./examples/) directory.*