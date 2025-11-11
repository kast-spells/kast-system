# Testing Guide

Comprehensive testing system for kast-system following Test-Driven Development (TDD) methodology.

## Overview

kast-system uses a dual testing approach with automatic discovery:
- **TDD Workflow:** Red-Green-Refactor cycle for all features
- **Snapshot Testing:** Output validation and K8s schema compliance
- **Glyph Testing:** Infrastructure template validation
- **Resource Completeness:** Expected resource generation verification
- **Automatic Discovery:** All charts, glyphs, and trinkets detected automatically

**Philosophy:** Write tests first, implement features second, verify continuously.

## Test-Driven Development (TDD)

### The Three Phases

#### 1. RED Phase - Write Failing Tests

**Purpose:** Define expected behavior before implementation

**Commands:**
```bash
make tdd-red          # Run tests expecting failures
```

**Mechanics:**
- Uses `||` operator: `make test-comprehensive || echo "Good! Tests failing"`
- Failures are **expected and celebrated**
- Exit code: 0 (success) even if tests fail

**When to use:**
- After creating new test examples
- Before implementing new features
- To verify test actually validates something

**Example:**
```bash
# Create test for new feature
make create-example CHART=summon EXAMPLE=pod-disruption

# Edit example to define expected behavior
cat > charts/summon/examples/pod-disruption.yaml <<EOF
workload:
  enabled: true
  type: deployment
  replicas: 3

podDisruptionBudget:
  enabled: true
  minAvailable: 2
EOF

# Verify test fails (feature doesn't exist yet)
make tdd-red
# Output: ❌ summon-pod-disruption (expectations failed)
#         ✅ Good! Tests are failing - now implement
```

#### 2. GREEN Phase - Make Tests Pass

**Purpose:** Implement minimum code to satisfy tests

**Commands:**
```bash
make tdd-green        # Run tests expecting success
```

**Mechanics:**
- Direct execution: `make test-comprehensive`
- Tests **must pass** or Make exits with error
- Exit code: non-zero if tests fail

**When to use:**
- After implementing features
- To verify implementation works
- Before committing code

**Example:**
```bash
# Implement PodDisruptionBudget feature
# Edit charts/summon/templates/pod-disruption-budget.yaml

# Verify test passes
make tdd-green
# Output: ✅ summon-pod-disruption
```

#### 3. REFACTOR Phase - Improve Code

**Purpose:** Optimize and clean code while maintaining functionality

**Commands:**
```bash
make tdd-refactor     # Run comprehensive test suite
```

**Mechanics:**
- Runs `test-all`: comprehensive + snapshots + glyphs
- All tests must pass
- Exit code: non-zero if any test fails

**When to use:**
- After cleaning up code
- After optimizing implementations
- Before finalizing work

**Example:**
```bash
# Clean up implementation, add comments
# Optimize template logic

# Verify nothing broke
make tdd-refactor
# Output: All tests pass (comprehensive + snapshots + glyphs)
```

## Testing Layers

### Layer 1: Syntax Validation

**Purpose:** Fast feedback on template syntax

**Command:**
```bash
make test-syntax
```

**What it validates:**
- Helm template syntax correctness
- YAML structure validity
- No rendering errors

**Speed:** Very fast (seconds)

**Requirements:** None (no K8s cluster needed)

**Output:**
```
Testing chart: summon
  ✅ basic-deployment
  ✅ complex-production
  ✅ statefulset-with-storage
```

### Layer 2: Resource Completeness

**Purpose:** Verify expected resources are generated

**Command:**
```bash
make test-comprehensive
```

**What it validates:**
- All expected K8s resources present
- Configuration-driven expectations:
  - `workload.enabled=true` → Deployment/StatefulSet
  - `service.enabled=true` → Service
  - `volumes.*.type=pvc` → PersistentVolumeClaim
  - `autoscaling.enabled=true` → HorizontalPodAutoscaler
- Chart-specific logic (StatefulSet vs Deployment)

