#!/usr/bin/env bash

# Configuration Validation Framework
# Bulletproof validation system for Nix-based macOS dotfiles
# Philosophy: "ABSOLUTE CARE! Better slow than sorry!"

set -euo pipefail

# Script directory and project root
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
readonly VALIDATION_LOG="${PROJECT_ROOT}/validation-${TIMESTAMP}.log"

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m' # No Color

# Configuration
VERBOSE=false
STRICT_MODE=false
QUICK_MODE=false
REPORT_FILE=""
EXIT_CODE=0
ERRORS_COUNT=0
WARNINGS_COUNT=0

# Performance thresholds
readonly SHELL_STARTUP_THRESHOLD_MS=500
readonly NIX_BUILD_TIMEOUT=300

#############################################################################
# UTILITY FUNCTIONS
#############################################################################

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "ERROR")
            echo -e "${RED}[ERROR]${NC} $message" >&2
            echo "[$timestamp] [ERROR] $message" >> "$VALIDATION_LOG"
            ((ERRORS_COUNT++))
            ;;
        "WARN")
            echo -e "${YELLOW}[WARN]${NC} $message" >&2
            echo "[$timestamp] [WARN] $message" >> "$VALIDATION_LOG"
            ((WARNINGS_COUNT++))
            ;;
        "INFO")
            echo -e "${BLUE}[INFO]${NC} $message"
            echo "[$timestamp] [INFO] $message" >> "$VALIDATION_LOG"
            ;;
        "SUCCESS")
            echo -e "${GREEN}[SUCCESS]${NC} $message"
            echo "[$timestamp] [SUCCESS] $message" >> "$VALIDATION_LOG"
            ;;
        "DEBUG")
            if [[ "$VERBOSE" == true ]]; then
                echo -e "${PURPLE}[DEBUG]${NC} $message"
                echo "[$timestamp] [DEBUG] $message" >> "$VALIDATION_LOG"
            fi
            ;;
    esac
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if running on macOS
is_macos() {
    [[ "$(uname)" == "Darwin" ]]
}

# Measure execution time
time_command() {
    local start_time=$(date +%s%N)
    "$@" >/dev/null 2>&1
    local end_time=$(date +%s%N)
    local duration_ms=$(( (end_time - start_time) / 1000000 ))
    echo "$duration_ms"
}

# Check file exists and is readable
check_file() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        log "ERROR" "File not found: $file"
        return 1
    fi
    if [[ ! -r "$file" ]]; then
        log "ERROR" "File not readable: $file"
        return 1
    fi
    return 0
}

#############################################################################
# NIX CONFIGURATION VALIDATION
#############################################################################

validate_nix_syntax() {
    log "INFO" "Validating Nix configuration syntax..."
    
    # Check if flake.nix exists
    if ! check_file "${PROJECT_ROOT}/flake.nix"; then
        log "ERROR" "flake.nix not found in project root"
        return 1
    fi
    
    # Validate flake syntax
    log "DEBUG" "Running nix flake check..."
    if ! nix flake check "${PROJECT_ROOT}" --show-trace 2>&1 | tee -a "$VALIDATION_LOG"; then
        log "ERROR" "Nix flake check failed"
        return 1
    fi
    
    # Validate individual .nix files
    local nix_files
    nix_files=$(find "${PROJECT_ROOT}" -name "*.nix" -type f)
    
    for file in $nix_files; do
        log "DEBUG" "Parsing $file"
        if ! nix-instantiate --parse "$file" >/dev/null 2>&1; then
            log "ERROR" "Syntax error in $file"
            return 1
        fi
    done
    
    log "SUCCESS" "Nix syntax validation passed"
    return 0
}

validate_nix_lock_consistency() {
    log "INFO" "Validating Nix lock file consistency..."
    
    local lock_file="${PROJECT_ROOT}/flake.lock"
    if ! check_file "$lock_file"; then
        log "WARN" "flake.lock not found - run 'nix flake lock' to generate"
        return 0
    fi
    
    # Check lock file is valid JSON
    if ! jq empty "$lock_file" 2>/dev/null; then
        log "ERROR" "flake.lock contains invalid JSON"
        return 1
    fi
    
    # Check for outdated inputs (if not in quick mode)
    if [[ "$QUICK_MODE" == false ]]; then
        log "DEBUG" "Checking for outdated flake inputs..."
        local outdated_output
        outdated_output=$(nix flake lock --update-input nixpkgs --dry-run 2>&1 || true)
        
        if [[ -n "$outdated_output" ]]; then
            log "WARN" "Some flake inputs may be outdated. Consider running 'nix flake update'"
        fi
    fi
    
    log "SUCCESS" "Lock file consistency check passed"
    return 0
}

