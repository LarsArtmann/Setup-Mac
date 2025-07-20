#!/usr/bin/env bash

# Configuration Validation Framework - Usage Examples
# Demonstrates various validation workflows and use cases

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "🎯 Configuration Validation Framework - Usage Examples"
echo "======================================================"

#############################################################################
# BASIC USAGE EXAMPLES
#############################################################################

echo ""
echo "📚 BASIC USAGE EXAMPLES"
echo "------------------------"

# Example 1: Quick validation during development
echo ""
echo "🔍 Example 1: Quick validation for development workflow"
echo "Command: ./scripts/config-validate.sh --quick"
echo "Use case: Fast feedback during active development"
echo "Duration: ~10-30 seconds"

# Example 2: Comprehensive validation for deployment
echo ""
echo "🔒 Example 2: Strict validation for production deployment"
echo "Command: ./scripts/config-validate.sh --strict"
echo "Use case: Pre-deployment safety check with warnings as errors"
echo "Duration: ~1-3 minutes"

# Example 3: Specific component validation
echo ""
echo "❄️ Example 3: Nix-only validation"
echo "Command: ./scripts/config-validate.sh nix"
echo "Use case: Focus on Nix configuration issues only"
echo "Duration: ~30-60 seconds"

#############################################################################
# JUST TASK RUNNER EXAMPLES
#############################################################################

echo ""
echo "⚡ JUST TASK RUNNER EXAMPLES"
echo "-----------------------------"

# Example 4: Development workflow
echo ""
echo "🔧 Example 4: Start development session"
echo "Command: just dev"
echo "What it does:"
echo "  1. Runs quick validation"
echo "  2. Shows any immediate issues"
echo "  3. Prepares environment for development"

# Example 5: Safe deployment
echo ""
echo "🛡️ Example 5: Safe configuration deployment"
echo "Command: just deploy-safe"
echo "What it does:"
echo "  1. Creates backup of current configuration"
echo "  2. Runs comprehensive validation"
echo "  3. Builds new configuration"
echo "  4. Applies configuration if all checks pass"

# Example 6: Troubleshooting workflow
echo ""
echo "🐛 Example 6: Troubleshooting configuration issues"
echo "Commands:"
echo "  just debug           # Show system information"
echo "  just logs            # Review recent validation logs"
echo "  just validate-report # Generate detailed report"

#############################################################################
# WORKFLOW SCENARIOS
#############################################################################

echo ""
echo "🌊 WORKFLOW SCENARIOS"
echo "---------------------"

echo ""
echo "📋 Scenario 1: Daily Development Workflow"
echo "==========================================="
cat << 'EOF'
# Morning setup
just dev                    # Quick validation and environment check

# During development (after each change)
git add .
git commit -m "Update config"  # Pre-commit hooks run automatically

# Before lunch break
just validate-quick         # Quick sanity check

# End of day
just validate-strict        # Comprehensive validation before signing off
EOF

echo ""
echo "📋 Scenario 2: Weekly Maintenance Workflow"
echo "==========================================="
cat << 'EOF'
# Update dependencies
just update                 # Update flake inputs
just validate-strict        # Ensure updates don't break anything

# Performance review
just benchmark              # Check shell startup times
just validate-report weekly-report.md  # Generate detailed report

# Cleanup
just clean                  # Clean up old generations and optimize store
EOF

echo ""
echo "📋 Scenario 3: Production Deployment Workflow"
echo "==============================================="
cat << 'EOF'
# Pre-deployment safety
just backup                 # Create configuration backup
just validate-strict        # Comprehensive validation

# Deployment
just deploy-safe           # Safe deployment with all checks

# Post-deployment verification
just validate-quick        # Verify deployment success
just benchmark             # Check performance impact
EOF

echo ""
echo "📋 Scenario 4: Emergency Recovery Workflow"
echo "==========================================="
cat << 'EOF'
# If system breaks after configuration change
ls backups/                            # Check available backups
just restore backups/config-backup-*.tar.gz  # Restore last known good

# Investigate issue
just debug                             # Gather system information
just logs                              # Review validation logs
just validate --verbose nix           # Detailed Nix validation

# Fix and re-deploy
# Fix the identified issue
just validate-strict                   # Ensure fix is correct
just deploy-safe                       # Re-deploy safely
EOF

#############################################################################
# SPECIFIC USE CASES
#############################################################################

echo ""
echo "🎯 SPECIFIC USE CASES"
echo "--------------------"