**Output:**
```
🧪 TDD: Comprehensive validation...
Testing chart: summon
  Validating basic-deployment...
    ✅ Workload resource present (deployment)
    ✅ Service resource present
    ✅ ServiceAccount resource present
  ✅ summon-basic-deployment

  Validating deployment-with-storage...
    ✅ Workload resource present (deployment)
    ✅ Service resource present
    ✅ All 2 PVC resources present
  ✅ summon-deployment-with-storage
```

### Layer 3: Snapshot Testing

**Purpose:** Detect unintended changes and validate K8s API compliance

**Commands:**
```bash
make test-snapshots                              # Test all snapshots
make generate-snapshots CHART=summon             # Generate snapshots
make update-snapshot CHART=summon EXAMPLE=basic  # Update specific
make show-snapshot-diff CHART=summon EXAMPLE=basic  # Show diff
```

**What it validates:**
- Output matches expected YAML (snapshot comparison)
- Resources valid per K8s API schema (`helm install --dry-run`)
- No unintended changes to resource generation

**How it works:**
1. `helm template` renders chart with example
2. Output compared to `output-test/<chart>/<example>.expected.yaml`
3. `helm install --dry-run` validates against K8s API
4. Diff shown if mismatch detected

**Example workflow:**
```bash
# Generate initial snapshot
make generate-snapshots CHART=summon

# Modify template
# ...

# Test shows diff
make test-snapshots
# Output: ❌ summon-basic-deployment (output differs from expected)

# Review diff
make show-snapshot-diff CHART=summon EXAMPLE=basic-deployment

# If change intentional, update snapshot
make update-snapshot CHART=summon EXAMPLE=basic-deployment

# Or update all snapshots
make update-all-snapshots
```

### Layer 4: Glyph Testing

**Purpose:** Test infrastructure templates via kaster orchestration

**Commands:**
```bash
make test-glyphs-all                    # Test all glyphs
make glyphs <name>                      # Test specific glyph
make list-glyphs                        # List available glyphs
make generate-expected GLYPH=<name>     # Generate expected outputs
make show-glyph-diff GLYPH=<name> EXAMPLE=<example>  # Show diff
```

**What it validates:**
- Glyph renders correctly via kaster
- Output matches expected YAML
- Runic indexer queries work
- Context (spellbook, chapter, lexicon) passed correctly

**CRITICAL:** Glyphs must be tested through kaster, not directly.

**Example:**
```bash
# Test vault glyph
make glyphs vault

# Output:
# Testing glyph: vault via kaster
#   ✅ vault-secrets (rendered successfully)
#   ✅ vault-prolicy-test (output matches expected)
#   ✅ vault-random-secrets (rendered successfully)

# Generate expected outputs
make generate-expected GLYPH=vault

# Show diff if output changed
make show-glyph-diff GLYPH=vault EXAMPLE=secrets
```

### Layer 5: Integration Testing

**Purpose:** Test complete book/chapter/spell structures

**Commands:**
```bash
make test-all         # All tests (comprehensive + snapshots + glyphs + tarot)
```

**What it validates:**
- Complete deployment configurations
- Multi-source applications
- Lexicon integration
- Values hierarchy
- Appendix propagation

## Automatic Test Discovery

### test-status Command

**Purpose:** Show testing coverage for all components

**Command:**
```bash
make test-status
```

**Output:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Testing Status Report
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📦 Main Charts:
  ✅ summon: 17 examples (17 snapshots)
  ⚠️  kaster: 1 examples (no snapshots)
  ❌ librarian: NO examples/

🎭 Glyphs:
  ✅ argo-events: 5 examples (5 snapshots)
  ✅ vault: 11 examples (11 snapshots)
  ✅ istio: 2 examples (2 snapshots)
  ⚠️  certManager: 2 examples (no snapshots)
  ❌ keycloak: NO examples/

🔮 Trinkets:
  ⚠️  microspell: 8 examples (no snapshots)
  ⚠️  tarot: 14 examples (no snapshots)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Legend:
  ✅ = Examples + Snapshots complete
  ⚠️  = Examples exist, snapshots needed
  ❌ = No examples (needs TDD work)
