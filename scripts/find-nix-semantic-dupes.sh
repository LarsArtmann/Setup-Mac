#!/usr/bin/env bash
# Advanced Nix duplication detector using AST-level comparison
# Requires: nix (for nix-instantiate --parse)

set -euo pipefail

echo "=== Advanced Nix Duplication Analysis ==="
echo ""

TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

# Parse all nix files and extract normalized AST
echo "🔍 Parsing Nix files to AST..."
find . -name "*.nix" -type f \
  ! -path "./.git/*" \
  ! -path "./result/*" \
  ! -path "./.direnv/*" \
  2>/dev/null | \
  while read file; do
    # Normalize: remove comments, normalize whitespace
    normalized=$(nix-instantiate --parse "$file" 2>/dev/null | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | tr -s ' \n' ' ')
    if [ -n "$normalized" ]; then
      hash=$(echo "$normalized" | md5 | cut -d' ' -f1)
      echo "$hash:$file" >> "$TMPDIR/hashes.txt"
    fi
  done

# Find duplicate hashes
echo ""
echo "🔍 Finding SEMANTICALLY identical files..."
sort "$TMPDIR/hashes.txt" | \
  awk -F: '{print $1}' | \
  uniq -d | \
  while read dup_hash; do
    echo "   Duplicate AST hash: $dup_hash"
    grep "^$dup_hash:" "$TMPDIR/hashes.txt" | \
      cut -d: -f2 | \
      while read f; do
        echo "     → $f"
      done
    echo ""
  done

# Extract and compare specific sections
echo ""
echo "🔍 Analyzing specific code sections..."

# Find similar package lists
echo "   Package list similarity:"
find . -name "*.nix" -type f ! -path "./.git/*" ! -path "./result/*" 2>/dev/null | \
  while read f; do
    # Extract package list (simplified)
    pkgs=$(grep -oE "pkgs\.[a-zA-Z0-9_-]+" "$f" 2>/dev/null | sort -u | tr '\n' ' ')
    if [ -n "$pkgs" ]; then
      hash=$(echo "$pkgs" | md5 | cut -d' ' -f1)
      echo "$hash:$f:$pkgs" >> "$TMPDIR/packages.txt"
    fi
  done

# Group by similar package lists
if [ -f "$TMPDIR/packages.txt" ]; then
  sort "$TMPDIR/packages.txt" | \
    awk -F: '{print $1": "$2}' | \
    uniq -w32 -d | \
    while read line; do
      hash=$(echo "$line" | cut -d: -f1)
      echo "   Similar packages (hash: $hash):"
      grep "^$hash:" "$TMPDIR/packages.txt" | \
        while read entry; do
          file=$(echo "$entry" | cut -d: -f2)
          echo "     - $file"
        done
      echo ""
    done
fi

# Find repeated strings across files (potential for extraction)
echo ""
echo "🔍 Common string literals (candidates for extraction):"
grep -rhoE '"[^"]{10,}"' --include="*.nix" . 2>/dev/null | \
  grep -v "sha256\|http\|file://" | \
  sort | \
  uniq -c | \
  sort -rn | \
  head -20 | \
  while read count str; do
    if [ "$count" -gt 1 ]; then
      echo "   $count×: $str"
    fi
  done

# Find common function patterns
echo ""
echo "🔍 Common function patterns:"
grep -rhoE "[a-zA-Z_]+ = [a-zA-Z_]+:" --include="*.nix" . 2>/dev/null | \
  sort | \
  uniq -c | \
  sort -rn | \
  head -15 | \
  while read count pattern; do
    if [ "$count" -gt 2 ]; then
      echo "   $count×: $pattern ..."
    fi
  done

echo ""
echo "=== Analysis Complete ==="
echo ""
echo "Recommendations:"
echo "1. Files with identical AST should be deduplicated"
echo "2. Similar package lists could be moved to common modules"
echo "3. Repeated string literals might become options or constants"
echo "4. Common function patterns suggest abstraction opportunities"
