# Crush-Patched

## Overview

Custom build of Crush (terminal AI assistant) with critical patches applied from upstream PRs.

**Current Version:** v0.41.0
**Last Updated:** February 10, 2026

## Applied Patches

The following critical patches are applied to fix bugs and improve stability:

### 1. PR #2181 - SQLite Busy Timeout Fix (Fixes #2129)
- **Issue:** SQLite deadlocks under high concurrency with 5s timeout
- **Fix:** Increase timeout from 5s to 30s, consolidate pragma configuration
- **Impact:** Multi-instance usage no longer causes database lockups
- **Files Modified:**
  - `internal/db/connect.go`
  - `internal/db/connect_modernc.go`
  - `internal/db/connect_ncruces.go`

### 2. PR #2180 - LSP Files Outside CWD Fix (Fixes #1401)
- **Issue:** LSP client couldn't handle files outside working directory
- **Fix:** Make LSP client receive working directory explicitly instead of calling `os.Getwd()` internally
- **Impact:** Improved IDE/editor integration reliability
- **Files Modified:**
  - `internal/lsp/client.go`
  - `internal/lsp/client_test.go`
  - `internal/lsp/manager.go`

### 3. PR #2161 - Regex Cache Memory Leak Fix
- **Issue:** Regex caches grow unbounded across sessions, causing memory leaks
- **Fix:** Clear regex caches at session boundaries
- **Impact:** Prevents unbounded memory growth during long sessions
- **Files Modified:**
  - `internal/agent/tools/grep.go`
  - `internal/ui/model/ui.go`

## Update to New Version

1. Edit `pkgs/crush-patched.nix`
2. Update `version` and source `sha256`

```bash
# Get new version's hash
nix-prefetch-url --type sha256 \
  https://github.com/charmbracelet/crush/archive/refs/tags/v0.41.0.tar.gz
```

3. Set `vendorHash = "sha256:0000000000000000000000000000000000000000000000000000000000000000";` (fake hash to force error)
4. Build and copy the correct hash from error message:

```bash
nix build .#crush-patched
```

Output shows:
```
got:    sha256-<correct-hash-here>
```

5. Paste the hash into `vendorHash = "sha256:<correct-hash-here>";`
6. Build again: `nix build .#crush-patched`
7. Install: `just switch`

## Patch Management

Patches are fetched using `pkgs.fetchpatch` from GitHub commit URLs. To add/remove patches:

1. Add/remove patch entries in `patches = [...]` list in `pkgs/crush-patched.nix`
2. Use `nix-prefetch-url` to get patch hashes:

```bash
nix-prefetch-url --type sha256 \
  https://github.com/charmbracelet/crush/commit/<commit-hash>.patch
```

3. Rebuild with `nix build .#crush-patched`

## Verification

To verify patches are applied:

```bash
# Check build log for patch applications
nix log /nix/store/<derivation-hash>-crush-patched-v0.41.0.drv | grep "applying patch"

# Verify binary version
result/bin/crush --version
```
