# Migration Guide: kast → runik (v2.0.0)

**Breaking Change Notice**: This is a major version upgrade (v1.x → v2.0.0) involving a complete rebranding from "kast" to "runik".

## Overview

Version 2.0.0 renames the project from **kast-system** to **runik-system**. This guide helps you migrate your existing deployments.

## What Changed

### 1. Project and Organization Names

| Component | Old (v1.x) | New (v2.0.0) |
|-----------|-----------|--------------|
| Project name | kast-system | runik-system |
| GitHub org | kast-spells | runik-spells |
| Repository URLs | github.com/kast-spells/* | github.com/runik-spells/* |
| Technology name | kast | runik |

### 2. **Important**: Chart Names (UNCHANGED)

The **kaster** chart name remains unchanged:

| Chart | Old (v1.x) | New (v2.0.0) | Status |
|-------|-----------|--------------|--------|
| kaster | kaster | kaster | ✓ NO CHANGE |
| summon | summon | summon | ✓ NO CHANGE |
| librarian | librarian | librarian | ✓ NO CHANGE |
| covenant | covenant | covenant | ✓ NO CHANGE |

**Why?** The "kaster" name is semantically meaningful (the one who casts) and is preserved throughout the codebase.

### 3. Kubernetes Annotations

| Old Annotation | New Annotation |
|----------------|----------------|
| `covenant.kast.io/*` | `covenant.runik.io/*` |
| `kast.ing/*` | `runik.ing/*` |

### 4. Repository URLs

All chart repository URLs have been updated:

**Before (v1.x):**
```yaml
repository: https://github.com/kast-spells/kast-system.git
path: ./charts/summon
```

**After (v2.0.0):**
```yaml
repository: https://github.com/runik-spells/runik-system.git
path: ./charts/summon
```

### 5. Copyright Headers

Template headers updated from:
```go
{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
*/}}
```

To:
```go
{{/*runik - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
*/}}
```

## Migration Steps

### Step 1: Update Book Configurations

Update your book `index.yaml` files:

**Before:**
```yaml
name: my-book

defaultTrinket:
  repository: https://github.com/kast-spells/kast-system.git
  path: ./charts/summon
  revision: main

trinkets:
  kaster-trinket:
    key: vault
    repository: https://github.com/kast-spells/kast-system.git
    path: ./charts/kaster
    revision: main
```

**After:**
```yaml
name: my-book

defaultTrinket:
  repository: https://github.com/runik-spells/runik-system.git
  path: ./charts/summon
  revision: main

trinkets:
  kaster-trinket:  # ← Name stays "kaster"
    key: vault
    repository: https://github.com/runik-spells/runik-system.git
    path: ./charts/kaster  # ← Path stays "kaster"
    revision: main
```

### Step 2: Update Covenant Configurations (if applicable)

If using covenant (Keycloak integration):

**Before:**
```yaml
realm:
  name: kast-production
  displayName: "Kast Production"
```

**After:**
```yaml
realm:
  name: runik-production
  displayName: "Runik Production"
```

### Step 3: Update Custom Annotations (if any)

If you have custom resources using kast annotations:

**Before:**
```yaml
metadata:
  annotations:
    covenant.kast.io/team: "platform"
    kast.ing/managed-by: "librarian"
```

**After:**
```yaml
metadata:
  annotations:
    covenant.runik.io/team: "platform"
    runik.ing/managed-by: "librarian"
```

### Step 4: Update GitHub Workflows (if forked)

If you forked the repository and have custom workflows:

**Before:**
```yaml
- name: Clone destination repository
  run: |
    git clone https://x-access-token:${{ secrets.PAT }}@github.com/kast-spells/kaster.git
```

**After:**
```yaml
- name: Clone destination repository
  run: |
    git clone https://x-access-token:${{ secrets.PAT }}@github.com/runik-spells/kaster.git
```

### Step 5: Update Documentation References

Update any internal documentation that references:
- `kast-system` → `runik-system`
- `kast-spells` → `runik-spells`
- "kast" (the technology) → "runik"

**Preserve "kaster"** when referring to the chart orchestrator.

## What DOESN'T Need to Change

### ✓ Chart Names
- `kaster` stays `kaster`
- `summon` stays `summon`
- `librarian` stays `librarian`
- All trinket names remain unchanged

### ✓ Chart Directory Structure
```
charts/
  kaster/     ← Stays "kaster"
  summon/     ← Stays "summon"
  glyphs/     ← Stays "glyphs"
  trinkets/   ← Stays "trinkets"
```

### ✓ Helm Release Names
Your existing ArgoCD Applications and Helm releases don't need renaming.

### ✓ Kubernetes Resources
Existing deployments, services, and other resources continue working unchanged.

## Testing Your Migration

### 1. Validate Book Configuration
```bash
# Render librarian to check for errors
helm template librarian ./librarian \
  -f bookrack/my-book/index.yaml \
  --set book=my-book
```

### 2. Check ArgoCD Applications
```bash
# List applications (they should sync successfully)
argocd app list -l book=my-book
```

### 3. Verify Spell Rendering
```bash
# Test a spell with the new configuration
helm template test ./charts/summon \
  -f bookrack/my-book/chapter/spell.yaml
```

## Rollback Plan

If you need to rollback:

1. **Revert repository URLs** in `index.yaml` files back to `kast-spells/kast-system`
2. **Use v1.x chart versions** (tags before v2.0.0)
3. **Revert annotations** from `covenant.runik.io/*` to `covenant.kast.io/*`

## FAQ

### Q: Why rename from kast to runik?

A: Strategic rebranding decision. "Runik" better represents the runic/arcane nature of the templating system.

### Q: Why keep "kaster" unchanged?

A: The "kaster" name (one who casts) is semantically meaningful in the glyph system architecture. It's the orchestrator that "casts" glyphs, and this meaning is preserved.

### Q: Will old URLs redirect automatically?

A: No. You must update all repository URLs in your configurations. GitHub does not automatically redirect organization renames in git clone operations.

### Q: Do I need to recreate my ArgoCD Applications?

A: No. Update the repository URLs in your book configurations and let ArgoCD sync the changes. Existing applications will update their source references.

### Q: What about existing Helm releases?

A: Helm releases are identified by name, not repository URL. They will continue working. ArgoCD manages the source changes.

### Q: Is this backward compatible?

A: No. This is a **breaking change** requiring manual migration. Use the previous version (v1.x) if you cannot migrate immediately.

## Support

For migration issues:
- GitHub Issues: https://github.com/runik-spells/runik-system/issues
- Documentation: https://github.com/runik-spells/runik-system/tree/master/docs

## Changelog Reference

See [CHANGELOG.md](./CHANGELOG.md) for detailed version history.

---

**Migration Checklist:**

- [ ] Update book `index.yaml` repository URLs
- [ ] Update chapter `index.yaml` files (if any)
- [ ] Update covenant realm names (if applicable)
- [ ] Update custom annotations
- [ ] Update internal documentation
- [ ] Test librarian rendering
- [ ] Verify ArgoCD sync
- [ ] Test spell deployments
- [ ] Update CI/CD pipelines (if applicable)
- [ ] Communicate changes to team
