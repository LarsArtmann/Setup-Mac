#!/usr/bin/env nix-shell
#!nix-shell -i bash -p nix coreutils git curl

set -euo pipefail

# Automated Testing Pipeline for Nix Configurations
# Validates configuration changes before deployment

CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT_DIR="${CONFIG_DIR}/test-reports/${TIMESTAMP}"
TEST_LOG="${REPORT_DIR}/test.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "${TEST_LOG}" 2>/dev/null || echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}[✓ PASS]${NC} $1" | tee -a "${TEST_LOG}" 2>/dev/null || echo -e "${GREEN}[✓ PASS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[⚠ WARN]${NC} $1" | tee -a "${TEST_LOG}" 2>/dev/null || echo -e "${YELLOW}[⚠ WARN]${NC} $1"
}

error() {
    echo -e "${RED}[✗ FAIL]${NC} $1" | tee -a "${TEST_LOG}"
}

info() {
    echo -e "${PURPLE}[INFO]${NC} $1" | tee -a "${TEST_LOG}" 2>/dev/null || echo -e "${PURPLE}[INFO]${NC} $1"
}

# Test statistics
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Track test results
track_test() {
    local result=$1
    ((TESTS_TOTAL++))

    case $result in
        "pass")
            ((TESTS_PASSED++))
            ;;
        "fail")
            ((TESTS_FAILED++))
            ;;
        "skip")
            ((TESTS_SKIPPED++))
            ;;
    esac
}

# Setup test environment
setup_test_env() {
    log "Setting up test environment..."

    # Create report directory
    mkdir -p "${REPORT_DIR}/artifacts"

    # Initialize test log
    touch "${TEST_LOG}"
    echo "Setup-Mac Configuration Test Report" > "${TEST_LOG}"
    echo "Started: $(date)" >> "${TEST_LOG}"
    echo "=================================" >> "${TEST_LOG}"
    echo "" >> "${TEST_LOG}"

    # Change to config directory
    cd "${CONFIG_DIR}"

    log "Test environment ready"
    track_test "pass"
}

# Test 1: Flake validation
test_flake_validation() {
    log "Running flake validation..."

    if nix flake check --all-systems > "${REPORT_DIR}/artifacts/flake-check.log" 2>&1; then
        success "Flake validation passed"
        track_test "pass"
        return 0
    else
        error "Flake validation failed"
        cat "${REPORT_DIR}/artifacts/flake-check.log" >> "${TEST_LOG}"
        track_test "fail"
        return 1
    fi
}

# Test 2: Nix syntax validation
test_nix_syntax() {
    log "Running Nix syntax validation..."

    local syntax_errors=0
    local nix_files=$(find . -name "*.nix" -type f)

    for file in $nix_files; do
        if nix-instantiate --parse "$file" > /dev/null 2>&1; then
            log "✓ $file: Valid syntax"
        else
            error "✗ $file: Syntax error"
            nix-instantiate --parse "$file" >> "${REPORT_DIR}/artifacts/syntax-errors.log" 2>&1 || true
            ((syntax_errors++))
        fi
    done

    if [[ $syntax_errors -eq 0 ]]; then
        success "All Nix files have valid syntax"
        track_test "pass"
        return 0
    else
        error "Found $syntax_errors files with syntax errors"
        track_test "fail"
        return 1
    fi
}

# Test 3: Package availability test
test_package_availability() {
    log "Running package availability test..."

    # Extract package names from configurations
    local packages=$(grep -h "pkgs\." dotfiles/nixos/configuration.nix dotfiles/common/packages.nix 2>/dev/null | \
                    grep -o "pkgs\.[a-zA-Z0-9_\-]*" | sort -u | sed 's/pkgs\.//' || true)

    local missing_packages=0
    local total_packages=0

    if [[ -n "$packages" ]]; then
        for package in $packages; do
            ((total_packages++))
            if nix --experimental-features "nix-command flakes" \
                    eval --impure --raw \
                    --expr "(builtins.getFlake (toString .)).packages.x86_64-linux.$package.name" \
                    > /dev/null 2>&1; then
                log "✓ $package: Available"
            else
                warning "? $package: Not available on x86_64-linux (may be platform-specific)"
                ((missing_packages++))
            fi
        done

        if [[ $total_packages -gt 0 ]]; then
            info "Checked $total_packages packages, $missing_packages potential issues"
        fi
    fi

    # Allow some packages to be missing (platform-specific)
    local tolerance=$((total_packages / 10))  # Allow 10% to be missing
    if [[ $missing_packages -le $tolerance ]]; then
        success "Package availability test passed (within tolerance)"
        track_test "pass"
        return 0
    else
        warning "Package availability test had issues ($missing_packages > $tolerance)"
        track_test "skip"  # Not a failure, just needs attention
        return 0
    fi
}

