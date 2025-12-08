#!/usr/bin/env bash
# Test script for NixOS evo-x2 Home Manager configuration fix

echo "🔧 Testing NixOS evo-x2 configuration build..."
echo "======================================================"

# Test 1: Check flake syntax
echo "1. Checking flake syntax..."
if nix flake check --quiet; then
    echo "✅ Flake syntax check passed"
else
    echo "❌ Flake syntax check failed"
    exit 1
fi

# Test 2: Try to build the configuration (dry run)
echo "2. Building configuration (dry run)..."
if nix build .#nixosConfigurations.evo-x2.config.system.build.toplevel --dry-run; then
    echo "✅ Configuration build check passed"
else
    echo "❌ Configuration build check failed"
    exit 1
fi

# Test 3: Check if we can apply the configuration (without actually applying)
echo "3. Testing nixos-rebuild check..."
if sudo nixos-rebuild check --flake .#evo-x2; then
    echo "✅ nixos-rebuild check passed"
else
    echo "❌ nixos-rebuild check failed"
    exit 1
fi

echo "======================================================"
echo "🎉 All tests passed! You can now safely run:"
echo "   sudo nixos-rebuild switch --flake .#evo-x2"