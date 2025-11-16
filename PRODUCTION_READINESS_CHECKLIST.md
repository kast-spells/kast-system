# Production Readiness Checklist - kast-system Testing Infrastructure

**Date:** 2025-11-16
**Target Production Date:** TBD
**Current Status:** 85% Production Ready
**Blockers:** 1 critical bug

---

## Quick Status Overview

| Category | Status | Blockers | Time to Fix |
|----------|--------|----------|-------------|
| **Critical (P0)** | ⚠️ 1 issue | 1 | 30 min |
| **High Priority (P1)** | ⚠️ 3 issues | 0 | 8 hours |
| **Medium Priority (P2)** | ⚠️ 4 issues | 0 | 11.5 hours |
| **Overall** | 🟡 READY (with fixes) | 1 | 30 min - 20 hours |

**Minimum Time to Production:** 30 minutes (P0 only)
**Recommended Time to Production:** 8.5 hours (P0 + P1)
**Full Production Ready:** 20 hours (P0 + P1 + P2)

---

## P0 - CRITICAL (Production Blockers)

### ❌ P0-1: test-spell.sh Resource Counting Bug

**Status:** MUST FIX BEFORE PRODUCTION
**Risk Level:** HIGH - Breaks spell testing workflow
**User Impact:** HIGH - Users see errors despite successful tests
**Time to Fix:** 30 minutes
**Difficulty:** Easy

#### Issue Details

**File:** `/home/namen/_home/kast/kast-system/tests/core/test-spell.sh`
**Lines:** 233, 238
**Error:** `integer expression expected` when counting resources

**Current Code (BROKEN):**
```bash
# Line 233
local resource_count=$(echo "$output" | grep -c "^kind:" || echo "0")

# Line 238 - Fails here
if [ "$resource_count" -gt 0 ]; then
    # Error: integer expression expected: 5\n
```

**Root Cause:** `grep -c` returns count with newline character, causing bash arithmetic to fail

#### Fix Implementation

**Option 1 (Recommended):**
```bash
# Replace line 233 with:
local resource_count=$(echo "$output" | grep "^kind:" | wc -l | tr -d '\n' | tr -d ' ')
```

**Option 2 (Alternative):**
```bash
# Replace line 233 with:
local resource_count=$(echo "$output" | grep -c "^kind:" 2>/dev/null || echo 0)
resource_count=$(echo "$resource_count" | tr -d '\n')
```

#### Testing Steps

```bash
# 1. Make the fix
vim tests/core/test-spell.sh

# 2. Test spell rendering
make test spell example-api --book example-tdd-book

# 3. Verify no "integer expression expected" error
# Expected output:
#   [PASS] example-api
#   Generated X resource(s)
#   Resource Summary:
#     1x kind: Deployment
#     1x kind: Service

# 4. Test with debug flag
make test spell example-api --book example-tdd-book --debug

# 5. Test with multiple spells if available
```

#### Verification Criteria

- [ ] No "integer expression expected" errors
- [ ] Resource count displays correctly
- [ ] Resource summary shows properly
- [ ] Works with all spells in example-tdd-book
- [ ] Debug mode still works

**Estimated Time Breakdown:**
- Understanding issue: 5 min
- Implementing fix: 5 min
- Testing: 15 min
- Documentation: 5 min
- **Total:** 30 minutes

---

## P1 - HIGH PRIORITY (Strongly Recommended)

### ⚠️ P1-1: Missing Snapshot Coverage

**Status:** RECOMMENDED BEFORE PRODUCTION
**Risk Level:** MEDIUM - No regression detection
**User Impact:** MEDIUM - Can't detect unintended changes
**Time to Fix:** 2 hours
**Difficulty:** Easy

#### Issue Details

**Current State:**
- 85 test examples across all components
- 0 snapshot files generated
- Snapshot infrastructure exists and works
- Just needs execution

**Impact:**
- No baseline for detecting template changes
- Can't catch unintended output modifications
- Regression testing incomplete

#### Fix Implementation

```bash
# Step 1: Generate all snapshots at once
make update-all-snapshots

# Step 2: Verify snapshot count
find output-test -name "*.expected.yaml" | wc -l
# Expected: 85 files

# Step 3: Test snapshot validation
make test snapshots chart summon
make test snapshots glyph vault
make test snapshots trinket tarot

# Step 4: Commit snapshots to git
git add output-test/**/*.expected.yaml
git commit -m "chore: add baseline snapshots for all components"
```

