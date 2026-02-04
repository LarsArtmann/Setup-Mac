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

# Step 3: Extract and update vendorHash
echo "Step 3/5: Extracting vendorHash..."
echo ""

# Extract hash using Python for reliable parsing
VENDOR_HASH=$(python3 << 'PYTHON_EOF'
import sys
# Read build log and find hash
with open('/tmp/crush-patched-build.log') as f:
    for line in f:
        if 'uo9Ve' in line:  # Look for our known hash pattern
            # Extract hash part (after colon, strip prefix)
            hash_part = line.split(':')[-1].strip()
            # Remove 'sha256:' prefix if present
            hash_part = hash_part.replace('sha256:', '').strip()
            # Remove trailing whitespace/newlines
            hash_part = hash_part.rstrip('\n')
            print(hash_part)
            break
PYTHON_EOF
)

if [[ -z "$VENDOR_HASH" ]]; then
    echo "❌ Could not extract vendorHash from build log"
    echo "   Check $BUILD_LOG for details"
    echo ""
    echo "Last 15 lines of build log:"
    tail -15 "$BUILD_LOG" | sed 's/^/   /'
    exit 1
fi

# Remove trailing '=' if present (base32 hash includes it)
VENDOR_HASH="${VENDOR_HASH%=}"

echo "Extracted vendorHash: $VENDOR_HASH"
echo "Hash length: ${#VENDOR_HASH}"

# Validate hash format (52 base32 chars or 64 hex)
if [[ ${#VENDOR_HASH} -eq 51 ]]; then
    # Base32 hash, append '=' if needed
    if [[ "$VENDOR_HASH" != *"=" ]]; then
        VENDOR_HASH="${VENDOR_HASH}="
    fi
elif [[ ${#VENDOR_HASH} -eq 64 ]]; then
    # SHA256 hash (valid)
    :
else
    echo "⚠️ Hash has unusual length: ${#VENDOR_HASH} (expected 51 or 64)"
fi

echo ""

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
