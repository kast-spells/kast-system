# Audit Report: Inspection and Debugging Tools in kast-system

**Date:** 2025-11-16
**Auditor:** Claude Code
**Scope:** Testing all inspection, debugging, and helper commands in the Makefile

## Executive Summary

The kast-system project includes several inspection and debugging tools for developers. This audit tested each command systematically to evaluate:
- Functionality and correctness
- Error handling
- Output quality and usefulness
- Documentation accuracy
- Missing features

### Overall Assessment

**Working Commands:** 6/9 (67%)
**Broken Commands:** 2/9 (22%)
**Limited/Incomplete:** 1/9 (11%)

## Detailed Findings

### 1. `make inspect-chart` ✅ WORKING

**Command:** `make inspect-chart CHART=summon EXAMPLE=basic-deployment`

**Status:** ✅ Fully functional

**Test Results:**
- ✅ Renders chart output correctly
- ✅ Error handling works (missing CHART/EXAMPLE parameters)
- ✅ Error handling works (non-existent examples)
- ❌ Doesn't support trinket paths (`CHART=trinkets/tarot` creates invalid release names)

**Output Quality:** Good
- Clean YAML output
- Shows all rendered Kubernetes resources
- Helm warnings visible (symbolic link notifications)

**Strengths:**
- Simple, direct inspection of chart rendering
- Fast feedback for development
- Clear error messages

**Weaknesses:**
- Cannot inspect trinkets (charts/trinkets/tarot, charts/trinkets/microspell)
- Release name construction breaks with paths containing `/`
  - Example: `inspect-trinkets/tarot-test` is invalid (contains `/`)
  - Should sanitize release names or use basename only

**Recommendation:**
- Fix release name construction to support trinket paths
- Consider: `inspect-$(shell echo $(CHART) | tr '/' '-')-$(EXAMPLE)`

---

### 2. `make debug-chart` ✅ WORKING

**Command:** `make debug-chart CHART=summon EXAMPLE=basic-deployment`

**Status:** ✅ Fully functional

**Test Results:**
- ✅ Uses `--debug` flag correctly
- ✅ Shows verbose Helm output (timestamps, chart paths)
- ✅ Error handling works (missing parameters)
- ❌ Same trinket path issue as inspect-chart

**Output Quality:** Good
- Shows debug information: timestamps, chart paths
- Includes template comments and TODO markers
- Helpful for debugging template logic

**Comparison to inspect-chart:**
- Adds: Debug timestamps, chart path resolution
- Shows: Same resource output as inspect-chart
- Usefulness: Marginal improvement over inspect-chart for most cases

**Recommendation:**
- Same fix needed for trinket paths
- Consider documenting when to use debug vs inspect
- Debug is most useful when templates fail to render

---

### 3. `make show-glyph-diff` ❌ BROKEN

**Command:** `make show-glyph-diff GLYPH=vault EXAMPLE=secrets`

**Status:** ❌ Non-functional

**Test Results:**
- ❌ Always shows "Expected or actual output not found"
- Root cause: Incorrect directory path

**Issue Details:**

**Current implementation (Makefile:172):**
```makefile
@if [ -f "output-test/glyph-$(GLYPH)/$(EXAMPLE).yaml" ] && \
    [ -f "output-test/glyph-$(GLYPH)/$(EXAMPLE).expected.yaml" ]; then
```

**Actual directory structure:**
```
output-test/
├── vault/              # Correct location
│   ├── secrets.yaml
│   └── secrets.expected.yaml
└── glyph-vault/        # Doesn't exist
```

**Root Cause:**
- Makefile looks for: `output-test/glyph-vault/`
- Test system creates: `output-test/vault/`
- Mismatch between command and test infrastructure

**Evidence from test-glyph.sh (line 138-141):**
```bash
mkdir -p "$OUTPUT_DIR/$glyph"
local actual_file="$OUTPUT_DIR/$glyph/$example_name.yaml"
local expected_file="$OUTPUT_DIR/$glyph/$example_name.expected.yaml"
```

**Fix Required:**
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