#### Component-by-Component Approach (Recommended)

```bash
# Generate and review incrementally
make test snapshots chart summon        # 20 snapshots
make test snapshots glyph vault         # 15 snapshots
make test snapshots glyph istio         # 2 snapshots
make test snapshots glyph argo-events   # 5 snapshots
make test snapshots trinket tarot       # 14 snapshots
make test snapshots trinket microspell  # 10 snapshots
# ... continue for all components
```

#### Verification Criteria

- [ ] All 85 snapshots generated
- [ ] All snapshot tests pass
- [ ] Files committed to git
- [ ] CI pipeline validates snapshots
- [ ] Documentation updated

**Estimated Time Breakdown:**
- Generate snapshots: 30 min
- Review each snapshot: 60 min
- Test validation: 15 min
- Commit and verify: 15 min
- **Total:** 2 hours

---

### ⚠️ P1-2: Regular Book Testing Not Implemented

**Status:** RECOMMENDED BEFORE PRODUCTION
**Risk Level:** MEDIUM - Limited book testing capability
**User Impact:** MEDIUM - Can't test non-covenant books
**Time to Fix:** 4 hours
**Difficulty:** Medium

#### Issue Details

**File:** `/home/namen/_home/kast/kast-system/tests/core/test-book.sh`
**Function:** `test_regular_book()`
**Current State:** Placeholder only - prints warning and skips

**Current Code:**
```bash
test_regular_book() {
    local book=$1
    log_warning "$book: Regular book testing not implemented yet"
    log_info "Book structure:"
    # ... only lists structure, doesn't test
    increment_skipped
    return 2
}
```

#### Fix Implementation

**Recommended Approach:**

```bash
test_regular_book() {
    local book=$1
    local bookrack_path="${BOOKRACK_PATH:-$REPO_ROOT/bookrack}"

    log_info "Testing regular book: $book"

    # 1. Discover all spells in book
    local spell_files=$(find "$bookrack_path/$book" -name "*.yaml" -not -name "index.yaml" -type f)
    local spell_count=$(echo "$spell_files" | grep -c "^" || echo 0)

    if [ "$spell_count" -eq 0 ]; then
        log_warning "$book: No spells found"
        increment_skipped
        return 2
    fi

    log_info "Found $spell_count spells to test"

    # 2. Test each spell
    local failed_spells=()
    while IFS= read -r spell_file; do
        local spell_name=$(basename "$spell_file" .yaml)
        local chapter=$(basename $(dirname "$spell_file"))

        log_info "Testing spell: $chapter/$spell_name"

        # Use test-spell.sh to test each spell
        if bash "$REPO_ROOT/tests/core/test-spell.sh" "$spell_name" "--book" "$book"; then
            increment_passed
        else
            increment_failed
            failed_spells+=("$chapter/$spell_name")
        fi
    done <<< "$spell_files"

    # 3. Report results
    if [ ${#failed_spells[@]} -gt 0 ]; then
        log_error "$book: Failed spells:"
        for spell in "${failed_spells[@]}"; do
            log_error "  - $spell"
        done
        return 1
    else
        log_success "$book: All spells passed"
        return 0
    fi
}
```

#### Testing Steps

```bash
# 1. Implement the fix
vim tests/core/test-book.sh

# 2. Test with example-tdd-book
make test book example-tdd-book

# Expected output:
#   [INFO] Testing regular book: example-tdd-book
#   [INFO] Found X spells to test
#   [INFO] Testing spell: intro/example-api
#   [PASS] example-api
#   [INFO] Testing spell: intro/payment-service
#   [PASS] payment-service
#   ...
#   [PASS] example-tdd-book: All spells passed

# 3. Test with debug flag
make test book example-tdd-book --debug

# 4. Test with book that has failures (if any)
```

#### Verification Criteria

- [ ] Discovers all spells in book
- [ ] Tests each spell individually
- [ ] Aggregates results correctly
- [ ] Reports failed spells clearly
- [ ] Works with debug flag
- [ ] Integration with existing test infrastructure

**Estimated Time Breakdown:**
- Design implementation: 30 min
- Code implementation: 90 min
- Testing: 60 min
- Edge cases: 30 min
- Documentation: 30 min
- **Total:** 4 hours

---

### ⚠️ P1-3: test-glyph_all() Counter Logic Complexity

