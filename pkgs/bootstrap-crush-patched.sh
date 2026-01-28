#!/usr/bin/env bash
# Bootstrap script for crush-patched.nix
# This script fetches PR patches and computes their hashes for nix

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NIX_FILE="$SCRIPT_DIR/crush-patched.nix"
PATCHES_DIR="$SCRIPT_DIR/patches"

# PR numbers to include
PRs=(1854 1617 1589)

echo "=== Crush Patched Bootstrap ==="
echo ""
echo "Fetching ${#PRs[@]} PRs..."

# Create patches directory
mkdir -p "$PATCHES_DIR"

# Fetch each PR patch and compute hash
patch_hashes=()
src_hash=""
for pr in "${PRs[@]}"; do
    patch_file="$PATCHES_DIR/pr-${pr}.patch"
    echo "  PR #$pr..."
    
    # Fetch patch using gh (more reliable than curl)
    if ! gh pr view "$pr" --json title --jq '.title' >/dev/null 2>&1; then
        echo "    ⚠️  PR #$pr not found or not accessible"
        continue
    fi
    
    gh pr diff "$pr" --patch > "$patch_file" 2>/dev/null || \
    curl -s "https://github.com/charmbracelet/crush/pull/${pr}.patch" > "$patch_file"
    
    if [ -f "$patch_file" ] && [ -s "$patch_file" ]; then
        # Compute hash for nix
        hash=$(nix hash file "$patch_file" --sri)
        patch_hashes+=("$hash")
        echo "    ✓ Hash: $hash"
    else
        echo "    ✗ Failed to fetch"
    fi
done

# Fetch source hash
echo ""
echo "Fetching crush source hash..."
src_url="https://github.com/charmbracelet/crush/archive/main.tar.gz"
src_archive="/tmp/crush-main.tar.gz"
tmp_dir=$(mktemp -d)

curl -sL "$src_url" -o "$src_archive"
tar -xzf "$src_archive" -C "$tmp_dir"
src_hash=$(nix hash path "$tmp_dir/crush-main" --sri)

echo "  ✓ Source hash: $src_hash"

# Generate patch array string
patch_array=$(printf 'fetchpatch {\n      url = "https://github.com/charmbracelet/crush/pull/%s.patch";\n      sha256 = "%s";\n      stripLength = 1;\n    }' \
    "$(printf '%s\n' "${PRs[@]}")" \
    "$(printf '%s\n' "${patch_hashes[@]}")" | head -1)

# Update nix file
echo ""
echo "Updating $NIX_FILE..."

cat > "$NIX_FILE" << NIXEOF
{
  lib,
  buildGoModule,
  fetchFromGitHub,
  fetchpatch,
  stdenv,
}:
let
  # PR numbers to include
  prNumbers = [$(printf '%s ' "${PRs[@]}")];

  # Fetch patches from GitHub PRs
  patches = lib.flatten (map (prNum: [
    fetchpatch {
      url = "https://github.com/charmbracelet/crush/pull/\${toString prNum}.patch";
      sha256 = lib.fakeHash; # TODO: Update with real hash
      stripLength = 1;
    }
  ]) prNumbers);
in
buildGoModule rec {
  pname = "crush-patched";

  src = fetchFromGitHub {
    owner = "charmbracelet";
    repo = "crush";
    rev = "main";
    sha256 = "$src_hash";
    fetchSubmodules = true;
  };

  inherit patches;

  vendorHash = lib.fakeHash; # Will be auto-detected on first build
  
  meta = with lib; {
    description = "Crush with Lars' PR patches applied";
    homepage = "https://github.com/charmbracelet/crush";
    license = licenses.mit;
    platforms = platforms.all;
  };
}
NIXEOF

echo "✓ Updated nix file"
echo ""
echo "Next steps:"
echo "  1. Edit $NIX_FILE and replace lib.fakeHash with real hashes"
echo "  2. Run: nix build .#crush-patched"
echo ""
echo "To add more PRs, add them to the PRs array at the top of this script."