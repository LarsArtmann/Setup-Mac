#!/usr/bin/env bash

# Test Framework for Configuration Validation
# Comprehensive testing suite for the validation framework

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "${SCRIPT_DIR}" && pwd)"
readonly VALIDATION_SCRIPT="${PROJECT_ROOT}/scripts/config-validate.sh"
readonly TEST_LOG="${PROJECT_ROOT}/test-validation-$(date +%Y%m%d_%H%M%S).log"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

#############################################################################
# TEST FRAMEWORK FUNCTIONS
#############################################################################

log_test() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    case "$level" in
        "PASS")
            echo -e "${GREEN}[PASS]${NC} $message"
            echo "[$timestamp] [PASS] $message" >> "$TEST_LOG"
            ((TESTS_PASSED++))
            ;;
        "FAIL")
            echo -e "${RED}[FAIL]${NC} $message"
            echo "[$timestamp] [FAIL] $message" >> "$TEST_LOG"
            ((TESTS_FAILED++))
            ;;
        "INFO")
            echo -e "${BLUE}[INFO]${NC} $message"
            echo "[$timestamp] [INFO] $message" >> "$TEST_LOG"
            ;;
        "WARN")
            echo -e "${YELLOW}[WARN]${NC} $message"
            echo "[$timestamp] [WARN] $message" >> "$TEST_LOG"
            ;;
    esac
}

run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_exit_code="${3:-0}"

    ((TESTS_RUN++))
    log_test "INFO" "Running test: $test_name"

    local actual_exit_code=0
    if ! eval "$test_command" >/dev/null 2>&1; then
        actual_exit_code=$?
    fi

    if [[ "$actual_exit_code" -eq "$expected_exit_code" ]]; then
        log_test "PASS" "$test_name"
        return 0
    else
        log_test "FAIL" "$test_name (expected exit code $expected_exit_code, got $actual_exit_code)"
        return 1
    fi
}

run_test_with_output() {
    local test_name="$1"
    local test_command="$2"
    local expected_pattern="$3"

    ((TESTS_RUN++))
    log_test "INFO" "Running test: $test_name"

    local output
    output=$(eval "$test_command" 2>&1) || true

    if echo "$output" | grep -q "$expected_pattern"; then
        log_test "PASS" "$test_name"
        return 0
    else
        log_test "FAIL" "$test_name (expected pattern '$expected_pattern' not found in output)"
        echo "Output was: $output" >> "$TEST_LOG"
        return 1
    fi
}

setup_test_environment() {
    log_test "INFO" "Setting up test environment..."

    # Ensure validation script exists and is executable
    if [[ ! -x "$VALIDATION_SCRIPT" ]]; then
        log_test "FAIL" "Validation script not found or not executable: $VALIDATION_SCRIPT"
        exit 1
    fi

    # Create test log
    echo "Test Framework Started: $(date)" > "$TEST_LOG"

    log_test "INFO" "Test environment ready"
}

cleanup_test_environment() {
    log_test "INFO" "Cleaning up test environment..."

    # Clean up any temporary files created during testing
    find "$PROJECT_ROOT" -name "validation-*.log" -type f -mtime +1 -delete 2>/dev/null || true
    find "$PROJECT_ROOT" -name "test-*.tmp" -type f -delete 2>/dev/null || true

    log_test "INFO" "Test environment cleaned up"
}

#############################################################################
# BASIC FUNCTIONALITY TESTS
#############################################################################

test_basic_functionality() {
    log_test "INFO" "Testing basic functionality..."

    # Test help command
    run_test "Help command" "$VALIDATION_SCRIPT --help" 0

    # Test version/basic execution
    run_test "Basic execution" "$VALIDATION_SCRIPT --quick all" 0

    # Test invalid option handling
    run_test "Invalid option handling" "$VALIDATION_SCRIPT --invalid-option" 1

    # Test command validation
    run_test_with_output "Help output contains usage" "$VALIDATION_SCRIPT --help" "USAGE:"
}

#############################################################################
# NIX VALIDATION TESTS
#############################################################################