**Status:** RECOMMENDED BEFORE PRODUCTION
**Risk Level:** LOW - Works but fragile
**User Impact:** LOW - Maintenance burden
**Time to Fix:** 2 hours
**Difficulty:** Medium

#### Issue Details

**File:** `/home/namen/_home/kast/kast-system/tests/core/test-glyph.sh`
**Lines:** 177-206
**Function:** `test_glyph_all()`

**Current Code (COMPLEX):**
```bash
test_glyph_all() {
    # Complex counter adjustments to prevent triple-counting
    local before_passed=$TESTS_PASSED
    local before_failed=$TESTS_FAILED
    local before_skipped=$TESTS_SKIPPED

    # Run all three modes
    test_glyph_syntax "$glyph" "$example" "$test_name"
    test_glyph_comprehensive "$glyph" "$example" "$test_name"
    test_glyph_snapshots "$glyph" "$example" "$test_name"

    # Adjust for triple counting (COMPLEX LOGIC)
    local total_passed=$((TESTS_PASSED - before_passed))
    local total_failed=$((TESTS_FAILED - before_failed))
    local total_skipped=$((TESTS_SKIPPED - before_skipped))

    # Reset to before + 1 count (instead of 3)
    TESTS_PASSED=$((before_passed + (total_passed > 0 ? 1 : 0)))
    TESTS_FAILED=$((before_failed + (total_failed > 0 ? 1 : 0)))
    TESTS_SKIPPED=$((before_skipped + (total_skipped > 0 ? 1 : 0)))
}
```

**Problem:** Hard to understand, error-prone, fragile

#### Fix Implementation

**Recommended Refactor:**

```bash
test_glyph_all() {
    local glyph=$1
    local example=$2
    local test_name=$3

    # Track results for all modes without incrementing counters
    local syntax_result=0
    local comprehensive_result=0
    local snapshots_result=0

    # Run modes with result tracking (don't increment counters yet)
    log_info "Running syntax validation..."
    test_glyph_syntax "$glyph" "$example" "$test_name" "no-count"
    syntax_result=$?

    log_info "Running comprehensive validation..."
    test_glyph_comprehensive "$glyph" "$example" "$test_name" "no-count"
    comprehensive_result=$?

    log_info "Running snapshot validation..."
    test_glyph_snapshots "$glyph" "$example" "$test_name" "no-count"
    snapshots_result=$?

    # Aggregate results - only increment once
    if [ $syntax_result -eq 0 ] && [ $comprehensive_result -eq 0 ] && [ $snapshots_result -eq 0 ]; then
        log_success "$test_name: All validations passed"
        increment_passed
        return 0
    elif [ $syntax_result -eq 2 ] || [ $comprehensive_result -eq 2 ] || [ $snapshots_result -eq 2 ]; then
        log_warning "$test_name: Skipped"
        increment_skipped
        return 2
    else
        log_error "$test_name: Some validations failed"
        increment_failed
        return 1
    fi
}
```

**Modify individual test functions to accept "no-count" flag:**

```bash
test_glyph_syntax() {
    local glyph=$1
    local example=$2
    local test_name=$3
    local no_count=${4:-""}  # Optional no-count flag

    # ... existing logic ...

    if [ $? -eq 0 ]; then
        [ "$no_count" != "no-count" ] && increment_passed
        return 0
    else
        [ "$no_count" != "no-count" ] && increment_failed
        return 1
    fi
}
```

#### Testing Steps

```bash
# 1. Implement refactor
vim tests/core/test-glyph.sh

# 2. Test all mode with single glyph
make test all glyph vault

# 3. Verify counter is incremented once (not 3 times)
# Expected: 15 tests (15 examples, not 45)

# 4. Test with multiple glyphs
make test all glyph vault istio

# 5. Test all glyphs
make test all glyph
```

#### Verification Criteria

- [ ] Counter incremented once per example (not per mode)
- [ ] All three modes execute correctly
- [ ] Results aggregated properly
- [ ] Works with single glyph
- [ ] Works with multiple glyphs
- [ ] Works with "all" glyphs

**Estimated Time Breakdown:**
- Refactor test_glyph_all: 30 min
- Modify individual test functions: 30 min
- Testing: 45 min
- Edge cases: 15 min
- **Total:** 2 hours

---

## P2 - MEDIUM PRIORITY (Quality Improvements)

