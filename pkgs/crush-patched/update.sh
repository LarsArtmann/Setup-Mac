#!/usr/bin/env nix-shell
#!nix-shell -p bash coreutils curl jq gnused gnugrep nix-prefetch-url -i bash

set -euo pipefail

# Crush-Patched Automated Update Script
# Nix-native automation for version updates

CRUSH_REPO="charmbracelet/crush"
PACKAGE_FILE="pkgs/crush-patched/package.nix"
PATCHES_DIR="pkgs/crush-patched/patches"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
  echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
  echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
  echo -e "${RED}✗${NC} $1"
}

# Get latest release version from GitHub
get_latest_version() {
  log_info "Fetching latest release from GitHub..."
  local latest_version
  latest_version=$(curl -s "https://api.github.com/repos/${CRUSH_REPO}/releases/latest" | jq -r '.tag_name')
  if [[ "$latest_version" == "null" ]] || [[ -z "$latest_version" ]]; then
    log_error "Failed to fetch latest version"
    return 1
  fi
  log_success "Latest version: $latest_version"
  echo "$latest_version"
}

# Fetch source hash for a version
get_source_hash() {
  local version="$1"
  log_info "Fetching source hash for $version..."
  local url="https://github.com/${CRUSH_REPO}/archive/refs/tags/${version}.tar.gz"
  local hash
  hash=$(nix-prefetch-url --type sha256 "$url" 2>&1 | tail -1)
  echo "$hash"
}

# Update version in package.nix
update_version() {
  local version="$1"
  local hash="$2"
  log_info "Updating package.nix with version $version..."

  # Update version
  sed -i.bak "s|version = \"v.*\"|version = \"${version}\"|g" "$PACKAGE_FILE"

  # Update source hash
  sed -i.bak "s|hash = \"sha256:.*\";|hash = \"sha256:${hash}\";|g" "$PACKAGE_FILE"

  # Clean up backup
  rm -f "${PACKAGE_FILE}.bak"

  log_success "Version updated to $version"
}

# Update vendor hash
update_vendor_hash() {
  local hash="$1"
  log_info "Updating vendor hash..."

  # Update vendorHash
  sed -i.bak "s|vendorHash = \"sha256:.*\";|vendorHash = \"${hash}\";|g" "$PACKAGE_FILE"
  rm -f "${PACKAGE_FILE}.bak"

  log_success "Vendor hash updated"
}

# Build package to get vendor hash
build_for_vendor_hash() {
  log_info "Building to compute vendor hash..."

  # Set vendorHash to null to force computation
  sed -i.bak 's|vendorHash = "sha256:.*";|vendorHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";|g' "$PACKAGE_FILE"
  rm -f "${PACKAGE_FILE}.bak"

  # Build and capture error
  local build_output
  if ! build_output=$(nix build .#crush-patched 2>&1); then
    # Extract vendor hash from error message
    local vendor_hash
    vendor_hash=$(echo "$build_output" | grep -oP 'got:\s+\Ksha256-[A-Za-z0-9+/=]+' || true)
    if [[ -n "$vendor_hash" ]]; then
      log_success "Vendor hash computed: $vendor_hash"
      echo "$vendor_hash"
      return 0
    else
      log_error "Failed to extract vendor hash from build output"
      echo "$build_output"
      return 1
    fi
  else
    log_warning "Build succeeded (vendor hash already correct)"
    return 0
  fi
}

# Test build
test_build() {
  log_info "Testing build..."
  if nix build .#crush-patched 2>&1 | tee /tmp/crush-build.log | grep -q "error"; then
    log_error "Build failed. Check /tmp/crush-build.log for details."
    return 1
  else
    log_success "Build successful!"
  fi
}

# Main update workflow
main() {
  local target_version="${1:-}"

  # If no version specified, get latest
  if [[ -z "$target_version" ]]; then
    target_version=$(get_latest_version)
  else
    # Ensure version starts with 'v'
    if [[ ! "$target_version" =~ ^v[0-9] ]]; then
      target_version="v${target_version}"
    fi
  fi

  log_info "Target version: $target_version"

  # Get current version
  local current_version
  current_version=$(grep 'version = "v' "$PACKAGE_FILE" | head -1 | sed 's/.*"\(v[^"]*\)".*/\1/')
  log_info "Current version: $current_version"

  # Check if update needed
  if [[ "$target_version" == "$current_version" ]]; then
    log_success "Already up to date at $target_version"
    exit 0
  fi

  # Get source hash
  local source_hash
  source_hash=$(get_source_hash "$target_version")

  # Update version in package.nix
  update_version "$target_version" "$source_hash"

  # Build to get vendor hash
  log_info "Building package to compute vendor hash..."
  log_warning "This may take several minutes..."
  local vendor_hash
  vendor_hash=$(build_for_vendor_hash)

  # Update vendor hash
  update_vendor_hash "$vendor_hash"

  # Test build
  test_build

  log_success "Update complete!"
  log_info "Next steps:"
  echo "  1. Review changes: git diff pkgs/crush-patched/package.nix"
  echo "  2. Build and test: nix build .#crush-patched"
  echo "  3. Apply changes: just switch"
}

# Run main function
main "$@"
