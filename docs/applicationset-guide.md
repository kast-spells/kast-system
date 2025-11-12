# ArgoCD ApplicationSet Complete Guide for Kast System

**Last Updated:** October 2025
**ArgoCD Version:** 2.12+
**ApplicationSet Controller:** Built-in

---

## Table of Contents

1. [Introduction](#introduction)
2. [How ApplicationSets Work](#how-applicationsets-work)
3. [Available Generators](#available-generators)
4. [Template Variables Reference](#template-variables-reference)
5. [Multi-Source Applications](#multi-source-applications)
6. [Kast System Integration Examples](#kast-system-integration-examples)
7. [Advanced Patterns](#advanced-patterns)
8. [Troubleshooting](#troubleshooting)

---

## Introduction

ApplicationSets provide a declarative way to automatically generate ArgoCD Applications based on various inputs. Instead of manually creating dozens of Application manifests, you define a template and a generator that creates Applications dynamically.

### Why Use ApplicationSets?

- **DRY Principle**: Define once, deploy everywhere
- **Automatic Discovery**: New environments/clusters automatically get applications
- **Consistency**: All generated applications follow the same pattern
- **GitOps Native**: Fully declarative and version controlled

### Current Implementation in Kast System

**Location:** `bookrack/the-yaml-life/intro/staging-appset.yaml`

**Purpose:** Automatically creates summon-based Applications for every YAML file in the `staging/` chapter directory.

---

## How ApplicationSets Work

```
┌─────────────────────┐
│   ApplicationSet    │
│   ┌─────────────┐   │
│   │ Generator   │──────> Discovers files/clusters/configs
│   └─────────────┘   │
│         │           │
│         ▼           │
│   ┌─────────────┐   │
│   │  Template   │──────> Generates Applications with parameters
│   └─────────────┘   │
└─────────────────────┘
         │
         ▼
┌──────────────────────────────────────┐
│  Generated Applications              │
│  - staging-conduwuit                 │
│  - staging-element                   │
│  - staging-liminal-space             │
│  - staging-namen-mautrix-telegram    │
└──────────────────────────────────────┘
```

### Basic Structure

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: my-applicationset
  namespace: argocd
spec:
  goTemplate: true  # Use Go templating (recommended in 2025)
  generators:
    - <generator-config>
  template:
    metadata:
      name: '{{.name}}'
    spec:
      project: default
      source: <source-config>
      destination: <destination-config>
```

---

## Available Generators

### 1. Git Files Generator

**Use Case:** Generate Applications based on YAML/JSON files in a Git repository.

**How It Works:**
1. Scans Git repository for files matching path pattern
2. Parses each file and extracts key-value pairs
3. Makes those values available as template variables

#### Path Variables

When a file is discovered, these variables are automatically available:

| Variable | Description | Example |
|----------|-------------|---------|
| `{{path.path}}` | Directory path to file | `bookrack/the-yaml-life/staging` |
| `{{path.basename}}` | Last directory name | `staging` |
| `{{path.filename}}` | Filename without extension | `conduwuit` |
| `{{path.basenameNormalized}}` | Basename with chars normalized | `staging` |
| `{{path[0]}}` | First path segment | `bookrack` |
| `{{path[1]}}` | Second path segment | `the-yaml-life` |
| `{{path[2]}}` | Third path segment | `staging` |

**⚠️ IMPORTANT:** `{{path}}` returns an **object**, not a string! Always use `{{path.path}}` for the string value.

#### File Content Variables

All key-value pairs from the YAML/JSON file are available as variables.

**Example file:** `bookrack/the-yaml-life/staging/conduwuit.yaml`
```yaml
name: conduwuit
namespace: matrix
image:
  repository: girlbossceo/conduwuit
  tag: latest
replicas: 2
```

**Available variables:**
- `{{.name}}` → `conduwuit`
- `{{.namespace}}` → `matrix`
- `{{.image.repository}}` → `girlbossceo/conduwuit`
- `{{.image.tag}}` → `latest`
- `{{.replicas}}` → `2`

#### Complete Example

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: staging-apps
  namespace: argocd
spec:
  goTemplate: true
  generators:
    - git:
        repoURL: git@github.com:the-yaml-life/proto-the-yaml-life.git
        revision: main
        files:
          - path: "bookrack/the-yaml-life/staging/*.yaml"
  template:
    metadata:
      name: 'staging-{{.path.filename}}'
      labels:
        chapter: '{{.path.basename}}'
        app: '{{.name}}'
    spec:
      project: default
      source:
        repoURL: https://github.com/kast-spells/kast-system.git
        path: charts/summon
        targetRevision: main
        helm:
          values: |
            name: {{.name}}
            namespace: {{.namespace}}
            replicas: {{.replicas}}
      destination:
        server: https://kubernetes.default.svc
        namespace: '{{.namespace}}'
```

---

### 2. Git Directory Generator

**Use Case:** Generate Applications based on directory structure (one app per directory).

**How It Works:**
1. Scans repository for directories matching pattern
2. Each directory becomes an Application
3. Optionally reads metadata from files in each directory

#### Variables Available

| Variable | Description | Example |
|----------|-------------|---------|
| `{{path.path}}` | Full path to directory | `apps/production/api` |
| `{{path.basename}}` | Directory name | `api` |
| `{{path[0]}}` | First segment | `apps` |
| `{{path[1]}}` | Second segment | `production` |

#### Example: Helm Charts Discovery

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: helm-charts-discovery
spec:
  goTemplate: true
  generators:
    - git:
        repoURL: https://github.com/kast-spells/kast-system.git
        revision: main
        directories:
          - path: charts/*
          - path: charts/trinkets/*
  template:
    metadata:
      name: 'chart-{{.path.basename}}'
    spec:
      project: default
      source:
        repoURL: https://github.com/kast-spells/kast-system.git
        path: '{{.path.path}}'
        targetRevision: main
      destination:
        server: https://kubernetes.default.svc
        namespace: '{{.path.basename}}'
```

**This would generate:**
- `chart-summon` from `charts/summon/`
- `chart-kaster` from `charts/kaster/`
- `chart-microspell` from `charts/trinkets/microspell/`
- `chart-tarot` from `charts/trinkets/tarot/`

---

### 3. List Generator

**Use Case:** Generate Applications from a static list defined in the ApplicationSet.

**When to Use:**
- Small, stable set of environments
- Testing ApplicationSet patterns
- Environments that rarely change

#### Example: Environment List

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: guestbook-envs
spec:
  goTemplate: true
  generators:
    - list:
        elements:
          - cluster: dev
            url: https://kubernetes.default.svc
            namespace: dev
          - cluster: staging
            url: https://staging.k8s.example.com
            namespace: staging
          - cluster: production
            url: https://production.k8s.example.com
            namespace: production
  template:
    metadata:
      name: 'guestbook-{{.cluster}}'
    spec:
      project: default
      source:
        repoURL: https://github.com/kast-spells/kast-system.git
        path: charts/summon
        targetRevision: main
        helm:
          values: |
            environment: {{.cluster}}
      destination:
        server: '{{.url}}'
        namespace: '{{.namespace}}'
```

---

### 4. Cluster Generator

**Use Case:** Generate Applications for all clusters registered in ArgoCD.

**Requirements:**
- Clusters must be pre-registered in ArgoCD
- Can filter by labels

#### Example: Deploy to All Clusters

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: monitoring-all-clusters
spec:
  goTemplate: true
  generators:
    - clusters:
        selector:
          matchLabels:
            monitoring: enabled
  template:
    metadata:
      name: 'monitoring-{{.name}}'
    spec:
      project: default
      source:
        repoURL: https://github.com/prometheus-community/helm-charts.git
        path: charts/kube-prometheus-stack
        targetRevision: main
      destination:
        server: '{{.server}}'
        namespace: monitoring
```

**Available Variables:**
- `{{.name}}` - Cluster name
- `{{.server}}` - Cluster API URL
- `{{.metadata.labels.<key>}}` - Cluster labels
- `{{.metadata.annotations.<key>}}` - Cluster annotations

---

### 5. Matrix Generator

**Use Case:** Combine multiple generators (cartesian product).

**Example:** Deploy multiple apps to multiple clusters

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: matrix-apps-clusters
spec:
  goTemplate: true
  generators:
    - matrix:
        generators:
          # Generator 1: List of apps
          - list:
              elements:
                - app: api
                  port: 8080
                - app: worker
                  port: 8081
          # Generator 2: List of environments
          - list:
              elements:
                - env: dev
                  replicas: 1
                - env: prod
                  replicas: 3
  template:
    metadata:
      name: '{{.app}}-{{.env}}'
    spec:
      project: default
      source:
        repoURL: https://github.com/kast-spells/kast-system.git
        path: charts/summon
        targetRevision: main
        helm:
          values: |
            name: {{.app}}
            service:
              port: {{.port}}
            replicas: {{.replicas}}
      destination:
        server: https://kubernetes.default.svc
        namespace: '{{.env}}'
```

**Generates:**
- `api-dev` (port: 8080, replicas: 1)
- `api-prod` (port: 8080, replicas: 3)
- `worker-dev` (port: 8081, replicas: 1)
- `worker-prod` (port: 8081, replicas: 3)

---

### 6. Merge Generator

**Use Case:** Merge parameters from multiple generators (same keys get combined).

**Example:** Combine cluster info with app config

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: merge-example
spec:
  goTemplate: true
  generators:
    - merge:
        mergeKeys:
          - cluster
        generators:
          # Base cluster info
          - list:
              elements:
                - cluster: dev
                  url: https://dev.k8s.local
          # App-specific overrides
          - list:
              elements:
                - cluster: dev
                  namespace: custom-namespace
                  replicas: 5
  template:
    metadata:
      name: 'app-{{.cluster}}'
    spec:
      destination:
        server: '{{.url}}'
        namespace: '{{.namespace}}'
```

---

## Template Variables Reference

### Standard Variables (All Generators)

```yaml
metadata:
  name: 'app-{{.name}}'           # From file/config
  namespace: argocd
  labels:
    env: '{{.environment}}'        # Custom variable
  annotations:
    description: '{{.description}}' # From file content
```

### Go Template Functions

With `goTemplate: true`, you can use Go template functions:

```yaml
# String manipulation
name: '{{.app | lower}}'                    # Lowercase
name: '{{.app | upper}}'                    # Uppercase
name: '{{.app | replace "_" "-"}}'          # Replace characters

# Conditionals
{{- if eq .environment "production" }}
replicas: 5
{{- else }}
replicas: 1
{{- end }}

# Defaults
namespace: '{{.namespace | default "default"}}'

# Index access
region: '{{index .path.segments 2}}'
```

---

## Multi-Source Applications

### The `$values` Reference Pattern

When using multiple sources, you can reference files from one source in another using the `$values` variable.

#### Setup Requirements

1. **Source with `ref`**: One source must have a `ref` field
2. **Path Resolution**: `$values` always refers to the **root** of the referenced repository
3. **Syntax**: `$values/<path-from-root>`

#### Current Kast System Implementation

**File:** `bookrack/the-yaml-life/intro/staging-appset.yaml`

```yaml
spec:
  sources:
    # Source 1: Helm chart
    - repoURL: https://github.com/kast-spells/kast-system.git
      path: charts/summon
      targetRevision: feature/coding-standards
      helm:
        valueFiles:
          - $values/{{path.path}}/{{path.filename}}.yaml

    # Source 2: Values repository
    - repoURL: git@github.com:the-yaml-life/proto-the-yaml-life.git
      targetRevision: main
      ref: values  # This creates the $values variable
```

**⚠️ CRITICAL FIX NEEDED:**

Currently we have:
```yaml
valueFiles:
  - $values/{{path}}  # ❌ WRONG - {{path}} is an object
```

Should be:
```yaml
valueFiles:
  - $values/{{path.path}}/{{path.filename}}.yaml  # ✅ CORRECT
```

#### How It Works

1. File discovered: `bookrack/the-yaml-life/staging/conduwuit.yaml`
2. Variables generated:
   - `{{path.path}}` = `bookrack/the-yaml-life/staging`
   - `{{path.filename}}` = `conduwuit`
3. ValueFile resolves to: `$values/bookrack/the-yaml-life/staging/conduwuit.yaml`
4. ArgoCD fetches that file from the `values` ref repository

---

## Kast System Integration Examples

### Example 1: Current Implementation (Staging Chapter)

**Purpose:** Auto-deploy all YAML files in staging chapter as summon applications.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: staging-summon-instances
  namespace: argocd
spec:
  goTemplate: true
  generators:
    - git:
        repoURL: git@github.com:the-yaml-life/proto-the-yaml-life.git
        revision: main
        files:
          - path: "bookrack/the-yaml-life/staging/*.yaml"

  template:
    metadata:
      name: 'staging-{{.path.filename}}'
      namespace: argocd
      labels:
        app.kubernetes.io/managed-by: applicationset
        book: the-yaml-life
        chapter: staging
      annotations:
        argocd.argoproj.io/sync-wave: "20"

    spec:
      project: default

      sources:
        # Summon chart
        - repoURL: https://github.com/kast-spells/kast-system.git
          path: charts/summon
          targetRevision: feature/coding-standards
          helm:
            valueFiles:
              - $values/{{.path.path}}/{{.path.filename}}.yaml

        # Values from proto-the-yaml-life
        - repoURL: git@github.com:the-yaml-life/proto-the-yaml-life.git
          targetRevision: main
          ref: values

      destination:
        server: https://kubernetes.default.svc
        namespace: staging

      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - CreateNamespace=true
          - ServerSideApply=true
```

**Generates Applications:**
- `staging-conduwuit` → uses `bookrack/the-yaml-life/staging/conduwuit.yaml`
- `staging-element` → uses `bookrack/the-yaml-life/staging/element.yaml`
- `staging-liminal-space` → uses `bookrack/the-yaml-life/staging/liminal-space.yaml`
- `staging-namen-mautrix-telegram` → uses `bookrack/the-yaml-life/staging/namen-mautrix-telegram.yaml`

---

### Example 2: All Chapters Auto-Discovery

**Purpose:** Generate ApplicationSets for ALL chapters automatically.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: all-chapters-summon
  namespace: argocd
spec:
  goTemplate: true
  generators:
    - git:
        repoURL: git@github.com:the-yaml-life/proto-the-yaml-life.git
        revision: main
        files:
          - path: "bookrack/the-yaml-life/*/*.yaml"

  template:
    metadata:
      name: '{{.path.basename}}-{{.path.filename}}'
      labels:
        book: the-yaml-life
        chapter: '{{.path.basename}}'

    spec:
      project: default

      sources:
        - repoURL: https://github.com/kast-spells/kast-system.git
          path: charts/summon
          targetRevision: main
          helm:
            valueFiles:
              - $values/{{.path.path}}/{{.path.filename}}.yaml

        - repoURL: git@github.com:the-yaml-life/proto-the-yaml-life.git
          targetRevision: main
          ref: values

      destination:
        server: https://kubernetes.default.svc
        namespace: '{{.namespace | default .path.basename}}'
```

**Generates:**
- `intro-argocd` from `intro/argocd.yaml`
- `intro-vault` from `intro/vault.yaml`
- `staging-conduwuit` from `staging/conduwuit.yaml`
- `admintools-stalwart` from `admintools/stalwart.yaml`
- etc.

---

### Example 3: Multi-Trinket Discovery

**Purpose:** Deploy different trinkets based on file metadata.

**File:** `bookrack/the-yaml-life/workflows/some-tarot.yaml`
```yaml
name: some-workflow
trinket: tarot
tarot:
  workflows:
    - name: build
      steps:
        - name: checkout
```

**ApplicationSet:**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: multi-trinket-discovery
spec:
  goTemplate: true
  generators:
    - git:
        repoURL: git@github.com:the-yaml-life/proto-the-yaml-life.git
        revision: main
        files:
          - path: "bookrack/the-yaml-life/**/*.yaml"

  template:
    metadata:
      name: '{{.name}}'
      labels:
        trinket: '{{.trinket | default "summon"}}'

    spec:
      project: default

      sources:
        # Dynamically select trinket chart
        - repoURL: https://github.com/kast-spells/kast-system.git
          path: 'charts/trinkets/{{.trinket | default "summon"}}'
          targetRevision: main
          helm:
            valueFiles:
              - $values/{{.path.path}}/{{.path.filename}}.yaml

        - repoURL: git@github.com:the-yaml-life/proto-the-yaml-life.git
          targetRevision: main
          ref: values

      destination:
        server: https://kubernetes.default.svc
        namespace: '{{.namespace | default "default"}}'
```

---

### Example 4: Glyph-Based ApplicationSets

**Purpose:** Deploy applications with kaster for glyph processing.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: glyph-apps
spec:
  goTemplate: true
  generators:
    - git:
        repoURL: git@github.com:the-yaml-life/proto-the-yaml-life.git
        revision: main
        files:
          - path: "bookrack/the-yaml-life/*/glyph-*.yaml"

  template:
    metadata:
      name: '{{.path.basename}}-{{.path.filename}}'

    spec:
      project: default

      sources:
        # Summon for workload (if any)
        - repoURL: https://github.com/kast-spells/kast-system.git
          path: charts/summon
          targetRevision: main
          helm:
            valueFiles:
              - $values/{{.path.path}}/{{.path.filename}}.yaml

        # Kaster for glyphs
        - repoURL: https://github.com/kast-spells/kast-system.git
          path: charts/kaster
          targetRevision: main
          helm:
            valueFiles:
              - $values/{{.path.path}}/{{.path.filename}}.yaml

        - repoURL: git@github.com:the-yaml-life/proto-the-yaml-life.git
          targetRevision: main
          ref: values

      destination:
        server: https://kubernetes.default.svc
        namespace: '{{.namespace}}'
```

---

### Example 5: Matrix Generator for Multi-Environment

**Purpose:** Deploy the same apps to dev/staging/prod with different configs.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: matrix-multi-env
spec:
  goTemplate: true
  generators:
    - matrix:
        generators:
          # Apps to deploy
          - git:
              repoURL: git@github.com:the-yaml-life/proto-the-yaml-life.git
              revision: main
              files:
                - path: "apps/base/*.yaml"

          # Environments
          - list:
              elements:
                - env: dev
                  namespace: dev
                  replicas: 1
                - env: staging
                  namespace: staging
                  replicas: 2
                - env: production
                  namespace: production
                  replicas: 5

  template:
    metadata:
      name: '{{.path.filename}}-{{.env}}'
      labels:
        app: '{{.name}}'
        environment: '{{.env}}'

    spec:
      project: default

      sources:
        - repoURL: https://github.com/kast-spells/kast-system.git
          path: charts/summon
          targetRevision: main
          helm:
            valueFiles:
              - $values/apps/base/{{.path.filename}}.yaml
              - $values/apps/envs/{{.env}}.yaml

        - repoURL: git@github.com:the-yaml-life/proto-the-yaml-life.git
          targetRevision: main
          ref: values

      destination:
        server: https://kubernetes.default.svc
        namespace: '{{.namespace}}'
```

---

## Advanced Patterns

### Pattern 1: Conditional Glyph Inclusion

```yaml
helm:
  values: |
    {{- if .glyphs }}
    glyphs:
      {{- toYaml .glyphs | nindent 6 }}
    {{- end }}

    {{- if .vault }}
    vault:
      {{- toYaml .vault | nindent 6 }}
    {{- end }}
```

### Pattern 2: Environment-Specific Overrides

**File structure:**
```
bookrack/the-yaml-life/
├── base/
│   └── api.yaml          # Base config
└── overlays/
    ├── dev.yaml          # Dev overrides
    ├── staging.yaml      # Staging overrides
    └── production.yaml   # Production overrides
```

**ApplicationSet:**
```yaml
helm:
  valueFiles:
    - $values/bookrack/the-yaml-life/base/{{.app}}.yaml
    - $values/bookrack/the-yaml-life/overlays/{{.env}}.yaml
```

### Pattern 3: Dynamic Namespace from File

```yaml
destination:
  server: https://kubernetes.default.svc
  namespace: '{{.namespace | default .path.basename}}'
```

If file has `namespace: custom`, uses `custom`.
Otherwise uses chapter name (path.basename).

### Pattern 4: Templated Annotations from File

```yaml
template:
  metadata:
    annotations:
      {{- range $key, $value := .annotations }}
      {{$key}}: '{{$value}}'
      {{- end }}
```

**File:**
```yaml
name: myapp
annotations:
  owner: platform-team
  cost-center: engineering
```

**Generates:**
```yaml
metadata:
  annotations:
    owner: platform-team
    cost-center: engineering
```

---

## Troubleshooting

### Error: "duplicate name"

**Cause:** Multiple files generate Applications with the same name.

**Solution:**
```yaml
# Bad - files with same name in different dirs collide
name: '{{.path.filename}}'

# Good - include directory in name
name: '{{.path.basename}}-{{.path.filename}}'
```

---

### Error: "{{path}} is invalid"

**Cause:** Using `{{path}}` which is an object, not a string.

**Solution:**
```yaml
# Bad
valueFiles:
  - $values/{{path}}

# Good
valueFiles:
  - $values/{{.path.path}}/{{.path.filename}}.yaml
```

---

### Error: "field exclude must be of type boolean"

**Cause:** Git Files generator doesn't support `exclude` as a string pattern.

**Solution:**
```yaml
# Bad
files:
  - path: "apps/*.yaml"
    exclude: "**/index.yaml"

# Good - use separate path entry with exclude: true
files:
  - path: "apps/*.yaml"
  - path: "apps/**/index.yaml"
    exclude: true
```

---

### Error: "unable to resolve $values"

**Cause:** Missing `ref` field on the values source.

**Solution:**
```yaml
sources:
  - repoURL: https://github.com/charts/my-chart.git
    path: chart
    helm:
      valueFiles:
        - $values/values.yaml

  - repoURL: https://github.com/configs/repo.git
    targetRevision: main
    ref: values  # ← MUST HAVE THIS
```

---

### ApplicationSet Not Generating Apps

**Debug Steps:**

1. Check ApplicationSet status:
```bash
kubectl get applicationset -n argocd
kubectl describe applicationset staging-summon-instances -n argocd
```

2. Look for conditions:
```yaml
status:
  conditions:
    - type: ErrorOccurred
      status: "True"
      message: "error message here"
```

3. Check generator output:
```bash
argocd appset get staging-summon-instances
```

4. Verify files match pattern:
```bash
# Clone repo and test pattern
git clone <repo>
find . -path "bookrack/the-yaml-life/staging/*.yaml"
```

---

## Best Practices

### 1. Always Use `goTemplate: true`

Modern ArgoCD versions support Go templating with much more power:

```yaml
spec:
  goTemplate: true  # ← Always include this
```

### 2. Namespace Applications Clearly

```yaml
metadata:
  name: '{{.book}}-{{.chapter}}-{{.name}}'  # the-yaml-life-staging-conduwuit
```

### 3. Use Labels for Organization

```yaml
metadata:
  labels:
    book: '{{.book}}'
    chapter: '{{.chapter}}'
    managed-by: applicationset
    generator: git-files
```

### 4. Set Sync Waves

```yaml
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "10"
```

Lower waves deploy first (dependencies → applications).

### 5. Document Generator Logic

```yaml
spec:
  # This generator discovers all YAML files in staging chapter
  # and creates a summon-based Application for each one.
  # See docs/applicationset-guide.md for details.
  generators:
    - git:
        ...
```

### 6. Test with Single File First

```yaml
# Start narrow
files:
  - path: "bookrack/the-yaml-life/staging/conduwuit.yaml"

# Then expand
files:
  - path: "bookrack/the-yaml-life/staging/*.yaml"
```

### 7. Use Specific targetRevision

```yaml
# Bad - unpredictable
targetRevision: HEAD

# Good - explicit
targetRevision: main
targetRevision: v1.2.3
```

---

## Version Compatibility

| ArgoCD Version | ApplicationSet | Notes |
|----------------|----------------|-------|
| 2.12+ | Built-in | Current (2025) |
| 2.6 - 2.11 | Built-in | Limited features |
| < 2.6 | Separate CRD | Legacy |

**Current Setup (Oct 2025):**
- ArgoCD: v2.12.3
- ApplicationSet: Built-in
- Go Templates: ✅ Supported

---

## References

- [ArgoCD ApplicationSet Docs](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/)
- [Git Files Generator](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/Generators-Git/)
- [Multi-Source Apps](https://argo-cd.readthedocs.io/en/stable/user-guide/multiple_sources/)
- [Kast System Architecture](./kast-architecture.md)

---

## Changelog

| Date | Change |
|------|--------|
| 2025-10-16 | Initial documentation created |
| 2025-10-16 | Added path variable fix for staging-appset |

---

**Maintained by:** Kast Platform Team
**Questions?** Check troubleshooting section or file an issue.
