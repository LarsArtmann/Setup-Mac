#!/bin/bash

# End-to-End Deployment Verification Script
# Verifies that Nix deployment completed successfully and all components work

set -euo pipefail

# Configuration
DOTFILES_DIR="./dotfiles/nix"
VERIFICATION_LOG="./deployment-verification.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

# Function to print section headers
print_header() {
    echo -e "${BLUE}📊 $1${NC}"
    echo "----------------------------------------"
}

# Function to log with timestamp
log() {
    local message="[$(date +'%H:%M:%S')] $*"
    echo -e "${BLUE}$message${NC}"
    echo "$message" >> "$VERIFICATION_LOG"
}

# Function to record check result
check_result() {
    local check_name="$1"
    local status="$2"
    local details="${3:-}"
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    if [[ "$status" == "PASS" ]]; then
        echo -e "${GREEN}✅ $check_name${NC} $details"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        echo -e "${RED}❌ $check_name${NC} $details"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
    fi
    
    echo "[$(date +'%H:%M:%S')] $status: $check_name $details" >> "$VERIFICATION_LOG"
}

# Initialize log
echo "Deployment Verification - $(date)" > "$VERIFICATION_LOG"

print_header "System Environment Verification"

# Check operating system
if [[ "$(uname -s)" == "Darwin" ]]; then
    check_result "Operating System" "PASS" "(macOS $(sw_vers -productVersion))"
else
    check_result "Operating System" "FAIL" "(Not macOS)"
fi

# Check Nix installation
if command -v nix &> /dev/null; then
    nix_version=$(nix --version | head -1)
    check_result "Nix Installation" "PASS" "($nix_version)"
else
    check_result "Nix Installation" "FAIL"
fi

# Check darwin-rebuild
if command -v darwin-rebuild &> /dev/null; then
    check_result "darwin-rebuild" "PASS"
else
    check_result "darwin-rebuild" "FAIL"
fi

print_header "Nix Configuration Verification"

# Check flake.nix exists
if [[ -f "$DOTFILES_DIR/flake.nix" ]]; then
    check_result "Flake Configuration" "PASS"
else
    check_result "Flake Configuration" "FAIL" "(flake.nix not found)"
fi

# Verify Nix configuration syntax
if cd "$DOTFILES_DIR" && nix flake check --no-build 2>/dev/null; then
    check_result "Nix Syntax Validation" "PASS"
else
    check_result "Nix Syntax Validation" "FAIL"
fi

print_header "Package Installation Verification"

# Core system packages verification
check_package() {
    local package_name="$1"
    local expected_path="$2"
    
    if [[ -x "$expected_path" ]]; then
        version=$($expected_path --version 2>/dev/null | head -1 || echo "version unknown")
        check_result "Package: $package_name" "PASS" "($version)"
    else
        check_result "Package: $package_name" "FAIL" "(not found at $expected_path)"
    fi
}

check_package "fish" "/run/current-system/sw/bin/fish"
check_package "carapace" "/run/current-system/sw/bin/carapace"
check_package "starship" "/run/current-system/sw/bin/starship"
check_package "hyperfine" "/run/current-system/sw/bin/hyperfine"
check_package "jq" "/run/current-system/sw/bin/jq"
check_package "gh" "/run/current-system/sw/bin/gh"

print_header "Homebrew Integration Verification"

# Check homebrew installation via nix-homebrew
if command -v brew &> /dev/null; then
    check_result "Homebrew Installation" "PASS"
else
    check_result "Homebrew Installation" "FAIL"
fi

# Check security tools from homebrew
declare -a SECURITY_TOOLS=("blockblock" "oversight" "knockknock" "dnd")
for tool in "${SECURITY_TOOLS[@]}"; do
    if brew list --cask 2>/dev/null | grep -q "^$tool$"; then
        check_result "Security Tool: $tool" "PASS" "(installed via Homebrew)"
    else
        check_result "Security Tool: $tool" "FAIL" "(not installed)"
    fi
done

print_header "Shell Configuration Verification"

# Check current shell
current_shell="$SHELL"
if [[ "$current_shell" == *"fish"* ]]; then
    check_result "Default Shell" "PASS" "(Fish shell active)"
