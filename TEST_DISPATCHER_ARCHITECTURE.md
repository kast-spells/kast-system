# Test Dispatcher System Architecture

## System Overview Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          USER INTERFACE                                 │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  make test [MODE] [TYPE] [COMPONENTS...] [FLAGS]                        │
│                                                                          │
│  Examples:                                                               │
│    make test syntax glyph vault                                         │
│    make test comprehensive trinket tarot                                │
│    make test all glyph                                                  │
│    make test spell example-api --book example-tdd-book                  │
│                                                                          │
└────────────────────────────┬────────────────────────────────────────────┘
                             │
                             ↓
┌─────────────────────────────────────────────────────────────────────────┐
│                         MAKEFILE (Entry Point)                          │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  test:                                                                   │
│    - Parse MAKECMDGOALS                                                 │
│    - Extract arguments                                                  │
│    - Invoke dispatcher                                                  │
│                                                                          │
│  Legacy Targets:                                                        │
│    - test-comprehensive  → test comprehensive chart                     │
│    - test-snapshots      → test snapshots chart                         │
│    - glyphs <name>       → test comprehensive glyph <name>              │
│                                                                          │
└────────────────────────────┬────────────────────────────────────────────┘
                             │
                             ↓
┌─────────────────────────────────────────────────────────────────────────┐
│                    TEST DISPATCHER (Router)                             │
│                  tests/core/test-dispatcher.sh                          │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  parse_args():                                                          │
│    ├─ Extract MODE (syntax/comprehensive/snapshots/all)                │
│    ├─ Extract TYPE (glyph/trinket/chart/spell/book)                    │
│    ├─ Extract COMPONENTS (names or "all")                              │
│    ├─ Extract FLAGS (--book, --debug, etc.)                            │
│    └─ Normalize (glyphs→glyph, empty→all, etc.)                        │
│                                                                          │
│  dispatch():                                                            │
│    ├─ Route to handler based on TYPE                                   │
│    └─ Pass MODE, COMPONENTS, FLAGS                                     │
│                                                                          │
└──────┬──────────┬──────────┬──────────┬──────────┬──────────────────────┘
       │          │          │          │          │
       ↓          ↓          ↓          ↓          ↓
  ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐
  │ GLYPH  │ │TRINKET │ │ CHART  │ │ SPELL  │ │  BOOK  │
  │HANDLER │ │HANDLER │ │HANDLER │ │HANDLER │ │HANDLER │
  └────────┘ └────────┘ └────────┘ └────────┘ └────────┘
       │          │          │          │          │
       └──────────┴──────────┴──────────┴──────────┘
                             │
                             ↓
┌─────────────────────────────────────────────────────────────────────────┐
│                      SHARED LIBRARIES                                   │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  tests/lib/utils.sh:                                                    │
│    ├─ log_info(), log_success(), log_error(), log_warning()            │
│    ├─ increment_passed(), increment_failed(), increment_skipped()      │
│    ├─ print_summary()                                                  │
│    ├─ get_repo_root()                                                  │
│    └─ get_flag_value(), parse_flag()                                   │
│                                                                          │
│  tests/lib/discover.sh:                                                 │
│    ├─ discover_glyphs()                                                │
│    ├─ discover_tested_glyphs()                                         │
│    ├─ discover_trinkets()                                              │
│    ├─ discover_charts()                                                │
│    ├─ discover_books()                                                 │
│    ├─ glyph_exists(), trinket_exists(), chart_exists()                 │
│    └─ get_glyph_examples(), get_trinket_examples()                     │
│                                                                          │
│  tests/lib/validate.sh:                                                 │
│    ├─ validate_syntax()                                                │
│    ├─ render_template()                                                │
│    ├─ count_resources()                                                │
│    ├─ compare_snapshot()                                               │
│    ├─ validate_k8s_schema()                                            │
│    └─ has_errors(), get_errors()                                       │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

## Handler Deep Dive

