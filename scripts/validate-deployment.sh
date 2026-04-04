#!/usr/bin/env nix-shell
#!nix-shell -i bash -p nix coreutils git

set -euo pipefail

# Deployment Validation Script
# Comprehensive validation for NixOS deployment to evo-x2

CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPORT_FILE="${CONFIG_DIR}/test-reports/deployment-validation-$(date +%Y%m%d_%H%M%S).txt"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

log() {
  echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$REPORT_FILE"
}

success() {
  echo -e "${GREEN}[✓ PASS]${NC} $1" | tee -a "$REPORT_FILE"
}

warning() {
  echo -e "${YELLOW}[⚠ WARN]${NC} $1" | tee -a "$REPORT_FILE"
}

error() {
  echo -e "${RED}[✗ FAIL]${NC} $1" | tee -a "$REPORT_FILE"
}

info() {
  echo -e "${PURPLE}[INFO]${NC} $1" | tee -a "$REPORT_FILE"
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

# Validate NixOS configuration
validate_nixos_config() {
  log "Validating NixOS configuration..."

  # Check if configuration files exist
  local config_files=(
    "dotfiles/nixos/configuration.nix"
    "dotfiles/nixos/hardware-configuration.nix"
    "dotfiles/nixos/home.nix"
    "dotfiles/nixos/ssh-banner"
  )

  local missing_files=0
  for file in "${config_files[@]}"; do
    if [[ -f $file ]]; then
      log "✓ Found configuration file: $file"
    else
      error "✗ Missing configuration file: $file"
      ((missing_files++))
    fi
  done

  if [[ $missing_files -eq 0 ]]; then
    success "All NixOS configuration files present"
    track_test "pass"
    return 0
  else
    error "Missing $missing_files configuration files"
    track_test "fail"
    return 1
  fi
}

# Validate boot configuration
validate_boot_config() {
  log "Validating boot configuration..."

  local boot_config_errors=0

  # Check systemd-boot configuration
  if grep -E "boot\.loader\.systemd-boot\.enable.*true" dotfiles/nixos/configuration.nix >/dev/null; then
    log "✓ systemd-boot enabled"
  else
    error "✗ systemd-boot not enabled"
    ((boot_config_errors++))
  fi

  # Check EFI configuration
  if grep -E "boot\.loader\.efi\.canTouchEfiVariables.*true" dotfiles/nixos/configuration.nix >/dev/null; then
    log "✓ EFI variables enabled"
  else
    error "✗ EFI variables not enabled"
    ((boot_config_errors++))
  fi

  # Check kernel configuration
  if grep -E "boot\.kernelPackages.*latest" dotfiles/nixos/configuration.nix >/dev/null; then
    log "✓ Latest kernel configured"
  else
    warning "⚠ Latest kernel not explicitly configured"
  fi

  if [[ $boot_config_errors -eq 0 ]]; then
    success "Boot configuration validation passed"
    track_test "pass"
    return 0
  else
    error "Boot configuration validation failed: $boot_config_errors errors"
    track_test "fail"
    return 1
  fi
}

# Validate AMD GPU configuration
validate_amd_gpu() {
  log "Validating AMD GPU configuration..."

  local gpu_config_errors=0

  # Check AMD GPU driver configuration
  if grep -E "services\.xserver\.videoDrivers.*amdgpu" dotfiles/nixos/configuration.nix >/dev/null; then
    log "✓ AMD GPU drivers configured"
  else
    error "✗ AMD GPU drivers not configured"
    ((gpu_config_errors++))
  fi

  # Check hardware graphics configuration
  if grep -E "hardware\.graphics\.enable.*true" dotfiles/nixos/configuration.nix >/dev/null; then
    log "✓ Hardware graphics enabled"
  else
    error "✗ Hardware graphics not enabled"
    ((gpu_config_errors++))
  fi

  # Check AMD kernel parameters
  local amd_params=(
    "amdgpu.ppfeaturemask=0xfffd7fff"
    "amd_pstate=guided"
  )

  for param in "${amd_params[@]}"; do
    if grep -F "$param" dotfiles/nixos/configuration.nix >/dev/null; then
      log "✓ AMD kernel parameter: $param"
    else
      warning "⚠ AMD kernel parameter not found: $param"
      ((gpu_config_errors++))
    fi
  done

  # Check for AMD GPU monitoring tools
  local gpu_tools=(
    "amdgpu_top"
    "corectrl"
    "vulkan-tools"
  )

  for tool in "${gpu_tools[@]}"; do
    if grep -q "$tool" dotfiles/nixos/configuration.nix; then
      log "✓ AMD GPU tool available: $tool"
    else
      warning "⚠ AMD GPU tool not found: $tool"
    fi
  done

  if [[ $gpu_config_errors -eq 0 ]]; then
    success "AMD GPU configuration validation passed"
    track_test "pass"
    return 0
  else
    error "AMD GPU configuration validation failed: $gpu_config_errors errors"
    track_test "fail"
    return 1
  fi
}

# Validate Niri desktop configuration
validate_niri() {
  log "Validating Niri desktop configuration..."

  local desktop_config_errors=0

  # Check Niri system configuration
  if grep -rE "programs\.niri\.enable.*=.*true" platforms/nixos/desktop/ >/dev/null 2>&1; then
    log "✓ Niri enabled at system level"
  else
    error "✗ Niri not enabled at system level"
    ((desktop_config_errors++))
  fi

  # Check display manager configuration
  if grep -rE "services\.displayManager\.sddm\.enable.*=.*true" platforms/nixos/desktop/ >/dev/null 2>&1; then
    log "✓ SDDM display manager enabled"
  else
    error "✗ SDDM display manager not enabled"
    ((desktop_config_errors++))
  fi

  if [[ $desktop_config_errors -eq 0 ]]; then
    success "Niri desktop configuration validation passed"
    track_test "pass"
    return 0
  else
    error "Niri desktop configuration validation failed: $desktop_config_errors errors"
    track_test "fail"
    return 1
  fi
}

# Validate SSH hardening
validate_ssh_hardening() {
  log "Validating SSH hardening configuration..."

  local ssh_config_errors=0

  # Check SSH service enabled
  if grep -E "services\.openssh\.enable.*true" dotfiles/nixos/configuration.nix >/dev/null; then
    log "✓ SSH service enabled"
  else
    error "✗ SSH service not enabled"
    ((ssh_config_errors++))
  fi

  # Check SSH hardening settings
  local ssh_settings=(
    "PasswordAuthentication.*false"
    'PermitRootLogin.*"no"'
    "PermitEmptyPasswords.*false"
  )

  for setting in "${ssh_settings[@]}"; do
    if grep -E "$setting" dotfiles/nixos/configuration.nix >/dev/null; then
      log "✓ SSH hardening: $setting"
    else
      error "✗ SSH hardening missing: $setting"
      ((ssh_config_errors++))
    fi
  done

  # Check SSH banner configuration
  if [[ -f "dotfiles/nixos/ssh-banner" ]]; then
    log "✓ SSH banner file exists"
    if grep -E "Banner.*/etc/ssh/banner" dotfiles/nixos/configuration.nix >/dev/null; then
      log "✓ SSH banner configured"
    else
      warning "⚠ SSH banner file exists but not configured"
    fi
  else
    error "✗ SSH banner file missing"
    ((ssh_config_errors++))
  fi

  # Check user SSH keys configuration
  if grep -E "openssh\.authorizedKeys\.keys" dotfiles/nixos/configuration.nix >/dev/null; then
    log "✓ SSH authorized keys configured"
  else
    warning "⚠ SSH authorized keys not found in configuration"
  fi

  if [[ $ssh_config_errors -eq 0 ]]; then
    success "SSH hardening validation passed"
    track_test "pass"
    return 0
  else
    error "SSH hardening validation failed: $ssh_config_errors errors"
    track_test "fail"
    return 1
  fi
}

# Validate user configuration
validate_user_config() {
  log "Validating user configuration..."

  local user_config_errors=0

  # Check user account configuration
  if grep -E "users\.users\.lars" dotfiles/nixos/configuration.nix >/dev/null; then
    log "✓ User 'lars' configured"
  else
    error "✗ User 'lars' not configured"
    ((user_config_errors++))
  fi

  # Check user group configuration
  local required_groups=(
    "networkmanager"
    "wheel"
    "docker"
    "video"
    "audio"
  )

  for group in "${required_groups[@]}"; do
    if grep -E "$group" dotfiles/nixos/configuration.nix >/dev/null; then
      log "✓ User group: $group"
    else
      warning "⚠ User group not found: $group"
    fi
  done

  # Check user shell configuration
  if grep -E "shell.*fish" dotfiles/nixos/configuration.nix >/dev/null; then
    log "✓ Fish shell configured for user"
  else
    warning "⚠ Fish shell not explicitly configured for user"
  fi

  if [[ $user_config_errors -eq 0 ]]; then
    success "User configuration validation passed"
    track_test "pass"
    return 0
  else
    error "User configuration validation failed: $user_config_errors errors"
    track_test "fail"
    return 1
  fi
}

# Validate security configuration
validate_security_config() {
  log "Validating security configuration..."

  local security_config_errors=0

  # Check firewall configuration
  if grep -E "networking\.firewall\.enable.*true" dotfiles/nixos/configuration.nix >/dev/null; then
    log "✓ Firewall enabled"
  else
    warning "⚠ Firewall not explicitly enabled"
  fi

  # Check polkit configuration
  if grep -E "security\.polkit\.enable.*true" dotfiles/nixos/configuration.nix >/dev/null; then
    log "✓ Polkit enabled"
  else
    error "✗ Polkit not enabled"
    ((security_config_errors++))
  fi

  # Check security features
  local security_features=(
    "zramSwap\.enable"
    "services\.pipewire\.enable"
    "security\.rtkit\.enable"
  )

  for feature in "${security_features[@]}"; do
    if grep -E "$feature.*true" dotfiles/nixos/configuration.nix >/dev/null; then
      log "✓ Security feature: $feature"
    else
      warning "⚠ Security feature not found: $feature"
    fi
  done

  if [[ $security_config_errors -eq 0 ]]; then
    success "Security configuration validation passed"
    track_test "pass"
    return 0
  else
    error "Security configuration validation failed: $security_config_errors errors"
    track_test "fail"
    return 1
  fi
}

# Validate deployment readiness
validate_deployment_readiness() {
  log "Validating deployment readiness..."

  local deployment_errors=0

  # Check flake configuration
  if [[ -f "flake.nix" ]]; then
    log "✅ Flake configuration exists"
  else
    error "❌ Flake configuration missing"
    ((deployment_errors++))
  fi

  # Check for evo-x2 configuration in flake
  if grep -E "nixosConfigurations.*evo-x2" flake.nix >/dev/null; then
    log "✅ evo-x2 configuration found in flake"
  else
    error "❌ evo-x2 configuration not found in flake"
    ((deployment_errors++))
  fi

  # Check flake validation
  if timeout 60 nix flake check --all-systems >/dev/null 2>&1; then
    log "✅ Flake validation passed"
  else
    error "❌ Flake validation failed"
    ((deployment_errors++))
  fi

  if [[ $deployment_errors -eq 0 ]]; then
    success "Deployment readiness validation passed"
    track_test "pass"
    return 0
  else
    error "Deployment readiness validation failed: $deployment_errors errors"
    track_test "fail"
    return 1
  fi
}

# Generate deployment report
generate_deployment_report() {
  log "Generating deployment validation report..."

  cat >>"$REPORT_FILE" <<EOF

========================================
DEPLOYMENT VALIDATION SUMMARY
========================================

Test Summary:
- Total Tests: $TESTS_TOTAL
- Passed: $TESTS_PASSED
- Failed: $TESTS_FAILED
- Skipped: $TESTS_SKIPPED
- Success Rate: $((TESTS_PASSED * 100 / TESTS_TOTAL))%

Deployment Status:
EOF

  if [[ $TESTS_FAILED -eq 0 ]]; then
    echo "✅ CONFIGURATION IS READY FOR DEPLOYMENT" >>"$REPORT_FILE"
    echo "   - All critical validations passed" >>"$REPORT_FILE"
    echo "   - NixOS configuration is complete" >>"$REPORT_FILE"
    echo "   - Hardware-specific optimizations are in place" >>"$REPORT_FILE"
    echo "" >>"$REPORT_FILE"
    echo "Next Steps:" >>"$REPORT_FILE"
    echo "1. Deploy to evo-x2 hardware" >>"$REPORT_FILE"
    echo "2. Run: sudo nixos-rebuild switch --flake .#evo-x2" >>"$REPORT_FILE"
    echo "3. Verify all services are running" >>"$REPORT_FILE"
    echo "4. Test Niri desktop environment" >>"$REPORT_FILE"
    echo "5. Validate AMD GPU performance" >>"$REPORT_FILE"
  else
    echo "❌ CONFIGURATION IS NOT READY FOR DEPLOYMENT" >>"$REPORT_FILE"
    echo "   - $TESTS_FAILED critical validations failed" >>"$REPORT_FILE"
    echo "   - Fix failing tests before deployment" >>"$REPORT_FILE"
    echo "" >>"$REPORT_FILE"
    echo "Required Actions:" >>"$REPORT_FILE"
    echo "1. Fix all failing validations" >>"$REPORT_FILE"
    echo "2. Re-run deployment validation" >>"$REPORT_FILE"
    echo "3. Ensure 100% test success rate" >>"$REPORT_FILE"
  fi

  echo "" >>"$REPORT_FILE"
  echo "Report generated: $(date)" >>"$REPORT_FILE"

  success "Deployment validation report generated"
}

# Show deployment results
show_deployment_results() {
  echo ""
  echo "=========================================="
  echo "🚀 DEPLOYMENT VALIDATION RESULTS"
  echo "=========================================="
  echo ""
  echo "Total Tests: $TESTS_TOTAL"
  echo "✓ Passed: $TESTS_PASSED"
  echo "✗ Failed: $TESTS_FAILED"
  echo "⚠ Skipped: $TESTS_SKIPPED"
  echo ""

  local success_rate=$((TESTS_PASSED * 100 / TESTS_TOTAL))
  echo "Success Rate: ${success_rate}%"
  echo ""

  if [[ $TESTS_FAILED -eq 0 ]]; then
    echo "🎉 DEPLOYMENT READY!"
    echo "Configuration passed all validation tests."
    echo ""
    echo "🚀 READY FOR EVO-X2 DEPLOYMENT!"
    echo ""
    echo "Deployment Command:"
    echo "  sudo nixos-rebuild switch --flake .#evo-x2"
    return 0
  else
    echo "❌ DEPLOYMENT NOT READY"
    echo "Fix failing tests before deployment."
    return 1
  fi
}

# Main execution
main() {
  log "Starting NixOS deployment validation..."
  log "Configuration directory: $CONFIG_DIR"
  log "Report file: $REPORT_FILE"

  # Initialize report file
  echo "NixOS Deployment Validation Report" >"$REPORT_FILE"
  echo "Started: $(date)" >>"$REPORT_FILE"
  echo "=================================" >>"$REPORT_FILE"
  echo "" >>"$REPORT_FILE"

  # Change to config directory
  cd "$CONFIG_DIR"

  # Run all validations
  validate_nixos_config
  validate_boot_config
  validate_amd_gpu
  validate_niri
  validate_ssh_hardening
  validate_user_config
  validate_security_config
  validate_deployment_readiness

  # Generate report and show results
  generate_deployment_report
  show_deployment_results
}

# Show help
show_help() {
  cat <<EOF
NixOS Deployment Validation Script

Usage: $0 [OPTIONS]

Options:
    -h, --help          Show this help message
    -q, --quiet         Minimal output
    -v, --verbose       Detailed output

Environment Variables:
    CONFIG_DIR          Override configuration directory

Examples:
    $0                              # Run full deployment validation
    CONFIG_DIR=/tmp/config $0       # Validate specific directory

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
  -h | --help)
    show_help
    exit 0
    ;;
  -q | --quiet)
    exec >/dev/null
    shift
    ;;
  -v | --verbose)
    set -x
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
