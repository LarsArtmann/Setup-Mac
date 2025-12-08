#!/usr/bin/env bash

set -euo pipefail

# Simple Configuration Test
# Validates the core functionality of the Nix configuration

echo "🧪 SETUP-MAC CONFIGURATION TEST"
echo "================================"
echo ""

# Test 1: Flake validation
echo "🔍 Testing flake validation..."
if nix flake check --all-systems; then
    echo "✅ Flake validation passed"
else
    echo "❌ Flake validation failed"
    exit 1
fi
echo ""

# Test 2: Nix syntax validation
echo "🔍 Testing Nix syntax..."
syntax_errors=0
for file in $(find . -name "*.nix" -type f); do
    if nix-instantiate --parse "$file" > /dev/null 2>&1; then
        echo "✅ $file: Valid syntax"
    else
        echo "❌ $file: Syntax error"
        ((syntax_errors++))
    fi
done

if [ $syntax_errors -eq 0 ]; then
    echo "✅ All Nix files have valid syntax"
else
    echo "❌ Found $syntax_errors files with syntax errors"
    exit 1
fi
echo ""

# Test 3: Required files
echo "🔍 Testing required files..."
required_files=("flake.nix" "dotfiles/nixos/configuration.nix" "dotfiles/nixos/hardware-configuration.nix")
missing_files=0

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file: Present"
    else
        echo "❌ $file: Missing"
        ((missing_files++))
    fi
done

if [ $missing_files -eq 0 ]; then
    echo "✅ All required files present"
else
    echo "❌ Found $missing_files missing files"
    exit 1
fi
echo ""

# Test 4: Essential configuration
echo "🔍 Testing essential configuration..."
essential_patterns=(
    "systemd-boot\.enable\s*=\s*true"
    "networking\.hostName\s*=\s*\"evo-x2\""
    "services\.openssh.*=\s*\{"
    "users\.users\.lars"
)

config_errors=0
for pattern in "${essential_patterns[@]}"; do
    if grep -E "$pattern" dotfiles/nixos/configuration.nix > /dev/null; then
        echo "✅ Configuration pattern: $pattern"
    else
        echo "❌ Missing configuration pattern: $pattern"
        ((config_errors++))
    fi
done

if [ $config_errors -eq 0 ]; then
    echo "✅ All essential configuration patterns found"
else
    echo "❌ Found $config_errors missing configuration patterns"
    exit 1
fi
echo ""

# Test 5: Security configuration
echo "🔍 Testing security configuration..."
security_issues=0

if grep -E "PasswordAuthentication\s*=\s*false" dotfiles/nixos/configuration.nix > /dev/null; then
    echo "✅ SSH: Password authentication disabled"
else
    echo "❌ SSH: Password authentication not explicitly disabled"
    ((security_issues++))
fi

if grep -E "PermitRootLogin\s*=\s*\"no\"" dotfiles/nixos/configuration.nix > /dev/null; then
    echo "✅ SSH: Root login disabled"
else
    echo "❌ SSH: Root login not explicitly disabled"
    ((security_issues++))
fi

if [ $security_issues -eq 0 ]; then
    echo "✅ Security configuration test passed"
else
    echo "❌ Found $security_issues security issues"
    exit 1
fi
echo ""

echo "🎉 ALL TESTS PASSED!"
echo "Configuration is ready for deployment."
echo ""