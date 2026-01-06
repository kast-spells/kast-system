# Pre-Migration State: KAST → RUNIK

**Date:** 2026-01-04
**Branch:** feat/rename-kast-to-runik
**Migration Version:** 2.0.0 (Breaking Change)

## Migration Strategy

**Single Naming Convention:**
- **kaster** (chart orchestrator) → **KEEP AS IS** (NO CHANGE)
- **kast** (all other references) → **runik**

## Repository State

### Git Information
- **Current Branch:** master → feat/rename-kast-to-runik
- **Last Commit:** f212c88 - feat(charts/trinkets/tarot/templates/_workflow-generator.tpl)
- **Repository:** kast-system → runik-system
- **Organization:** kast-spells → runik-spells

### Chart Versions (Pre-Migration)

| Chart | Version | Location | Post-Migration Name |
|-------|---------|----------|---------------------|
| kaster | 1.4.4 | charts/kaster/ | **kaster** (UNCHANGED) |
| summon | (TBD) | charts/summon/ | summon (unchanged) |
| glyphs | (TBD) | charts/glyphs/ | glyphs (unchanged) |
| trinkets | (TBD) | charts/trinkets/ | trinkets (unchanged) |

### Key Components

**Charts:**
- kaster (Glyph orchestrator)
- summon (Workload chart)
- glyphs/ (15 glyphs)
- trinkets/ (microspell, tarot, covenant)

**Glyphs Available:**
- certManager
- common
- crossplane
- freeForm
- gcp
- istio
- runic-system
- summon
- vault
- postgresql
- argo-events
- keycloak
- s3
- external-secrets
- aws

**Directories:**
- charts/
- librarian/
- covenant/
- bookrack/
- docs/
- tests/

## Migration Scope

### Total Files Affected: 226+

| Category | Count | Description |
|----------|-------|-------------|
| Directories | 1 | charts/kaster/ |
| Files with "kast" in name | 7 | Chart files, workflows |
| YAML files | 74 | Configuration files |
| Template files (.tpl) | 110 | Helm templates with headers |
| Documentation (.md) | 28 | User and developer docs |
| GitHub workflows | 6 | CI/CD pipelines |
| Kubernetes annotations | 71 | covenant.runik.io + runik.ing |

## Key Changes Required

### Naming Convention (Single Strategy)

**Chart Name (kaster):**
- **kaster** → **UNCHANGED** (stays as kaster)
- Directory: `charts/kaster/` → **UNCHANGED**
- Chart.yaml name field: `name: kaster` → **UNCHANGED**
- Workflow: `.github/workflows/kaster.yml` → **UNCHANGED**
- Git tags: `kaster-1.x.x` → continues as `kaster-2.x.x`

**All Other References (kast → runik):**
- **kast-system** → **runik-system**
- **kast-spells** → **runik-spells**
- Template headers: `{{/*kast` → `{{/*runik`
- Documentation references
- Variable names and descriptions

### Kubernetes Annotations
- `covenant.runik.io/*` → `covenant.runik.io/*`
- `runik.ing/*` → `runik.ing/*`

### Repository URLs
- `https://github.com/kast-spells/` → `https://github.com/runik-spells/`
- `https://github.com/kast-spells/kast-system` → `https://github.com/runik-spells/runik-system`

### Template Headers (110 files)
```go
{{/*kast - Kubernetes arcane spelling technology
→
{{/*runik - Kubernetes arcane spelling technology
```

### Examples
- `kaster` chart → `kaster` chart (UNCHANGED)
- `kast-system` → `runik-system`
- `covenant.runik.io/team` → `covenant.runik.io/team`
- `https://github.com/kast-spells/` → `https://github.com/runik-spells/`

## Test Status (Pre-Migration)

**Test execution status will be documented below after running `make test-all`**

---

## Migration Phases

1. ✅ **Phase 1: Preparation** - Complete
2. ⏳ Phase 2: Update Kubernetes annotations (covenant.runik.io→covenant.runik.io, runik.ing→runik.ing)
3. ⏳ Phase 3: Update template headers ({{/*kast→{{/*runik)
4. ⏳ Phase 4: Update Chart.yaml files (URLs only, keep name: kaster)
5. ⏳ Phase 5: Update documentation (kast→runik, keep kaster references)
6. ⏳ Phase 6: Update repository URLs (kast-spells→runik-spells, kast-system→runik-system)
7. ⏳ Phase 7: Update GitHub workflows (URLs to runik, keep kaster.yml filename)
8. ⏳ Phase 8: Update bookrack examples (URLs to runik, keep kaster-trinket)
9. ⏳ Phase 9: Execute comprehensive tests
10. ⏳ Phase 10: Update LICENSE and copyright (kast→runik)
11. ⏳ Phase 11: Create migration guide

## Notes

- This is a BREAKING CHANGE requiring major version bump (2.0.0)
- No backward compatibility possible due to annotation/URL changes
- Requires coordination across multiple repositories
- GitHub organization rename required (kast-spells → runik-spells)
- Chart kaster name UNCHANGED but annotations and URLs change

## Backup

Git provides automatic backup through version control. To revert:
```bash
git checkout master
git branch -D feat/rename-kast-to-runik
```

## Next Steps

1. Execute `make test-all` to document current test state
2. Proceed with Phase 2: Directory renaming
3. Incremental testing after each phase