### Glyph Handler (test-glyph.sh)

```
┌─────────────────────────────────────────────────────────────┐
│              test-glyph.sh <mode> <components...>           │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  main():                                                     │
│    ├─ Parse arguments (mode, components)                   │
│    ├─ Check dependencies (helm, yq)                        │
│    └─ Call test_glyphs()                                   │
│                                                              │
│  test_glyphs():                                             │
│    ├─ Auto-discover if "all"                               │
│    │   └─ discover_tested_glyphs()                         │
│    ├─ Loop through glyphs                                  │
│    │   └─ test_glyph(name, mode)                           │
│    └─ print_summary()                                      │
│                                                              │
│  test_glyph():                                              │
│    ├─ Check glyph exists                                   │
│    ├─ Validate has examples                                │
│    ├─ Load examples from charts/glyphs/<name>/examples/   │
│    └─ For each example:                                    │
│        ├─ mode=syntax       → test_glyph_syntax()          │
│        ├─ mode=comprehensive → test_glyph_comprehensive()  │
│        ├─ mode=snapshots    → test_glyph_snapshots()       │
│        └─ mode=all          → test_glyph_all()             │
│                                                              │
│  test_glyph_syntax():                                       │
│    ├─ validate_syntax(kaster, example)                     │
│    └─ increment_passed() or increment_failed()             │
│                                                              │
│  test_glyph_comprehensive():                                │
│    ├─ render_template(kaster, example)                     │
│    ├─ has_errors() → fail                                  │
│    ├─ count_resources() → must be > 0                      │
│    └─ increment_passed() or increment_failed()             │
│                                                              │
│  test_glyph_snapshots():                                    │
│    ├─ render_template(kaster, example)                     │
│    ├─ Save to output-test/<glyph>/<example>.yaml          │
│    ├─ compare_snapshot(actual, expected)                   │
│    └─ increment_passed/failed/skipped()                    │
│                                                              │
│  CRITICAL: Tests glyphs through KASTER, never directly!    │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Trinket Handler (test-trinket.sh)

```
┌─────────────────────────────────────────────────────────────┐
│            test-trinket.sh <mode> <components...>           │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Similar structure to test-glyph.sh but:                    │
│    - Tests trinkets directly (not through kaster)          │
│    - Sources: charts/trinkets/<name>/examples/             │
│    - No auto-discovery warnings for untested                │
│                                                              │
│  test_trinket():                                            │
│    ├─ Check trinket exists                                 │
│    ├─ Validate has examples                                │
│    ├─ Load examples from charts/trinkets/<name>/examples/ │
│    └─ For each example:                                    │
│        ├─ mode=syntax       → test_trinket_syntax()        │
│        ├─ mode=comprehensive → test_trinket_comprehensive()│
│        ├─ mode=snapshots    → test_trinket_snapshots()     │
│        └─ mode=all          → test_trinket_all()           │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Chart Handler (test-chart.sh)

