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

test-tarot: ## Test Tarot trinket system (all modes: syntax, execution, cards, secrets, rbac)
	@tests/scripts/test-tarot.sh all

# =============================================================================
# COVENANT BOOK TESTING
# =============================================================================

.PHONY: test-covenant list-covenant-books

test-covenant: ## Test all covenant books (Usage: make test-covenant or make test-covenant BOOK=covenant-tyl)
	@if [ -z "$(BOOK)" ]; then \
		echo "$(BLUE)📖 Testing all covenant books...$(RESET)"; \
		tests/scripts/test-covenant-book.sh covenant-tyl; \
		tests/scripts/test-covenant-book.sh covenant-test-full; \
	else \
		echo "$(BLUE)📖 Testing covenant book: $(BOOK)...$(RESET)"; \
		tests/scripts/test-covenant-book.sh $(BOOK); \
	fi

list-covenant-books: ## List all available covenant books
	@echo "$(BLUE)📚 Available Covenant Books:$(RESET)"
	@BOOKRACK_PATH=$${COVENANT_BOOKRACK_PATH:-$$HOME/_home/the.yaml.life/proto-the-yaml-life/bookrack}; \
	if [ -d "$$BOOKRACK_PATH" ]; then \
		find "$$BOOKRACK_PATH" -maxdepth 2 -name "index.yaml" -exec grep -l "realm:" {} \; 2>/dev/null | \
			xargs -I {} dirname {} | xargs -I {} basename {} | sort | sed 's/^/  - /'; \
	else \
		echo "  $(YELLOW)Bookrack not found at: $$BOOKRACK_PATH$(RESET)"; \
		echo "  $(YELLOW)Set COVENANT_BOOKRACK_PATH to override$(RESET)"; \
	fi

# =============================================================================
# SPELL TESTING (Simple individual spell testing)
# =============================================================================

test-spell: ## Test individual spell with context (Usage: make test-spell BOOK=example-tdd-book SPELL=example-api)
	@if [ -z "$(BOOK)" ] || [ -z "$(SPELL)" ]; then \
		echo "$(RED)Error: BOOK and SPELL variables required$(RESET)"; \
		echo "$(YELLOW)Usage: make test-spell BOOK=example-tdd-book SPELL=example-api$(RESET)"; \
		exit 1; \
	fi
	@tests/scripts/test-spell.sh $(BOOK) $(SPELL)

# =============================================================================
# LINTING & VALIDATION
# =============================================================================

lint: ## Run helm lint on all charts (glyphs as templates, not dependencies)
	@echo "$(BLUE)🔍 Linting all charts...$(RESET)"
	@echo "$(YELLOW)Note: Glyphs are copied templates, not helm dependencies - lint warnings about missing dependencies are expected$(RESET)"
	@echo ""
	@FAILED=0; \
	for chart_dir in $(CHARTS_DIR)/summon $(CHARTS_DIR)/kaster $(LIBRARIAN_DIR) $(CHARTS_DIR)/trinkets/*; do \
		if [ -f "$$chart_dir/Chart.yaml" ]; then \
			chart_name=$$(basename $$chart_dir); \
			echo "$(BLUE)  Linting $$chart_name...$(RESET)"; \
			LINT_OUTPUT=$$(helm lint $$chart_dir 2>&1); \
			LINT_EXIT=$$?; \
			if echo "$$LINT_OUTPUT" | grep -q "chart metadata is missing these dependencies"; then \
				echo "$(YELLOW)  ⚠️  $$chart_name (glyphs not declared as dependencies - by design)$(RESET)"; \
			elif [ $$LINT_EXIT -eq 0 ]; then \
				echo "$(GREEN)  ✅ $$chart_name$(RESET)"; \
			else \
				echo "$(RED)  ❌ $$chart_name (real errors found)$(RESET)"; \
				echo "$$LINT_OUTPUT" | grep -E "\[ERROR\]" | sed 's/^/     /'; \
				FAILED=1; \
			fi; \
		fi; \
	done; \
	if [ $$FAILED -eq 1 ]; then \
		echo ""; \
		echo "$(RED)❌ Lint found real errors (not dependency warnings)$(RESET)"; \
		exit 1; \
	fi

# =============================================================================
# CLEANUP
# =============================================================================

clean: ## Clean up generated test files
	@echo "$(BLUE)🧹 TDD: Cleaning up test files...$(RESET)"
	@rm -rf $(OUTPUT_TEST_DIR)
	@echo "$(GREEN)✅ Cleanup completed$(RESET)"