echo ""
echo "🔍 Use Case 1: Debugging Nix Configuration Issues"
cat << 'EOF'
# Step 1: Run specific Nix validation with verbose output
./scripts/config-validate.sh --verbose nix

# Step 2: Check flake directly
nix flake check --show-trace

# Step 3: Test individual files
nix-instantiate --parse ./home.nix
nix-instantiate --parse ./system.nix

# Step 4: Check for common issues
grep -r "TODO\|FIXME\|XXX" *.nix
EOF

echo ""
echo "🐚 Use Case 2: Optimizing Shell Performance"
cat << 'EOF'
# Step 1: Benchmark current performance
just benchmark

# Step 2: Run shell-specific validation
just validate-shell --verbose

# Step 3: Profile specific shells
time fish -c "echo test"
time zsh -c "echo test"

# Step 4: Check for performance issues
./scripts/config-validate.sh --verbose shell
EOF

echo ""
echo "📦 Use Case 3: Resolving Package Conflicts"
cat << 'EOF'
# Step 1: Check for conflicts
just validate-deps --verbose

# Step 2: Examine PATH
echo $PATH | tr ':' '\n' | nl

# Step 3: Check installed packages
brew list                  # Homebrew packages
nix-env -q                # Nix user packages
ls /nix/store | grep -E "^[a-z0-9]{32}-" | head -20  # Nix store

# Step 4: Resolve conflicts
# Remove duplicate packages from one package manager
# Update configuration to use single source
EOF

echo ""
echo "🔒 Use Case 4: Security Audit Workflow"
cat << 'EOF'
# Step 1: Run security-focused validation
./scripts/config-validate.sh --verbose nix | grep -i "security\|password\|key\|secret"

# Step 2: Check for hardcoded secrets
grep -r -i "password\|secret\|key\|token" *.nix || echo "No hardcoded secrets found"

# Step 3: Review file permissions
find . -name "*.nix" -exec ls -la {} \;

# Step 4: Validate SSL/TLS configurations
grep -r -i "ssl\|tls\|cert" *.nix || echo "No SSL/TLS configurations found"
EOF

#############################################################################
# ADVANCED EXAMPLES
#############################################################################

echo ""
echo "🚀 ADVANCED EXAMPLES"
echo "--------------------"

echo ""
echo "🔧 Advanced Example 1: Custom Validation Integration"
cat << 'EOF'
# Create custom validation script
cat > custom-validation.sh << 'SCRIPT'
#!/usr/bin/env bash
# Custom organization-specific validations

# Run framework validation first
./scripts/config-validate.sh --strict

# Add custom checks
echo "Running custom validations..."

# Check for organization-specific requirements
if ! grep -q "company.security.policy" *.nix; then
    echo "ERROR: Missing company security policy configuration"
    exit 1
fi

echo "All custom validations passed!"
SCRIPT

chmod +x custom-validation.sh
./custom-validation.sh
EOF

echo ""
echo "🔄 Advanced Example 2: CI/CD Integration"
cat << 'EOF'
# GitHub Actions workflow example
cat > .github/workflows/validate.yml << 'YAML'
name: Configuration Validation

on: [push, pull_request]

jobs:
  validate:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3

      - name: Install Nix
        uses: cachix/install-nix-action@v18
        with:
          enable_flakes: true

      - name: Run Validation
        run: |
          chmod +x scripts/config-validate.sh
          ./scripts/config-validate.sh --strict

      - name: Generate Report
        run: |
          ./scripts/config-validate.sh --report validation-report.md report

      - name: Upload Report
        uses: actions/upload-artifact@v3
        with:
          name: validation-report
          path: validation-report.md
YAML
EOF

echo ""
echo "📊 Advanced Example 3: Performance Monitoring Setup"
cat << 'EOF'
# Create performance monitoring script
cat > monitor-performance.sh << 'SCRIPT'
#!/usr/bin/env bash

echo "📊 Performance Monitoring Report - $(date)"
echo "==========================================="

# Shell startup times
echo ""
echo "🐚 Shell Startup Times:"
for shell in fish zsh bash; do
    if command -v $shell >/dev/null; then
        time_ms=$(( $(date +%s%N) ))
        $shell -c "echo test" >/dev/null 2>&1
        time_ms=$(( ($(date +%s%N) - time_ms) / 1000000 ))
        echo "  $shell: ${time_ms}ms"
    fi
done

