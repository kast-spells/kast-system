# Configuration Backup - Pre-Migration

**Date:** 2026-01-03
**Purpose:** Backup of critical configurations before kast → runik + odin migration

## Critical Chart Configuration

### charts/kaster/Chart.yaml (BEFORE)
```yaml
apiVersion: v2
name: kaster
version: 1.4.4
description: a kaster for the glyphs system.
home: https://github.com/kast-spells
sources:
  - https://github.com/kast-spells/kast-system
maintainers:
  - name: namen malkav
    email: namenmalkav@gmail.com
  - name: laaledesiempre
    email: laaledesiempre@disroot.org
```

**POST-MIGRATION (Expected):**
```yaml
apiVersion: v2
name: kaster  # UNCHANGED
version: 2.0.0  # Major bump for breaking annotations/URLs
description: a kaster for the glyphs system.  # UNCHANGED
home: https://github.com/runik-spells
sources:
  - https://github.com/runik-spells/runik-system
maintainers:
  - name: namen malkav
    email: namenmalkav@gmail.com
  - name: laaledesiempre
    email: laaledesiempre@disroot.org
```

## Directory Structure

### charts/kaster/ (BEFORE)
```
charts/kaster/
├── charts -> ../glyphs  (SYMLINK - preserve during migration)
├── Chart.yaml
├── examples/
│   ├── argo-events-test.yaml
│   └── summon-serviceaccount-test.yaml
├── LICENSE
├── templates/
│   └── kaster.yaml
└── values.yaml
```

**POST-MIGRATION (Expected):**
```
charts/kaster/  # UNCHANGED directory name
├── charts -> ../glyphs  # SYMLINK - preserved
├── Chart.yaml  # Updated URLs only
├── examples/  # UNCHANGED
│   ├── argo-events-test.yaml
│   └── summon-serviceaccount-test.yaml
├── LICENSE  # Updated copyright text
├── templates/  # UNCHANGED directory
│   └── kaster.yaml  # UNCHANGED filename
└── values.yaml  # UNCHANGED
```

## GitHub Workflow Configuration

### .github/workflows/kaster.yml (BEFORE)
```yaml
name: kaster-sync

on:
  push:
    tags:
      - "kaster-*"

jobs:
  sync-kaster:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout source repository
        uses: actions/checkout@v4

      - name: Detect event type
        id: event_type
        run: |
          if [[ "${GITHUB_REF}" == refs/tags/* ]]; then
            echo "is_tag=true" >> $GITHUB_OUTPUT
            echo "TAG_NAME=${GITHUB_REF#refs/tags/}" >> $GITHUB_ENV
          else
            echo "is_tag=false" >> $GITHUB_OUTPUT
            {
              echo "COMMIT_MSG<<EOF"
              echo "${{ github.event.head_commit.message }}"
              echo "EOF"
            } >> $GITHUB_ENV
          fi

      - name: Clone destination repository
        run: |
          git clone https://x-access-token:${{ secrets.DEST_REPO_PAT }}@github.com/kast-spells/kaster.git kaster-repo
          cd kaster-repo
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"

      - name: Copy files to destination repository (branch)
        run: |
          rsync -avL --ignore-existing --include='*/' --include='Chart.yaml' --exclude='*' charts/kaster/ kaster-repo/
          rsync -avL --exclude='Chart.yaml' charts/kaster/ kaster-repo/

      - name: Copy files to destination repository (tag)
        if: steps.event_type.outputs.is_tag == 'true'
        run: |
          CHART_VERSION=$(echo $TAG_NAME | sed 's/kaster-//')
          sed -i "s/^version:.*/version: ${CHART_VERSION}/" kaster-repo/Chart.yaml

      - name: Commit and push changes (branch)
        if: steps.event_type.outputs.is_tag == 'false'
        run: |
          cd kaster-repo
          git add .
          if git diff --cached --quiet -- . ':(exclude)Chart.yaml'; then
            echo "No changes to commit."
          else
            git commit -m "$COMMIT_MSG"
            git push origin master
          fi

      - name: Commit, tag and push changes (tag)
        if: steps.event_type.outputs.is_tag == 'true'
        run: |
          cd kaster-repo
          if git rev-parse "$TAG_NAME" >/dev/null 2>&1; then
            echo "Tag $TAG_NAME already exists. Skipping..."
          else
            git add .
            git commit -m "Release - Tag: $TAG_NAME"
            git push origin master
            git tag "$TAG_NAME"
            git push origin "$TAG_NAME"
          fi
```