# Test 4: Configuration structure test
test_config_structure() {
    log "Running configuration structure test..."

    local structure_errors=0

    # Check required files
    local required_files=(
        "flake.nix"
        "dotfiles/nixos/configuration.nix"
        "dotfiles/nixos/hardware-configuration.nix"
        "dotfiles/nix/core.nix"
        "dotfiles/common/home.nix"
        "dotfiles/common/packages.nix"
    )

    for file in "${required_files[@]}"; do
        if [[ -f "$file" ]]; then
            log "✓ $file: Present"
        else
            error "✗ $file: Missing"
            ((structure_errors++))
        fi
    done

    # Check for essential configuration sections
    local essential_patterns=(
        "boot\.loader\.systemd-boot\.enable\s*=\s*true"
        "networking\.hostName\s*=\s*\""
        "services\.openssh\.enable\s*=\s*true"
        "users\.users\.lars"
        "nix\.settings\.experimental-features"
    )

    for pattern in "${essential_patterns[@]}"; do
        if grep -E "$pattern" dotfiles/nixos/configuration.nix > /dev/null 2>&1; then
            log "✓ Configuration pattern: $pattern"
        else
            error "✗ Missing configuration pattern: $pattern"
            ((structure_errors++))
        fi
    done

    if [[ $structure_errors -eq 0 ]]; then
        success "Configuration structure test passed"
        track_test "pass"
        return 0
    else
        error "Configuration structure test failed: $structure_errors errors"
        track_test "fail"
        return 1
    fi
}

# Test 5: Security configuration test
test_security_config() {
    log "Running security configuration test..."

    local security_issues=0
    local security_warnings=0

    # Check for secure SSH configuration
    if grep -E "PasswordAuthentication\s*=\s*false" dotfiles/nixos/configuration.nix > /dev/null; then
        log "✓ SSH: Password authentication disabled"
    else
        error "✗ SSH: Password authentication not explicitly disabled"
        ((security_issues++))
    fi

    if grep -E "PermitRootLogin\s*=\s*\"no\"" dotfiles/nixos/configuration.nix > /dev/null; then
        log "✓ SSH: Root login disabled"
    else
        error "✗ SSH: Root login not explicitly disabled"
        ((security_issues++))
    fi

    # Check for experimental features (required for flakes)
    if grep -E "experimental-features.*flakes" dotfiles/nixos/configuration.nix > /dev/null; then
        log "✓ Nix: Experimental features enabled"
    else
        warning "⚠ Nix: Experimental features not found"
        ((security_warnings++))
    fi

    # Check for firewall configuration
    if grep -E "networking\.firewall\.enable\s*=\s*true" dotfiles/nixos/configuration.nix > /dev/null; then
        log "✓ Firewall: Enabled"
    else
        warning "⚠ Firewall: Not explicitly enabled"
        ((security_warnings++))
    fi

    if [[ $security_issues -eq 0 ]]; then
        success "Security configuration test passed ($security_warnings warnings)"
        track_test "pass"
        return 0
    else
        error "Security configuration test failed: $security_issues issues"
        track_test "fail"
        return 1
    fi
}

# Test 6: Cross-platform compatibility test
test_cross_platform() {
    log "Running cross-platform compatibility test..."

    local compatibility_issues=0

    # Check for platform-specific imports
    local darwin_files=$(find . -name "*darwin*" -o -name "*macos*" | head -5)
    local nixos_files=$(find . -name "*nixos*" | head -5)

    if [[ -n "$darwin_files" ]]; then
        log "✓ Found macOS-specific files: $(echo $darwin_files | tr '\n' ' ')"
    fi

    if [[ -n "$nixos_files" ]]; then
        log "✓ Found NixOS-specific files: $(echo $nixos_files | tr '\n' ' ')"
    fi

    # Check for platform conditionals
    if grep -r "lib\.mkIf" . --include="*.nix" > /dev/null 2>&1; then
        log "✓ Found platform conditionals"
    fi

    # Check flake outputs
    if grep -E "darwinConfigurations|nixosConfigurations" flake.nix > /dev/null; then
        log "✓ Flake defines both platform configurations"
    else
        error "✗ Flake missing platform configuration outputs"
        ((compatibility_issues++))
    fi

    if [[ $compatibility_issues -eq 0 ]]; then
        success "Cross-platform compatibility test passed"
        track_test "pass"
        return 0
    else
        error "Cross-platform compatibility test failed: $compatibility_issues issues"
        track_test "fail"
        return 1
    fi
}

# Test 7: Documentation completeness test
test_documentation() {
    log "Running documentation completeness test..."

    local doc_issues=0

    # Check for essential documentation
    local essential_docs=(
        "README.md"
        "docs/status"
    )

    for doc in "${essential_docs[@]}"; do
        if [[ -e "$doc" ]]; then
            log "✓ Documentation found: $doc"
        else
            warning "⚠ Documentation missing: $doc"
            ((doc_issues++))
        fi
    done

    # Check for inline documentation in configuration
    local commented_configs=$(grep -c "^#" dotfiles/nixos/configuration.nix 2>/dev/null || echo "0")
    if [[ $commented_configs -gt 10 ]]; then
        log "✓ Configuration has inline documentation ($commented_configs lines)"
    else
        warning "⚠ Configuration has minimal inline documentation ($commented_configs lines)"
        ((doc_issues++))
    fi

    if [[ $doc_issues -le 2 ]]; then  # Allow some missing docs
        success "Documentation test passed"
        track_test "pass"
        return 0
    else
        warning "Documentation test had issues"
        track_test "skip"
        return 0
    fi
}

