#!/bin/bash
set -euo pipefail

echo "🔍 Nix Configuration Diagnostic Tool"
echo "====================================="

echo "📍 Current directory: $(pwd)"
echo "📂 Working directory: $(pwd)"

echo ""
echo "🌐 Network Connectivity Test:"
echo "----------------------------"

# Test basic connectivity
if curl -s --connect-timeout 5 https://cache.nixos.org >/dev/null 2>&1; then
    echo "✅ cache.nixos.org: reachable"
else
    echo "❌ cache.nixos.org: NOT reachable"
fi

if curl -s --connect-timeout 5 https://github.com >/dev/null 2>&1; then
    echo "✅ github.com: reachable"
else
    echo "❌ github.com: NOT reachable"
fi

echo ""
echo "🔧 Nix Configuration Status:"
echo "---------------------------"

echo "📋 Flake inputs:"
cd dotfiles/nix 2>/dev/null || echo "❌ Cannot find dotfiles/nix directory"

if [ -f "flake.nix" ]; then
    echo "✅ flake.nix exists"
    echo "📦 Nixpkgs version:"
    grep -A1 "nixpkgs.url" flake.nix | tail -1 | sed 's/.*\///;s/".*//'
else
    echo "❌ flake.nix missing"
fi

if [ -f "flake.lock" ]; then
    echo "✅ flake.lock exists"
    echo "📊 Lock file size: $(du -h flake.lock | cut -f1)"
else
    echo "❌ flake.lock missing"
fi

echo ""
echo "💾 Disk Space:"
echo "------------"
echo "📂 Nix store: $(du -sh /nix/store 2>/dev/null || echo "Not accessible")"
echo "💻 Available space: $(df -h . | tail -1 | awk '{print $4}')"

echo ""
echo "🔨 Recent Build Errors:"
echo "--------------------"

# Check for recent error logs
if [ -d ~/.local/state/nix/logs ]; then
    echo "📋 Recent Nix logs:"
    find ~/.local/state/nix/logs -name "*.log" -mtime -1 -exec ls -la {} \; 2>/dev/null | head -3 || echo "No recent logs found"
else
    echo "📋 No Nix log directory found"
fi

echo ""
echo "🚀 Recommended Fix Strategy:"
echo "==========================="
echo "1. 🔄 Update to stable nixpkgs: $(grep -A1 "nixpkgs.url" flake.nix 2>/dev/null | tail -1 | sed 's/.*\///;s/".*//' || echo 'unknown')"
echo "2. 🗑️  Remove problematic inputs (treefmt-full-flake, nix-ai-tools)"
echo "3. 🌐 Fix network connectivity issues"
echo "4. 🧹 Clear corrupted caches: nix-store --gc"
echo "5. ⚡ Try offline mode or use fallback configuration"

echo ""
echo "🔧 Quick Fix Commands:"
echo "---------------------"
echo "# Reset to minimal configuration"
echo "cd dotfiles/nix"
echo "rm flake.lock"
echo "nix flake update --no-registries"

echo ""
echo "# Build with less dependencies"
echo "darwin-rebuild build --flake . --option sandbox false"

echo ""
echo "✅ Diagnostic complete!"