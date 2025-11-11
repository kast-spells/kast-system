# Kast Framework - TDD Testing System
# Test-Driven Development for Kubernetes Helm Charts

# Colors for output
BLUE := \033[36m
GREEN := \033[32m
YELLOW := \033[33m
RED := \033[31m
RESET := \033[0m

# Directories
CHARTS_DIR := charts
GLYPHS_DIR := $(CHARTS_DIR)/glyphs  
TRINKETS_DIR := $(CHARTS_DIR)/trinkets
SUMMON_DIR := $(CHARTS_DIR)/summon
KASTER_DIR := $(CHARTS_DIR)/kaster
LIBRARIAN_DIR := librarian
TESTS_DIR := tests

.PHONY: help test test-all tdd-red tdd-green tdd-refactor lint validate clean

# Default target
help: ## Show this help message
	@echo "$(BLUE)Kast Framework TDD Testing Commands$(RESET)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "$(GREEN)%-25s$(RESET) %s\n", $$1, $$2}'

# =============================================================================
# TDD WORKFLOW TARGETS
# =============================================================================

tdd-red: ## TDD Red: Run tests expecting failures (write tests first)
	@echo "$(RED)🔴 TDD RED: Running tests expecting failures...$(RESET)"
	@echo "$(RED)Write your tests/examples first, then run this to see failures$(RESET)"
	@$(MAKE) test-comprehensive || echo "$(RED)✅ Good! Tests are failing - now implement to make them pass$(RESET)"

tdd-green: ## TDD Green: Run tests expecting success (after implementation)
	@echo "$(GREEN)🟢 TDD GREEN: Running tests expecting success...$(RESET)"
	@$(MAKE) test-comprehensive

tdd-refactor: ## TDD Refactor: Run tests after refactoring (should still pass)
	@echo "$(BLUE)🔵 TDD REFACTOR: Running tests after refactoring...$(RESET)"
	@$(MAKE) test-all

# =============================================================================
# CORE TESTING TARGETS
# =============================================================================

test: test-comprehensive test-tarot lint ## Run comprehensive TDD tests (original)
	@echo "$(GREEN)✅ TDD tests completed successfully!$(RESET)"

test-all: test-comprehensive test-snapshots test-glyphs-all test-tarot lint ## Run all TDD tests (comprehensive + snapshots + glyphs)
	@echo "$(GREEN)✅ All TDD tests completed successfully!$(RESET)"

test-status: ## Show testing status for all charts, glyphs, and trinkets
	@tests/scripts/test-status.sh
	@echo "$(BLUE)📊 Testing Status Report$(RESET)"
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)"
	@echo ""
	@echo "$(BLUE)📦 Main Charts:$(RESET)"
	@find . -name "Chart.yaml" -not -path "./charts/glyphs/*" -not -path "./charts/trinkets/*" | while read chart_file; do \
		chart_dir=$$(dirname $$chart_file); \
		chart_name=$$(basename $$chart_dir); \
		if [ -d "$$chart_dir/examples" ]; then \
			example_count=$$(find $$chart_dir/examples -name "*.yaml" -type f 2>/dev/null | wc -l); \
			snapshot_count=$$(find output-test/$$chart_name -name "*.expected.yaml" -type f 2>/dev/null | wc -l); \
			if [ $$snapshot_count -gt 0 ]; then \
				echo "  $(GREEN)✅ $$chart_name: $$example_count examples ($$snapshot_count snapshots)$(RESET)"; \
			else \
				echo "  $(YELLOW)⚠️  $$chart_name: $$example_count examples (no snapshots)$(RESET)"; \
			fi; \
		else \
			echo "  $(RED)❌ $$chart_name: NO examples/$(RESET)"; \
		fi; \
	done
	@echo ""
	@echo "$(BLUE)🎭 Glyphs:$(RESET)"
	@for glyph_dir in charts/glyphs/*/; do \
		glyph_name=$$(basename $$glyph_dir); \
		if [ -d "$$glyph_dir/examples" ]; then \
			example_count=$$(find $$glyph_dir/examples -name "*.yaml" -type f 2>/dev/null | wc -l); \
			snapshot_count=$$(find output-test/$$glyph_name -name "*.expected.yaml" -type f 2>/dev/null | wc -l); \
			if [ $$snapshot_count -gt 0 ]; then \
				echo "  $(GREEN)✅ $$glyph_name: $$example_count examples ($$snapshot_count snapshots)$(RESET)"; \
			else \
				echo "  $(YELLOW)⚠️  $$glyph_name: $$example_count examples (no snapshots)$(RESET)"; \
			fi; \
		else \
			echo "  $(RED)❌ $$glyph_name: NO examples/$(RESET)"; \
		fi; \
	done
	@echo ""
	@echo "$(BLUE)🔮 Trinkets:$(RESET)"
	@for trinket_dir in charts/trinkets/*/; do \
		trinket_name=$$(basename $$trinket_dir); \
		if [ -d "$$trinket_dir/examples" ]; then \
			example_count=$$(find $$trinket_dir/examples -name "*.yaml" -type f 2>/dev/null | wc -l); \
			snapshot_count=$$(find output-test/$$trinket_name -name "*.expected.yaml" -type f 2>/dev/null | wc -l); \
			if [ $$snapshot_count -gt 0 ]; then \
				echo "  $(GREEN)✅ $$trinket_name: $$example_count examples ($$snapshot_count snapshots)$(RESET)"; \
			else \
				echo "  $(YELLOW)⚠️  $$trinket_name: $$example_count examples (no snapshots)$(RESET)"; \
			fi; \
		else \
			echo "  $(RED)❌ $$trinket_name: NO examples/$(RESET)"; \
		fi; \
	done
	@echo ""
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)"

test-syntax: ## Quick syntax validation for all charts
	@tests/scripts/test-charts.sh syntax

test-comprehensive: ## Test charts with comprehensive validation (rendering + resource completeness)
	@tests/scripts/test-charts.sh comprehensive

test-snapshots: ## Test charts with snapshot validation + K8s schema (dry-run)
	@tests/scripts/test-charts.sh snapshots

# =============================================================================
# GLYPH TESTING (via Kaster orchestration)
# =============================================================================

# Output test directory for expected results
OUTPUT_TEST_DIR := output-test

# Dynamic glyph testing - Usage: make glyphs <glyph-name>
glyphs: ## Test specific glyph (Usage: make glyphs vault)
	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "$(RED)Usage: make glyphs <glyph-name>$(RESET)"; \
		echo "$(BLUE)Available glyphs:$(RESET)"; \
		ls -1 $(GLYPHS_DIR) | sed 's/^/  - /'; \
		exit 1; \
	fi
	@$(MAKE) test-glyph-$(filter-out $@,$(MAKECMDGOALS))

# Catch-all rule for glyph names to prevent make errors
%:
	@:

test-glyphs-all: ## Test all glyphs through kaster system
	@tests/scripts/test-glyphs.sh all

# Generic glyph testing with diff validation
test-glyph-%:
	@tests/scripts/test-glyphs.sh test $*

# =============================================================================
# INSPECTION AND DEBUGGING
# =============================================================================

inspect-chart: ## Inspect rendered output for specific chart and example (Usage: make inspect-chart CHART=summon EXAMPLE=basic-deployment)
	@if [ -z "$(CHART)" ] || [ -z "$(EXAMPLE)" ]; then \
		echo "$(RED)Usage: make inspect-chart CHART=summon EXAMPLE=basic-deployment$(RESET)"; \
		exit 1; \
	fi
	@echo "$(BLUE)📋 Inspecting $(CHART)/$(EXAMPLE)...$(RESET)"
	@helm template inspect-$(CHART)-$(EXAMPLE) $(CHARTS_DIR)/$(CHART) -f $(CHARTS_DIR)/$(CHART)/examples/$(EXAMPLE).yaml

debug-chart: ## Debug chart rendering with verbose output (Usage: make debug-chart CHART=summon EXAMPLE=basic-deployment)  
	@if [ -z "$(CHART)" ] || [ -z "$(EXAMPLE)" ]; then \
		echo "$(RED)Usage: make debug-chart CHART=summon EXAMPLE=basic-deployment$(RESET)"; \
		exit 1; \
	fi
	@echo "$(BLUE)🐛 Debugging $(CHART)/$(EXAMPLE)...$(RESET)"
	@helm template debug-$(CHART)-$(EXAMPLE) $(CHARTS_DIR)/$(CHART) -f $(CHARTS_DIR)/$(CHART)/examples/$(EXAMPLE).yaml --debug

# =============================================================================
# GLYPH OUTPUT MANAGEMENT
# =============================================================================

generate-expected: ## Generate expected outputs for glyph (Usage: make generate-expected GLYPH=vault)
	@tests/scripts/test-glyphs.sh generate $(GLYPH)

show-glyph-diff: ## Show diff for specific glyph test (Usage: make show-glyph-diff GLYPH=vault EXAMPLE=secrets)
	@tests/scripts/test-glyphs.sh show-diff $(GLYPH) $(EXAMPLE)

list-glyphs: ## List all available glyphs
	@echo "$(BLUE)Available glyphs:$(RESET)"
	@ls -1 $(GLYPHS_DIR) | sed 's/^/  - /'

clean-output-tests: ## Clean generated output test files
	@echo "$(BLUE)🧽 Cleaning output test files...$(RESET)"
	@rm -rf $(OUTPUT_TEST_DIR)
	@echo "$(GREEN)✅ Output test files cleaned$(RESET)"

# =============================================================================
# SNAPSHOT MANAGEMENT (for all charts)
# =============================================================================

generate-snapshots: ## Generate expected snapshots for chart (Usage: make generate-snapshots CHART=summon)
	@tests/scripts/manage-snapshots.sh generate $(CHART)

update-snapshot: ## Update specific snapshot (Usage: make update-snapshot CHART=summon EXAMPLE=basic-deployment)
	@tests/scripts/manage-snapshots.sh update $(CHART) $(EXAMPLE)

update-all-snapshots: ## Update all snapshots for all charts
	@tests/scripts/manage-snapshots.sh update-all

show-snapshot-diff: ## Show diff for specific snapshot (Usage: make show-snapshot-diff CHART=summon EXAMPLE=basic-deployment)
	@tests/scripts/manage-snapshots.sh show-diff $(CHART) $(EXAMPLE)

# =============================================================================
# DEVELOPMENT WORKFLOW
# =============================================================================

watch: ## Watch for changes and run TDD tests (requires entr)
	@echo "$(BLUE)👁️  TDD: Watching for changes... (Press Ctrl+C to stop)$(RESET)"
	@find $(CHARTS_DIR) -name "*.yaml" -o -name "*.tpl" | entr -c make test

create-example: ## Create a new example file (Usage: make create-example CHART=summon EXAMPLE=my-test)
	@if [ -z "$(CHART)" ] || [ -z "$(EXAMPLE)" ]; then \
		echo "$(RED)Usage: make create-example CHART=summon EXAMPLE=my-test$(RESET)"; \
		exit 1; \
	fi
	@mkdir -p $(CHARTS_DIR)/$(CHART)/examples
	@echo "# $(EXAMPLE) Example" > $(CHARTS_DIR)/$(CHART)/examples/$(EXAMPLE).yaml
	@echo "# TDD: Write your test configuration here" >> $(CHARTS_DIR)/$(CHART)/examples/$(EXAMPLE).yaml
	@echo "$(GREEN)✅ Created $(CHARTS_DIR)/$(CHART)/examples/$(EXAMPLE).yaml$(RESET)"
	@echo "$(BLUE)Next: Edit the example file and run 'make tdd-red' to see it fail$(RESET)"

# =============================================================================
# TAROT SYSTEM TESTING
# =============================================================================

test-tarot: ## Test Tarot trinket system comprehensively
	@tests/scripts/test-tarot.sh all

test-tarot-syntax: ## Test Tarot template syntax validation
	@tests/scripts/test-tarot.sh syntax

test-tarot-execution-modes: ## Test all Tarot execution modes
	@tests/scripts/test-tarot.sh execution-modes

test-tarot-card-resolution: ## Test Tarot card resolution system
	@tests/scripts/test-tarot.sh card-resolution

test-tarot-secrets: ## Test Tarot secret management
	@tests/scripts/test-tarot.sh secrets

test-tarot-rbac: ## Test Tarot RBAC system
	@tests/scripts/test-tarot.sh rbac

test-tarot-complex: ## Test complex Tarot workflows
	@tests/scripts/test-tarot.sh complex

# =============================================================================
# COVENANT BOOK TESTING
# =============================================================================

.PHONY: test-covenant test-covenant-tyl test-covenant-test-full list-covenant-books

test-covenant: test-covenant-tyl test-covenant-test-full ## Test all covenant books

test-covenant-tyl: ## Test covenant-tyl book
	@echo "$(BLUE)📖 Testing covenant-tyl book...$(RESET)"
	@tests/scripts/test-covenant-book.sh covenant-tyl

test-covenant-test-full: ## Test covenant-test-full book
	@echo "$(BLUE)📖 Testing covenant-test-full book...$(RESET)"
	@tests/scripts/test-covenant-book.sh covenant-test-full

test-covenant-book: ## Test specific covenant book (use BOOK=<name>)
	@if [ -z "$(BOOK)" ]; then \
		echo "$(RED)Error: BOOK variable not set$(RESET)"; \
		echo "$(YELLOW)Usage: make test-covenant-book BOOK=covenant-tyl$(RESET)"; \
		exit 1; \
	fi
	@echo "$(BLUE)📖 Testing covenant book: $(BOOK)...$(RESET)"
	@tests/scripts/test-covenant-book.sh $(BOOK)

test-covenant-chapter: ## Test specific chapter of covenant book (use BOOK=<name> CHAPTER=<chapter>)
	@if [ -z "$(BOOK)" ] || [ -z "$(CHAPTER)" ]; then \
		echo "$(RED)Error: BOOK and CHAPTER variables required$(RESET)"; \
		echo "$(YELLOW)Usage: make test-covenant-chapter BOOK=covenant-tyl CHAPTER=tyl$(RESET)"; \
		exit 1; \
	fi
	@echo "$(BLUE)📖 Testing covenant book chapter: $(BOOK) / $(CHAPTER)...$(RESET)"
	@tests/scripts/test-covenant-book.sh $(BOOK) --chapter-filter $(CHAPTER)

test-covenant-all-chapters: ## Test covenant book with all chapters (use BOOK=<name>)
	@if [ -z "$(BOOK)" ]; then \
		echo "$(RED)Error: BOOK variable not set$(RESET)"; \
		echo "$(YELLOW)Usage: make test-covenant-all-chapters BOOK=covenant-tyl$(RESET)"; \
		exit 1; \
	fi
	@echo "$(BLUE)📖 Testing covenant book with all chapters: $(BOOK)...$(RESET)"
	@tests/scripts/test-covenant-book.sh $(BOOK) --all-chapters

test-covenant-debug: ## Debug covenant book rendering (use BOOK=<name>)
	@if [ -z "$(BOOK)" ]; then \
		echo "$(RED)Error: BOOK variable not set$(RESET)"; \
		echo "$(YELLOW)Usage: make test-covenant-debug BOOK=covenant-tyl$(RESET)"; \
		exit 1; \
	fi
	@echo "$(BLUE)🔍 Debug rendering covenant book: $(BOOK)...$(RESET)"
	@tests/scripts/test-covenant-book.sh $(BOOK) --debug

list-covenant-books: ## List all available covenant books (from proto-the-yaml-life)
	@echo "$(BLUE)📚 Available Covenant Books (proto-the-yaml-life):$(RESET)"
	@find /home/namen/_home/the.yaml.life/proto-the-yaml-life/bookrack -maxdepth 2 -name "index.yaml" -exec grep -l "realm:" {} \; 2>/dev/null | \
		xargs -I {} dirname {} | xargs -I {} basename {} | sort | sed 's/^/  - /' || echo "  $(YELLOW)No covenant books found$(RESET)"

# =============================================================================
# CLEANUP
# =============================================================================

clean: ## Clean up generated test files
	@echo "$(BLUE)🧹 TDD: Cleaning up test files...$(RESET)"
	@rm -rf $(OUTPUT_TEST_DIR)
	@echo "$(GREEN)✅ Cleanup completed$(RESET)"
# RunicIndexer Tests
.PHONY: test-runic-indexer test-runic-and-logic test-runic-fallback test-runic-empty

test-runic-indexer: test-runic-and-logic test-runic-fallback test-runic-empty

test-runic-and-logic:
	@echo "🧪 Testing runicIndexer AND logic (multi-selector)..."
	@echo "Expected: Only external-gateway (matches access=external AND environment=staging)"
	@helm template test-lexicon charts/kaster -f charts/glyphs/runic-system/examples/lexicon-lookup.yaml 2>&1 | \
		grep -E "(kind: VirtualService|name: test-|hosts:)" | \
		grep -A2 "kind: VirtualService" || echo "  ❌ Test failed"
	@echo ""

test-runic-fallback:
	@echo "🧪 Testing runicIndexer fallback to chapter/book defaults..."
	@echo "Expected: chapter-default-gateway (selector doesn't match, falls back to chapter default)"
	@helm template test-fallback charts/kaster -f charts/glyphs/runic-system/examples/fallback-defaults.yaml 2>&1 | \
		grep -E "(kind: VirtualService|name:|hosts:)" | \
		grep -A2 "kind: VirtualService" || echo "  ❌ Test failed"
	@echo ""

test-runic-empty:
	@echo "🧪 Testing runicIndexer with empty selector..."
	@echo "Expected: chapter-default (NOT all gateways!)"
	@helm template test-empty charts/kaster -f charts/glyphs/runic-system/examples/empty-selector.yaml 2>&1 | \
		grep -E "(kind: VirtualService|name:|hosts:)" | \
		grep -A2 "kind: VirtualService" || echo "  ❌ Test failed"
	@echo ""

# =============================================================================
# LIBRARIAN MIGRATION TESTING (ApplicationSets TDD)
# =============================================================================

.PHONY: snapshot-librarian test-librarian-appsets compare-librarian-migration tdd-librarian-red tdd-librarian-green tdd-librarian-refactor render-spell-from-cluster

LIBRARIAN_SNAPSHOT_DIR := $(OUTPUT_TEST_DIR)/librarian-snapshot
LIBRARIAN_APPSETS_DIR := $(OUTPUT_TEST_DIR)/librarian-appsets

snapshot-librarian: ## Generate snapshot of current librarian Applications (TDD baseline)
	@echo "$(BLUE)📸 TDD: Generating librarian Applications snapshot...$(RESET)"
	@tests/scripts/test-librarian-migration.sh baseline the-yaml-life $(LIBRARIAN_SNAPSHOT_DIR)

# Deprecated - use snapshot-librarian
test-librarian-appsets: ## Test ApplicationSet expansion (simulates git files generator)
	@echo "$(BLUE)🔮 TDD: Testing ApplicationSet expansion...$(RESET)"
	@tests/scripts/test-librarian-migration.sh test the-yaml-life /home/namen/_home/the.yaml.life/proto-the-yaml-life/bookrack $(LIBRARIAN_APPSETS_DIR)

# Deprecated - use compare-librarian-migration  
compare-librarian-migration: ## Compare current vs ApplicationSet generated Applications
	@echo "$(BLUE)🔍 TDD: Comparing librarian migration...$(RESET)"
	@tests/scripts/test-librarian-migration.sh compare $(LIBRARIAN_SNAPSHOT_DIR) $(LIBRARIAN_APPSETS_DIR)

render-spell-from-cluster: ## Render spell from cluster Application (Usage: make render-spell-from-cluster SPELL=stalwart)
	@tests/scripts/test-librarian-migration.sh render $(SPELL)

tdd-librarian-red: snapshot-librarian ## TDD Red: Generate snapshot baseline (before ApplicationSets)
	@echo "$(GREEN)✅ Snapshot generated at $(LIBRARIAN_SNAPSHOT_DIR)$(RESET)"
	@echo "$(YELLOW)Next: Modify librarian to generate ApplicationSets, then run 'make tdd-librarian-green'$(RESET)"

tdd-librarian-green: test-librarian-appsets compare-librarian-migration ## TDD Green: Test ApplicationSets match snapshot
	@echo "$(GREEN)✅ TDD Green phase complete!$(RESET)"

tdd-librarian-refactor: tdd-librarian-green ## TDD Refactor: Verify after refactoring
	@echo "$(BLUE)🔵 TDD Refactor: Re-running tests...$(RESET)"
	@$(MAKE) test-librarian-appsets
	@$(MAKE) compare-librarian-migration