```
┌─────────────────────────────────────────────────────────────┐
│             test-chart.sh <mode> <components...>            │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Similar structure to test-glyph.sh but:                    │
│    - Tests main charts (summon, kaster, librarian)         │
│    - Sources: charts/<name>/examples/ or librarian/examples/│
│    - Calls validate-resource-completeness.sh               │
│    - Performs K8s schema validation                        │
│                                                              │
│  test_chart_comprehensive():                                │
│    ├─ render_template(chart, example)                      │
│    ├─ has_errors() → fail                                  │
│    ├─ count_resources() → must be > 0                      │
│    ├─ validate-resource-completeness.sh                    │
│    └─ increment_passed() or increment_failed()             │
│                                                              │
│  test_chart_snapshots():                                    │
│    ├─ render_template(chart, example)                      │
│    ├─ Save to output-test/<chart>/<example>.yaml          │
│    ├─ validate_k8s_schema() (helm install --dry-run)      │
│    ├─ compare_snapshot(actual, expected)                   │
│    └─ increment_passed/failed/skipped()                    │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Spell Handler (test-spell.sh)

```
┌─────────────────────────────────────────────────────────────┐
│      test-spell.sh <spell> [--book <book>] [--debug]       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Step 1: Render librarian                                   │
│    ├─ helm template librarian -f bookrack/<book>/index.yaml│
│    └─ Generate ArgoCD Applications                         │
│                                                              │
│  Step 2: Extract spell's Application                        │
│    ├─ yq eval 'select(.kind=="Application" and .metadata.  │
│    │           name=="<spell>")'                            │
│    └─ Fail if not found, list available spells             │
│                                                              │
│  Step 3: Parse sources                                      │
│    ├─ Extract .spec.sources[] count                        │
│    └─ Validate sources exist                               │
│                                                              │
│  Step 4: Render each source                                 │
│    For each source:                                         │
│      ├─ Extract chart path (./charts/summon)               │
│      ├─ Extract values (valuesObject or values)            │
│      ├─ helm template <release> <chart> -f <values>        │
│      ├─ Count resources                                    │
│      ├─ Show resource summary                              │
│      └─ Save to output-test/spell-<spell>-source-N.yaml    │
│                                                              │
│  Flags:                                                     │
│    --book <name>  : Specify book (default: example-tdd-book)│
│    --debug        : Show full helm output                   │
│                                                              │
│  ISSUE: Resource count has newline bug (line 233, 238)     │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Book Handler (test-book.sh)

```
┌─────────────────────────────────────────────────────────────┐
│  test-book.sh <mode> <book> [--chapter <ch>] [--debug]     │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  detect_book_type():                                        │
│    ├─ Check for realm: in index.yaml                       │
│    ├─ "covenant" if realm: found                           │
│    ├─ "regular" if no realm:                               │
│    └─ "unknown" if no index.yaml                           │
│                                                              │
│  test_covenant_book():                                      │
│    ├─ Parse flags (--chapter, --type, --debug)             │
│    ├─ Delegate to tests/scripts/test-covenant-book.sh      │
│    └─ Track result                                         │
│                                                              │
│  test_regular_book():                                       │
│    ├─ PLACEHOLDER - not implemented                        │
│    ├─ Lists book structure                                 │
│    └─ increment_skipped()                                  │
│                                                              │
│  test_book():                                               │
│    ├─ Detect type                                          │
│    ├─ Route to covenant or regular handler                 │
│    └─ Return result                                        │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Data Flow Example: Testing Vault Glyph

```
User Command:
  $ make test comprehensive glyph vault

Makefile:
  ├─ Parse: ARGS = ["comprehensive", "glyph", "vault"]
  └─ Execute: bash tests/core/test-dispatcher.sh comprehensive glyph vault

Dispatcher (test-dispatcher.sh):
  ├─ parse_args():
  │   ├─ MODE = "comprehensive"
  │   ├─ TYPE = "glyph"
  │   └─ COMPONENTS = ["vault"]
  ├─ dispatch():
  │   └─ bash tests/core/test-glyph.sh comprehensive vault

Handler (test-glyph.sh):
  ├─ main("comprehensive", "vault")
  ├─ test_glyphs("comprehensive", ["vault"])
  ├─ test_glyph("vault", "comprehensive")
  │   ├─ glyph_exists("vault") → true
  │   ├─ validate_has_examples() → true
  │   ├─ get_glyph_examples("vault") → 15 files
  │   └─ For each example (15 iterations):
  │       └─ test_glyph_comprehensive("vault", example, test_name)
  │           ├─ render_template($KASTER_DIR, example, test_name)
  │           │   └─ helm template test-vault kaster -f example.yaml
  │           ├─ has_errors(output) → false
  │           ├─ count_resources(output) → e.g., 10
  │           ├─ log_success("vault/secrets: Generated 10 resources")
  │           └─ increment_passed()
  └─ print_summary()
      ├─ Total: 15
      ├─ Passed: 15
      └─ Failed: 0

