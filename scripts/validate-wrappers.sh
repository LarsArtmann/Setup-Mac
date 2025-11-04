#!/usr/bin/env bash
# validate-wrappers.sh - Validate wrapper syntax

echo "🔍 Validating wrapper syntax..."
ERRORS=0

for wrapper in dotfiles/nix/wrappers/applications/*.nix dotfiles/nix/wrappers/shell/*.nix dotfiles/nix/wrappers/core/*.nix; do
    if [ -f "$wrapper" ]; then
        echo "Checking $wrapper..."
        if ! nix-instantiate --parse "$wrapper" >/dev/null 2>&1; then
            echo "  ❌ Syntax error in $wrapper"
            ERRORS=$((ERRORS + 1))
        else
            echo "  ✅ Syntax OK"
        fi
    fi
done

if [ $ERRORS -eq 0 ]; then
    echo "✅ All wrapper syntax is valid"
else
    echo "❌ $ERRORS wrappers have syntax errors"
    exit 1
fi