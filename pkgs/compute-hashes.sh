#!/usr/bin/env bash
# Compute all hashes needed for crush-patched.nix

set -euo pipefail

echo "=== Computing hashes for crush-patched ==="
echo ""

# Get source hash
echo "1. Fetching and hashing source tarball..."
nix-prefetch-url --type sha256 https://github.com/charmbracelet/crush/archive/main.tar.gz 2>/dev/null

# Get each PR patch hash
echo ""
echo "2. Fetching and hashing PR patches..."
for pr in 1854 1617 1589; do
    echo "   PR #$pr..."
    gh pr diff "$pr" --patch > "/tmp/pr-${pr}.patch" 2>/dev/null
    nix hash file "/tmp/pr-${pr}.patch" --sri
done

echo ""
echo "3. To get vendorHash, run:"
echo "   cd pkgs && nix-build -A crush-patched 2>&1 | grep 'got:'"
echo ""
echo "Or use the sandbox method in the nix file."