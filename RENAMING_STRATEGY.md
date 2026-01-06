# Renaming Strategy: KAST → RUNIK

## Overview

This document outlines the naming strategy for renaming the kast-system project to runik-system.

## Strategy Summary

### Chart Name: kaster
**KEEP AS IS** - The orchestrator chart `kaster` will **NOT** be renamed.

**Unchanged Items:**
- Directory: `charts/kaster/` (stays as kaster)
- Chart.yaml: `name: kaster` (stays as kaster)
- Workflow file: `.github/workflows/kaster.yml` (stays as kaster.yml)
- Templates: `charts/kaster/templates/kaster.yaml` (stays as kaster.yaml)
- Git tags: `kaster-1.x.x` (continues with kaster prefix)

### Everything Else: kast → runik
All references to "kast" (except kaster chart name) will be renamed to "runik".

**Affected Items:**
- Project name: `kast-system` → `runik-system`
- GitHub org: `kast-spells` → `runik-spells`
- Annotations: `covenant.runik.io/*` → `covenant.runik.io/*`
- Annotations: `runik.ing/*` → `runik.ing/*`
- Template headers: `{{/*kast` → `{{/*runik`
- Documentation references
- Repository URLs
- License text

## Examples

### Chart References (NO CHANGE to chart name)
```yaml
# BEFORE
name: kaster
description: a kaster for the glyphs system

# AFTER
name: kaster  # UNCHANGED
description: a kaster for the glyphs system  # UNCHANGED
```

### Repository URLs (kast → runik)
```yaml
# BEFORE
sources:
  - https://github.com/kast-spells/kast-system
home: https://github.com/kast-spells

# AFTER
sources:
  - https://github.com/runik-spells/runik-system
home: https://github.com/runik-spells
```

### Annotations
```yaml
# BEFORE
annotations:
  covenant.runik.io/team: "platform"
  runik.ing/action: "rotate"

# AFTER
annotations:
  covenant.runik.io/team: "platform"
  runik.ing/action: "rotate"
```

### Template Headers
```go
# BEFORE
{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2023 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
*/}}

# AFTER
{{/*runik - Kubernetes arcane spelling technology
Copyright (C) 2023-2026 namenmalkv@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
*/}}
```

### Documentation (kast-system → runik-system, keep kaster)
```markdown
# BEFORE
The kaster chart orchestrates glyphs in the kast-system framework.

# AFTER
The kaster chart orchestrates glyphs in the runik-system framework.
```

### Bookrack Trinkets (URLs only)
```yaml
# BEFORE
trinkets:
  kaster-trinket:
    repository: https://github.com/kast-spells/kaster.git
    path: ./charts/kaster

# AFTER
trinkets:
  kaster-trinket:  # UNCHANGED
    repository: https://github.com/runik-spells/kaster.git  # URL changed
    path: ./charts/kaster  # UNCHANGED
```

## Search & Replace Patterns

### Phase 1: NO File/Directory Renames
**SKIP THIS PHASE** - kaster files stay as they are

### Phase 2: Content Replacements ONLY

**IMPORTANT: kaster chart name stays unchanged, only URLs and references change**
```bash
# Organizations and repos (HIGHEST PRIORITY - most specific)
kast-spells → runik-spells
kast-system → runik-system
kast-docs → runik-docs

# Annotations
covenant.runik.io → covenant.runik.io
runik.ing → runik.ing

# Template headers (KEEP "kaster" unchanged in comments referring to the chart)
{{/*kast - Kubernetes arcane spelling technology → {{/*runik - Kubernetes arcane spelling technology

# License
"kast - Kubernetes arcane spelling technology" → "runik - Kubernetes arcane spelling technology"
```

**EXCLUSIONS (DO NOT CHANGE):**
```bash
# These MUST remain as "kaster":
name: kaster  # in Chart.yaml
charts/kaster/  # directory name
kaster.yaml  # template filename
kaster.yml  # workflow filename
kaster-1.x.x  # git tags
```

## Validation Checklist

After each phase, verify:

- [ ] `make test-syntax` passes
- [ ] `kaster` chart name still present: `grep "name: kaster" charts/kaster/Chart.yaml`
- [ ] No occurrences of old URLs: `grep -r "kast-spells" .` (should be runik-spells)
- [ ] No old annotations: `grep -r "covenant\.kast\.io" .` and `grep -r "kast\.ing" .`
- [ ] Chart.yaml files updated correctly (URLs changed, name: kaster unchanged)
- [ ] Git workflow files still reference kaster (unchanged)
- [ ] Documentation uses runik-system but keeps kaster chart references

## Files Requiring Manual Review

These files need careful manual verification:

1. **CHANGELOG.md** - Keep historical references, add migration note
2. **Migration guides** - Will contain both old and new names
3. **Git commit history** - Do NOT rewrite (keep old references)
4. **Git tags** - Keep old tags, create new odin-2.0.0 tag

## Version Strategy

- **kaster chart:** `kaster-1.4.4` → `kaster-2.0.0` (major bump for breaking annotations/URLs)
- Chart name unchanged but breaking changes in annotations
- Other charts: Bump to align with 2.0.0 release ecosystem-wide

## Post-Migration

After migration completes:

1. Create migration guide for users
2. Update all dependent repositories
3. Create GitHub org redirects (kast-spells → runik-spells)
4. Update chart repository (kaster continues, but in runik-spells org)
5. Publish kaster-2.0.0 release
6. Announce breaking change to users (annotations, URLs)