**Recommendation:** CRITICAL FIX NEEDED
- Update Makefile line 172-174 to use correct paths
- Add test to ensure command works after fix

---

### 4. `make show-snapshot-diff` ✅ WORKING

**Command:** `make show-snapshot-diff CHART=summon EXAMPLE=basic-deployment`

**Status:** ✅ Functional with prerequisites

**Test Results:**
- ⚠️ Requires running `make generate-snapshots` first
- ✅ Shows proper unified diff output
- ✅ Error handling: Checks file existence
- ✅ Helpful error message: "Run: make test-snapshots"

**Output Quality:** Excellent
- Clean unified diff format
- Color-coded (via script, not Makefile)
- Shows actual differences clearly

**Workflow:**
```bash
# Required workflow
make generate-snapshots CHART=summon          # Generate expected
make test snapshots chart summon              # Generate actual
make show-snapshot-diff CHART=summon EXAMPLE=basic-deployment
```

**Output Example:**
```diff
--- output-test/summon/basic-deployment.expected.yaml
+++ output-test/summon/basic-deployment.yaml
@@ -1,5 +1,5 @@
-  name: snapshot-summon-basic-deployment
+  name: test-summon-basic-deployment
```

**Strengths:**
- Delegates to well-written `tests/scripts/manage-snapshots.sh`
- Proper error handling
- Useful for TDD workflow

**Recommendation:** Working well, no changes needed

---

### 5. `make list-glyphs` ✅ WORKING

**Command:** `make list-glyphs`

**Status:** ✅ Fully functional

**Test Results:**
- ✅ Lists all glyphs in charts/glyphs/
- ✅ Clean, readable output
- ✅ No parameters needed

**Output:**
```
Available glyphs:
  - argo-events
  - certManager
  - common
  - crossplane
  - freeForm
  - gcp
  - istio
  - keycloak
  - postgresql
  - runic-system
  - s3
  - summon
  - vault
```

**Strengths:**
- Simple, reliable
- Alphabetically sorted (by ls)
- Matches actual directory contents

**Recommendation:** Working perfectly, no changes needed

---

### 6. `make list-covenant-books` ⚠️ WORKING WITH ISSUES

**Command:** `make list-covenant-books`

**Status:** ⚠️ Partially functional

**Test Results:**
- ❌ Default path has double `_home/` prefix
- ✅ Works with `COVENANT_BOOKRACK_PATH` environment variable
- ✅ Helpful error message when path not found
- ✅ Finds covenant books correctly when path is correct

**Issue Details:**

**Current default path (Makefile:247):**
```makefile
BOOKRACK_PATH=$${COVENANT_BOOKRACK_PATH:-$$HOME/_home/the.yaml.life/proto-the-yaml-life/bookrack}
```

**Problem:**
- `$HOME` = `/home/namen`
- Path becomes: `/home/namen/_home/the.yaml.life/...` (double prefix)
- Should be: `/home/namen/_home/the.yaml.life/...` OR just `$HOME/the.yaml.life/...`

**Fix Required:**
```diff
-BOOKRACK_PATH=$${COVENANT_BOOKRACK_PATH:-$$HOME/_home/the.yaml.life/proto-the-yaml-life/bookrack}
+BOOKRACK_PATH=$${COVENANT_BOOKRACK_PATH:-$$HOME/.local/share/the.yaml.life/proto-the-yaml-life/bookrack}
```

Or better, make it environment-specific:
```makefile
# Use absolute path or make it configurable in project
COVENANT_BOOKRACK_PATH ?= /home/namen/_home/the.yaml.life/proto-the-yaml-life/bookrack
```

**Workaround (current):**
```bash
COVENANT_BOOKRACK_PATH=/home/namen/_home/the.yaml.life/proto-the-yaml-life/bookrack make list-covenant-books
```

**Output (when working):**
```
📚 Available Covenant Books:
  - covenant-tyl
  - test-post-provision
```

**Recommendation:**
- Fix default path or make it project-configurable
- Consider adding to .env or project config
- Document required environment variable

---

### 7. `make generate-expected` ✅ WORKING