### 🟡 P2-1: Hard-coded Paths (Portability)

**Status:** NICE TO HAVE
**Risk Level:** LOW - Works on primary system
**User Impact:** LOW - Affects new developers
**Time to Fix:** 1 hour
**Difficulty:** Easy

#### Quick Fix

```bash
# Replace hard-coded paths with environment variables

# tests/core/test-book.sh
COVENANT_BOOKRACK_PATH="${COVENANT_BOOKRACK_PATH:-../proto-the-yaml-life/bookrack}"

# tests/lib/discover.sh
local bookrack_path="${COVENANT_BOOKRACK_PATH:-${HOME}/_home/the.yaml.life/proto-the-yaml-life/bookrack}"

# Add to README.md
echo "export COVENANT_BOOKRACK_PATH=/path/to/bookrack" >> README.md
```

**Files to Update:**
- `/home/namen/_home/kast/kast-system/tests/core/test-book.sh:23`
- `/home/namen/_home/kast/kast-system/tests/lib/discover.sh:98`

---

### 🟡 P2-2: Missing Help in Individual Handlers

**Status:** NICE TO HAVE
**Risk Level:** NONE - UX improvement
**User Impact:** LOW - Better user experience
**Time to Fix:** 1.5 hours
**Difficulty:** Easy

#### Quick Fix

Add to each handler (`test-glyph.sh`, `test-trinket.sh`, `test-chart.sh`, `test-spell.sh`, `test-book.sh`):

```bash
show_usage() {
    echo "Usage: $0 <mode> [components...]"
    echo ""
    echo "Modes:"
    echo "  syntax        - Syntax validation only"
    echo "  comprehensive - Rendering + resource validation"
    echo "  snapshots     - Snapshot comparison + K8s schema"
    echo "  all           - All of the above"
    echo ""
    echo "Components: component names or 'all' for auto-discovery"
    echo ""
    echo "Examples:"
    echo "  $0 syntax vault"
    echo "  $0 all glyph"
    echo "  $0 comprehensive vault istio"
}

if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    show_usage
    exit 0
fi
```

---

### 🟡 P2-3: Inconsistent Flag Parsing

**Status:** NICE TO HAVE
**Risk Level:** NONE - Code quality
**User Impact:** NONE - Internal
**Time to Fix:** 1 hour
**Difficulty:** Easy

#### Quick Fix

Standardize all flag parsing to use `tests/lib/utils.sh:get_flag_value()`:

```bash
# Instead of manual parsing:
if [ "$1" = "--debug" ]; then
    debug="$1"
fi

# Use standard function:
debug=$(get_flag_value "--debug" "$@")
book=$(get_flag_value "--book" "$@")
```

---

### 🟡 P2-4: No Parallel Execution Support

**Status:** FUTURE ENHANCEMENT
**Risk Level:** NONE - Performance optimization
**User Impact:** LOW - Faster tests appreciated
**Time to Fix:** 8 hours
**Difficulty:** Hard

#### Implementation Plan (Future)

```bash
# Add --parallel flag to test commands
make test all glyph --parallel

# Use GNU parallel for concurrent execution
if [ "$PARALLEL" = "true" ]; then
    export -f test_glyph
    echo "${glyphs[@]}" | tr ' ' '\n' | parallel -j 4 test_glyph {} $mode
fi
```

**Note:** Deferred to future enhancement - not required for production

---

## Production Deployment Scenarios

### Scenario 1: Minimal (P0 Only) - 30 Minutes

**What to Fix:**
- ✅ P0-1: test-spell.sh resource counting bug

**Production Ready:** 75%
**Risk:** Medium - No snapshots, book testing incomplete
**Recommended For:** Emergency deployments only

**Commands:**
```bash
# Fix P0-1
vim tests/core/test-spell.sh  # Apply fix from P0-1

# Test
make test spell example-api --book example-tdd-book

# Deploy
```

---

### Scenario 2: Recommended (P0 + P1) - 8.5 Hours

**What to Fix:**
- ✅ P0-1: test-spell.sh resource counting bug (30 min)
- ✅ P1-1: Generate snapshots (2 hours)
- ✅ P1-2: Implement regular book testing (4 hours)
- ✅ P1-3: Refactor counter logic (2 hours)

**Production Ready:** 95%
**Risk:** Low - All major functionality working
**Recommended For:** Standard production deployment