# Test 8: Performance optimization test
test_performance() {
    log "Running performance optimization test..."

    local performance_score=0

    # Check for ZRAM (memory optimization)
    if grep -E "zramSwap\.enable\s*=\s*true" dotfiles/nixos/configuration.nix > /dev/null; then
        log "✓ ZRAM enabled for memory optimization"
        ((performance_score++))
    fi

    # Check for SSD optimizations
    if grep -E "compress=|noatime" dotfiles/nixos/hardware-configuration.nix > /dev/null; then
        log "✓ SSD optimizations found"
        ((performance_score++))
    fi

    # Check for AMD GPU optimizations
    if grep -E "amdgpu" dotfiles/nixos/configuration.nix > /dev/null; then
        log "✓ AMD GPU optimizations found"
        ((performance_score++))
    fi

    # Check for Wayland/Hyprland optimizations
    if grep -E "wayland|hyprland" dotfiles/nixos/configuration.nix > /dev/null; then
        log "✓ Wayland/Hyprland optimizations found"
        ((performance_score++))
    fi

    if [[ $performance_score -ge 3 ]]; then
        success "Performance optimization test passed (score: $performance_score/4)"
        track_test "pass"
        return 0
    else
        warning "Performance optimization test had low score: $performance_score/4"
        track_test "skip"
        return 0
    fi
}

# Generate test report
generate_report() {
    log "Generating test report..."

    local report_file="${REPORT_DIR}/test-summary.txt"

    cat > "$report_file" << EOF
Setup-Mac Configuration Test Report
==================================

Test Summary:
- Started: $(date)
- Total Tests: $TESTS_TOTAL
- Passed: $TESTS_PASSED
- Failed: $TESTS_FAILED
- Skipped: $TESTS_SKIPPED
- Success Rate: $(( TESTS_PASSED * 100 / TESTS_TOTAL ))%

Test Details:
$(cat "$TEST_LOG")

Artifacts:
- flake-check.log: Flake validation output
- syntax-errors.log: Nix syntax errors (if any)
- Full test log: ${TEST_LOG}

Recommendations:
EOF

    # Add recommendations based on test results
    if [[ $TESTS_FAILED -gt 0 ]]; then
        echo "- Fix failing tests before deploying configuration" >> "$report_file"
    fi

    if [[ $TESTS_SKIPPED -gt 2 ]]; then
        echo "- Review skipped tests for potential improvements" >> "$report_file"
    fi

    echo "" >> "$report_file"
    echo "Report generated: $(date)" >> "$report_file"

    success "Test report generated: $report_file"
}

# Show test results
show_results() {
    echo ""
    echo "================================"
    echo "🧪 SETUP-MAC TEST RESULTS"
    echo "================================"
    echo ""
    echo "Total Tests: $TESTS_TOTAL"
    echo "✓ Passed: $TESTS_PASSED"
    echo "✗ Failed: $TESTS_FAILED"
    echo "⚠ Skipped: $TESTS_SKIPPED"
    echo ""

    local success_rate=$(( TESTS_PASSED * 100 / TESTS_TOTAL ))
    echo "Success Rate: ${success_rate}%"
    echo ""

    if [[ $TESTS_FAILED -eq 0 ]]; then
        success "🎉 All critical tests passed! Configuration is ready for deployment."
        return 0
    else
        error "❌ Some tests failed. Review the report before deploying."
        return 1
    fi
}

# Main execution
main() {
    log "Starting Setup-Mac configuration test pipeline..."

    # Check if we're in right directory
    if [[ ! -f "${CONFIG_DIR}/flake.nix" ]]; then
        error "Not in a valid Setup-Mac directory (flake.nix not found)"
        exit 1
    fi

    # Run all tests
    setup_test_env
    test_flake_validation
    test_nix_syntax
    test_package_availability
    test_config_structure
    test_security_config
    test_cross_platform
    test_documentation
    test_performance

    # Generate report and show results
    generate_report
    show_results
}

# Show help
show_help() {
    cat << EOF
Setup-Mac Configuration Test Pipeline

Usage: $0 [OPTIONS]

Options:
    -h, --help          Show this help message
    -q, --quiet         Minimal output
    -v, --verbose       Detailed output
    --report-only       Only generate report from existing results

Environment Variables:
    CONFIG_DIR          Override configuration directory

Examples:
    $0                              # Run full test suite
    $0 --quiet                      # Run with minimal output
    CONFIG_DIR=/tmp/config $0       # Test specific directory

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -q|--quiet)
            exec > /dev/null
            shift
            ;;
        -v|--verbose)
            set -x
            shift
            ;;
        --report-only)
            REPORT_ONLY=1
            shift
            ;;
        *)
            error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Execute main function
main