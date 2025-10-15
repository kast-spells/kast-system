# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

kast-system is a Test-Driven Development (TDD) Kubernetes deployment framework built around Helm charts, described as "Kubernetes arcane spelling technology". The project uses a modular architecture with reusable Helm template components called "glyphs" and follows strict TDD practices for reliability and correctness.

## TDD Development Philosophy

**kast-system is built TDD-first.** Every feature, template, and glyph follows the Red-Green-Refactor cycle:

1. **🔴 RED**: Write failing tests/examples first - define expected behavior
2. **🟢 GREEN**: Implement minimal code to make tests pass  
3. **🔵 REFACTOR**: Improve code while maintaining test coverage

### Core TDD Commands

```bash
# TDD Workflow Commands
make tdd-red         # Run tests expecting failures (Red phase)
make tdd-green       # Run tests expecting success (Green phase)
make tdd-refactor    # Run tests after refactoring (Blue phase)

# Testing Status & Discovery
make test-status     # Show testing status for all charts/glyphs/trinkets (automatic discovery)

# Core Testing
make test            # Run comprehensive TDD tests (rendering + resource completeness)
make test-all        # Run ALL tests (comprehensive + snapshots + glyphs + tarot)
make test-comprehensive  # Test rendering + resource completeness (original TDD)
make test-snapshots  # Test snapshots + K8s schema validation (helm dry-run)
make test-syntax     # Quick syntax validation

# Snapshot Testing
make generate-snapshots CHART=<name>     # Generate snapshots for chart
make update-snapshot CHART=<name> EXAMPLE=<example>  # Update specific snapshot
make update-all-snapshots                # Update all snapshots
make show-snapshot-diff CHART=<name> EXAMPLE=<example>  # Show diff

# Validation
make validate-completeness  # Ensure all expected resources are generated
make lint                  # Helm lint all charts

# Glyph Testing (Automatic Discovery)
make glyphs <name>         # Test specific glyph (e.g., make glyphs vault)
make test-glyphs-all       # Test all glyphs automatically
make list-glyphs           # List all available glyphs
make generate-expected GLYPH=<name>     # Generate expected outputs for glyph
make show-glyph-diff GLYPH=<name> EXAMPLE=<example>  # Show diff

# Development Helpers
make create-example CHART=summon EXAMPLE=my-test  # Create new test
make inspect-chart CHART=summon EXAMPLE=basic-deployment  # Debug output
make watch          # Auto-run tests on file changes
make clean-output-tests    # Clean generated test outputs
```

## Project Structure