**POST-MIGRATION (Expected):**
```yaml
name: kaster-sync  # UNCHANGED

on:
  push:
    tags:
      - "kaster-*"  # UNCHANGED

jobs:
  sync-kaster:  # UNCHANGED
    runs-on: ubuntu-latest
    steps:
      - name: Checkout source repository
        uses: actions/checkout@v4

      - name: Detect event type
        id: event_type
        run: |
          if [[ "${GITHUB_REF}" == refs/tags/* ]]; then
            echo "is_tag=true" >> $GITHUB_OUTPUT
            echo "TAG_NAME=${GITHUB_REF#refs/tags/}" >> $GITHUB_ENV
          else
            echo "is_tag=false" >> $GITHUB_OUTPUT
            {
              echo "COMMIT_MSG<<EOF"
              echo "${{ github.event.head_commit.message }}"
              echo "EOF"
            } >> $GITHUB_ENV
          fi

      - name: Clone destination repository
        run: |
          git clone https://x-access-token:${{ secrets.DEST_REPO_PAT }}@github.com/runik-spells/kaster.git kaster-repo  # URL changed to runik-spells
          cd kaster-repo
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"

      - name: Copy files to destination repository (branch)
        run: |
          rsync -avL --ignore-existing --include='*/' --include='Chart.yaml' --exclude='*' charts/kaster/ kaster-repo/  # UNCHANGED paths
          rsync -avL --exclude='Chart.yaml' charts/kaster/ kaster-repo/

      - name: Copy files to destination repository (tag)
        if: steps.event_type.outputs.is_tag == 'true'
        run: |
          CHART_VERSION=$(echo $TAG_NAME | sed 's/kaster-//')  # UNCHANGED pattern
          sed -i "s/^version:.*/version: ${CHART_VERSION}/" kaster-repo/Chart.yaml

      - name: Commit and push changes (branch)
        if: steps.event_type.outputs.is_tag == 'false'
        run: |
          cd kaster-repo
          git add .
          if git diff --cached --quiet -- . ':(exclude)Chart.yaml'; then
            echo "No changes to commit."
          else
            git commit -m "$COMMIT_MSG"
            git push origin master
          fi

      - name: Commit, tag and push changes (tag)
        if: steps.event_type.outputs.is_tag == 'true'
        run: |
          cd kaster-repo
          if git rev-parse "$TAG_NAME" >/dev/null 2>&1; then
            echo "Tag $TAG_NAME already exists. Skipping..."
          else
            git add .
            git commit -m "Release - Tag: $TAG_NAME"
            git push origin master
            git tag "$TAG_NAME"
            git push origin "$TAG_NAME"
          fi
```

**CHANGES:** Only the GitHub org URL changes from `kast-spells` to `runik-spells`

## Git Tags (BEFORE Migration)
```
kaster-1.4.3
kaster-1.4.4
kaster-1.5.0
kaster-1.6.0
kaster-1.7.0
```

**POST-MIGRATION:**
- Keep old tags for historical reference
- New versioning: `kaster-2.0.0` (major bump for breaking annotations/URLs)
- **kaster tag pattern UNCHANGED**

## Repository References

### GitHub Organization
- **BEFORE:** kast-spells
- **AFTER:** runik-spells

### Repository Names
- **BEFORE:** kast-system, kaster, kast-docs
- **AFTER:** runik-system, kaster (UNCHANGED), runik-docs

## Critical Annotations

### Covenant Labels (BEFORE)
```yaml
covenant.runik.io/team
covenant.runik.io/owner
covenant.runik.io/department
covenant.runik.io/member
covenant.runik.io/organization
covenant.runik.io/integration
covenant.runik.io/realm
```

**AFTER:**
```yaml
covenant.runik.io/team
covenant.runik.io/owner
covenant.runik.io/department
covenant.runik.io/member
covenant.runik.io/organization
covenant.runik.io/integration
covenant.runik.io/realm
```

### Operational Annotations (BEFORE)
```yaml
runik.ing/action
runik.ing/rotate
runik.ing/s3-identity
runik.ing/s3-provider
runik.ing/identity-name
runik.ing/source-namespace
```

**AFTER:**
```yaml
runik.ing/action
runik.ing/rotate
runik.ing/s3-identity
runik.ing/s3-provider
runik.ing/identity-name
runik.ing/source-namespace
```

## Important Notes

1. **Symlink Preservation:** The symlink `charts/kaster/charts -> ../glyphs` already exists and requires no changes

2. **Git Workflow:** The workflow sync target repository will change from `kast-spells/kaster` to `runik-spells/kaster` (only org changes)

3. **Tag Pattern:** Tag pattern UNCHANGED - continues as `kaster-*`

4. **Version Bump:** Breaking change requires major version bump: 1.4.4 → 2.0.0

5. **Chart Name:** kaster chart name stays UNCHANGED, only URLs and annotations change

## Restore Procedure

If migration needs to be rolled back:

```bash
# Switch back to master branch
git checkout master

# Delete migration branch
git branch -D feat/rename-kast-to-runik

# All original files remain intact in master
```

---

**Backup created:** 2026-01-03
**Migration branch:** feat/rename-kast-to-runik
**Status:** Phase 1 Complete - Ready for Phase 2