# Nix evaluation time
echo ""
echo "❄️ Nix Evaluation Time:"
time nix eval .#darwinConfigurations.Lars-MacBook-Air.config.system.build.toplevel.outPath

# System resources
echo ""
echo "💻 System Resources:"
echo "  Memory: $(vm_stat | grep "Pages free" | awk '{print $3}' | sed 's/\.//')KB free"
echo "  Load: $(uptime | awk -F'load averages:' '{print $2}')"

# Validation performance
echo ""
echo "🔍 Validation Performance:"
time ./scripts/config-validate.sh --quick >/dev/null
SCRIPT

chmod +x monitor-performance.sh
./monitor-performance.sh
EOF

#############################################################################
# INTEGRATION EXAMPLES
#############################################################################

echo ""
echo "🔗 INTEGRATION EXAMPLES"
echo "-----------------------"

echo ""
echo "🪝 Integration Example 1: Pre-commit Hook Setup"
cat << 'EOF'
# Install pre-commit
brew install pre-commit  # or nix-env -iA nixpkgs.pre-commit

# Setup hooks
just setup-hooks

# Test hooks
just run-hooks

# Add custom hook
cat >> .pre-commit-config.yaml << 'YAML'
  - repo: local
    hooks:
      - id: custom-security-check
        name: Custom Security Check
        entry: ./custom-security-check.sh
        language: script
        files: \.nix$
YAML
EOF

echo ""
echo "⏰ Integration Example 2: Scheduled Validation (cron)"
cat << 'EOF'
# Add to crontab for weekly validation
# Run: crontab -e
# Add line:
0 9 * * 1 cd /path/to/dotfiles && ./scripts/config-validate.sh --report weekly-report.md report
EOF

echo ""
echo "🔔 Integration Example 3: Notification Setup"
cat << 'EOF'
# Create notification wrapper
cat > validate-with-notifications.sh << 'SCRIPT'
#!/usr/bin/env bash

if ./scripts/config-validate.sh --strict; then
    osascript -e 'display notification "Configuration validation passed!" with title "Nix Config"'
else
    osascript -e 'display notification "Configuration validation failed!" with title "Nix Config" sound name "Basso"'
fi
SCRIPT

chmod +x validate-with-notifications.sh
EOF

#############################################################################
# MAINTENANCE EXAMPLES
#############################################################################

echo ""
echo "🧹 MAINTENANCE EXAMPLES"
echo "-----------------------"

echo ""
echo "📅 Maintenance Example 1: Weekly Cleanup Routine"
cat << 'EOF'
#!/usr/bin/env bash
# Weekly maintenance routine

echo "🧹 Weekly Nix Configuration Maintenance"
echo "========================================"

# Update dependencies
echo "📦 Updating flake inputs..."
just update

# Comprehensive validation
echo "🔍 Running comprehensive validation..."
just validate-strict

# Performance check
echo "⏱️ Checking performance..."
just benchmark

# Generate weekly report
echo "📊 Generating weekly report..."
just validate-report "weekly-report-$(date +%Y%m%d).md"

# Cleanup old generations
echo "🗑️ Cleaning up old generations..."
just clean

# Backup current configuration
echo "💾 Creating weekly backup..."
just backup

echo "✅ Weekly maintenance completed!"
EOF

echo ""
echo "🔄 Maintenance Example 2: Dependency Update Workflow"
cat << 'EOF'
#!/usr/bin/env bash
# Safe dependency update workflow

echo "📦 Safe Dependency Update Workflow"
echo "=================================="

# Create backup before updates
echo "💾 Creating backup..."
just backup

# Update dependencies
echo "🔄 Updating flake inputs..."
nix flake update

# Validate after update
echo "🔍 Validating updated configuration..."
if just validate-strict; then
    echo "✅ Updates validated successfully"

    # Test build
    echo "🏗️ Testing build..."
    if just build; then
        echo "✅ Build successful, ready to deploy"
    else
        echo "❌ Build failed, reverting updates"
        git checkout -- flake.lock
    fi
else
    echo "❌ Validation failed, reverting updates"
    git checkout -- flake.lock
fi
EOF

echo ""
echo "✨ Examples complete! Use these patterns as starting points for your own workflows."
echo ""
echo "🔗 Quick reference:"
echo "  - Basic: just validate-quick"
echo "  - Safe deployment: just deploy-safe"
echo "  - Troubleshooting: just debug && just logs"
echo "  - Documentation: less docs/configuration-validation.md"