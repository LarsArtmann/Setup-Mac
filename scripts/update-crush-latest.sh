#!/usr/bin/env bash
# Update to the latest version of Crush from NUR (Nix User Repository)
# This script ensures you're always on the bleeding edge version

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🚀 Checking for latest Crush version from NUR..."

# Get current version info
echo "Current system Crush:"
which crush && crush --version || echo "Not installed"

# Check what NUR has
echo ""
echo "Latest NUR Crush available:"
nix eval --json 'github:nix-community/NUR#repos.charmbracelet.crush.version' 2>/dev/null || echo "Checking..."

# Update flake inputs to get latest NUR
echo ""
echo "📦 Updating flake inputs (NUR)..."
cd "$REPO_ROOT"
nix flake update nur

# Build the new configuration
echo ""
echo "🔨 Building NixOS configuration with latest Crush..."
nix build .#nixosConfigurations.evo-x2.config.system.build.toplevel

# Show what's changing
echo ""
echo "📊 Crush version changes:"
echo "  Current: $(crush --version 2>/dev/null || echo 'not installed')"
echo "  New: $(nix eval .#nixosConfigurations.evo-x2.config.system.build.toplevel --apply 'x: let crush = builtins.elemAt (builtins.filter (p: p ? pname && p.pname == "crush") x.config.environment.systemPackages) 0; in crush.version' 2>/dev/null || echo 'check after switch')"

echo ""
echo "✅ Build complete! To activate the new configuration, run:"
echo "  sudo ./result/bin/switch-to-configuration switch"
echo ""
echo "Or use your usual switch command:"
echo "  just switch"