```

**Automatic discovery:**
- Scans all charts in `charts/`
- Scans all glyphs in `charts/glyphs/`
- Scans all trinkets in `charts/trinkets/`
- Checks for `examples/` directories
- Checks for snapshot files

## TDD Workflow Examples

### Adding New Chart Feature

**Complete RED-GREEN-REFACTOR cycle:**

```bash
# === RED PHASE ===
# 1. Create test case
make create-example CHART=summon EXAMPLE=ingress-support

# 2. Define expected behavior
cat > charts/summon/examples/ingress-support.yaml <<EOF
name: web-app
image:
  repository: nginx
  tag: alpine

service:
  enabled: true
  port: 80

ingress:
  enabled: true
  hosts:
    - host: app.example.com
      paths:
        - path: /
          pathType: Prefix
EOF

# 3. Verify test fails (feature doesn't exist)
make tdd-red
# Output: ❌ summon-ingress-support (expectations failed)
#         ✅ Good! Tests are failing - now implement

# === GREEN PHASE ===
# 4. Implement feature
cat > charts/summon/templates/ingress.yaml <<'EOF'
{{- if .Values.ingress.enabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "common.name" . }}
spec:
  rules:
  {{- range .Values.ingress.hosts }}
    - host: {{ .host }}
      http:
        paths:
        {{- range .paths }}
          - path: {{ .path }}
            pathType: {{ .pathType }}
            backend:
              service:
                name: {{ include "common.name" $ }}
                port:
                  number: {{ $.Values.service.port }}
        {{- end }}
  {{- end }}
{{- end }}
EOF

# 5. Verify test passes
make tdd-green
# Output: ✅ summon-ingress-support

# === REFACTOR PHASE ===
# 6. Clean up implementation
# Add comments, optimize logic, add validation

# 7. Verify all tests still pass
make tdd-refactor
# Output: All tests pass (comprehensive + snapshots + glyphs)

# 8. Generate snapshot for regression testing
make generate-snapshots CHART=summon
```

### Adding New Glyph Feature

**TDD for glyphs:**

```bash
# === RED PHASE ===
# 1. Create test case
cat > charts/glyphs/vault/examples/database-engine.yaml <<EOF
lexicon:
  - name: test-vault
    type: vault
    url: http://vault.vault.svc:8200
    namespace: vault
    authPath: kubernetes
    secretPath: kv
    labels:
      default: book

glyphs:
  vault:
    - type: databaseEngine
      name: postgres-engine
      databaseType: postgresql
      connectionURL: postgresql://postgres.db.svc:5432/mydb
      username: admin
      password: secret
      roles:
        - name: readonly
          dbName: mydb
          defaultTTL: 1h
EOF

# 2. Test (expect failure - template doesn't exist)
make glyphs vault
# Output: ❌ vault-database-engine (template "vault.databaseEngine" not found)

# === GREEN PHASE ===
# 3. Implement template
cat > charts/glyphs/vault/templates/database-engine.tpl <<'EOF'
{{- define "vault.databaseEngine" -}}
{{- $root := index . 0 -}}
{{- $glyphDefinition := index . 1 }}
---
apiVersion: redhatcop.redhat.io/v1alpha1
kind: DatabaseSecretEngineConfig
metadata:
  name: {{ $glyphDefinition.name }}
spec:
  # Implementation
{{- end }}
EOF

# 4. Test (expect success)
make glyphs vault
# Output: ✅ vault-database-engine

# === REFACTOR PHASE ===
# 5. Generate expected output
make generate-expected GLYPH=vault

