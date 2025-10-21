# ApplicationSet Quick Reference

One-page cheat sheet for ApplicationSet usage in Kast System.

---

## Template Variables Cheat Sheet

### Git Files Generator

```yaml
# Path variables (auto-generated)
{{.path.path}}               # bookrack/the-yaml-life/staging
{{.path.basename}}           # staging
{{.path.filename}}           # conduwuit (no extension!)
{{.path[0]}}                 # bookrack
{{.path[1]}}                 # the-yaml-life
{{.path[2]}}                 # staging

# File content (from YAML)
{{.name}}                    # Any field from the file
{{.namespace}}               # Any nested field
{{.image.tag}}               # Nested access
```

⚠️ **NEVER** use `{{path}}` - it's an object! Use `{{.path.path}}`

---

## Common Patterns

### Multi-Source with ValueFiles

```yaml
sources:
  # Chart source
  - repoURL: https://github.com/org/charts.git
    path: charts/app
    helm:
      valueFiles:
        - $values/{{.path.path}}/{{.path.filename}}.yaml

  # Values source (MUST have ref!)
  - repoURL: https://github.com/org/configs.git
    targetRevision: main
    ref: values  # Creates $values variable
```

### Dynamic Namespace

```yaml
destination:
  namespace: '{{.namespace | default .path.basename}}'
```

### Conditional Values

```yaml
helm:
  values: |
    {{- if .replicas }}
    replicas: {{.replicas}}
    {{- else }}
    replicas: 1
    {{- end }}
```

### Exclude Files

```yaml
files:
  - path: "apps/*.yaml"
  - path: "apps/index.yaml"
    exclude: true  # Boolean, not pattern!
```

---

## Generator Types

| Generator | Use Case | Example |
|-----------|----------|---------|
| Git Files | YAML/JSON files → Apps | Config per environment |
| Git Directory | Directories → Apps | Helm chart per dir |
| List | Static list → Apps | Fixed environments |
| Cluster | ArgoCD clusters → Apps | Multi-cluster deploy |
| Matrix | Combine generators | Apps × Envs |

---

## Debugging Commands

```bash
# Check ApplicationSet status
kubectl get appset -n argocd
kubectl describe appset my-appset -n argocd

# View generated applications
argocd appset get my-appset

# Check conditions
kubectl get appset my-appset -n argocd -o jsonpath='{.status.conditions}'

# Test file discovery locally
git clone <repo>
find . -path "bookrack/*/staging/*.yaml"
```

---

## Common Errors & Fixes

| Error | Cause | Fix |
|-------|-------|-----|
| "duplicate name" | Same filename in multiple dirs | Use `{{.path.basename}}-{{.path.filename}}` |
| "{{path}} is invalid" | Using object as string | Use `{{.path.path}}` |
| "exclude must be boolean" | String pattern in exclude | Use `exclude: true` on separate path entry |
| "$values unresolved" | Missing ref field | Add `ref: values` to source |

---

## Current Kast System Implementation

**File:** `bookrack/the-yaml-life/intro/staging-appset.yaml`

**Purpose:** Auto-generate summon Apps for all staging/*.yaml files

**Fix Needed:**
```yaml
# Current (BROKEN)
valueFiles:
  - $values/{{path}}

# Should be
valueFiles:
  - $values/{{.path.path}}/{{.path.filename}}.yaml
```

---

## Go Template Functions

```yaml
# String manipulation
{{.name | lower}}                    # lowercase
{{.name | upper}}                    # UPPERCASE
{{.name | replace "_" "-"}}          # replace chars

# Defaults
{{.namespace | default "default"}}   # fallback value

# Conditionals
{{- if eq .env "prod" }}
replicas: 5
{{- else }}
replicas: 1
{{- end }}

# Loops
{{- range .items }}
- name: {{.name}}
{{- end }}
```

---

## Best Practices Checklist

- [ ] Use `goTemplate: true`
- [ ] Never use `{{path}}` directly
- [ ] Include `ref: values` for multi-source
- [ ] Add labels for tracking
- [ ] Use sync waves for ordering
- [ ] Test with single file first
- [ ] Document generator logic
- [ ] Set specific targetRevision

---

**Full Documentation:** `docs/applicationset-guide.md`