- **charts/** - Core Helm charts (all TDD-tested)
  - **glyphs/** - Reusable Helm template library (common, summon, vault, istio, certManager, crossplane, gcp, freeForm)
  - **kaster/** - Main chart for the glyphs system  
  - **summon/** - Chart for creating microservices/containers
  - **trinkets/** - Additional utilities (microspell, etc.)
- **librarian/** - ArgoCD Apps of Apps configuration
- **bookrack/** - Configuration management using "books" pattern
- **tests/** - TDD testing infrastructure
  - **scripts/** - Validation and testing scripts
- **output-test/** - Generated glyph test outputs (created automatically)
  - **<glyph-name>/** - Per-glyph test results
    - **<example>.yaml** - Actual rendered output
    - **<example>.expected.yaml** - Expected output for diff validation

## Testing System Overview

kast-system uses a **dual testing approach** that automatically discovers all charts, glyphs, and trinkets:

### Testing Layers

1. **Syntax Validation** (`make test-syntax`)
   - Validates Helm template syntax
   - Fast feedback during development
   - No K8s cluster required

2. **Comprehensive Testing** (`make test-comprehensive`)
   - Rendering validation
   - Resource completeness checks
   - Validates expected K8s resources are generated

3. **Snapshot Testing** (`make test-snapshots`)
   - **Snapshot comparison**: Output matches expected YAML
   - **K8s schema validation**: `helm install --dry-run` validates against K8s API
   - Detects unintended changes and invalid values

4. **Glyph Testing** (`make test-glyphs-all`)
   - Tests all glyphs through kaster orchestration
   - Automatic discovery of glyphs with examples/
   - Snapshot-based validation

### Current Testing Status

Run `make test-status` to see automatic discovery of all tests:

```bash
$ make test-status
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
  ...

🔮 Trinkets:
  ⚠️  microspell: 8 examples (no snapshots)
  ⚠️  tarot: 14 examples (no snapshots)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Legend:
  ✅ = Examples + Snapshots complete
  ⚠️  = Examples exist, snapshots needed
  ❌ = No examples (needs TDD work)
```

## TDD Development Workflow

### Understanding the TDD Cycle Mechanics

The TDD commands (`tdd-red`, `tdd-green`, `tdd-refactor`) have different behaviors that enforce the Red-Green-Refactor cycle:

#### How `tdd-red` Works (Red Phase)

```makefile
tdd-red: ## TDD Red: Run tests expecting failures
	@echo "🔴 TDD RED: Running tests expecting failures..."
	@$(MAKE) test-comprehensive || echo "✅ Good! Tests are failing - now implement"
```

**Key mechanic:** Uses the `||` operator (logical OR)
- Runs `test-comprehensive`
- If tests **FAIL** → executes the echo message (celebrates failure!)
- If tests **PASS** → shows nothing special (unexpected at this phase)
- **Philosophy:** You're writing tests for features that don't exist yet, so failures are GOOD

**When to use:**
- After writing new test examples
- Before implementing new features
- To verify your test actually tests something (not a false positive)

#### How `tdd-green` Works (Green Phase)

```makefile
tdd-green: ## TDD Green: Run tests expecting success
	@echo "🟢 TDD GREEN: Running tests expecting success..."
	@$(MAKE) test-comprehensive
```

**Key mechanic:** No `||` operator - direct execution
- Runs `test-comprehensive`
- If tests **PASS** → exits successfully (good!)
- If tests **FAIL** → Make will exit with error code (bad!)
- **Philosophy:** You've implemented the feature, tests should now pass

**When to use:**
- After implementing features
- To verify your implementation works
- Before committing code

#### How `tdd-refactor` Works (Refactor Phase)

```makefile
tdd-refactor: ## TDD Refactor: Run tests after refactoring
	@echo "🔵 TDD REFACTOR: Running tests after refactoring..."
	@$(MAKE) test-all
```

**Key mechanic:** Runs the comprehensive test suite (`test-all`)
- Executes ALL tests (comprehensive + snapshots + glyphs)
- Ensures your refactoring didn't break anything
- **Philosophy:** Code improvement should not change behavior

**When to use:**
- After cleaning up code
- After optimizing implementations
- Before finalizing work

#### Comparison Table

| Command | What Runs | Expected Result | Exit Code if Fail |
|---------|-----------|-----------------|-------------------|
| `tdd-red` | `test-comprehensive` | Failures are OK | 0 (success) |
| `tdd-green` | `test-comprehensive` | Must pass | Non-zero (error) |
| `tdd-refactor` | `test-all` | Must pass | Non-zero (error) |

#### Live Example: Adding PodDisruptionBudget

```bash
# RED PHASE - Write test first
cat > charts/summon/examples/test-pod-disruption.yaml <<EOF
workload:
  enabled: true
  type: deployment
  replicas: 3

podDisruptionBudget:
  enabled: true
  minAvailable: 2
EOF

# Confirm test fails (feature doesn't exist yet)
make tdd-red
# Output: ❌ summon-test-pod-disruption (expectations failed)
#         ✅ Good! Tests are failing - now implement

# GREEN PHASE - Implement feature
# Edit charts/summon/templates/pod-disruption-budget.yaml
# Add template logic for PDB

# Verify test passes
make tdd-green
# Output: ✅ summon-test-pod-disruption

# REFACTOR PHASE - Improve implementation
# Clean up code, add comments, optimize
make tdd-refactor
# Output: All tests pass including snapshots and glyphs
```

### 1. Adding New Features (TDD Approach)

**ALWAYS follow this sequence:**

```bash
# 1. RED PHASE - Write failing test first
make create-example CHART=summon EXAMPLE=my-new-feature
# Edit charts/summon/examples/my-new-feature.yaml with expected configuration

# 2. Confirm test fails (should fail because feature doesn't exist yet)
make tdd-red
# Should show: ❌ summon-my-new-feature (expectations failed)

# 3. GREEN PHASE - Implement minimal code to make test pass
# Edit summon templates to support the new feature
# Add necessary template logic

# 4. Verify test passes
make tdd-green
# Should show: ✅ summon-my-new-feature

# 5. REFACTOR PHASE - Clean up implementation
# Improve code quality, add documentation, optimize
make tdd-refactor
# Should still show: ✅ summon-my-new-feature

# 6. SNAPSHOT PHASE - Lock in the expected output
make generate-snapshots CHART=summon
# Creates output-test/summon/my-new-feature.expected.yaml
```

### 2. TDD Workflow for Glyphs

**NEW: Dynamic glyph testing system allows testing specific glyphs without predefined rules:**

```bash
# 1. RED PHASE - Add new glyph feature example
# Edit charts/glyphs/vault/examples/new-feature.yaml with expected configuration

# 2. Test to see failure (Red)
make glyphs vault
# Should show: ❌ vault-new-feature (rendering failed)

# 3. GREEN PHASE - Implement glyph feature
# Edit glyph templates in charts/glyphs/vault/templates/

# 4. Test to see success (Green)
make glyphs vault
# Should show: ✅ vault-new-feature (rendered successfully)

# 5. Generate expected output for diff validation
make generate-expected GLYPH=vault

# 6. REFACTOR PHASE - Verify diff validation works
make glyphs vault
# Should show: ✅ vault-new-feature (output matches expected)
```

### 3. Glyph Output Validation System

The system now includes comprehensive diff-based validation:

```bash
# List available glyphs
make list-glyphs

# Test specific glyph with automatic example discovery
make glyphs vault
make glyphs istio
make glyphs certManager

# Generate expected outputs for comparison
make generate-expected GLYPH=vault

# Show differences when outputs change
make show-glyph-diff GLYPH=vault EXAMPLE=secrets

# Clean output test files
make clean-output-tests
```

### 4. Modifying Existing Features

```bash
# 1. Add test case for new behavior first
make create-example CHART=summon EXAMPLE=existing-feature-enhancement

# 2. Run tests to see current behavior
make test-comprehensive

# 3. Modify templates to support new behavior
# Edit relevant template files

# 4. Verify all tests pass (new and existing)  
make test-comprehensive
```

### 5. TDD Testing Levels

The testing system validates multiple levels:

1. **Syntax Validation**: Does Helm template render without errors?
2. **Resource Completeness**: Are all expected K8s resources generated?
3. **Configuration-Driven Expectations**: 
   - `workload.enabled=true` → Should generate Deployment/StatefulSet
   - `service.enabled=true` → Should generate Service resource
   - `volumes.*.type=pvc` → Should generate PersistentVolumeClaim
   - `autoscaling.enabled=true` → Should generate HorizontalPodAutoscaler
4. **Chart-Specific Logic**: StatefulSet vs Deployment based on `workload.type`

### 4. Examples as Documentation and Tests

Every chart MUST have comprehensive examples that serve dual purposes:
- **Documentation**: Show users how to use features
- **Tests**: Validate that features work correctly

```
charts/summon/examples/
├── basic-deployment.yaml       # Simple deployment (tests core functionality)
├── complex-production.yaml     # Full-featured (tests autoscaling, volumes, etc.)
├── deployment-with-storage.yaml # Tests PVC volumes
└── statefulset-with-storage.yaml # Tests StatefulSet workloads

charts/trinkets/microspell/examples/
├── basic-microservice.yaml     # Simple microservice
└── advanced-microservice.yaml  # With secrets and routing
```

## Architecture and Patterns

### Glyphs System
The project uses a unique "glyphs" pattern where reusable Helm templates are organized as separate charts:
- Each glyph provides specific functionality (e.g., vault integration, GCP resources)
- Glyphs are imported as dependencies in other charts
- Templates follow naming pattern: `<glyph>.<template>.tpl`
- **All glyphs must have examples for testing**

### Template Conventions
- All templates must include copyright header with GNU GPL v3 license
- Use named templates for reusability: `{{- define "glyph.templateName" -}}`
- Follow naming conventions in charts/glyphs/STYLE_GUIDE.md
- Values should be namespaced under chart name
- **Every template must be testable through examples**

### Book Pattern
Configuration is organized as "books" in bookrack/:
- Each book has an index.yaml defining structure
- Chapters contain values.yaml files for different environments/scenarios
- Books reference specific chart versions

### GitOps Integration
- Designed for ArgoCD deployment (see librarian/)
- GitHub Actions automatically sync components to separate repositories
- Changes trigger automated tagging and releases

## TDD Development Tips

### When Adding New Glyphs:
1. **Write example first** - Create examples/ directory with test cases
2. **Run TDD red phase** - Verify tests fail
3. **Implement minimal glyph** - Create basic template structure
4. **Make tests pass** - Implement full functionality
5. **Refactor** - Clean up and optimize

### When Modifying Existing Glyphs:
1. **Add test case first** - New example showing desired behavior
2. **Verify current behavior** - Run existing tests
3. **Modify templates** - Update template logic
4. **Ensure all tests pass** - Both new and existing functionality

### When Adding Template Logic:
1. **Parameter validation** - Check required values exist
2. **Resource completeness** - Generate all expected K8s resources
3. **Error handling** - Graceful fallbacks for optional features
4. **Documentation** - Comments explaining complex logic

### Testing During Development:

```bash
# Quick syntax validation during development
make test-syntax

# Full validation including resource completeness
make test

# Test specific chart and example
make inspect-chart CHART=summon EXAMPLE=basic-deployment

# Debug with verbose output  
make debug-chart CHART=summon EXAMPLE=complex-production

# Auto-run tests on file changes (useful during development)
make watch
```

### Pre-commit Validation:

```bash
# ALWAYS run before committing
make test-all

# Validate resource completeness
make validate-completeness

# Lint all charts
make lint
```

## Validation System

The TDD system includes comprehensive validation:

### Resource Completeness Validation
The validation script (`tests/scripts/validate-resource-completeness.sh`) checks:
- **Workload Resources**: Deployment when `workload.type=deployment`, StatefulSet when `workload.type=statefulset`
- **Service Resources**: Service when `service.enabled=true`
- **Storage Resources**: PVC resources when `volumes.*.type=pvc`
- **Scaling Resources**: HPA when `autoscaling.enabled=true`
- **Security Resources**: ServiceAccount when `serviceAccount.enabled=true`

### Chart-Specific Validations:
- **Summon**: Validates workload types, storage configurations, service configurations
- **Microspell**: Validates microservice patterns, secrets integration, routing
- **Kaster**: Validates glyph orchestration and resource generation

### Example Validation Output:
```
🧪 TDD: Comprehensive validation...
Testing chart: summon
  Validating basic-deployment...
    ✅ Workload resource present (deployment)
    ✅ Service resource present  
    ✅ ServiceAccount resource present
  ✅ summon-basic-deployment

  Validating complex-production...
    ✅ Workload resource present (deployment)
    ✅ Service resource present
    ✅ All 2 PVC resources present
    ✅ HorizontalPodAutoscaler resource present  
  ✅ summon-complex-production
```

## Important TDD Rules

### DO:
- **Write tests first** - Always create examples before implementing features
- **Run tdd-red** - Verify tests fail before implementing
- **Make minimal changes** - Implement just enough to make tests pass
- **Refactor safely** - Improve code while maintaining test coverage
- **Test resource completeness** - Ensure expected K8s resources are generated
- **Use examples as documentation** - Examples should be comprehensive and realistic

### DON'T:
- **Skip the red phase** - Always see tests fail first
- **Implement without tests** - Every feature needs examples
- **Break existing tests** - Ensure backward compatibility
- **Skip validation** - Always run comprehensive validation
- **Commit failing tests** - Fix all test failures before committing

## Testing Anti-Patterns to Avoid

❌ **Writing implementation first, then tests**
✅ **Write failing tests first, then implement**

❌ **Testing only syntax/rendering**  
✅ **Test resource completeness and expected behavior**

❌ **Single example per chart**
✅ **Multiple examples covering different scenarios**

❌ **Manual testing only**
✅ **Automated TDD testing with make commands**

❌ **Ignoring test failures**
✅ **Fix all failures before proceeding**

## Important Notes

- This is a GitOps-focused project - avoid manual kubectl operations
- All Kubernetes resources should be managed through Helm templates
- The project uses GNU GPL v3 license - ensure all files have proper headers
- Follow the comprehensive style guide at charts/glyphs/STYLE_GUIDE.md
- **TDD is mandatory** - all features must have tests/examples
- We don't use dependencies in Chart.yaml files - they are static symlinks
- When templating and testing, use the-yaml-life book for examples
- **Resource completeness validation is critical** - ensure all expected resources are generated
- **CRITICAL: Glyphs must be tested through kaster**, not directly. Use `make glyphs <name>` which tests via kaster chart
- **Never test glyphs directly** with `helm template charts/glyphs/<name>` - this will fail due to missing dependencies

## Getting Started with TDD Development

```bash
# 1. Verify TDD system works
make test

# 2. See all available TDD commands  
make help

# 3. Explore available glyphs
make list-glyphs

# 4. Test specific glyph to understand current state
make glyphs vault

# 5. Create your first feature using TDD (for charts)
make create-example CHART=summon EXAMPLE=my-feature

# 6. Follow TDD cycle: Red -> Green -> Refactor
make tdd-red      # Should fail initially
# Implement feature
make tdd-green    # Should pass after implementation  
make tdd-refactor # Should still pass after cleanup

# 7. For glyph development, use the glyph TDD workflow:
# - Edit charts/glyphs/<name>/examples/new-feature.yaml
# - make glyphs <name>  # Red phase - should fail
# - Implement glyph templates
# - make glyphs <name>  # Green phase - should pass
# - make generate-expected GLYPH=<name>  # Lock in expected output
# - make glyphs <name>  # Refactor phase - should match expected
```

Remember: **TDD isn't just testing - it's a design methodology that leads to better, more reliable code.**

---

## Testing Coverage Status (Auto-Discovered)

The testing system automatically discovers all charts, glyphs, and trinkets. Use `make test-status` to see current coverage.

### Fully Tested (✅ Examples + Snapshots)
**Main Charts:**
- summon: 17 examples with full snapshot coverage

**Glyphs:**
- argo-events: 5 examples
- vault: 11 examples
- istio: 2 examples
- common: 2 examples

### Needs Snapshots (⚠️ Examples exist, snapshots missing)
**Main Charts:**
- kaster: 1 example

**Glyphs:**
- certManager: 2 examples
- crossplane: 2 examples
- freeForm: 2 examples
- gcp: 3 examples
- runic-system: 3 examples

**Trinkets:**
- microspell: 8 examples
- tarot: 14 examples

**Action:** Run `make update-all-snapshots` to generate all missing snapshots.

### Needs TDD Work (❌ No examples/)
**Main Charts:**
- librarian: Infrastructure chart (may not need examples)

**Glyphs:**
- default-verbs: Utility glyph
- keycloak: Integration glyph
- postgres-cloud: Integration glyph
- trinkets: Meta glyph

**Trinkets:**
- covenant: New trinket (in development)

**Action:** Create examples/ directories and add test cases following TDD workflow.

### How to Improve Coverage

```bash
# 1. Check current status
make test-status

# 2. For items with examples but no snapshots
make update-all-snapshots

# 3. For items without examples, create them (TDD approach)
make create-example CHART=kaster EXAMPLE=basic-glyph
# Edit the example file
make tdd-red
# Implement feature
make tdd-green
make generate-snapshots CHART=kaster

# 4. Verify everything works
make test-all
```