# 6. Verify diff validation works
make glyphs vault
# Output: ✅ vault-database-engine (output matches expected)
```

## Testing Commands Reference

### Core Testing

| Command | Purpose | Exit Code on Failure |
|---------|---------|---------------------|
| `make test` | Comprehensive TDD tests | Non-zero |
| `make test-all` | All tests (comprehensive + snapshots + glyphs + tarot) | Non-zero |
| `make test-syntax` | Quick syntax validation | Non-zero |
| `make test-comprehensive` | Rendering + resource completeness | Non-zero |
| `make test-snapshots` | Snapshot + K8s schema validation | Non-zero |

### TDD Phases

| Command | Purpose | Exit Code on Failure |
|---------|---------|---------------------|
| `make tdd-red` | Run tests expecting failures | 0 (success) |
| `make tdd-green` | Run tests expecting success | Non-zero |
| `make tdd-refactor` | Run comprehensive test suite | Non-zero |

### Glyph Testing

| Command | Purpose |
|---------|---------|
| `make test-glyphs-all` | Test all glyphs automatically |
| `make glyphs <name>` | Test specific glyph |
| `make list-glyphs` | List all available glyphs |
| `make generate-expected GLYPH=<name>` | Generate expected outputs |
| `make show-glyph-diff GLYPH=<name> EXAMPLE=<example>` | Show diff |

### Snapshot Management

| Command | Purpose |
|---------|---------|
| `make generate-snapshots CHART=<name>` | Generate all snapshots for chart |
| `make update-snapshot CHART=<name> EXAMPLE=<example>` | Update specific snapshot |
| `make update-all-snapshots` | Update all snapshots |
| `make show-snapshot-diff CHART=<name> EXAMPLE=<example>` | Show diff |

### Development Helpers

| Command | Purpose |
|---------|---------|
| `make create-example CHART=<name> EXAMPLE=<example>` | Create new test example |
| `make inspect-chart CHART=<name> EXAMPLE=<example>` | Debug chart output |
| `make debug-chart CHART=<name> EXAMPLE=<example>` | Verbose debugging |
| `make validate-completeness` | Ensure expected resources generated |
| `make lint` | Helm lint all charts |
| `make watch` | Auto-run tests on file changes |
| `make clean-output-tests` | Clean generated test outputs |
| `make test-status` | Show testing status for all charts/glyphs/trinkets |

### Tarot Testing

| Command | Purpose |
|---------|---------|
| `make test-tarot` | Run all Tarot tests |

### Covenant Testing

| Command | Purpose |
|---------|---------|
| `make test-covenant` | Test all covenant books |
| `make test-covenant-book BOOK=<name>` | Test specific covenant book |
| `make test-covenant-chapter BOOK=<name> CHAPTER=<chapter>` | Test specific chapter |
| `make test-covenant-all-chapters BOOK=<name>` | Test main + all chapters |
| `make test-covenant-debug BOOK=<name>` | Debug covenant rendering |
| `make list-covenant-books` | List available covenant books |

## Continuous Testing

### Watch Mode

**Purpose:** Auto-run tests on file changes

**Command:**
```bash
make watch
```

**What it does:**
- Monitors file changes in charts/
- Automatically runs tests when files change
- Provides immediate feedback during development

**Use case:** Development workflow with instant test feedback

### Pre-Commit Validation

**Run before every commit:**

```bash
# Complete validation
make test-all

# Resource completeness check
make validate-completeness

# Helm lint
make lint
```

**Recommended:** Add to git pre-commit hook:

```bash
cat > .git/hooks/pre-commit <<'EOF'
#!/bin/bash
make test-all
EOF
chmod +x .git/hooks/pre-commit
```

## Testing Best Practices

### Write Tests First

**Good:**
```bash
# 1. Write test
make create-example CHART=summon EXAMPLE=new-feature
# 2. See it fail
make tdd-red
# 3. Implement
# 4. See it pass
make tdd-green
```

**Avoid:**
```bash
# Implementing without test
# No way to verify it works correctly
```

### Test Edge Cases

**Comprehensive test coverage:**

```
examples/
├── basic.yaml              # Happy path
├── advanced.yaml           # All features enabled
├── edge-cases.yaml         # Boundary conditions
├── disabled-features.yaml  # All optional features off
└── validation-errors.yaml  # Invalid inputs (should fail)
```

### Keep Tests Focused

**Good (focused):**
```yaml
# pod-disruption-budget.yaml
workload:
  type: deployment
  replicas: 3
podDisruptionBudget:
  enabled: true
  minAvailable: 2
