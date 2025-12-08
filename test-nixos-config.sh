#!/usr/bin/env bash

# Test script for NixOS configuration
# Run this on evo-x2 (NixOS system) to verify the configuration builds correctly

echo "🔨 Testing NixOS Configuration Build..."
echo "======================================="

# Check if running on NixOS
if [ ! -f /etc/nixos/configuration.nix ]; then
    echo "Error: This script must be run on NixOS"
    exit 1
fi

# Test build without applying
echo "Building configuration (dry run)..."
if sudo nixos-rebuild build --flake .#evo-x2; then
    echo "✓ Configuration builds successfully!"

    # Check the built configuration
    if [ -d ./result ]; then
        echo "✓ Build result created in ./result"

        # List what's in the result
        echo "Build contents:"
        ls -la ./result/
    fi
else
    echo "✗ Configuration build failed!"
    echo "Check the error messages above for issues."
    exit 1
fi

# Optional: Test configuration check (faster)
echo "Running quick configuration check..."
if sudo nixos-rebuild check --flake .#evo-x2; then
    echo "✓ Configuration check passed!"
else
    echo "✗ Configuration check failed!"
    exit 1
fi

echo "✅ All tests passed! Configuration is ready to apply."
echo "To apply the configuration, run: sudo nixos-rebuild switch --flake .#evo-x2"