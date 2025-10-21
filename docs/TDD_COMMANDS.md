# TDD Command Reference

## TDD Workflow

kast-system follows Test-Driven Development with Red-Green-Refactor cycle.

### Basic Cycle

```bash
# Red: Write failing test
make create-example CHART=summon EXAMPLE=my-feature
# Edit charts/summon/examples/my-feature.yaml

# Red: Verify test fails
make tdd-red

# Green: Implement feature
# Edit templates to support the feature

# Green: Verify test passes
make tdd-green

# Refactor: Improve code
make tdd-refactor
```

## Testing Commands

### Core Testing

```bash
make test                    # Comprehensive TDD tests (rendering + resource completeness)
make test-all                # All tests (comprehensive + snapshots + glyphs + tarot)
make test-syntax             # Quick syntax validation
make test-comprehensive      # Rendering + resource completeness validation
make test-snapshots          # Snapshot + K8s schema validation (helm dry-run)
```

### Glyph Testing

```bash
make test-glyphs-all         # Test all glyphs automatically
make glyphs <name>           # Test specific glyph (e.g., make glyphs vault)
make list-glyphs             # List all available glyphs
make test-status             # Show testing status for all charts/glyphs/trinkets
```

### Tarot Testing

```bash
make test-tarot              # Run all Tarot tests
```

### Snapshot Management

```bash
make generate-snapshots CHART=<name>                    # Generate snapshots for chart
make update-snapshot CHART=<name> EXAMPLE=<example>     # Update specific snapshot
make update-all-snapshots                               # Update all snapshots
make show-snapshot-diff CHART=<name> EXAMPLE=<example>  # Show diff
```

### Glyph Output Validation

```bash
make generate-expected GLYPH=<name>                     # Generate expected outputs
make show-glyph-diff GLYPH=<name> EXAMPLE=<example>     # Show diff
make clean-output-tests                                 # Clean generated test outputs
```

## Development Commands

### Creating Examples

```bash
make create-example CHART=summon EXAMPLE=my-test        # Create new test example
```

### Debugging

```bash
make inspect-chart CHART=summon EXAMPLE=basic-deployment    # Debug chart output
make debug-chart CHART=summon EXAMPLE=complex-production    # Verbose debugging
```

### Validation

```bash
make validate-completeness   # Ensure all expected resources are generated
make lint                    # Helm lint all charts
make watch                   # Auto-run tests on file changes
```

## TDD Phase Commands

### tdd-red
```bash
make tdd-red
```
Runs tests expecting failures. Uses `||` operator so failures are acceptable. Use when:
- After writing new test examples
- Before implementing features
- To verify test actually tests something

### tdd-green
```bash
make tdd-green
```
Runs tests expecting success. Exits with error if tests fail. Use when:
- After implementing features
- To verify implementation works
- Before committing code

### tdd-refactor
```bash
make tdd-refactor
```
Runs comprehensive test suite. Ensures refactoring didn't break anything. Use when:
- After cleaning up code
- After optimizing implementations
- Before finalizing work

## Glyph Development Workflow

```bash
# 1. Create example
# Edit charts/glyphs/vault/examples/new-feature.yaml

# 2. Test to see failure (Red)
make glyphs vault

# 3. Implement feature
# Edit charts/glyphs/vault/templates/

# 4. Test to see success (Green)
make glyphs vault

# 5. Generate expected output
make generate-expected GLYPH=vault

# 6. Verify diff validation (Refactor)
make glyphs vault
```

## Chart Testing Workflow

```bash
# 1. Create example
make create-example CHART=summon EXAMPLE=my-feature

# 2. Run tests expecting failure
make tdd-red

# 3. Implement feature in templates
# Edit charts/summon/templates/

# 4. Run tests expecting success
make tdd-green

# 5. Generate snapshots
make generate-snapshots CHART=summon

# 6. Refactor and verify
make tdd-refactor
```

## Pre-Commit Checklist

```bash
# Run all validations before committing
make test-all
make validate-completeness
make lint
```

## Continuous Testing

```bash
# Auto-run tests on file changes
make watch
```

## Output Directories

Generated test outputs are stored in:
- `output-test/<glyph-name>/` - Glyph test outputs
- Charts create snapshots in their own directories

Clean outputs:
```bash
make clean-output-tests
```

## Exit Codes

- `make tdd-red`: Exit 0 regardless of test result (failures expected)
- `make tdd-green`: Exit non-zero if tests fail (success required)
- `make tdd-refactor`: Exit non-zero if any test fails (all must pass)

## Examples by Chart

### Summon
```bash
make create-example CHART=summon EXAMPLE=my-app
make test-comprehensive
make generate-snapshots CHART=summon
```

### Kaster
Tested through glyph examples:
```bash
make test-glyphs-all
```

### Microspell
```bash
helm template test charts/trinkets/microspell -f charts/trinkets/microspell/examples/basic-microservice.yaml
```

### Tarot
```bash
make test-tarot
helm template test charts/trinkets/tarot -f charts/trinkets/tarot/examples/minimal-test.yaml
```

## Testing Status

View current test coverage:
```bash
make test-status
```

Output shows:
- ✅ Examples + Snapshots complete
- ⚠️  Examples exist, snapshots needed
- ❌ No examples (needs TDD work)