**Commands:**
```bash
# Fix P0-1
vim tests/core/test-spell.sh

# Fix P1-1
make update-all-snapshots
git add output-test/**/*.expected.yaml
git commit -m "chore: add baseline snapshots"

# Fix P1-2
vim tests/core/test-book.sh  # Implement test_regular_book()
make test book example-tdd-book

# Fix P1-3
vim tests/core/test-glyph.sh  # Refactor test_glyph_all()
make test all glyph

# Verify all
make test-all
```

---

### Scenario 3: Full Production (P0 + P1 + P2) - 20 Hours

**What to Fix:**
- All P0 fixes (30 min)
- All P1 fixes (8 hours)
- All P2 fixes (11.5 hours)

**Production Ready:** 98%
**Risk:** Very Low - Polished, production-grade
**Recommended For:** Major releases, long-term stability

---

## Testing the Fixes

### Pre-Deployment Test Suite

```bash
# 1. TDD Workflow
make tdd-red
make tdd-green
make tdd-refactor

# 2. All Components
make test all glyph
make test all trinket
make test all chart

# 3. Specific Tests
make test spell example-api --book example-tdd-book
make test book example-tdd-book

# 4. Snapshots
make test snapshots chart summon
make test snapshots glyph vault

# 5. Lint
make lint

# 6. Full Suite
make test-all
```

### Acceptance Criteria

- [ ] All TDD workflow commands work (red/green/refactor)
- [ ] All 13 glyphs test successfully
- [ ] All 2 trinkets test successfully
- [ ] All 3 charts test successfully
- [ ] Spell testing works without errors
- [ ] Book testing works (covenant + regular)
- [ ] All snapshots validate correctly
- [ ] Lint passes for all charts
- [ ] No hard-coded path errors
- [ ] Help available for all commands

---

## Sign-Off Checklist

### Technical Sign-Off

- [ ] All P0 issues resolved
- [ ] All P1 issues resolved (recommended)
- [ ] All tests passing
- [ ] Documentation updated
- [ ] Code reviewed
- [ ] CI pipeline green

### Quality Assurance Sign-Off

- [ ] Manual testing completed
- [ ] Edge cases tested
- [ ] Error handling validated
- [ ] Performance acceptable
- [ ] User experience smooth

### Deployment Sign-Off

- [ ] Deployment plan reviewed
- [ ] Rollback plan prepared
- [ ] Monitoring configured
- [ ] Team trained on new features
- [ ] Documentation published

---

## Post-Deployment Validation

```bash
# Run immediately after deployment
make test-all

# Expected results:
# Total: 85+ tests
# Passed: 85+ tests
# Failed: 0 tests
# Skipped: 0 tests

# Verify specific functionality
make test spell <real-spell> --book <real-book>
make test book <real-book>
```

---

## Rollback Plan

If critical issues arise post-deployment:

```bash
# 1. Identify failing component
make test syntax glyph
make test syntax trinket
make test syntax chart

# 2. Rollback specific fix
git revert <commit-hash>

# 3. Verify system stable
make test-all

# 4. Plan fix for next deployment
```

---

## Success Metrics

### Pre-Production Metrics (Current)

- Test Coverage: 85 examples
- Snapshot Coverage: 0%
- Auto-Discovery: 100%
- TDD Workflow: 100%
- Error Rate: ~1.2% (1 critical bug)

### Post-Production Metrics (Target)

- Test Coverage: 85+ examples
- Snapshot Coverage: 100%
- Auto-Discovery: 100%
- TDD Workflow: 100%
- Error Rate: 0%

---

## Timeline Recommendation

### Week 1 (Critical Path)
- **Day 1:** Fix P0-1 (30 min) + Testing (2 hours)
- **Day 2:** Generate snapshots P1-1 (2 hours) + Review (2 hours)
- **Day 3:** Implement P1-2 (4 hours) + Testing (2 hours)
- **Day 4:** Refactor P1-3 (2 hours) + Testing (2 hours)
- **Day 5:** Integration testing + Documentation

### Week 2 (Polish - Optional)
- **Day 1-2:** P2-1, P2-2, P2-3 (3.5 hours)
- **Day 3-5:** P2-4 Parallel execution (8 hours) - OPTIONAL

---

**Checklist Last Updated:** 2025-11-16
**Next Review:** After P0 fixes deployed
**Production Target:** TBD based on fix timeline
