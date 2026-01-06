# TDD Command Reference

## TDD Workflow

runik-system follows Test-Driven Development with Red-Green-Refactor cycle.

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

---

## Modular Test Dispatcher

New semantic testing syntax for precise control:

```bash
make test [MODE] [TYPE] [COMPONENTS...] [FLAGS]
```

### Modes

| Mode | What It Does | Speed |
|------|--------------|-------|
| `syntax` | Template syntax only | Fast (3s) |
| `comprehensive` | Rendering + resource checks | Medium (8s) |
| `snapshots` | Output comparison + K8s validation | Medium (10s) |
| `all` | All of the above | Slow (20s+) |

**Default:** `comprehensive`

### Types

| Type | Tests | Examples |
|------|-------|----------|
| `glyph` | Reusable templates | vault, istio |
| `trinket` | Specialized charts | tarot, microspell |
| `chart` | Main charts | summon, kaster |
| `spell` | Individual deployments | example-api |
| `book` | Configuration books | fwck, example-tdd-book |

**Plural forms OK:** `glyphs`, `trinkets`, `charts` → auto-normalized

### Common Patterns

**Test single component:**
```bash
make test glyph vault                    # Comprehensive test
make test syntax glyph vault             # Syntax only
make test snapshots trinket tarot        # Snapshot test
```

**Test multiple components:**
```bash
make test glyph vault istio postgresql   # Multiple glyphs
make test comprehensive chart summon kaster
```

**Test all (auto-discovery):**
```bash
make test all glyph                      # All modes, all glyphs
make test glyphs                         # Comprehensive, all glyphs
make test syntax glyphs                  # Syntax, all glyphs
make test trinkets                       # Comprehensive, all trinkets
```

**Context-based (regular books):**
```bash
make test spell example-api --book example-tdd-book
make test book fwck --chapter intro
```

**Covenant books (special type, uses covenant chart instead of librarian):**
```bash
# Main ApplicationSet view
make test-covenant BOOK=covenant-tyl

# Specific chapter filters (ApplicationSet children)
make test-covenant BOOK=covenant-tyl CHAPTER=tyl
make test-covenant BOOK=covenant-tyl CHAPTER=fwck
make test-covenant BOOK=covenant-tyl CHAPTER=radio-pirata

# Test main + all chapters
make test-covenant BOOK=covenant-tyl --all-chapters

# Use external bookrack path if symlinked
export COVENANT_BOOKRACK_PATH=/path/to/proto-the-yaml-life/bookrack
```

### Flags Reference

**Spell testing:**
- `--book <name>` - Specify book (default: example-tdd-book)
- `--debug` - Show full helm template output

**Book testing:**
- `--chapter <name>` - Test specific chapter only
- `--type <type>` - Filter by resource type
- `--debug` - Show debug output

### Decision Tree

```
What do you want to test?
│
├─ Reusable template (vault, istio)
│  └─ make test glyph <name>
│
├─ Specialized chart (tarot, microspell)
│  └─ make test trinket <name>
│
├─ Main chart (summon, kaster)
│  └─ make test chart <name>
│
├─ Specific deployment (example-api)
│  └─ make test spell <name> --book <book>
│
└─ Entire book (covenant-tyl)
   └─ make test book <name>
```

---

## Troubleshooting

### "Glyph not found"
Check spelling and list available:
```bash
ls charts/glyphs/
make list-glyphs
```

### "No examples found"
Create examples directory:
```bash
make create-example CHART=<name> EXAMPLE=<example>
ls charts/glyphs/<name>/examples/
```

### "Snapshot differs"
Review diff and update if intentional:
```bash
diff output-test/<name>/<example>.yaml \
     output-test/<name>/<example>.expected.yaml
make update-snapshot CHART=<name> EXAMPLE=<example>
```

### "Template rendering failed"
Check syntax first, then debug:
```bash
make test syntax glyph <name>
make test glyph <name> --debug
```

### "integer expression expected" (spell tests)
Known bug in resource counting. Tests still pass, ignore error message.

### "entr not found" (watch command)
Install entr for file watching:
```bash
# Debian/Ubuntu
apt-get install entr

# macOS
brew install entr
```

---

## Quick Reference

**Most common commands:**
```bash
# Development cycle
make tdd-red           # Write test, expect fail
make tdd-green         # Implement, expect pass
make tdd-refactor      # Improve, still passing

# Quick validation
make test syntax glyph vault
make test chart summon

# Full validation before commit
make test-all

# Debugging
make inspect-chart CHART=summon EXAMPLE=basic-deployment
make test spell example-api --book example-tdd-book --debug
```

**Performance tips:**
- Use `syntax` mode during development (fastest)
- Use `comprehensive` for regular testing (medium)
- Use `snapshots` before commits (thorough)
- Use `all` before releases (complete)

**Exit codes:**
- `0` - All tests passed
- `1` - Test failures occurred
- `2` - Tests skipped (no examples)

---

## See Also

- [Testing Guide](TESTING.md) - TDD methodology and architecture
- [Examples Index](EXAMPLES_INDEX.md) - All examples catalog
- [CODING_STANDARDS.md](CODING_STANDARDS.md) - Code conventions