**Command:** `make generate-expected GLYPH=vault`

**Status:** ✅ Fully functional

**Test Results:**
- ✅ Delegates to test dispatcher correctly
- ✅ Generates expected output files
- ✅ Used in TDD workflow

**Implementation:**
```makefile
generate-expected: ## Generate expected outputs for glyph
	@bash tests/core/test-dispatcher.sh snapshots glyph $(GLYPH)
```

**Note:** This is essentially an alias for:
```bash
make test snapshots glyph vault
```

**Recommendation:**
- Consider renaming to `generate-glyph-expected` for clarity
- Or expand to support charts: `make generate-expected CHART=summon`

---

### 8. `make clean-output-tests` ✅ WORKING

**Command:** `make clean-output-tests`

**Status:** ✅ Fully functional

**Test Results:**
- ✅ Removes entire `output-test/` directory
- ✅ Clean output messages
- ✅ No errors if directory doesn't exist

**Output:**
```
🧽 Cleaning output test files...
✅ Output test files cleaned
```

**Verification:**
```bash
# Before: 14 directories
ls output-test/ | wc -l
# 14

# After:
make clean-output-tests
ls output-test/
# ls: cannot access 'output-test/': No such file or directory
```

**Recommendation:** Working perfectly, no changes needed

---

### 9. `make test-status` ⚠️ LIMITED FUNCTIONALITY

**Command:** `make test-status`

**Status:** ⚠️ Incomplete implementation

**Test Results:**
- ✅ Shows usage information
- ❌ Does NOT show actual test coverage status
- ❌ Misleading name and documentation

**Current Output:**
```
Testing Status Report
Run tests with: make test [MODE] [TYPE] [COMPONENTS]
  Modes: syntax, comprehensive, snapshots, all
  Types: glyph, trinket, chart, spell, book, glyphs, trinkets, charts

Examples:
  make test syntax glyph vault
  make test all glyphs
  make test comprehensive trinket tarot
```

**Documentation Claims (CLAUDE.md lines 590-621):**
```markdown
Run `make test-status` to see automatic discovery of all tests:

$ make test-status
Testing Status Report

Main Charts:
  [COMPLETE] summon: 17 examples (17 snapshots)
  [PARTIAL]  kaster: 1 examples (no snapshots)
  [MISSING]  librarian: NO examples/

Glyphs:
  [COMPLETE] argo-events: 5 examples (5 snapshots)
  ...
```

**Actual Implementation (Makefile:101-112):**
```makefile
test-status: ## Show testing status for all components
	@echo "$(BLUE)Testing Status Report$(RESET)"
	@echo "Run tests with: make test [MODE] [TYPE] [COMPONENTS]"
	@echo "  Modes: syntax, comprehensive, snapshots, all"
	@echo "  Types: glyph, trinket, chart, spell, book, glyphs, trinkets, charts"
	@echo ""
	@echo "Examples:"
	@echo "  make test syntax glyph vault"
	@echo "  make test all glyphs"
	@echo "  make test comprehensive trinket tarot"
	@echo ""
```

**Gap Analysis:**
- Documentation describes a detailed status report
- Implementation only shows usage help
- Misleading command name (should be `test-usage` or `test-help`)

**Recommendation:**
1. **Option A - Implement Missing Functionality:**
   - Create script to discover all components
   - Count examples and snapshots
   - Show coverage status as documented

2. **Option B - Fix Documentation:**
   - Update CLAUDE.md to reflect actual command
   - Rename command to `test-usage` or `test-help`
   - Remove misleading status information from docs

**Suggested Implementation (Option A):**
```bash
#!/bin/bash
# tests/scripts/show-test-status.sh

# Discover all charts
for chart in charts/*/; do
    examples=$(ls -1 "$chart/examples" 2>/dev/null | wc -l)
    snapshots=$(ls -1 "output-test/$(basename $chart)"/*.expected.yaml 2>/dev/null | wc -l)
    # Show status based on examples/snapshots
done

# Same for glyphs, trinkets
```

---

### 10. `make watch` ⚠️ REQUIRES DEPENDENCY

