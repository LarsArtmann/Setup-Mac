#!/usr/bin/env bash
# Find duplicate/similar Nix code patterns
# Usage: ./scripts/find-nix-duplicates.sh

set -euo pipefail

echo "=== Nix Code Duplication Finder ==="
echo ""

# 1. Find files with identical content (exact duplicates)
echo "🔍 1. Finding EXACT duplicate files..."
find . -name "*.nix" -type f ! -path "./.git/*" ! -path "./result/*" -exec md5 -r {} + 2>/dev/null | \
  sort | \
  uniq -w32 -d | \
  while read hash file; do
    echo "   Duplicate hash: $hash"
    find . -name "*.nix" -type f ! -path "./.git/*" ! -path "./result/*" -exec md5 -r {} + 2>/dev/null | \
      grep "^$hash" | \
      awk '{print "     - "$2}'
    echo ""
  done

echo ""
echo "🔍 2. Finding SIMILAR file names..."
# Group files by similar names (excluding path)
find . -name "*.nix" -type f ! -path "./.git/*" ! -path "./result/*" | \
  sed 's|.*/||' | \
  sort | \
  uniq -c | \
  sort -rn | \
  awk '$1 > 1 {print "   "$1" files named: "$2}'

echo ""
echo "🔍 3. Finding duplicate attribute patterns..."
# Find common attribute patterns that might be duplicated
echo "   Common patterns (might indicate duplication):"
grep -rh "^  [a-z].*=.*{*" --include="*.nix" . 2>/dev/null | \
  sed 's/^[[:space:]]*//' | \
  sort | \
  uniq -c | \
  sort -rn | \
  head -20 | \
  awk '{print "   "$0}'

echo ""
echo "🔍 4. Finding duplicate let bindings..."
# Find common let variable names
grep -rh "let$" --include="*.nix" . 2>/dev/null | \
  head -20 | \
  awk '{print "   "NR": "$0}'

echo ""
echo "🔍 5. Cross-platform comparison (Darwin vs NixOS)..."
echo "   Files that exist in BOTH platforms/:"
darwin_files=$(find ./platforms/darwin -name "*.nix" -type f 2>/dev/null | sed 's|.*/||' | sort)
nixos_files=$(find ./platforms/nixos -name "*.nix" -type f 2>/dev/null | sed 's|.*/||' | sort)

comm -12 <(echo "$darwin_files") <(echo "$nixos_files") | \
  while read file; do
    echo "     - $file"
    echo "       Darwin: $(find ./platforms/darwin -name "$file" 2>/dev/null | head -1)"
    echo "       NixOS:  $(find ./platforms/nixos -name "$file" 2>/dev/null | head -1)"
    echo ""
  done

echo ""
echo "🔍 6. Checking for duplicate package lists..."
# Find files with similar package lists
for f1 in $(find . -name "*.nix" -type f ! -path "./.git/*" ! -path "./result/*"); do
  for f2 in $(find . -name "*.nix" -type f ! -path "./.git/*" ! -path "./result/*"); do
    if [ "$f1" != "$f2" ] && [ "$f1" \< "$f2" ]; then
      # Extract package names (simplified)
      pkgs1=$(grep -oE "pkgs\.[a-zA-Z0-9_-]+" "$f1" 2>/dev/null | sort -u | md5)
      pkgs2=$(grep -oE "pkgs\.[a-zA-Z0-9_-]+" "$f2" 2>/dev/null | sort -u | md5)
      if [ "$pkgs1" = "$pkgs2" ]; then
        echo "   Similar package lists:"
        echo "     $f1"
        echo "     $f2"
        echo ""
      fi
    fi
  done
done 2>/dev/null | head -50

echo ""
echo "=== Analysis Complete ==="