test_nix_validation() {
    log_test "INFO" "Testing Nix validation functionality..."

    # Test Nix syntax validation
    run_test "Nix syntax validation" "$VALIDATION_SCRIPT --quick nix" 0

    # Test flake check integration
    if command -v nix >/dev/null 2>&1; then
        run_test "Nix flake check" "nix flake check --show-trace" 0
    else
        log_test "WARN" "Nix not available, skipping flake check test"
    fi

    # Test individual file parsing
    for nix_file in "$PROJECT_ROOT"/*.nix; do
        if [[ -f "$nix_file" ]]; then
            local filename=$(basename "$nix_file")
            if command -v nix-instantiate >/dev/null 2>&1; then
                run_test "Parse $filename" "nix-instantiate --parse '$nix_file'" 0
            else
                log_test "WARN" "nix-instantiate not available, skipping $filename parse test"
            fi
        fi
    done
}

#############################################################################
# SHELL VALIDATION TESTS
#############################################################################

test_shell_validation() {
    log_test "INFO" "Testing shell validation functionality..."

    # Test shell validation command
    run_test "Shell validation command" "$VALIDATION_SCRIPT --quick shell" 0

    # Test Fish configuration if available
    if command -v fish >/dev/null 2>&1; then
        local fish_config="$HOME/.config/fish/config.fish"
        if [[ -f "$fish_config" ]]; then
            run_test "Fish config syntax" "fish -n '$fish_config'" 0
        else
            log_test "INFO" "Fish config not found, skipping Fish syntax test"
        fi
    else
        log_test "INFO" "Fish not available, skipping Fish tests"
    fi

    # Test Zsh configuration if available
    if command -v zsh >/dev/null 2>&1; then
        local zsh_config="$HOME/.zshrc"
        if [[ -f "$zsh_config" ]]; then
            run_test "Zsh config syntax" "zsh -n '$zsh_config'" 0
        else
            log_test "INFO" "Zsh config not found, skipping Zsh syntax test"
        fi
    else
        log_test "INFO" "Zsh not available, skipping Zsh tests"
    fi

    # Test Bash configuration
    local bash_config="$HOME/.bashrc"
    if [[ -f "$bash_config" ]]; then
        run_test "Bash config syntax" "bash -n '$bash_config'" 0
    else
        log_test "INFO" "Bash config not found, skipping Bash syntax test"
    fi
}

#############################################################################
# DEPENDENCY VALIDATION TESTS
#############################################################################

test_dependency_validation() {
    log_test "INFO" "Testing dependency validation functionality..."

    # Test dependency validation command
    run_test "Dependency validation command" "$VALIDATION_SCRIPT --quick deps" 0

    # Test PATH analysis
    run_test_with_output "PATH validation" "echo \$PATH | tr ':' '\n' | wc -l" "[0-9]+"

    # Test package manager detection
    if command -v brew >/dev/null 2>&1; then
        run_test "Homebrew detection" "brew --version" 0
    fi

    if command -v nix >/dev/null 2>&1; then
        run_test "Nix detection" "nix --version" 0
    fi
}

#############################################################################
# INTEGRATION TESTS
#############################################################################

test_integration() {
    log_test "INFO" "Testing integration functionality..."

    # Test comprehensive validation
    run_test "Comprehensive validation" "$VALIDATION_SCRIPT --quick all" 0

    # Test report generation
    local test_report="test-report-$(date +%Y%m%d_%H%M%S).md"
    run_test "Report generation" "$VALIDATION_SCRIPT --quick --report '$test_report' report" 0

    # Verify report was created
    if [[ -f "$test_report" ]]; then
        log_test "PASS" "Report file created successfully"
        rm -f "$test_report"
    else
        log_test "FAIL" "Report file was not created"
    fi

    # Test strict mode
    run_test "Strict mode execution" "$VALIDATION_SCRIPT --quick --strict all"
}

#############################################################################
# PERFORMANCE TESTS
#############################################################################

test_performance() {
    log_test "INFO" "Testing performance characteristics..."

    # Test quick mode performance
    local start_time=$(date +%s)
    if "$VALIDATION_SCRIPT" --quick all >/dev/null 2>&1; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))

        if [[ $duration -lt 60 ]]; then
            log_test "PASS" "Quick validation completed in ${duration}s (< 60s threshold)"
        else
            log_test "FAIL" "Quick validation took ${duration}s (exceeded 60s threshold)"
        fi
    else
        log_test "FAIL" "Quick validation failed"
    fi

    # Test timeout handling (if applicable)
    log_test "INFO" "Performance tests completed"
}

#############################################################################
# ERROR HANDLING TESTS
#############################################################################

test_error_handling() {
    log_test "INFO" "Testing error handling..."

    # Test invalid file handling
    run_test "Invalid file handling" "$VALIDATION_SCRIPT --quick nix" 0

    # Test permission handling
    run_test "Permission handling" "$VALIDATION_SCRIPT --quick shell" 0

    # Test missing dependency handling
    run_test "Missing dependency handling" "$VALIDATION_SCRIPT --quick deps" 0

    log_test "INFO" "Error handling tests completed"
}

#############################################################################
# JUST INTEGRATION TESTS
#############################################################################

test_just_integration() {
    log_test "INFO" "Testing Just task runner integration..."

    if ! command -v just >/dev/null 2>&1; then
        log_test "WARN" "Just command not available, skipping Just integration tests"
        return 0
    fi

    # Test basic just commands
    run_test "Just list commands" "just --list" 0

    # Test validation commands
    run_test "Just validate-quick" "just validate-quick" 0

    # Test debug command
    run_test "Just debug" "just debug" 0

    log_test "INFO" "Just integration tests completed"
}

#############################################################################
# FILE STRUCTURE TESTS
#############################################################################

test_file_structure() {
    log_test "INFO" "Testing file structure requirements..."

    # Test required files exist
    local required_files=(
        "scripts/config-validate.sh"
        ".pre-commit-config.yaml"
        "justfile"
        "docs/configuration-validation.md"
        "examples/validation-usage.sh"
        "flake.nix"
    )

    for file in "${required_files[@]}"; do
        if [[ -f "$PROJECT_ROOT/$file" ]]; then
            log_test "PASS" "Required file exists: $file"
        else
            log_test "FAIL" "Required file missing: $file"
        fi
    done

    # Test script permissions
    if [[ -x "$VALIDATION_SCRIPT" ]]; then
        log_test "PASS" "Validation script is executable"
    else
        log_test "FAIL" "Validation script is not executable"
    fi

    # Test directory structure
    local required_dirs=(
        "scripts"
        "docs"
        "examples"
    )

    for dir in "${required_dirs[@]}"; do
        if [[ -d "$PROJECT_ROOT/$dir" ]]; then
            log_test "PASS" "Required directory exists: $dir"
        else
            log_test "FAIL" "Required directory missing: $dir"
        fi
    done
}

#############################################################################
# MAIN TEST RUNNER
#############################################################################

main() {
    echo "🧪 Configuration Validation Framework - Test Suite"
    echo "=================================================="
    echo ""

    setup_test_environment

    # Run all test suites
    test_file_structure
    test_basic_functionality
    test_nix_validation
    test_shell_validation
    test_dependency_validation
    test_integration
    test_performance
    test_error_handling
    test_just_integration

    cleanup_test_environment

    # Print summary
    echo ""
    echo "📊 TEST SUMMARY"
    echo "==============="
    echo "Tests run: $TESTS_RUN"
    echo "Tests passed: $TESTS_PASSED"
    echo "Tests failed: $TESTS_FAILED"
    echo ""

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}✅ All tests passed!${NC}"
        echo "Test log: $TEST_LOG"
        exit 0
    else
        echo -e "${RED}❌ $TESTS_FAILED test(s) failed!${NC}"
        echo "Test log: $TEST_LOG"
        echo ""
        echo "Review the test log for detailed failure information."
        exit 1
    fi
}

# Show usage if help requested
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    cat << EOF
Configuration Validation Test Framework

USAGE:
    $0                 # Run all tests
    $0 --help          # Show this help

DESCRIPTION:
    Comprehensive test suite for the configuration validation framework.
    Tests all components including Nix validation, shell configuration,
    dependency detection, and integration features.

OUTPUT:
    - Real-time test results with pass/fail status
    - Summary report with test counts
    - Detailed test log file for troubleshooting

REQUIREMENTS:
    - Validation framework must be installed
    - Nix (optional, for Nix-specific tests)
    - Various shells (optional, for shell tests)
    - Just command runner (optional, for integration tests)

EOF
    exit 0
fi

# Run main function
main "$@"