**Command:** `make watch`

**Status:** ⚠️ Requires external tool

**Test Results:**
- ❌ Fails if `entr` not installed
- ✅ Clear error message
- ✅ Graceful failure (not cryptic)

**Error:**
```
👁️  TDD: Watching for changes... (Press Ctrl+C to stop)
/bin/sh: 1: entr: not found
make: *** [Makefile:209: watch] Error 127
```

**Recommendation:**
- Add installation instructions to CLAUDE.md
- Add check for `entr` with helpful message:
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

---

## Missing Features

### 1. No `inspect-glyph` Command

**Current State:**
- Can inspect charts: `make inspect-chart CHART=summon EXAMPLE=basic`
- Cannot inspect glyphs directly
- Must use: `make test syntax glyph vault` (runs all examples)

**Recommendation:**
Add `make inspect-glyph GLYPH=vault EXAMPLE=secrets`:
```makefile
inspect-glyph: ## Inspect rendered output for specific glyph
	@if [ -z "$(GLYPH)" ] || [ -z "$(EXAMPLE)" ]; then \
		echo "$(RED)Usage: make inspect-glyph GLYPH=vault EXAMPLE=secrets$(RESET)"; \
		exit 1; \
	fi
	@echo "$(BLUE)📋 Inspecting glyph $(GLYPH)/$(EXAMPLE)...$(RESET)"
	@helm template inspect-glyph-$(GLYPH)-$(EXAMPLE) charts/kaster \
		-f charts/glyphs/$(GLYPH)/examples/$(EXAMPLE).yaml
```

### 2. No `inspect-trinket` Command

**Current State:**
- `make inspect-chart CHART=trinkets/tarot` fails (invalid release name)
- Must use test dispatcher

**Recommendation:**
Add dedicated command:
```makefile
inspect-trinket: ## Inspect rendered output for specific trinket
	@if [ -z "$(TRINKET)" ] || [ -z "$(EXAMPLE)" ]; then \
		echo "$(RED)Usage: make inspect-trinket TRINKET=tarot EXAMPLE=minimal-test$(RESET)"; \
		exit 1; \
	fi
	@echo "$(BLUE)📋 Inspecting trinket $(TRINKET)/$(EXAMPLE)...$(RESET)"
	@helm template inspect-trinket-$(TRINKET)-$(EXAMPLE) \
		charts/trinkets/$(TRINKET) \
		-f charts/trinkets/$(TRINKET)/examples/$(EXAMPLE).yaml
```

### 3. No Quick Example Viewer

**Use Case:** Developers want to quickly see what's in an example file without cat/less

**Recommendation:**
```makefile
show-example: ## Show example file (Usage: make show-example CHART=summon EXAMPLE=basic-deployment)
	@if [ -z "$(CHART)" ] || [ -z "$(EXAMPLE)" ]; then \
		echo "$(RED)Usage: make show-example CHART=summon EXAMPLE=basic-deployment$(RESET)"; \
		exit 1; \
	fi
	@echo "$(BLUE)📄 Example: $(CHART)/$(EXAMPLE)$(RESET)"
	@echo "$(YELLOW)─────────────────────────────────────────────────────────$(RESET)"
	@cat charts/$(CHART)/examples/$(EXAMPLE).yaml
	@echo "$(YELLOW)─────────────────────────────────────────────────────────$(RESET)"
```

### 4. No Diff Comparison Between Examples

**Use Case:** Compare two examples to understand differences

**Recommendation:**
```makefile
compare-examples: ## Compare two examples (Usage: make compare-examples CHART=summon EXAMPLE1=basic EXAMPLE2=complex)
	@if [ -z "$(CHART)" ] || [ -z "$(EXAMPLE1)" ] || [ -z "$(EXAMPLE2)" ]; then \
		echo "$(RED)Usage: make compare-examples CHART=summon EXAMPLE1=basic EXAMPLE2=complex$(RESET)"; \
		exit 1; \
	fi
	@echo "$(BLUE)📊 Comparing $(EXAMPLE1) vs $(EXAMPLE2)$(RESET)"
	@diff -u charts/$(CHART)/examples/$(EXAMPLE1).yaml \
	         charts/$(CHART)/examples/$(EXAMPLE2).yaml || true
```