```

**Avoid (unfocused):**
```yaml
# everything-kitchen-sink.yaml
# Tests PDB + volumes + secrets + autoscaling + ...
# Hard to debug when it fails
```

### Use Snapshots for Regression

**Workflow:**
```bash
# After feature is working
make generate-snapshots CHART=summon

# Future changes automatically compared
make test-snapshots
# Detects unintended changes
```

### Test Glyphs via Kaster

**Correct:**
```bash
make glyphs vault
```

**Incorrect (will fail):**
```bash
helm template charts/glyphs/vault  # Missing dependencies!
```

## Troubleshooting Tests

### Tests Failing Unexpectedly

**Check what changed:**

```bash
# Show snapshot diff
make show-snapshot-diff CHART=summon EXAMPLE=basic-deployment

# Show glyph diff
make show-glyph-diff GLYPH=vault EXAMPLE=secrets

# Inspect full output
make inspect-chart CHART=summon EXAMPLE=basic-deployment
```

### Resource Completeness Failures

**Debug:**

```bash
# Check which resources expected
cat tests/scripts/validate-resource-completeness.sh

# Check what was generated
helm template test charts/summon -f charts/summon/examples/my-test.yaml

# Common issues:
# - Conditional not triggering (enabled: false)
# - Typo in configuration key
# - Missing required field
```

### Glyph Test Failures

**Debug:**

```bash
# Render via kaster with debug
helm template test charts/kaster \
  -f charts/glyphs/vault/examples/secrets.yaml \
  --debug

# Check lexicon passed correctly
helm template test charts/kaster \
  -f charts/glyphs/vault/examples/secrets.yaml \
  | yq '.Values.lexicon'

# Check template exists
grep -r "define.*vault.secret" charts/glyphs/vault/
```

### Snapshot Mismatches

**When output intentionally changed:**

```bash
# Update specific snapshot
make update-snapshot CHART=summon EXAMPLE=basic-deployment

# Or update all snapshots
make update-all-snapshots
```

**When output unexpectedly changed:**

```bash
# Review diff carefully
make show-snapshot-diff CHART=summon EXAMPLE=basic-deployment

# Investigate what caused change
git diff charts/summon/templates/
```

## Testing Anti-Patterns

### Anti-Pattern 1: Implementation First

**Avoid:**
```bash
# Implement feature
# Then write test
# Test always passes (might be wrong)
```

**Do:**
```bash
# Write test (RED)
make tdd-red
# Implement (GREEN)
make tdd-green
# Refactor (BLUE)
make tdd-refactor
```

### Anti-Pattern 2: Ignoring Failures

**Avoid:**
```bash
make test-all
# 5 tests failing
# Commit anyway
```

**Do:**
```bash
make test-all
# Fix all failures
# Then commit
```

### Anti-Pattern 3: No Edge Cases

**Avoid:**
```
examples/
└── basic.yaml  # Only happy path
```

**Do:**
```
examples/
├── basic.yaml
├── advanced.yaml
├── edge-cases.yaml
└── disabled.yaml
```

### Anti-Pattern 4: Manual Testing Only

**Avoid:**
```bash
# Manually run helm template
# Manually check output
# No automated validation
```

**Do:**
```bash
# Automated TDD tests
make test-all
```

## Related Documentation

- [TDD_COMMANDS.md](TDD_COMMANDS.md) - Quick command reference
- [GLYPH_DEVELOPMENT.md](GLYPH_DEVELOPMENT.md) - Glyph testing specifics
- [CLAUDE.md](../CLAUDE.md) - TDD development philosophy
- [README.md](../README.md) - Architecture overview

## Summary

**Testing Philosophy:**
- TDD is mandatory - write tests first
- Automatic discovery of all components
- Multiple validation layers (syntax, completeness, snapshots, integration)
- Red-Green-Refactor cycle for all features

**Key Commands:**
- `make tdd-red` - Expect failures (write tests first)
- `make tdd-green` - Expect success (implement features)
- `make tdd-refactor` - Verify all tests (improve code)
- `make test-status` - Check coverage
- `make test-all` - Run everything before commit

**Remember:** Tests are not just validation - they're design tools that lead to better, more reliable code.