elif [[ "$current_shell" == *"zsh"* ]]; then
    check_result "Default Shell" "WARN" "(ZSH active, Fish available)"
else
    check_result "Default Shell" "FAIL" "(Unexpected shell: $current_shell)"
fi

# Check Fish configuration
if [[ -f "$HOME/.config/fish/config.fish" ]]; then
    check_result "Fish Configuration" "PASS"
else
    check_result "Fish Configuration" "FAIL" "(config.fish not found)"
fi

# Check shell performance (quick test)
if command -v fish &> /dev/null; then
    start_time=$(date +%s%N)
    fish -c "echo test" &> /dev/null
    end_time=$(date +%s%N)
    duration=$(( (end_time - start_time) / 1000000 )) # Convert to milliseconds
    
    if [[ $duration -lt 100 ]]; then
        check_result "Fish Performance" "PASS" "(${duration}ms startup)"
    elif [[ $duration -lt 500 ]]; then
        check_result "Fish Performance" "WARN" "(${duration}ms startup - acceptable)"
    else
        check_result "Fish Performance" "FAIL" "(${duration}ms startup - too slow)"
    fi
fi

print_header "Service and Application Verification"

# Check specific applications
declare -a EXPECTED_APPS=("ActivityWatch.app")
for app in "${EXPECTED_APPS[@]}"; do
    if [[ -d "/Applications/$app" ]]; then
        check_result "Application: $app" "PASS"
    else
        check_result "Application: $app" "FAIL" "(not found in /Applications)"
    fi
done

print_header "Configuration File Verification"

# Check key configuration files
check_config_file() {
    local config_name="$1"
    local config_path="$2"
    
    if [[ -e "$config_path" ]]; then
        check_result "$config_name" "PASS"
    else
        check_result "$config_name" "FAIL" "(not found: $config_path)"
    fi
}

check_config_file "Starship Config" "$HOME/.config/starship.toml"
check_config_file "Git Config" "$HOME/.gitconfig"
check_config_file "ActivityWatch Config" "$HOME/Library/Application Support/activitywatch"

print_header "Performance and Monitoring Verification"

# Check if performance monitoring is working
if [[ -f "./shell-performance-benchmark.sh" ]] && [[ -x "./shell-performance-benchmark.sh" ]]; then
    check_result "Performance Monitoring Script" "PASS"
else
    check_result "Performance Monitoring Script" "FAIL"
fi

# Check if performance data directory exists
if [[ -d "./performance-data" ]]; then
    check_result "Performance Data Directory" "PASS"
else
    check_result "Performance Data Directory" "FAIL"
fi

print_header "Manual Steps Verification"

# Check if Fish shell needs manual activation
if [[ "$SHELL" != *"fish"* ]] && command -v fish &> /dev/null; then
    echo -e "${YELLOW}📝 Manual step required: Activate Fish shell${NC}"
    echo "   Run: chsh -s /run/current-system/sw/bin/fish"
fi

# Check if security tools need configuration
security_tools_need_config=false
for tool in "${SECURITY_TOOLS[@]}"; do
    if brew list --cask 2>/dev/null | grep -q "^$tool$"; then
        if ! ls "/Applications" | grep -qi "$tool"; then
            security_tools_need_config=true
            break
        fi
    fi
done

if $security_tools_need_config; then
    echo -e "${YELLOW}📝 Manual step required: Configure security tools${NC}"
    echo "   Security tools installed but may need manual setup"
fi

print_header "Deployment Verification Summary"

echo ""
echo "Total Checks: $TOTAL_CHECKS"
echo -e "Passed: ${GREEN}$PASSED_CHECKS${NC}"
echo -e "Failed: ${RED}$FAILED_CHECKS${NC}"

if [[ $FAILED_CHECKS -eq 0 ]]; then
    echo -e "${GREEN}🎉 All checks passed! Deployment successful.${NC}"
    exit 0
elif [[ $FAILED_CHECKS -le 3 ]]; then
    echo -e "${YELLOW}⚠️  Deployment mostly successful with minor issues.${NC}"
    exit 1
else
    echo -e "${RED}❌ Deployment has significant issues. Review failed checks.${NC}"
    exit 2
fi