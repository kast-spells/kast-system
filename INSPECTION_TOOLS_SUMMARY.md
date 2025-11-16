# Inspection Tools Audit - Quick Summary

## Status Overview

| Command | Status | Issue |
|---------|--------|-------|
| `make inspect-chart` | ✅ Working | ❌ Doesn't support trinkets |
| `make debug-chart` | ✅ Working | ❌ Doesn't support trinkets |
| `make show-glyph-diff` | ❌ **BROKEN** | Wrong directory paths |
| `make show-snapshot-diff` | ✅ Working | - |
| `make list-glyphs` | ✅ Working | - |
| `make list-covenant-books` | ⚠️ Partial | Wrong default path |
| `make generate-expected` | ✅ Working | - |
| `make clean-output-tests` | ✅ Working | - |
| `make test-status` | ⚠️ Misleading | Doesn't show actual status |
| `make watch` | ⚠️ Dependency | Requires `entr` (not installed) |

## Critical Fixes Needed

### 1. Fix `show-glyph-diff` (BROKEN)

**Problem:** Command looks for `output-test/glyph-vault/` but files are in `output-test/vault/`

**Fix (Makefile line 172-174):**
```diff
-@if [ -f "output-test/glyph-$(GLYPH)/$(EXAMPLE).yaml" ] && \
-    [ -f "output-test/glyph-$(GLYPH)/$(EXAMPLE).expected.yaml" ]; then
-    diff -u "output-test/glyph-$(GLYPH)/$(EXAMPLE).expected.yaml" \
-            "output-test/glyph-$(GLYPH)/$(EXAMPLE).yaml" || true;
+@if [ -f "output-test/$(GLYPH)/$(EXAMPLE).yaml" ] && \
+    [ -f "output-test/$(GLYPH)/$(EXAMPLE).expected.yaml" ]; then
+    diff -u "output-test/$(GLYPH)/$(EXAMPLE).expected.yaml" \
+            "output-test/$(GLYPH)/$(EXAMPLE).yaml" || true;
```

### 2. Fix `list-covenant-books` Default Path

**Problem:** Default path is `/home/namen/_home/_home/the.yaml.life/...` (double `_home/`)

**Fix (Makefile line 247):**
```diff
-BOOKRACK_PATH=$${COVENANT_BOOKRACK_PATH:-$$HOME/_home/the.yaml.life/proto-the-yaml-life/bookrack}
+BOOKRACK_PATH=$${COVENANT_BOOKRACK_PATH:-/home/namen/_home/the.yaml.life/proto-the-yaml-life/bookrack}
```

**Or make it project-configurable:**
```makefile
COVENANT_BOOKRACK_PATH ?= /home/namen/_home/the.yaml.life/proto-the-yaml-life/bookrack
```

### 3. Fix `test-status` Implementation

**Problem:** Documentation claims it shows detailed coverage, but it only shows usage info

**Option A - Implement Promised Functionality:**
Create `tests/scripts/show-test-status.sh` that discovers and reports coverage

**Option B - Fix Documentation:**
Update CLAUDE.md to remove misleading examples and rename command to `test-usage`

## High Priority Improvements

### 4. Support Trinket Paths in `inspect-chart`

**Problem:** `make inspect-chart CHART=trinkets/tarot EXAMPLE=test` fails with:
```
invalid release name "inspect-trinkets/tarot-test"
```

**Fix:** Sanitize release names:
```diff
-@helm template inspect-$(CHART)-$(EXAMPLE) $(CHARTS_DIR)/$(CHART) ...
+@helm template inspect-$(shell echo $(CHART) | tr '/' '-')-$(EXAMPLE) $(CHARTS_DIR)/$(CHART) ...
```

### 5. Add `inspect-glyph` Command

**Missing:** No way to inspect single glyph example quickly

**Add to Makefile:**
```makefile
inspect-glyph: ## Inspect rendered output for specific glyph (Usage: make inspect-glyph GLYPH=vault EXAMPLE=secrets)
	@if [ -z "$(GLYPH)" ] || [ -z "$(EXAMPLE)" ]; then \
		echo "$(RED)Usage: make inspect-glyph GLYPH=vault EXAMPLE=secrets$(RESET)"; \
		exit 1; \
	fi
	@echo "$(BLUE)📋 Inspecting glyph $(GLYPH)/$(EXAMPLE)...$(RESET)"
	@helm template inspect-glyph-$(GLYPH)-$(EXAMPLE) charts/kaster \
		-f charts/glyphs/$(GLYPH)/examples/$(EXAMPLE).yaml
```

### 6. Improve `watch` Error Handling

**Problem:** Fails with cryptic error if `entr` not installed

**Fix:**
```makefile
watch: ## Watch for changes and run TDD tests (requires entr)
	@which entr >/dev/null 2>&1 || { \
		echo "$(RED)Error: 'entr' is not installed$(RESET)"; \
		echo "$(YELLOW)Install with: apt-get install entr  # Debian/Ubuntu$(RESET)"; \
		echo "$(YELLOW)            brew install entr       # macOS$(RESET)"; \
		exit 1; \
	}
	@echo "$(BLUE)👁️  TDD: Watching for changes...$(RESET)"
	@find charts tests -type f | entr -c make test-comprehensive
```

## Nice to Have

7. Add `inspect-trinket` command (dedicated for trinkets)
8. Add `show-example` command (view example file)
9. Add `compare-examples` command (diff two examples)
10. Add `summary-chart` command (resource count summary)

## Test Results

### Working Commands (6/9)
- ✅ `inspect-chart` - Works for charts, not trinkets
- ✅ `debug-chart` - Same as above
- ✅ `show-snapshot-diff` - Works well
- ✅ `list-glyphs` - Perfect
- ✅ `generate-expected` - Works
- ✅ `clean-output-tests` - Works

### Broken/Limited (3/9)
- ❌ `show-glyph-diff` - Completely broken
- ⚠️ `list-covenant-books` - Path issue
- ⚠️ `test-status` - Misleading

## Quick Fix Script

Save as `fix-inspection-tools.sh`:

```bash
#!/bin/bash
# Quick fixes for inspection tools

# Fix show-glyph-diff paths
sed -i 's|output-test/glyph-$(GLYPH)|output-test/$(GLYPH)|g' Makefile

# Fix covenant books path (adjust to your environment)
sed -i 's|$$HOME/_home/the.yaml.life|/home/namen/_home/the.yaml.life|' Makefile

echo "Fixed show-glyph-diff and list-covenant-books"
echo "Still need to:"
echo "  1. Implement test-status properly OR update documentation"
echo "  2. Add trinket support to inspect-chart"
echo "  3. Add inspect-glyph command"
echo "  4. Improve watch command error handling"
```

## Documentation Updates Needed

1. **CLAUDE.md** - Remove `test-status` detailed output example (lines 590-621)
2. **CLAUDE.md** - Document `COVENANT_BOOKRACK_PATH` environment variable
3. **CLAUDE.md** - Add note about `entr` requirement for `watch`
4. **CLAUDE.md** - Document that trinkets can't use `inspect-chart` directly

## Bottom Line

**Working:** Most inspection commands work well
**Broken:** `show-glyph-diff` is completely broken
**Limited:** Trinket inspection not supported, covenant path issues
**Misleading:** `test-status` doesn't match documentation

**Priority:** Fix the critical issues (show-glyph-diff, covenant path, test-status) first, then add missing features.