Output:
  [INFO] vault: Found 15 examples
  [PASS] vault/secrets: Generated 10 resources
  [PASS] vault/policies: Generated 13 resources
  ...
  [PASS] vault: All tests passed (15/15)

  Test Summary
  Total:   15
  Passed:  15
  Failed:  0
  Skipped: 0
```

## Auto-Discovery Flow

```
User Command:
  $ make test all glyph

Auto-Discovery Sequence:
  ├─ Handler: test_glyphs("all", ["all"])
  ├─ Check: if components == "all"
  ├─ Call: discover_tested_glyphs()
  │   ├─ Scan: charts/glyphs/*/examples/*.yaml
  │   ├─ Find: argo-events (5 examples)
  │   ├─ Find: certManager (2 examples)
  │   ├─ Find: vault (15 examples)
  │   └─ ... (all glyphs with examples)
  ├─ Return: ["argo-events", "certManager", ..., "vault"]
  ├─ Log: "Auto-discovering glyphs..."
  ├─ Log: "Found 13 glyphs total"
  └─ Test: Each glyph in mode "all"

Result:
  Tests all 13 glyphs with all modes (syntax, comprehensive, snapshots)
  Total time: ~5 minutes (13 glyphs × avg 8 examples × 3 modes)
```

## Validation Layers

```
┌─────────────────────────────────────────────────────────────┐
│                    VALIDATION LAYERS                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Layer 1: Syntax Validation                                 │
│    ├─ Tool: helm template                                   │
│    ├─ Check: Template renders without errors               │
│    └─ Fast: ~0.3s per test                                 │
│                                                              │
│  Layer 2: Resource Generation                               │
│    ├─ Tool: helm template + grep                           │
│    ├─ Check: count_resources() > 0                         │
│    └─ Fast: ~0.3s per test                                 │
│                                                              │
│  Layer 3: Resource Completeness                             │
│    ├─ Tool: validate-resource-completeness.sh              │
│    ├─ Check: Expected resources based on values            │
│    │   - workload.enabled → Deployment/StatefulSet         │
│    │   - service.enabled → Service                         │
│    │   - volumes.*.type=pvc → PVC                          │
│    │   - autoscaling.enabled → HPA                         │
│    └─ Medium: ~0.5s per test                               │
│                                                              │
│  Layer 4: Snapshot Comparison                               │
│    ├─ Tool: diff                                           │
│    ├─ Check: output matches expected.yaml                  │
│    └─ Fast: ~0.1s per test                                 │
│                                                              │
│  Layer 5: K8s Schema Validation                             │
│    ├─ Tool: helm install --dry-run                         │
│    ├─ Check: Resources valid against K8s API               │
│    └─ Slow: ~0.8s per test                                 │
│                                                              │
└─────────────────────────────────────────────────────────────┘

Mode Coverage:
  syntax       → Layers 1
  comprehensive → Layers 1, 2, 3
  snapshots    → Layers 1, 2, 4, 5
  all          → Layers 1, 2, 3, 4, 5
```

## Error Propagation

```
┌─────────────────────────────────────────────────────────────┐
│                   ERROR HANDLING FLOW                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  1. Template Error (helm template fails)                    │
│     ├─ Caught by: validate_syntax() or render_template()   │
│     ├─ Logged: log_error() with error message              │
│     ├─ Tracked: increment_failed()                         │
│     └─ Exit: Returns 1 to handler                          │
│                                                              │
│  2. No Resources Generated                                  │
│     ├─ Caught by: count_resources() == 0                   │
│     ├─ Logged: log_error("No resources generated")         │
│     ├─ Tracked: increment_failed()                         │
│     └─ Exit: Returns 1 to handler                          │
│                                                              │
│  3. Snapshot Mismatch                                       │
│     ├─ Caught by: compare_snapshot() returns 1             │
│     ├─ Logged: log_error() + diff command hint             │
│     ├─ Tracked: increment_failed()                         │
│     └─ Exit: Returns 1 to handler                          │
│                                                              │
│  4. Component Not Found                                     │
│     ├─ Caught by: glyph_exists() returns false             │
│     ├─ Logged: log_error("Glyph not found")                │
│     ├─ Tracked: increment_failed()                         │
│     └─ Exit: Returns 1 immediately                         │
│                                                              │
│  5. No Examples                                             │
│     ├─ Caught by: validate_has_examples() returns false    │
│     ├─ Logged: log_warning("No examples found")            │
│     ├─ Tracked: increment_skipped()                        │
│     └─ Exit: Returns 2 to handler                          │
│                                                              │
│  6. Handler Failure                                         │
│     ├─ Aggregated: test_glyph() returns 1 if any fail      │
│     ├─ Logged: log_error("X/Y tests failed")               │
│     ├─ Tracked: Added to failed_glyphs[]                   │
│     └─ Exit: Handler exits with 1                          │
│                                                              │
│  7. Dispatcher Failure                                      │
│     ├─ Aggregated: print_summary() returns 1 if FAILED > 0 │
│     ├─ Logged: Summary shows failed count                  │
│     └─ Exit: Dispatcher exits with 1                       │
│                                                              │
│  8. Makefile Propagation                                    │
│     ├─ Check: make test exits with non-zero                │
│     ├─ Action: CI pipeline fails                           │
│     └─ Display: Error message in red                       │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## File Structure

```
kast-system/
├── Makefile                           # Entry point
├── tests/
│   ├── core/                          # Dispatcher & handlers
│   │   ├── test-dispatcher.sh         # Main router
│   │   ├── test-glyph.sh              # Glyph handler
│   │   ├── test-trinket.sh            # Trinket handler
│   │   ├── test-chart.sh              # Chart handler
│   │   ├── test-spell.sh              # Spell handler
│   │   └── test-book.sh               # Book handler
│   ├── lib/                           # Shared libraries
│   │   ├── utils.sh                   # Logging, tracking
│   │   ├── discover.sh                # Auto-discovery
│   │   └── validate.sh                # Validation functions
│   └── scripts/                       # Legacy/specialized
│       ├── validate-resource-completeness.sh
│       └── test-covenant-book.sh
├── charts/
│   ├── glyphs/                        # Glyph sources
│   │   ├── vault/
│   │   │   ├── Chart.yaml
│   │   │   ├── templates/
│   │   │   └── examples/              # Test cases
│   │   │       ├── secrets.yaml
│   │   │       ├── policies.yaml
│   │   │       └── ...
│   │   └── ...
│   ├── trinkets/                      # Trinket sources
│   │   ├── tarot/
│   │   │   ├── Chart.yaml
│   │   │   ├── templates/
│   │   │   └── examples/
│   │   └── microspell/
│   ├── summon/                        # Main chart
│   │   ├── Chart.yaml
│   │   ├── templates/
│   │   └── examples/
│   └── kaster/                        # Glyph orchestrator
│       ├── Chart.yaml
│       ├── templates/
│       └── examples/
├── librarian/                         # ArgoCD Apps of Apps
│   ├── Chart.yaml
│   └── templates/
├── bookrack/                          # Configuration books
│   └── example-tdd-book/
│       ├── index.yaml
│       └── intro/
│           ├── example-api.yaml
│           └── ...
└── output-test/                       # Generated outputs
    ├── vault/
    │   ├── secrets.yaml
    │   ├── secrets.expected.yaml
    │   └── ...
    ├── summon/
    └── spell-example-api-source-1-summon.yaml
```

---

**Architecture Version:** 1.0
**Last Updated:** 2025-11-15
**For Implementation Details:** See AUDIT_REPORT_TEST_DISPATCHER.md
