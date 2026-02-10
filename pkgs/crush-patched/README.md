# Crush-Patched

Hybrid Nix implementation combining **callPackage** for composability with **fetchpatch** for reliability.

## Quick Start

```bash
# Build package
nix build .#crush-patched

# Test version
./result/bin/crush --version

# Apply to system
just switch
```

## Architecture

### Hybrid Approach

This package uses the **best of both worlds**:

**callPackage Pattern (Composability):**
```nix
# flake.nix
packages = {
  crush-patched = pkgs.callPackage ./pkgs/crush-patched/package.nix { };
};
```
- Standard nixpkgs pattern
- Allows easy overrides
- Better composability
- Clean module structure

**fetchpatch (Reliability):**
```nix
# package.nix
patches = [
  (fetchpatch {
    url = "https://github.com/charmbracelet/crush/commit/xxx.patch";
    hash = "sha256:...";
  })
];
```
- No local file corruption issues
- Immutable URLs with verified hashes
- Reproduducible builds
- No patch directory maintenance

**Benefits:**
- ✅ Clean `callPackage` pattern for composability
- ✅ `fetchpatch` for reliable patch application
- ✅ No local patch files to maintain or corrupt
- ✅ Immutable GitHub URLs with SHA256 hashes
- ✅ Standard nixpkgs patterns
- ✅ Easy to add/remove patches

## Update to New Version

### Automated Update (Semi-Automatic)

```bash
cd pkgs/crush-patched
./update.sh v0.42.0
```

The update script automates:
- Fetching latest version from GitHub API
- Computing source hash with `nix-prefetch-url`
- Building to compute vendor hash
- Testing the final build

**Note:** The script updates version and hashes, but patches use immutable URLs and remain unchanged.

### Manual Update

```bash
# 1. Update version in package.nix
#    version = "v0.42.0"

# 2. Get source hash
nix-prefetch-url --type sha256 \
  https://github.com/charmbracelet/crush/archive/refs/tags/v0.42.0.tar.gz

# 3. Set vendorHash to fake value
#    vendorHash = "sha256-0000000000000000000000000000000000000000000000000000000000000000";

# 4. Build and copy correct hash
nix build .#crush-patched
# Output: got:    sha256-<correct-hash>

# 5. Update vendorHash with correct hash
#    vendorHash = "sha256-<correct-hash>";

# 6. Rebuild and test
nix build .#crush-patched
```

## Applied Patches

### 1. PR #2181 - SQLite Busy Timeout Fix (Fixes #2129)
- **Issue:** SQLite deadlocks under high concurrency with 5s timeout
- **Fix:** Increase timeout from 5s to 30s, consolidate pragma configuration
- **Impact:** Multi-instance usage no longer causes database lockups
- **Commit:** 2b12f560f6a350393a27347a7f28a0ca8de483b7
- **Files:** internal/db/connect.go, connect_modernc.go, connect_ncruces.go

### 2. PR #2180 - LSP Files Outside CWD Fix (Fixes #1401)
- **Issue:** LSP client can't handle files outside working directory
- **Fix:** Make LSP client receive working directory explicitly
- **Impact:** Improved IDE/editor integration reliability
- **Commit:** 5efab4c40a675297122f6eef18da53585b7150ba
- **Files:** internal/lsp/client.go, client_test.go, manager.go

### 3. PR #2161 - Regex Cache Memory Leak Fix
- **Issue:** Regex caches grow unbounded across sessions
- **Fix:** Clear regex caches at session boundaries
- **Impact:** Prevents memory leaks during long sessions
- **Commit:** 2d5a911afd50a54aed5002ce0183263b49b712a7
- **Files:** internal/agent/tools/grep.go, internal/ui/model/ui.go

## Adding New Patches

```bash
# 1. Find the patch commit URL on GitHub
#    Example: https://github.com/charmbracelet/crush/commit/abc123.patch

# 2. Get the SHA256 hash
nix-prefetch-url --type sha256 \
  https://github.com/charmbracelet/crush/commit/abc123.patch

# 3. Add to package.nix patches list
#    patches = [
#      (fetchpatch {
#        url = "https://github.com/charmbracelet/crush/commit/abc123.patch";
#        hash = "sha256:<computed-hash>";
#      })
#      # ... existing patches
#    ];

# 4. Rebuild
nix build .#crush-patched
```

## Removing Patches

```bash
# 1. Remove from patches list in package.nix
# 2. Rebuild
nix build .#crush-patched
```

## Architecture Comparison

### Original Approach (fetchpatch only)
```nix
# pkgs/crush-patched.nix
{pkgs}:
  pkgs.buildGoModule {
    src = pkgs.fetchurl { ... };
    patches = [
      (pkgs.fetchpatch { ... })
    ];
  };

# flake.nix
packages.crush-patched = import ./pkgs/crush-patched.nix { inherit pkgs; };
```

**Issues:**
- ❌ Direct import (less composable)
- ❌ No easy override mechanism
- ❌ Not standard nixpkgs pattern

### Attempted Nix-Native (local patches)
```nix
# pkgs/crush-patched/package.nix
patches = [
  ./patches/xxx.patch  # Local files prone to corruption
];
```

**Issues:**
- ❌ Local patch files can corrupt
- ❌ Manual file maintenance
- ❌ Harder to verify integrity
- ❌ Patch directory management

### Hybrid Approach (callPackage + fetchpatch)
```nix
# pkgs/crush-patched/package.nix
{ lib, buildGoModule, fetchurl, fetchpatch }:
  buildGoModule {
    src = fetchurl { ... };
    patches = [
      (fetchpatch {  # Reliable, immutable
        url = "https://github.com/.../commit/xxx.patch";
        hash = "sha256:...";
      })
    ];
  };

# flake.nix
packages.crush-patched = pkgs.callPackage ./pkgs/crush-patched/package.nix { };
```

**Benefits:**
- ✅ `callPackage` pattern (composable, standard)
- ✅ `fetchpatch` for patches (reliable, no corruption)
- ✅ No local patch files (zero maintenance)
- ✅ Immutable URLs with verified hashes
- ✅ Follows nixpkgs patterns
- ✅ Easy to add/remove patches

## Verification

### Check Patches Applied
```bash
nix log $(nix-store -qd result) | grep "applying patch"
```

### Verify Binary
```bash
./result/bin/crush --version
# Expected: crush version v0.41.0
```

### Flake Check
```bash
nix flake check
```

## Troubleshooting

### Update Script Fails
```bash
# Check dependencies
nix-shell -p bash coreutils curl jq gnused gnugrep nix-prefetch-url

# Run manually with debug output
cd pkgs/crush-patched
bash -x update.sh v0.42.0
```

### Patch Application Errors
```bash
# Verify patch URL is accessible
curl -I https://github.com/charmbracelet/crush/commit/xxx.patch

# Check hash matches
nix-prefetch-url --type sha256 \
  https://github.com/charmbracelet/crush/commit/xxx.patch
```

### Vendor Hash Issues
```bash
# Clean build environment
nix-store --gc

# Force rebuild
nix build .#crush-patched --rebuild

# Or compute manually
nix build .#crush-patched 2>&1 | grep "got:"
```

## Resources

- [Crush GitHub](https://github.com/charmbracelet/crush)
- [Nixpkgs Manual](https://nixos.org/manual/nixpkgs/stable/)
- [buildGoModule Documentation](https://nixos.org/manual/nixpkgs/stable/#sec-language-go)
- [fetchpatch Documentation](https://nixos.org/manual/nixpkgs/stable/#trivial-builder-fetchpatch)