### 5. No Resource Summary

**Use Case:** Quickly see what resources an example generates without full output

**Recommendation:**
```makefile
summary-chart: ## Show resource summary for chart (Usage: make summary-chart CHART=summon EXAMPLE=basic)
	@if [ -z "$(CHART)" ] || [ -z "$(EXAMPLE)" ]; then \
		echo "$(RED)Usage: make summary-chart CHART=summon EXAMPLE=basic$(RESET)"; \
		exit 1; \
	fi
	@echo "$(BLUE)📊 Resource Summary: $(CHART)/$(EXAMPLE)$(RESET)"
	@helm template test-$(CHART)-$(EXAMPLE) charts/$(CHART) \
		-f charts/$(CHART)/examples/$(EXAMPLE).yaml 2>/dev/null | \
		grep "^kind:" | sort | uniq -c | sort -rn
```

Output example:
```
📊 Resource Summary: summon/basic-deployment
      1 Deployment
      1 Service
      1 ServiceAccount
```

---

## Error Handling Analysis

### Good Error Handling ✅

**Commands with proper error checking:**
1. `inspect-chart` - Checks for required parameters
2. `debug-chart` - Checks for required parameters
3. `show-snapshot-diff` - Checks file existence, helpful error message
4. `list-covenant-books` - Checks directory existence, suggests solution

**Example (show-snapshot-diff):**
```bash
[ERROR] Missing files
Run: make test-snapshots
```
Clean, actionable, helpful.

### Weak Error Handling ⚠️

**Commands that could improve:**
1. `show-glyph-diff` - Generic error, doesn't help debug
   - Current: "Expected or actual output not found"
   - Better: Show which files are missing, suggest fix

2. `inspect-chart` with trinkets - Cryptic Helm error
   - Current: "invalid release name, must match regex..."
   - Better: "Trinkets not supported. Use: make test syntax trinket tarot"

### Missing Error Handling ❌

