#!/usr/bin/env bash
# Find duplicate/similar Nix code patterns
# Usage: ./scripts/find-nix-duplicates.sh [--semantic]
#   --semantic: Use AST-level comparison instead of content hashing

set -euo pipefail

SEMANTIC=false
if [[ ${1:-} == "--semantic" ]]; then
  SEMANTIC=true
fi

echo "=== Nix Code Duplication Finder ==="
if [[ $SEMANTIC == "true" ]]; then
  echo "Mode: SEMANTIC (AST-level comparison)"
else
  echo "Mode: CONTENT (hash-based comparison)"
fi
echo ""

if [[ $SEMANTIC == "true" ]]; then
  # AST-level semantic comparison
  TMPDIR=$(mktemp -d)
  trap "rm -rf $TMPDIR" EXIT

  echo "🔍 Parsing Nix files to AST..."
  find . -name "*.nix" -type f \
    ! -path "./.git/*" \
    ! -path "./result/*" \
    ! -path "./.direnv/*" \
    2>/dev/null |
    while read file; do
      normalized=$(nix-instantiate --parse "$file" 2>/dev/null | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | tr -s ' \n' ' ')
      if [ -n "$normalized" ]; then
        hash=$(echo "$normalized" | md5 | cut -d' ' -f1)
        echo "$hash:$file" >>"$TMPDIR/hashes.txt"
      fi
    done

  echo ""
  echo "🔍 Finding SEMANTICALLY identical files..."
  sort "$TMPDIR/hashes.txt" |
    awk -F: '{print $1}' |
    uniq -d |
    while read dup_hash; do
      echo "   Duplicate AST hash: $dup_hash"
      grep "^$dup_hash:" "$TMPDIR/hashes.txt" |
        cut -d: -f2 |
        while read f; do
          echo "     → $f"
        done
      echo ""
    done

  echo "🔍 Analyzing specific code sections..."
  echo "   Package list similarity:"
  find . -name "*.nix" -type f ! -path "./.git/*" ! -path "./result/*" 2>/dev/null |
    while read f; do
      pkgs=$(grep -oE "pkgs\.[a-zA-Z0-9_-]+" "$f" 2>/dev/null | sort -u | tr '\n' ' ')
      if [ -n "$pkgs" ]; then
        hash=$(echo "$pkgs" | md5 | cut -d' ' -f1)
        echo "$hash:$f:$pkgs" >>"$TMPDIR/packages.txt"
      fi
    done

  if [ -f "$TMPDIR/packages.txt" ]; then
    sort "$TMPDIR/packages.txt" |
      awk -F: '{print $1": "$2}' |
      uniq -w32 -d |
      while read line; do
        hash=$(echo "$line" | cut -d: -f1)
        echo "   Similar packages (hash: $hash):"
        grep "^$hash:" "$TMPDIR/packages.txt" |
          while read entry; do
            file=$(echo "$entry" | cut -d: -f2)
            echo "     - $file"
          done
        echo ""
      done
  fi

  echo "🔍 Common string literals (candidates for extraction):"
  grep -rhoE '"[^"]{10,}"' --include="*.nix" . 2>/dev/null |
    grep -v "sha256\|http\|file://" |
    sort |
    uniq -c |
    sort -rn |
    head -20 |
    while read count str; do
      if [ "$count" -gt 1 ]; then
        echo "   $count×: $str"
      fi
    done

  echo ""
  echo "🔍 Common function patterns:"
  grep -rhoE "[a-zA-Z_]+ = [a-zA-Z_]+:" --include="*.nix" . 2>/dev/null |
    sort |
    uniq -c |
    sort -rn |
    head -15 |
    while read count pattern; do
      if [ "$count" -gt 2 ]; then
        echo "   $count×: $pattern ..."
      fi
    done

  echo ""
  echo "Recommendations:"
  echo "1. Files with identical AST should be deduplicated"
  echo "2. Similar package lists could be moved to common modules"
  echo "3. Repeated string literals might become options or constants"
  echo "4. Common function patterns suggest abstraction opportunities"

else
  # Original content-based comparison
  echo "🔍 1. Finding EXACT duplicate files..."
  find . -name "*.nix" -type f ! -path "./.git/*" ! -path "./result/*" -exec md5 -r {} + 2>/dev/null |
    sort |
    uniq -w32 -d |
    while read hash file; do
      echo "   Duplicate hash: $hash"
      find . -name "*.nix" -type f ! -path "./.git/*" ! -path "./result/*" -exec md5 -r {} + 2>/dev/null |
        grep "^$hash" |
        awk '{print "     - "$2}'
      echo ""
    done

  echo ""
  echo "🔍 2. Finding SIMILAR file names..."
  find . -name "*.nix" -type f ! -path "./.git/*" ! -path "./result/*" |
    sed 's|.*/||' |
    sort |
    uniq -c |
    sort -rn |
    awk '$1 > 1 {print "   "$1" files named: "$2}'

  echo ""
  echo "🔍 3. Finding duplicate attribute patterns..."
  echo "   Common patterns (might indicate duplication):"
  grep -rh "^  [a-z].*=.*{*" --include="*.nix" . 2>/dev/null |
    sed 's/^[[:space:]]*//' |
    sort |
    uniq -c |
    sort -rn |
    head -20 |
    awk '{print "   "$0}'

  echo ""
  echo "🔍 4. Finding duplicate let bindings..."
  grep -rh "let$" --include="*.nix" . 2>/dev/null |
    head -20 |
    awk '{print "   "NR": "$0}'

  echo ""
  echo "🔍 5. Cross-platform comparison (Darwin vs NixOS)..."
  echo "   Files that exist in BOTH platforms/:"
  darwin_files=$(find ./platforms/darwin -name "*.nix" -type f 2>/dev/null | sed 's|.*/||' | sort)
  nixos_files=$(find ./platforms/nixos -name "*.nix" -type f 2>/dev/null | sed 's|.*/||' | sort)

  comm -12 <(echo "$darwin_files") <(echo "$nixos_files") |
    while read file; do
      echo "     - $file"
      echo "       Darwin: $(find ./platforms/darwin -name "$file" 2>/dev/null | head -1)"
      echo "       NixOS:  $(find ./platforms/nixos -name "$file" 2>/dev/null | head -1)"
      echo ""
    done

  echo ""
  echo "🔍 6. Checking for duplicate package lists..."
  for f1 in $(find . -name "*.nix" -type f ! -path "./.git/*" ! -path "./result/*"); do
    for f2 in $(find . -name "*.nix" -type f ! -path "./.git/*" ! -path "./result/*"); do
      if [ "$f1" != "$f2" ] && [ "$f1" \< "$f2" ]; then
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
fi

echo ""
echo "=== Analysis Complete ==="
