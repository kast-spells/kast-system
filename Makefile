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
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)"
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
	@echo "$(BLUE)🚀 TDD: Running syntax validation...$(RESET)"
	@find . -name "Chart.yaml" -not -path "./charts/glyphs/*" | while read chart_file; do \
		chart_dir=$$(dirname $$chart_file); \
		chart_name=$$(basename $$chart_dir); \
		helm template test-syntax-$$chart_name $$chart_dir > /dev/null && \
			echo "$(GREEN)✅ $$chart_name syntax$(RESET)" || \
			echo "$(RED)❌ $$chart_name syntax$(RESET)"; \
	done

test-comprehensive: ## Test charts with comprehensive validation (rendering + resource completeness)
	@echo "$(BLUE)🧪 TDD: Comprehensive validation (rendering + resource expectations)...$(RESET)"
	@find . -name "Chart.yaml" -not -path "./charts/glyphs/*" | while read chart_file; do \
		chart_dir=$$(dirname $$chart_file); \
		chart_name=$$(basename $$chart_dir); \
		echo "$(BLUE)Testing chart: $$chart_name$(RESET)"; \
		if [ -d "$$chart_dir/examples" ]; then \
			for example in $$chart_dir/examples/*.yaml; do \
				if [ -f "$$example" ]; then \
					example_name=$$(basename $$example .yaml); \
					test_name="tdd-$$chart_name-$$example_name"; \
					echo "$(BLUE)  Validating $$example_name...$(RESET)"; \
					if helm template $$test_name $$chart_dir -f $$example > /dev/null 2>&1; then \
						if $(TESTS_DIR)/scripts/validate-resource-completeness.sh $$chart_dir $$example $$test_name; then \
							echo "$(GREEN)✅ $$chart_name-$$example_name$(RESET)"; \
						else \
							echo "$(RED)❌ $$chart_name-$$example_name (expectations failed)$(RESET)"; \
						fi; \
					else \
						echo "$(RED)❌ $$chart_name-$$example_name (rendering failed)$(RESET)"; \
					fi; \
				fi \
			done \
		else \
			echo "$(YELLOW)⚠️  $$chart_name has no examples/ directory - create test examples for TDD$(RESET)"; \
			helm template test-$$chart_name $$chart_dir > /dev/null && \
				echo "$(GREEN)✅ $$chart_name-basic$(RESET)" || \
				echo "$(RED)❌ $$chart_name-basic$(RESET)"; \
		fi \
	done

test-snapshots: ## Test charts with snapshot validation + K8s schema (dry-run)
	@echo "$(BLUE)📸 TDD: Snapshot + K8s schema validation...$(RESET)"
	@find . -name "Chart.yaml" -not -path "./charts/glyphs/*" | while read chart_file; do \
		chart_dir=$$(dirname $$chart_file); \
		chart_name=$$(basename $$chart_dir); \
		echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)"; \
		echo "$(BLUE)Testing chart: $$chart_name$(RESET)"; \
		echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)"; \
		if [ -d "$$chart_dir/examples" ]; then \
			for example in $$chart_dir/examples/*.yaml; do \
				if [ -f "$$example" ]; then \
					example_name=$$(basename $$example .yaml); \
					test_name="tdd-$$chart_name-$$example_name"; \
					echo "$(BLUE)  Testing $$example_name...$(RESET)"; \
					mkdir -p $(OUTPUT_TEST_DIR)/$$chart_name; \
					actual_output="$(OUTPUT_TEST_DIR)/$$chart_name/$$example_name.yaml"; \
					expected_output="$(OUTPUT_TEST_DIR)/$$chart_name/$$example_name.expected.yaml"; \
					issues=0; \
					\
					echo "$(BLUE)    [1/3] Rendering template...$(RESET)"; \
					if helm template $$test_name $$chart_dir -f $$example > $$actual_output 2>/dev/null; then \
						echo "$(GREEN)      ✅ Rendered successfully$(RESET)"; \
					else \
						echo "$(RED)      ❌ Rendering failed$(RESET)"; \
						issues=$$((issues + 1)); \
					fi; \
					\
					if [ $$issues -eq 0 ]; then \
						echo "$(BLUE)    [2/3] Snapshot comparison...$(RESET)"; \
						if [ -f "$$expected_output" ]; then \
							if diff -q $$actual_output $$expected_output > /dev/null 2>&1; then \
								echo "$(GREEN)      ✅ Snapshot matches$(RESET)"; \
							else \
								echo "$(RED)      ❌ Snapshot differs$(RESET)"; \
								echo "$(YELLOW)      💡 diff $$actual_output $$expected_output$(RESET)"; \
								echo "$(YELLOW)      💡 make update-snapshot CHART=$$chart_name EXAMPLE=$$example_name$(RESET)"; \
								issues=$$((issues + 1)); \
							fi; \
						else \
							echo "$(YELLOW)      ⚠️  No snapshot (run: make generate-snapshots CHART=$$chart_name)$(RESET)"; \
						fi; \
						\
						echo "$(BLUE)    [3/3] K8s schema validation...$(RESET)"; \
						if helm install $$test_name $$chart_dir -f $$example --dry-run --namespace validate-ns --create-namespace > /dev/null 2>&1; then \
							echo "$(GREEN)      ✅ Schema valid$(RESET)"; \
						else \
							echo "$(RED)      ❌ Schema validation failed$(RESET)"; \
							issues=$$((issues + 1)); \
						fi; \
					fi; \
					\
					if [ $$issues -eq 0 ]; then \
						echo "$(GREEN)  ✅ $$chart_name-$$example_name$(RESET)"; \
					else \
						echo "$(RED)  ❌ $$chart_name-$$example_name ($$issues issues)$(RESET)"; \
					fi; \
					echo ""; \
				fi \
			done \
		else \
			echo "$(YELLOW)⚠️  $$chart_name has no examples/ directory - create test examples for TDD$(RESET)"; \
			helm template test-$$chart_name $$chart_dir > /dev/null && \
				echo "$(GREEN)✅ $$chart_name-basic$(RESET)" || \
				echo "$(RED)❌ $$chart_name-basic$(RESET)"; \
		fi \
	done

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
	@echo "$(BLUE)🎭 TDD: Testing all glyphs through kaster orchestration...$(RESET)"
	@for glyph in $(GLYPHS_DIR)/*/; do \
		glyph_name=$$(basename $$glyph); \
		if [ -d "$$glyph/examples" ]; then \
			$(MAKE) test-glyph-$$glyph_name || true; \
		fi; \
	done
	@echo "$(GREEN)✅ All glyph tests completed!$(RESET)"