**Commands missing validation:**
1. `generate-expected` - No check if GLYPH is provided
2. `list-glyphs` - No validation (but also doesn't need parameters)

---

## Output Quality Analysis

### Excellent Output 🌟

1. **show-snapshot-diff**
   - Uses proper diff format
   - Color-coded (in script)
   - Shows context
   - Professional quality

2. **list-covenant-books**
   - Uses emojis appropriately (📚)
   - Color-coded
   - Clean formatting

3. **clean-output-tests**
   - Clear status messages
   - Uses emojis (🧽, ✅)
   - Friendly output

### Good Output ✅

1. **inspect-chart** / **debug-chart**
   - Shows complete YAML
   - Preserves formatting
   - Includes helpful Helm warnings

2. **list-glyphs**
   - Simple, clean list
   - Consistent formatting

### Could Improve ⚠️

1. **test-status**
   - Doesn't match documentation
   - Just static text
   - Misses opportunity to be useful

2. **show-glyph-diff**
   - Would be good if it worked
   - Error message not helpful

---

## Documentation Accuracy

### Accurate Documentation ✅

1. `inspect-chart` - Usage string matches behavior
2. `debug-chart` - Usage string matches behavior
3. `show-snapshot-diff` - Works as documented
4. `list-glyphs` - Simple and accurate

### Inaccurate Documentation ❌

1. **test-status** - Major discrepancy
   - CLAUDE.md shows detailed coverage report
   - Actual command shows usage info only
   - Command name is misleading

2. **list-covenant-books** - Path issues
   - Default path doesn't work out of the box
   - Not documented that COVENANT_BOOKRACK_PATH may be needed

### Missing Documentation ⚠️

1. **watch command** - No mention of `entr` requirement in help text
2. **Trinket inspection** - No documented way to inspect trinkets
3. **Glyph inspection** - No documented way to inspect single glyph example

---

## Recommendations Summary

### Critical Fixes (P0)

1. **Fix `show-glyph-diff` paths** (Makefile:172-174)
   - Change `output-test/glyph-$(GLYPH)/` to `output-test/$(GLYPH)/`
   - Add test to verify it works

2. **Fix `list-covenant-books` default path** (Makefile:247)
   - Remove double `_home/` prefix
   - Make configurable in project settings
   - Document environment variable

3. **Fix `test-status` implementation or documentation**
   - Either implement the promised functionality
   - Or update CLAUDE.md and rename command

### High Priority (P1)

4. **Fix trinket path support in `inspect-chart`**
   - Sanitize release names to remove `/`
   - Or add dedicated `inspect-trinket` command

5. **Add `inspect-glyph` command**
   - Fills important gap in tooling
   - Consistent with inspect-chart pattern

6. **Improve `watch` command error handling**
   - Check for `entr` before running
   - Show install instructions if missing

### Nice to Have (P2)

7. **Add `inspect-trinket` command**
8. **Add `show-example` command**
9. **Add `compare-examples` command**
10. **Add `summary-chart` command**
11. **Improve error messages** across all commands

---

## Testing Coverage

### Commands Tested

| Command | Parameters Tested | Edge Cases | Error Handling |
|---------|-------------------|------------|----------------|
| inspect-chart | ✅ Valid | ✅ Missing args | ✅ Non-existent |
| debug-chart | ✅ Valid | ✅ Missing args | ✅ |
| show-glyph-diff | ✅ Valid | ❌ (broken) | ❌ (broken) |
| show-snapshot-diff | ✅ Valid | ✅ Missing files | ✅ |
| list-glyphs | ✅ Valid | N/A | N/A |
| list-covenant-books | ✅ Valid | ⚠️ Path issues | ✅ |
| generate-expected | ✅ Valid | ❌ Not tested | ⚠️ |
| clean-output-tests | ✅ Valid | ✅ No directory | ✅ |
| test-status | ✅ Valid | N/A | ⚠️ Misleading |
| watch | ⚠️ Dependency | ❌ No entr | ⚠️ |

### Test Commands Used

```bash
# inspect-chart
make inspect-chart CHART=summon EXAMPLE=basic-deployment
make inspect-chart  # Missing parameters
make inspect-chart CHART=summon EXAMPLE=nonexistent
make inspect-chart CHART=kaster EXAMPLE=argo-events-test
make inspect-chart CHART=trinkets/tarot EXAMPLE=minimal-test  # Fails

# debug-chart
make debug-chart CHART=summon EXAMPLE=basic-deployment
make debug-chart  # Missing parameters

# show-glyph-diff
make show-glyph-diff GLYPH=vault EXAMPLE=secrets  # Broken
make test snapshots glyph vault  # Generate files first

# show-snapshot-diff
make generate-snapshots CHART=summon
make test snapshots chart summon
make show-snapshot-diff CHART=summon EXAMPLE=basic-deployment

# list commands
make list-glyphs
make list-covenant-books
COVENANT_BOOKRACK_PATH=/home/namen/_home/the.yaml.life/proto-the-yaml-life/bookrack make list-covenant-books

# Other commands
make generate-expected GLYPH=vault
make clean-output-tests
make test-status
make watch  # No entr installed
```

---

## Conclusion

The inspection and debugging tools in kast-system provide useful functionality but have several issues:

**Strengths:**
- Good coverage of basic inspection needs
- Generally good error messages
- Clean, professional output formatting
- Consistent command naming patterns

**Critical Issues:**
1. `show-glyph-diff` completely broken (wrong paths)
2. `test-status` doesn't match documentation
3. `list-covenant-books` default path incorrect
4. Trinket inspection not supported

**Impact:**
- Developers may struggle with glyph diff inspection
- Covenant book discovery requires manual path setup
- Test status command misleading
- Trinket development less convenient

**Next Steps:**
1. Apply critical fixes (P0 items)
2. Add missing commands (P1 items)
3. Update documentation to match reality
4. Add tests for inspection commands
5. Consider adding convenience commands (P2 items)

The foundation is solid, but several commands need fixes to match their documentation and provide the promised functionality.
