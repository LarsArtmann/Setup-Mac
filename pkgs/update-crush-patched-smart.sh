#!/usr/bin/env bash
# Smart Crush-Patched Updater
# Automatically detects merged PRs and skips them based on version

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NIX_FILE="$SCRIPT_DIR/crush-patched.nix"

echo "=== Smart Crush-Patched Update ==="
echo ""

# 1. Get latest Crush release
echo "📡 Fetching latest Crush release..."
LATEST=$(curl -s https://api.github.com/repos/charmbracelet/crush/releases/latest | python3 -c "import sys, json; data = json.load(sys.stdin); print(data.get('tag_name', ''))" 2>/dev/null || echo "")

if [[ -z "$LATEST" ]]; then
  echo -e "${RED}❌ Failed to fetch latest release${NC}"
  exit 1
fi

echo -e "${GREEN}Latest version: $LATEST${NC}"

# 2. Get current version
CURRENT=$(grep 'version = ' "$NIX_FILE" 2>/dev/null | cut -d'"' -f2 || echo "unknown")
echo "Current version: $CURRENT"

if [[ "$LATEST" == "$CURRENT" ]]; then
  echo -e "${GREEN}✅ Already up to date!${NC}"
  exit 0
fi

echo -e "${YELLOW}⬆ Updating from $CURRENT to $LATEST...${NC}"
echo ""

# 3. Get release info
echo "📊 Fetching release information..."
RELEASE_INFO=$(curl -s "https://api.github.com/repos/charmbracelet/crush/releases/tags/${LATEST}")
RELEASE_DATE=$(echo "$RELEASE_INFO" | python3 -c "import sys, json; data = json.load(sys.stdin); print(data.get('published_at', ''))" 2>/dev/null || echo "")

if [[ -z "$RELEASE_DATE" ]]; then
  echo -e "${RED}❌ Failed to fetch release date${NC}"
  exit 1
fi

echo "Release date: $RELEASE_DATE"
echo ""

# 4. Define patches to check
# Format: "PR_NUM:SHA256:MERGE_COMMIT_SHA"
PATCHES=(
  "1854:fWWY+3/ycyvGtRsPxKIYVOt/CdQfmMAcAa8H6gONAFA=:416f5a0131"
  "1617:yFprXfDfWxeWrsmhGmXvxrfjD0GK/DVDi6mugdrM/sg=:133cb6f9b03d769e5328e5124506e1c6e321c075"
  "2068:sha256:5f30a28e50e0d9a56a82046035d3686d9f67851a8f4519993e570053097e1a4c:552fa171bc6c0ed03b0121d6e98adb11697e8479"
  "2019:sha256:c68f4835de3bdb0ec75cf79033b3499bc9ac495ba8a96e8a9263072f020b4c32:e8009f2fff504bdbef39484f9918cb7282f39637"
  "2070:sha256:ede9e0ff7b642db0b07295a1bc9539ee53acc087343226167ca902c4512fd50d:d0a7ac89b5e3fcb0316ca421ca400fc1dedd1939"
)

# 5. Check each patch
echo "=== Checking patch PRs ==="
ACTIVE_PATCHES=()
SKIPPED_PATCHES=()

for patch_info in "${PATCHES[@]}"; do
  IFS=':' read -r PR_NUM SHA256 MERGE_SHA <<< "$patch_info"
  
  echo "Checking PR #$PR_NUM..."
  
  # Get PR info from GitHub API
  PR_INFO=$(curl -s "https://api.github.com/repos/charmbracelet/crush/pulls/${PR_NUM}")
  STATE=$(echo "$PR_INFO" | python3 -c "import sys, json; data = json.load(sys.stdin); print(data.get('state', ''))" 2>/dev/null || echo "")
  MERGED_AT=$(echo "$PR_INFO" | python3 -c "import sys, json; data = json.load(sys.stdin); print(data.get('merged_at', ''))" 2>/dev/null || echo "")
  
  # Check if PR is in the release
  # If PR is merged before release date → it's in the tarball
  if [ "$STATE" = "open" ]; then
    echo -e "  ${YELLOW}✗ OPEN${NC} → Will apply patch"
    ACTIVE_PATCHES+=("$PR_NUM:$SHA256")
  elif [ -n "$MERGED_AT" ] && python3 -c "from datetime import datetime; merged = datetime.strptime('$MERGED_AT', '%Y-%m-%dT%H:%M:%SZ'); release = datetime.strptime('$RELEASE_DATE', '%Y-%m-%dT%H:%M:%SZ'); print(1 if merged < release else 0)" 2>/dev/null; then
    echo -e "  ${GREEN}✓ MERGED${NC} (${MERGED_AT:0:10}) < RELEASE (${RELEASE_DATE:0:10}) → ${YELLOW}Skip patch${NC}"
    SKIPPED_PATCHES+=("#$PR_NUM")
  else
    # PR merged after release or not merged → need patch
    echo -e "  ${YELLOW}✗ MERGED/OPEN${NC} (${MERGED_AT:0:10}) > RELEASE (${RELEASE_DATE:0:10}) → Will apply patch"
    ACTIVE_PATCHES+=("$PR_NUM:$SHA256")
  fi
done

echo ""
echo "=== Summary ==="
echo -e "${GREEN}✅ Patches to apply: ${#ACTIVE_PATCHES[@]}${NC}"
echo -e "${YELLOW}⏭ Patches skipped (already in release): ${#SKIPPED_PATCHES[@]}${NC}"
echo ""

# 6. Prefetch source hash
echo "📦 Prefetching source hash..."
SOURCE_URL="https://github.com/charmbracelet/crush/archive/refs/tags/${LATEST}.tar.gz"
SOURCE_HASH=$(nix-prefetch-url --type sha256 "$SOURCE_URL" 2>/dev/null | head -1)

if [[ -z "$SOURCE_HASH" ]]; then
  echo -e "${RED}❌ Failed to prefetch source hash${NC}"
  exit 1
fi

echo "Source hash: $SOURCE_HASH"
echo ""

# 7. Generate updated Nix file
echo "📝 Generating $NIX_FILE..."

cat > "$NIX_FILE" <<'EOF'
{ pkgs }:
pkgs.buildGoModule rec {
  pname = "crush-patched";
  version = "${LATEST}";

  src = pkgs.fetchurl {
    url = "${SOURCE_URL}";
    sha256 = "${SOURCE_HASH}";
  };

  patches = [
EOF

# Add active patches
for patch_info in "${ACTIVE_PATCHES[@]}"; do
  IFS=':' read -r PR_NUM SHA256 <<< "$patch_info"
  cat >> "$NIX_FILE" <<PATCHEOF
    (pkgs.fetchurl {
      url = "https://github.com/charmbracelet/crush/pull/${PR_NUM}.patch";
      sha256 = "${SHA256}";
    })
PATCHEOF
done

cat >> "$NIX_FILE" <<'EOF'
  ];

  env = {
    GOEXPERIMENT = "greenteagc";
    CGO_ENABLED = "0";
  };

  ldflags = [
    "-s"
    "-w"
    "-X=github.com/charmbracelet/crush/internal/version.Version=${version}"
  ];

  doCheck = false;

  vendorHash = pkgs.lib.fakeHash;

  meta = with pkgs.lib; {
    description = "Crush with smart auto-applied patches";
    homepage = "https://github.com/charmbracelet/crush";
    license = licenses.mit;
    platforms = platforms.all;
  };
}
EOF

echo -e "${GREEN}✅ Generated $NIX_FILE${NC}"
echo ""
echo "📋 Changes:"
echo "  Version: $CURRENT → $LATEST"
echo "  Patches applied: ${#ACTIVE_PATCHES[@]}"
echo "  Patches skipped: ${#SKIPPED_PATCHES[@]}"
echo ""
echo "Next steps:"
echo "  1. Review: git diff $NIX_FILE"
echo "  2. Test: nix build .#crush-patched"
echo "  3. Update: nix flake update"
echo "  4. Apply: just switch"
