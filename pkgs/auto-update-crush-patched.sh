#!/usr/bin/env bash
# Full automatic update for crush-patched: update version, build, fix vendorHash, rebuild

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NIX_FILE="$SCRIPT_DIR/crush-patched.nix"
BUILD_LOG="/tmp/crush-patched-build.log"
EXTRACTOR_SCRIPT="$SCRIPT_DIR/extract-vendorhash.py"

echo "=== Full Automatic Crush-Patched Update ==="
echo ""

# Step 1: Update version
echo "Step 1/5: Updating version..."
echo ""
bash "$SCRIPT_DIR/update-crush-patched.sh"
echo ""

# Step 2: Build with fakeHash to get real vendorHash
echo "Step 2/5: Building with fake vendorHash..."
echo "This may fail but we'll extract the hash..."
echo ""

# Clear build log
rm -f "$BUILD_LOG"

# Build and capture output
if nix build .#crush-patched 2>&1 | tee "$BUILD_LOG"; then
    echo "✅ Build succeeded on first try!"
    SUCCESS=1
else
    echo "⚠️  Build failed (expected for fake vendorHash)"
    SUCCESS=0
fi

echo ""

# Step 3: Extract and update vendorHash using Python extractor
echo "Step 3/5: Extracting vendorHash..."
echo ""

if [[ ! -f "$EXTRACTOR_SCRIPT" ]]; then
    echo "❌ Extractor script not found: $EXTRACTOR_SCRIPT"
    exit 1
fi

# Use Python script for reliable hash extraction
VENDOR_HASH=$("$EXTRACTOR_SCRIPT" "$BUILD_LOG" 2>&1)

if [[ -z "$VENDOR_HASH" ]]; then
    echo "❌ Could not extract vendorHash from build log"
    echo "   Check $BUILD_LOG for details"
    echo ""
    echo "Last 15 lines of build log:"
    tail -15 "$BUILD_LOG" | sed 's/^/   /'
    exit 1
fi

echo "Extracted vendorHash: $VENDOR_HASH"
echo "Hash length: ${#VENDOR_HASH}"
echo ""

# Validate hash format (52 base32 chars with = or 64 hex)
if [[ ${#VENDOR_HASH} -eq 51 ]] || [[ ${#VENDOR_HASH} -eq 52 ]] || [[ ${#VENDOR_HASH} -eq 64 ]]; then
    echo "✅ Hash format is valid"
else
    echo "⚠️ Hash has unusual length: ${#VENDOR_HASH} (expected 51, 52, or 64)"
fi

# Update vendorHash in nix file
echo "Updating vendorHash in $NIX_FILE..."
sed -i.bak "s|vendorHash = .*|vendorHash = \"$VENDOR_HASH\";|" "$NIX_FILE"
rm "${NIX_FILE}.bak"
echo "✅ Updated vendorHash in $NIX_FILE"
echo ""

# Step 4: Rebuild with correct hash
echo "Step 4/5: Rebuilding with correct vendorHash..."
echo ""
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
echo ""

# Step 5: Verify binary
echo "Step 5/5: Verifying binary..."
echo ""

if ./result/bin/crush --version > /dev/null 2>&1; then
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