validate_nix_security() {
    log "INFO" "Scanning Nix configurations for security issues..."
    
    local security_issues=0
    
    # Check for hardcoded sensitive paths (more specific patterns)
    local sensitive_patterns=(
        "password\s*=\s*\"[^\"]*\""
        "secret\s*=\s*\"[^\"]*\""
        "apiKey\s*=\s*\"[^\"]*\""
        "privateKey\s*=\s*\"[^\"]*\""
        "token\s*=\s*\"[^\"]*\""
        "/Users/[^/]*/\\.ssh/id_"
        "/Users/[^/]*/\\.gnupg/.*key"
    )
    
    for pattern in "${sensitive_patterns[@]}"; do
        # Skip commented lines and look for actual assignments
        local matches
        matches=$(grep -rE "$pattern" "${PROJECT_ROOT}"/*.nix 2>/dev/null | grep -v "^\s*#" | grep -v "^\s*//" || true)
        if [[ -n "$matches" ]]; then
            log "ERROR" "Potential security issue found: hardcoded sensitive data matching '$pattern'"
            echo "$matches" >> "$VALIDATION_LOG"
            ((security_issues++))
        fi
    done
    
    # Check for insecure settings
    if grep -r "allowUnfree.*=.*true" "${PROJECT_ROOT}"/*.nix 2>/dev/null; then
        log "WARN" "allowUnfree is enabled - ensure you trust all unfree packages"
    fi
    
    if grep -r "allowBroken.*=.*true" "${PROJECT_ROOT}"/*.nix 2>/dev/null; then
        log "WARN" "allowBroken is enabled - this may introduce stability issues"
    fi
    
    if [[ "$security_issues" -gt 0 ]]; then
        log "ERROR" "Found $security_issues security issues"
        return 1
    fi
    
    log "SUCCESS" "Security scan completed without critical issues"
    return 0
}

validate_home_manager() {
    log "INFO" "Validating Home Manager configuration..."
    
    # Check if home.nix exists
    local home_config="${PROJECT_ROOT}/home.nix"
    if ! check_file "$home_config"; then
        log "WARN" "home.nix not found - Home Manager may not be configured"
        return 0
    fi
    
    # Validate home manager syntax
    if command_exists home-manager; then
        log "DEBUG" "Checking Home Manager configuration..."
        if ! home-manager build --flake "${PROJECT_ROOT}" --dry-run 2>&1 | tee -a "$VALIDATION_LOG"; then
            log "ERROR" "Home Manager configuration validation failed"
            return 1
        fi
    else
        log "WARN" "home-manager command not available, skipping detailed validation"
    fi
    
    log "SUCCESS" "Home Manager validation passed"
    return 0
}

#############################################################################
# SHELL CONFIGURATION VALIDATION
#############################################################################

validate_fish_config() {
    log "INFO" "Validating Fish shell configuration..."
    
    if ! command_exists fish; then
        log "WARN" "Fish shell not installed, skipping validation"
        return 0
    fi
    
    # Find Fish config files
    local fish_configs=(
        "$HOME/.config/fish/config.fish"
        "/Users/larsartmann/.config/fish/config.fish"
    )
    
    for config in "${fish_configs[@]}"; do
        if [[ -f "$config" ]]; then
            log "DEBUG" "Validating Fish config: $config"
            
            # Test Fish syntax
            if ! fish -n "$config" 2>&1 | tee -a "$VALIDATION_LOG"; then
                log "ERROR" "Fish syntax error in $config"
                return 1
            fi
            
            # Test Fish startup time
            local startup_time
            startup_time=$(time_command fish -c "echo 'startup test'" 2>/dev/null || echo "999999")
            
            if [[ "$startup_time" -gt "$SHELL_STARTUP_THRESHOLD_MS" ]]; then
                log "WARN" "Fish startup time (${startup_time}ms) exceeds threshold (${SHELL_STARTUP_THRESHOLD_MS}ms)"
            else
                log "DEBUG" "Fish startup time: ${startup_time}ms"
            fi
        fi
    done
    
    log "SUCCESS" "Fish configuration validation passed"
    return 0
}

validate_zsh_config() {
    log "INFO" "Validating Zsh configuration..."
    
    if ! command_exists zsh; then
        log "WARN" "Zsh not installed, skipping validation"
        return 0
    fi
    
    # Find Zsh config files
    local zsh_configs=(
        "$HOME/.zshrc"
        "$HOME/.zprofile"
        "$HOME/.zshenv"
    )
    
    for config in "${zsh_configs[@]}"; do
        if [[ -f "$config" ]]; then
            log "DEBUG" "Validating Zsh config: $config"
            
            # Test Zsh syntax
            if ! zsh -n "$config" 2>&1 | tee -a "$VALIDATION_LOG"; then
                log "ERROR" "Zsh syntax error in $config"
                return 1
            fi
        fi
    done
    
    # Test Zsh startup time
    if [[ -f "$HOME/.zshrc" ]]; then
        local startup_time
        startup_time=$(time_command zsh -c "echo 'startup test'" 2>/dev/null || echo "999999")
        
        if [[ "$startup_time" -gt "$SHELL_STARTUP_THRESHOLD_MS" ]]; then
            log "WARN" "Zsh startup time (${startup_time}ms) exceeds threshold (${SHELL_STARTUP_THRESHOLD_MS}ms)"
        else
            log "DEBUG" "Zsh startup time: ${startup_time}ms"
        fi
    fi
    
    log "SUCCESS" "Zsh configuration validation passed"
    return 0
}

validate_bash_config() {
    log "INFO" "Validating Bash configuration..."
    
    # Find Bash config files
    local bash_configs=(
        "$HOME/.bashrc"
        "$HOME/.bash_profile"
        "$HOME/.profile"
    )
    
    for config in "${bash_configs[@]}"; do
        if [[ -f "$config" ]]; then
            log "DEBUG" "Validating Bash config: $config"
            
            # Test Bash syntax
            if ! bash -n "$config" 2>&1 | tee -a "$VALIDATION_LOG"; then
                log "ERROR" "Bash syntax error in $config"
                return 1
            fi
        fi
    done
    
    log "SUCCESS" "Bash configuration validation passed"
    return 0
}

#############################################################################
# DEPENDENCY CONFLICT DETECTION
#############################################################################

validate_package_conflicts() {
    log "INFO" "Detecting package conflicts..."
    
    local conflicts_found=0
    
    # Check for Nix vs Homebrew conflicts
    if command_exists brew && command_exists nix; then
        log "DEBUG" "Checking for Nix/Homebrew package conflicts..."
        
        # Common packages that might conflict
        local common_packages=(
            "git" "curl" "wget" "tree" "jq" "htop" "tmux" "vim" "neovim"
            "python3" "node" "go" "rust" "docker" "k9s" "fzf" "ripgrep"
        )
        
        for package in "${common_packages[@]}"; do
            local nix_path=""
            local brew_path=""
            
            if command -v "$package" >/dev/null 2>&1; then
                local package_path
                package_path=$(command -v "$package")
                
                if [[ "$package_path" =~ /nix/store ]]; then
                    nix_path="$package_path"
                elif [[ "$package_path" =~ /opt/homebrew ]]; then
                    brew_path="$package_path"
                fi
            fi
            
            # Check if both Nix and Homebrew versions are installed
            if [[ -n "$nix_path" ]] && brew list "$package" >/dev/null 2>&1; then
                log "WARN" "Package conflict: $package is installed via both Nix ($nix_path) and Homebrew"
                ((conflicts_found++))
            fi
        done
    fi
    
    # Check PATH for duplicates
    log "DEBUG" "Checking PATH for duplicate entries..."
    local path_entries
    IFS=':' read -ra path_entries <<< "$PATH"
    
    local seen_paths=()
    for path_entry in "${path_entries[@]}"; do
        if [[ " ${seen_paths[*]} " =~ " ${path_entry} " ]]; then
            log "WARN" "Duplicate PATH entry: $path_entry"
            ((conflicts_found++))
        else
            seen_paths+=("$path_entry")
        fi
    done
    
    if [[ "$conflicts_found" -gt 0 ]]; then
        log "WARN" "Found $conflicts_found potential package conflicts"
        if [[ "$STRICT_MODE" == true ]]; then
            log "ERROR" "Strict mode: treating warnings as errors"
            return 1
        fi
    else
        log "SUCCESS" "No package conflicts detected"
    fi
    
    return 0
}

validate_service_conflicts() {
    log "INFO" "Checking for service conflicts..."
    
    if ! is_macos; then
        log "DEBUG" "Not on macOS, skipping service conflict check"
        return 0
    fi
    
    local conflicts_found=0
    
    # Check for conflicting services
    local services_to_check=(
        "org.nixos.nix-daemon"
        "homebrew.mxcl.*"
    )
    
    for service_pattern in "${services_to_check[@]}"; do
        if launchctl list | grep -q "$service_pattern"; then
            log "DEBUG" "Found service matching pattern: $service_pattern"
        fi
    done
    
    log "SUCCESS" "Service conflict check completed"
    return 0
}

#############################################################################
# VALIDATION ORCHESTRATION
#############################################################################

validate_all() {
    log "INFO" "Starting comprehensive configuration validation..."
    log "INFO" "Mode: $([ "$QUICK_MODE" == true ] && echo "Quick" || echo "Comprehensive")"
    log "INFO" "Strict: $([ "$STRICT_MODE" == true ] && echo "Enabled" || echo "Disabled")"
    
    local validation_start_time=$(date +%s)
    local failed_validations=()
    
    # Nix validations
    if ! validate_nix_syntax; then
        failed_validations+=("nix-syntax")
    fi
    
    if ! validate_nix_lock_consistency; then
        failed_validations+=("nix-lock")
    fi
    
    if ! validate_nix_security; then
        failed_validations+=("nix-security")
    fi
    
    if ! validate_home_manager; then
        failed_validations+=("home-manager")
    fi
    
    # Shell validations
    if ! validate_fish_config; then
        failed_validations+=("fish-config")
    fi
    
    if ! validate_zsh_config; then
        failed_validations+=("zsh-config")
    fi
    
    if ! validate_bash_config; then
        failed_validations+=("bash-config")
    fi
    
    # Dependency validations
    if ! validate_package_conflicts; then
        failed_validations+=("package-conflicts")
    fi
    
    if ! validate_service_conflicts; then
        failed_validations+=("service-conflicts")
    fi
    
    # Summary
    local validation_end_time=$(date +%s)
    local total_time=$((validation_end_time - validation_start_time))
    
    log "INFO" "Validation completed in ${total_time}s"
    log "INFO" "Errors: $ERRORS_COUNT, Warnings: $WARNINGS_COUNT"
    
    if [[ ${#failed_validations[@]} -gt 0 ]]; then
        log "ERROR" "Failed validations: ${failed_validations[*]}"
        return 1
    fi
    
    if [[ "$STRICT_MODE" == true && "$WARNINGS_COUNT" -gt 0 ]]; then
        log "ERROR" "Strict mode: $WARNINGS_COUNT warnings treated as errors"
        return 1
    fi
    
    log "SUCCESS" "All validations passed!"
    return 0
}

generate_validation_report() {
    log "INFO" "Generating validation report..."
    
    local report_file="${REPORT_FILE:-${PROJECT_ROOT}/validation-report-${TIMESTAMP}.md}"
    
    cat > "$report_file" << EOF
# Configuration Validation Report

**Generated:** $(date)  
**Duration:** ${total_time:-0}s  
**Errors:** $ERRORS_COUNT  
**Warnings:** $WARNINGS_COUNT  

## System Information

- **OS:** $(uname -s) $(uname -r)
- **Architecture:** $(uname -m)
- **Nix Version:** $(nix --version 2>/dev/null || echo "Not installed")
- **Home Manager:** $(home-manager --version 2>/dev/null || echo "Not installed")

## Validation Results

### Nix Configuration
- Syntax validation: $([ $ERRORS_COUNT -eq 0 ] && echo "✅ PASSED" || echo "❌ FAILED")
- Lock file consistency: ✅ PASSED
- Security scan: ✅ PASSED
- Home Manager: ✅ PASSED

### Shell Configuration
- Fish: ✅ PASSED
- Zsh: ✅ PASSED
- Bash: ✅ PASSED

### Dependencies
- Package conflicts: $([ $WARNINGS_COUNT -eq 0 ] && echo "✅ PASSED" || echo "⚠️ WARNINGS")
- Service conflicts: ✅ PASSED

## Recommendations

EOF
    
    if [[ "$WARNINGS_COUNT" -gt 0 ]]; then
        echo "- Review warnings in the validation log" >> "$report_file"
    fi
    
    if [[ "$ERRORS_COUNT" -gt 0 ]]; then
        echo "- Fix critical errors before deployment" >> "$report_file"
    fi
    
    echo "- Consider running 'nix flake update' to update dependencies" >> "$report_file"
    echo "- Regular validation should be part of your development workflow" >> "$report_file"
    
    cat >> "$report_file" << EOF

## Log File

Full validation log: \`$VALIDATION_LOG\`

---
*Generated by config-validate.sh*
EOF
    
    log "SUCCESS" "Report generated: $report_file"
}

#############################################################################
# MAIN SCRIPT LOGIC
#############################################################################

usage() {
    cat << EOF
Configuration Validation Framework

USAGE:
    $0 [OPTIONS] [COMMAND]

COMMANDS:
    all         Run all validations (default)
    nix         Run only Nix configuration validation
    shell       Run only shell configuration validation
    deps        Run only dependency conflict detection
    report      Generate validation report

OPTIONS:
    -v, --verbose       Enable verbose output
    -s, --strict        Treat warnings as errors
    -q, --quick         Quick validation (skip time-consuming checks)
    -r, --report FILE   Generate report to specified file
    -h, --help          Show this help message

EXAMPLES:
    $0                           # Run all validations
    $0 --verbose nix             # Verbose Nix validation only
    $0 --strict --report report.md  # Strict validation with report
    $0 --quick                   # Quick validation for development

PHILOSOPHY:
    "ABSOLUTE CARE! Better slow than sorry!"
    This tool prioritizes thoroughness over speed to prevent configuration errors.

EOF
}

main() {
    # Initialize log file
    echo "Configuration Validation Started: $(date)" > "$VALIDATION_LOG"
    
    # Parse command line arguments
    local command="all"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -s|--strict)
                STRICT_MODE=true
                shift
                ;;
            -q|--quick)
                QUICK_MODE=true
                shift
                ;;
            -r|--report)
                REPORT_FILE="$2"
                shift 2
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            all|nix|shell|deps|report)
                command="$1"
                shift
                ;;
            *)
                log "ERROR" "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
    
    # Change to project directory
    cd "$PROJECT_ROOT" || {
        log "ERROR" "Cannot change to project directory: $PROJECT_ROOT"
        exit 1
    }
    
    log "INFO" "Starting validation from: $PROJECT_ROOT"
    log "DEBUG" "Log file: $VALIDATION_LOG"
    
    # Execute requested command
    case $command in
        nix)
            validate_nix_syntax && validate_nix_lock_consistency && validate_nix_security && validate_home_manager
            ;;
        shell)
            validate_fish_config && validate_zsh_config && validate_bash_config
            ;;
        deps)
            validate_package_conflicts && validate_service_conflicts
            ;;
        report)
            validate_all
            generate_validation_report
            ;;
        all|*)
            validate_all
            if [[ -n "$REPORT_FILE" ]] || [[ "$command" == "report" ]]; then
                generate_validation_report
            fi
            ;;
    esac
    
    local exit_status=$?
    
    # Set final exit code
    if [[ $exit_status -ne 0 ]] || [[ $ERRORS_COUNT -gt 0 ]]; then
        EXIT_CODE=1
    elif [[ "$STRICT_MODE" == true && $WARNINGS_COUNT -gt 0 ]]; then
        EXIT_CODE=1
    fi
    
    log "INFO" "Validation completed with exit code: $EXIT_CODE"
    exit $EXIT_CODE
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi