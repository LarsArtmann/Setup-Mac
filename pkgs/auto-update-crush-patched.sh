#!/usr/bin/env bash
# Full automatic update for crush-patched: update version, build, fix vendorHash, rebuild

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NIX_FILE="$SCRIPT_DIR/crush-patched.nix"
BUILD_LOG="/tmp/crush-patched-build.log"

echo "=== Full Automatic Crush-Patched Update ==="
echo ""

# Step 1: Update version
echo "Step 1/5: Updating version..."
bash "$SCRIPT_DIR/update-crush-patched.sh"
echo ""

# Step 2: Build with fakeHash to get real vendorHash
echo "Step 2/5: Building with fake vendorHash..."
echo "This may fail but we'll extract the hash..."
if nix build .#crush-patched 2>&1 | tee "$BUILD_LOG"; then
    echo "✅ Build succeeded on first try!"
else
    echo "⚠️  Build failed (expected for fake vendorHash)"
fi

# Step 3: Extract and update vendorHash
echo ""
echo "Step 3/5: Extracting vendorHash..."
VENDOR_HASH=$(grep -oP 'got: *\K[^\s]+' "$BUILD_LOG" | head -1 || true)

if [[ -z "$VENDOR_HASH" ]]; then
    echo "❌ Could not extract vendorHash from build log"
    echo "   Check $BUILD_LOG for details"
    exit 1
fi

echo "Extracted vendorHash: $VENDOR_HASH"

# Update vendorHash in nix file
sed -i.bak "s|vendorHash = .*|vendorHash = \"$VENDOR_HASH\";|" "$NIX_FILE"
rm "${NIX_FILE}.bak"
echo "✅ Updated vendorHash in $NIX_FILE"

# Step 4: Rebuild with correct hash
echo ""
echo "Step 4/5: Rebuilding with correct vendorHash..."
if ! nix build .#crush-patched; then
    echo "❌ Build failed with correct vendorHash"
    echo "   Possible issues:"
    echo "   - Patches don't apply to new version"
    echo "   - Source hash incorrect"
    echo ""
    echo "Check build output above and:"
    echo "   1. Update/remove conflicting patches in $NIX_FILE"
    echo "   2. Run this script again"
    exit 1
fi

echo "✅ Build succeeded!"

# Step 5: Verify binary
echo ""
echo "Step 5/5: Verifying binary..."
if ./result/bin/crush --version; then
    echo ""
    echo "🎉 Full update successful!"
    echo ""
    echo "Binary: $(readlink -f ./result/bin/crush)"
    echo "Version: $(./result/bin/crush --version)"
    echo ""
    echo "To install system-wide, run:"
    echo "  just switch"
    echo ""
    echo "Patches applied:"
    grep -E "PR #|pull/.*patch" "$NIX_FILE" | sed 's/^/  /'
else
    echo "❌ Binary verification failed"
    exit 1
fi
