# Test Dispatcher Quick Reference Guide

## Command Syntax at a Glance

```bash
make test [MODE] [TYPE] [COMPONENTS...] [FLAGS]
```

## Modes (What to test)

| Mode | What It Does | Speed |
|------|--------------|-------|
| `syntax` | Template syntax only | Fast (3s) |
| `comprehensive` | Rendering + resource checks | Medium (8s) |
| `snapshots` | Output comparison + K8s validation | Medium (10s) |
| `all` | All of the above | Slow (20s+) |

**Default:** `comprehensive`

## Types (What to test)

| Type | Tests | Handler | Examples |
|------|-------|---------|----------|
| `glyph` | Reusable templates | test-glyph.sh | vault, istio |
| `trinket` | Specialized charts | test-trinket.sh | tarot, microspell |
| `chart` | Main charts | test-chart.sh | summon, kaster |
| `spell` | Individual deployments | test-spell.sh | example-api |
| `book` | Configuration books | test-book.sh | covenant-tyl |

**Plural forms OK:** `glyphs`, `trinkets`, `charts` → auto-normalized

## Common Commands

### Test Single Component
```bash
make test glyph vault                    # Comprehensive test for vault glyph
make test syntax glyph vault             # Syntax only
make test snapshots trinket tarot        # Snapshot test for tarot
```

### Test Multiple Components
```bash
make test glyph vault istio postgresql   # Multiple glyphs
make test comprehensive chart summon kaster  # Multiple charts
```

### Test All Components (Auto-Discovery)
```bash
make test all glyph                      # All modes, all glyphs
make test glyphs                         # Comprehensive, all glyphs
make test syntax glyphs                  # Syntax, all glyphs
make test trinkets                       # Comprehensive, all trinkets
```

### Context-Based Testing
```bash
make test spell example-api --book example-tdd-book
make test spell example-api --book example-tdd-book --debug
make test book covenant-tyl
make test book covenant-tyl --chapter tyl --debug
```

### Legacy Commands (Still Work)
```bash
make glyphs vault                        # Same as: test glyph vault
make test-comprehensive                  # Same as: test comprehensive chart
make test-all                            # Runs comprehensive + snapshots + glyphs + lint
```

## Decision Tree

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

## Flags Reference

### Spell Testing Flags
- `--book <name>` - Specify book (default: example-tdd-book)
- `--debug` - Show full helm template output

### Book Testing Flags
- `--chapter <name>` - Test specific chapter only
- `--type <type>` - Filter by resource type (covenant books)
- `--debug` - Show debug output

## Auto-Discovery

When you use `all` or omit components:

```bash
make test glyphs                         # Auto-discovers all glyphs
make test all glyph                      # Auto-discovers all glyphs
make test trinkets                       # Auto-discovers all trinkets
```

**Discovery Logic:**
- Glyphs: Scans `charts/glyphs/*/examples/*.yaml`
- Trinkets: Scans `charts/trinkets/*/examples/*.yaml`
- Charts: Scans `charts/*/examples/*.yaml`
- Books: Scans `bookrack/*/index.yaml`

## TDD Workflow

```bash
# 1. RED: Write test/example, expect failure
make tdd-red

# 2. GREEN: Implement feature, expect success
make tdd-green

# 3. REFACTOR: Improve code, still passing
make tdd-refactor
```

## Output Locations

```bash
output-test/
├── <glyph>/
│   ├── <example>.yaml           # Actual output
│   └── <example>.expected.yaml  # Expected snapshot
├── <trinket>/
│   └── ...
├── <chart>/
│   └── ...
└── spell-<name>-source-<N>-<chart>.yaml
```

## Exit Codes

- `0` - All tests passed
- `1` - Test failures occurred
- `2` - Tests skipped (no examples)

## Common Patterns

### Quick Syntax Check
```bash
make test syntax glyph vault
make test syntax chart summon
```

### Full Validation
```bash
make test all glyph vault
make test all trinket tarot
```

### Snapshot Generation
```bash
make test snapshots glyph vault
make generate-snapshots CHART=summon
```

### Debug Failed Tests
```bash
make test glyph vault --debug
make test spell example-api --book example-tdd-book --debug
```

## Help Commands

```bash
make test help                           # Show dispatcher help
make help                                # Show all Makefile targets
```

## Component Lists

### Available Glyphs (13)
```
argo-events, certManager, common, crossplane, freeForm, gcp,
istio, keycloak, postgresql, runic-system, s3, summon, vault
```

### Available Trinkets (2)
```
microspell, tarot
```

### Available Charts (3)
```
summon, kaster, librarian
```

## Examples by Use Case

### Adding New Feature (TDD)
```bash
# 1. Create example
make create-example CHART=summon EXAMPLE=my-feature

# 2. Test (should fail - red phase)
make tdd-red

# 3. Implement feature in templates
# ... edit templates ...

# 4. Test (should pass - green phase)
make tdd-green

# 5. Generate snapshot
make generate-snapshots CHART=summon

# 6. Refactor
# ... improve code ...
make tdd-refactor
```

### Testing Before Commit
```bash
# Quick check
make test syntax chart

# Full validation
make test-all

# Or new syntax
make test all chart && make test all glyph && make lint
```

### Debugging Rendering Issues
```bash
# Test with debug output
make test spell example-api --book example-tdd-book --debug

# Inspect rendered output
make inspect-chart CHART=summon EXAMPLE=basic-deployment

# Show diff with snapshot
make show-glyph-diff GLYPH=vault EXAMPLE=secrets
```

### Continuous Integration
```bash
# Run in CI pipeline
make test all chart
make test all glyph
make test all trinket
make lint
```

## Troubleshooting

### "Glyph not found"
- Check spelling
- List available: `ls charts/glyphs/`

### "No examples found"
- Create examples: `make create-example CHART=<name> EXAMPLE=<example>`
- Check: `ls charts/glyphs/<name>/examples/`

### "Snapshot differs"
- Review diff: `diff output-test/<name>/<example>.yaml output-test/<name>/<example>.expected.yaml`
- Update if intentional: `make update-snapshot CHART=<name> EXAMPLE=<example>`

### "Template rendering failed"
- Check syntax: `make test syntax glyph <name>`
- Debug: Add `--debug` flag
- Review error output

## Performance Tips

- Use `syntax` mode for quick feedback (fastest)
- Use `comprehensive` for regular testing (medium)
- Use `snapshots` before commits (slower but thorough)
- Use `all` before releases (slowest, most complete)

## Best Practices

1. **Always test before committing**
   ```bash
   make test-all
   ```

2. **Use syntax mode during development**
   ```bash
   make test syntax glyph vault
   ```

3. **Generate snapshots for new features**
   ```bash
   make generate-snapshots CHART=summon
   ```

4. **Test multiple components together**
   ```bash
   make test glyph vault istio certManager
   ```

5. **Follow TDD workflow strictly**
   ```bash
   make tdd-red → implement → make tdd-green → make tdd-refactor
   ```

---

**Quick Reference Version:** 1.0
**Last Updated:** 2025-11-15
**For Full Details:** See AUDIT_REPORT_TEST_DISPATCHER.md
