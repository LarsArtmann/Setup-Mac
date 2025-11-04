#!/usr/bin/env bash
# list-wrappers.sh - List available wrapped packages

echo "📦 Available wrapped packages:"
find dotfiles/nix/wrappers -name "*.nix" -type f | grep -v default.nix | sort | while read wrapper; do
    echo "  - $(basename "$wrapper" .nix)"
done
echo ""

echo "🔧 Wrapper system status:"
if nix eval --impure --raw --expr 'let pkgs = import <nixpkgs> {}; wrappers = import ./dotfiles/nix/wrappers/default.nix { config = {}; lib = pkgs.lib; pkgs = pkgs; }; in "available"' 2>/dev/null; then
    echo "  ✅ Wrapper system enabled"
else
    echo "  ❌ Wrapper system not available"
fi