# Generic glyph testing with diff validation
test-glyph-%: 
	@glyph_name="$*"; \
	glyph_dir="charts/glyphs/$$glyph_name"; \
	if [ ! -d "$$glyph_dir" ]; then \
		echo "$(RED)❌ Glyph $$glyph_name not found in $$glyph_dir$(RESET)"; \
		echo "$(BLUE)Available glyphs:$(RESET)"; \
		ls -1 charts/glyphs | sed 's/^/  - /'; \
		exit 1; \
	fi; \
	if [ ! -d "$$glyph_dir/examples" ]; then \
		echo "$(YELLOW)⚠️  $$glyph_name has no examples/ directory$(RESET)"; \
		exit 1; \
	fi; \
	echo "$(BLUE)🎭 Testing $$glyph_name glyphs...$(RESET)"; \
	mkdir -p $(OUTPUT_TEST_DIR)/$$glyph_name; \
	for example in $$glyph_dir/examples/*.yaml; do \
		if [ -f "$$example" ]; then \
			example_name=$$(basename $$example .yaml); \
			test_name=$$(echo "tdd-$$glyph_name-$$example_name" | tr '[:upper:]' '[:lower:]'); \
			echo "$(BLUE)  Testing $$example_name...$(RESET)"; \
			if helm template $$test_name $(KASTER_DIR) -f $$example > $(OUTPUT_TEST_DIR)/$$glyph_name/$$example_name.yaml 2>/dev/null; then \
				expected_file="$(OUTPUT_TEST_DIR)/$$glyph_name/$$example_name.expected.yaml"; \
				if [ -f "$$expected_file" ]; then \
					if diff -q $(OUTPUT_TEST_DIR)/$$glyph_name/$$example_name.yaml $$expected_file > /dev/null 2>&1; then \
						echo "$(GREEN)✅ $$glyph_name-$$example_name (output matches expected)$(RESET)"; \
					else \
						echo "$(RED)❌ $$glyph_name-$$example_name (output differs from expected)$(RESET)"; \
						echo "$(YELLOW)  Run: diff $(OUTPUT_TEST_DIR)/$$glyph_name/$$example_name.yaml $$expected_file$(RESET)"; \
					fi; \
				else \
					echo "$(GREEN)✅ $$glyph_name-$$example_name (rendered successfully, no expected output to compare)$(RESET)"; \
					echo "$(YELLOW)  💡 To add output validation, create: $$expected_file$(RESET)"; \
				fi; \
			else \
				echo "$(RED)❌ $$glyph_name-$$example_name (rendering failed)$(RESET)"; \
			fi; \
		fi; \
	done

# =============================================================================
# VALIDATION AND LINTING
# =============================================================================

lint: ## Run helm lint on all charts using standardized discovery
	@echo "$(BLUE)🔍 TDD: Running helm lint on all charts...$(RESET)"
	@find . -name "Chart.yaml" -not -path "./charts/glyphs/*" | while read chart_file; do \
		chart_dir=$$(dirname $$chart_file); \
		chart_name=$$(basename $$chart_dir); \
		echo "$(BLUE)  Linting $$chart_name...$(RESET)"; \
		helm lint $$chart_dir > /dev/null 2>&1 && \
			echo "$(GREEN)✅ $$chart_name-lint$(RESET)" || \
			echo "$(YELLOW)⚠️  $$chart_name-lint$(RESET)"; \
	done

validate-completeness: ## Run resource completeness validation on all examples
	@echo "$(BLUE)🧪 TDD: Running resource completeness validation...$(RESET)"
	@find . -name "Chart.yaml" -not -path "./charts/glyphs/*" | while read chart_file; do \
		chart_dir=$$(dirname $$chart_file); \
		chart_name=$$(basename $$chart_dir); \
		if [ -d "$$chart_dir/examples" ]; then \
			for example in $$chart_dir/examples/*.yaml; do \
				if [ -f "$$example" ]; then \
					example_name=$$(basename $$example .yaml); \
					test_name="validate-$$chart_name-$$example_name"; \
					$(TESTS_DIR)/scripts/validate-resource-completeness.sh $$chart_dir $$example $$test_name; \
				fi \
			done \
		fi \
	done

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
	@if [ -z "$(GLYPH)" ]; then \
		echo "$(RED)Usage: make generate-expected GLYPH=vault$(RESET)"; \
		exit 1; \
	fi
	@glyph_name="$(GLYPH)"; \
	glyph_dir="charts/glyphs/$$glyph_name"; \
	if [ ! -d "$$glyph_dir" ]; then \
		echo "$(RED)❌ Glyph $$glyph_name not found in $$glyph_dir$(RESET)"; \
		echo "$(BLUE)Available glyphs:$(RESET)"; \
		ls -1 charts/glyphs | sed 's/^/  - /'; \
		exit 1; \
	fi; \
	mkdir -p $(OUTPUT_TEST_DIR)/$$glyph_name; \
	echo "$(BLUE)📄 Generating expected outputs for $$glyph_name...$(RESET)"; \
	for example in $$glyph_dir/examples/*.yaml; do \
		if [ -f "$$example" ]; then \
			example_name=$$(basename $$example .yaml); \
			test_name="tdd-$$glyph_name-$$example_name"; \
			echo "$(BLUE)  Generating $$example_name.expected.yaml...$(RESET)"; \
			if helm template $$test_name $(KASTER_DIR) -f $$example > $(OUTPUT_TEST_DIR)/$$glyph_name/$$example_name.expected.yaml 2>/dev/null; then \
				echo "$(GREEN)✅ Generated $$example_name.expected.yaml$(RESET)"; \
			else \
				echo "$(RED)❌ Failed to generate $$example_name.expected.yaml$(RESET)"; \
			fi; \
		fi; \
	done

show-glyph-diff: ## Show diff for specific glyph test (Usage: make show-glyph-diff GLYPH=vault EXAMPLE=secrets)
	@if [ -z "$(GLYPH)" ] || [ -z "$(EXAMPLE)" ]; then \
		echo "$(RED)Usage: make show-glyph-diff GLYPH=vault EXAMPLE=secrets$(RESET)"; \
		exit 1; \
	fi
	@actual="$(OUTPUT_TEST_DIR)/$(GLYPH)/$(EXAMPLE).yaml"; \
	expected="$(OUTPUT_TEST_DIR)/$(GLYPH)/$(EXAMPLE).expected.yaml"; \
	if [ ! -f "$$actual" ] || [ ! -f "$$expected" ]; then \
		echo "$(RED)❌ Missing files. Run 'make glyphs $(GLYPH)' and 'make generate-expected GLYPH=$(GLYPH)' first$(RESET)"; \
		exit 1; \
	fi; \
	echo "$(BLUE)🔍 Showing diff for $(GLYPH)/$(EXAMPLE)...$(RESET)"; \
	diff -u $$expected $$actual || echo "$(YELLOW)Files differ$(RESET)"

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
	@if [ -z "$(CHART)" ]; then \
		echo "$(RED)Usage: make generate-snapshots CHART=summon$(RESET)"; \
		echo "$(BLUE)Available charts:$(RESET)"; \
		find . -name "Chart.yaml" -not -path "./charts/glyphs/*" -exec dirname {} \; | xargs -n1 basename | sed 's/^/  - /'; \
		exit 1; \
	fi
	@chart_dir="charts/$(CHART)"; \
	if [ "$(CHART)" = "microspell" ] || [ "$(CHART)" = "tarot" ] || [ "$(CHART)" = "covenant" ]; then \
		chart_dir="charts/trinkets/$(CHART)"; \
	elif [ "$(CHART)" = "librarian" ]; then \
		chart_dir="librarian"; \
	fi; \
	if [ ! -d "$$chart_dir" ]; then \
		echo "$(RED)❌ Chart $(CHART) not found in $$chart_dir$(RESET)"; \
		exit 1; \
	fi; \
	if [ ! -d "$$chart_dir/examples" ]; then \
		echo "$(RED)❌ No examples/ directory in $$chart_dir$(RESET)"; \
		exit 1; \
	fi; \
	mkdir -p $(OUTPUT_TEST_DIR)/$(CHART); \
	echo "$(BLUE)📸 Generating snapshots for $(CHART)...$(RESET)"; \
	for example in $$chart_dir/examples/*.yaml; do \
		if [ -f "$$example" ]; then \
			example_name=$$(basename $$example .yaml); \
			test_name="tdd-$(CHART)-$$example_name"; \
			expected_output="$(OUTPUT_TEST_DIR)/$(CHART)/$$example_name.expected.yaml"; \
			echo "$(BLUE)  Generating $$example_name.expected.yaml...$(RESET)"; \
			if helm template $$test_name $$chart_dir -f $$example > $$expected_output 2>/dev/null; then \
				echo "$(GREEN)    ✅ Generated $$expected_output$(RESET)"; \
			else \
				echo "$(RED)    ❌ Failed to generate snapshot$(RESET)"; \
			fi; \
		fi; \
	done

update-snapshot: ## Update specific snapshot (Usage: make update-snapshot CHART=summon EXAMPLE=basic-deployment)
	@if [ -z "$(CHART)" ] || [ -z "$(EXAMPLE)" ]; then \
		echo "$(RED)Usage: make update-snapshot CHART=summon EXAMPLE=basic-deployment$(RESET)"; \
		exit 1; \
	fi
	@chart_dir="charts/$(CHART)"; \
	if [ "$(CHART)" = "microspell" ] || [ "$(CHART)" = "tarot" ] || [ "$(CHART)" = "covenant" ]; then \
		chart_dir="charts/trinkets/$(CHART)"; \
	elif [ "$(CHART)" = "librarian" ]; then \
		chart_dir="librarian"; \
	fi; \
	example_file="$$chart_dir/examples/$(EXAMPLE).yaml"; \
	if [ ! -f "$$example_file" ]; then \
		echo "$(RED)❌ Example file not found: $$example_file$(RESET)"; \
		exit 1; \
	fi; \
	mkdir -p $(OUTPUT_TEST_DIR)/$(CHART); \
	test_name="tdd-$(CHART)-$(EXAMPLE)"; \
	expected_output="$(OUTPUT_TEST_DIR)/$(CHART)/$(EXAMPLE).expected.yaml"; \
	echo "$(BLUE)📸 Updating snapshot for $(CHART)/$(EXAMPLE)...$(RESET)"; \
	if helm template $$test_name $$chart_dir -f $$example_file > $$expected_output 2>/dev/null; then \
		echo "$(GREEN)✅ Updated $$expected_output$(RESET)"; \
	else \
		echo "$(RED)❌ Failed to update snapshot$(RESET)"; \
		exit 1; \
	fi

update-all-snapshots: ## Update all snapshots for all charts
	@echo "$(BLUE)📸 Updating all snapshots...$(RESET)"
	@find . -name "Chart.yaml" -not -path "./charts/glyphs/*" | while read chart_file; do \
		chart_dir=$$(dirname $$chart_file); \
		chart_name=$$(basename $$chart_dir); \
		if [ -d "$$chart_dir/examples" ]; then \
			echo "$(BLUE)Updating snapshots for $$chart_name...$(RESET)"; \
			$(MAKE) generate-snapshots CHART=$$chart_name; \
		fi; \
	done
	@echo "$(GREEN)✅ All snapshots updated$(RESET)"

show-snapshot-diff: ## Show diff for specific snapshot (Usage: make show-snapshot-diff CHART=summon EXAMPLE=basic-deployment)
	@if [ -z "$(CHART)" ] || [ -z "$(EXAMPLE)" ]; then \
		echo "$(RED)Usage: make show-snapshot-diff CHART=summon EXAMPLE=basic-deployment$(RESET)"; \
		exit 1; \
	fi
	@actual="$(OUTPUT_TEST_DIR)/$(CHART)/$(EXAMPLE).yaml"; \
	expected="$(OUTPUT_TEST_DIR)/$(CHART)/$(EXAMPLE).expected.yaml"; \
	if [ ! -f "$$actual" ]; then \
		echo "$(RED)❌ Actual output not found. Run 'make test-comprehensive' first$(RESET)"; \
		exit 1; \
	fi; \
	if [ ! -f "$$expected" ]; then \
		echo "$(RED)❌ Expected snapshot not found. Run 'make generate-snapshots CHART=$(CHART)' first$(RESET)"; \
		exit 1; \
	fi; \
	echo "$(BLUE)🔍 Showing diff for $(CHART)/$(EXAMPLE)...$(RESET)"; \
	diff -u $$expected $$actual || echo "$(YELLOW)Files differ (see above)$(RESET)"

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
	@echo "$(BLUE)🎭 TDD: Testing Tarot System...$(RESET)"
	@$(MAKE) test-tarot-syntax
	@$(MAKE) test-tarot-execution-modes
	@$(MAKE) test-tarot-card-resolution
	@$(MAKE) test-tarot-secrets
	@$(MAKE) test-tarot-rbac
	@echo "$(GREEN)✅ Tarot system tests completed successfully!$(RESET)"

test-tarot-syntax: ## Test Tarot template syntax validation
	@echo "$(BLUE)🧪 Testing Helm Template Syntax...$(RESET)"
	@cd charts/trinkets/tarot && \
	for example in examples/*.yaml; do \
		example_name=$$(basename "$$example" .yaml); \
		echo "$(BLUE)  📋 Testing $$example_name...$(RESET)"; \
		if helm template test-$$example_name . -f "$$example" --dry-run > /dev/null 2>&1; then \
			echo "$(GREEN)    ✅ Template renders successfully$(RESET)"; \
		else \
			echo "$(RED)    ❌ Template rendering failed$(RESET)"; \
			exit 1; \
		fi; \
	done

test-tarot-execution-modes: ## Test all Tarot execution modes
	@echo "$(BLUE)🎯 Testing Execution Modes...$(RESET)"
	@echo "$(BLUE)  🔍 Container Mode...$(RESET)"
	@cd charts/trinkets/tarot && \
	if helm template test-container . -f examples/minimal-test.yaml | grep -q "container:"; then \
		echo "$(GREEN)    ✅ Container mode working$(RESET)"; \
	else \
		echo "$(RED)    ❌ Container mode failed$(RESET)"; \
		exit 1; \
	fi
	@echo "$(BLUE)  🔍 DAG Mode...$(RESET)"
	@cd charts/trinkets/tarot && \
	if helm template test-dag . -f examples/simple-dag-test.yaml | grep -q "dag:"; then \
		echo "$(GREEN)    ✅ DAG mode working$(RESET)"; \
	else \
		echo "$(RED)    ❌ DAG mode failed$(RESET)"; \
		exit 1; \
	fi

test-tarot-card-resolution: ## Test Tarot card resolution system
	@echo "$(BLUE)🎴 Testing Card Resolution...$(RESET)"
	@cd charts/trinkets/tarot && \
	if helm template test-cards . -f examples/mixed-cards-example.yaml > /dev/null 2>&1; then \
		echo "$(GREEN)    ✅ Card resolution working$(RESET)"; \
	else \
		echo "$(RED)    ❌ Card resolution failed$(RESET)"; \
		exit 1; \
	fi

test-tarot-secrets: ## Test Tarot secret management
	@echo "$(BLUE)🔐 Testing Secret Management...$(RESET)"
	@cd charts/trinkets/tarot && \
	if helm template test-secrets . -f examples/basic-ci-custom.yaml | grep -q "kind: Secret"; then \
		echo "$(GREEN)    ✅ Secret generation working$(RESET)"; \
	else \
		echo "$(RED)    ❌ Secret generation failed$(RESET)"; \
		exit 1; \
	fi

test-tarot-rbac: ## Test Tarot RBAC system
	@echo "$(BLUE)👮 Testing RBAC System...$(RESET)"
	@cd charts/trinkets/tarot && \
	if helm template test-rbac . -f examples/simple-dag-test.yaml | grep -q "kind: ServiceAccount"; then \
		echo "$(GREEN)    ✅ RBAC generation working$(RESET)"; \
	else \
		echo "$(RED)    ❌ RBAC generation failed$(RESET)"; \
		exit 1; \
	fi

test-tarot-complex: ## Test complex Tarot workflows
	@echo "$(BLUE)🎪 Testing Complex Workflows...$(RESET)"
	@cd charts/trinkets/tarot && \
	for example in examples/enterprise-approval.yaml examples/complex-ml-pipeline.yaml; do \
		example_name=$$(basename "$$example" .yaml); \
		echo "$(BLUE)  🏭 Testing $$example_name...$(RESET)"; \
		if helm template test-$$example_name . -f "$$example" > /dev/null 2>&1; then \
			echo "$(GREEN)    ✅ Complex workflow renders$(RESET)"; \
		else \
			echo "$(RED)    ❌ Complex workflow failed$(RESET)"; \
			exit 1; \
		fi; \
	done

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
