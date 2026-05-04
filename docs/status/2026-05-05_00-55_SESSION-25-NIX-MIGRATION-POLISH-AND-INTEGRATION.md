# Full System Status Report

**Date:** 2026-05-05 00:55 CEST
**Session:** 25 — Post-Nix-Migration Polish & Integration Verification
**Repos:** SystemNix (master@242bff1), library-policy (master@8b039b1)

---

## a) FULLY DONE ✓

### library-policy — Nix Flake Migration (COMPLETE)

| Component | Status | Details |
|-----------|--------|---------|
| flake.nix | ✅ | flake-parts, treefmt-nix, git-hooks-nix, 4 systems |
| nix/packages/default.nix | ✅ | buildGoModule (debug + production), Go 1.26.2, 3 build tags |
| nix/checks/default.nix | ✅ | 7 checks: vet, test, test-integration, lint, quality, duplicates, treefmt |
| nix/apps/default.nix | ✅ | 10 apps (build, test, lint, dogfood, generate-typespec, etc.) |
| nix/devshells/default.nix | ✅ | Full dev env with pre-commit hooks shellHook |
| .github/workflows/ci.yml | ✅ | Nix-based CI with DeterminateSystems installer |
| .envrc | ✅ | `use flake` for direnv |
| justfile | ✅ | Deprecated header added, all 22 recipes have nix equivalents |

**All 198 tests pass. `nix flake check --no-build` passes. `go vet ./...` clean.**

### library-policy — Bug Fixes (COMPLETE)

| Fix | Status | Details |
|-----|--------|---------|
| FindGoModFile BDD test | ✅ | Changed `os.UserHomeDir()` → `os.TempDir()` for nix sandbox compatibility |
| `--ginkgo.skip` removal | ✅ | Removed skip flag — all 48 BDD specs pass including previously-skipped test |
| `getProjectGoVersion()` | ✅ | Implemented using `pass.Module.GoVersion` from `go/analysis` framework |
| Hermetic lint check | ✅ | Replaced fixed-output derivation hack with `buildGoModule` + `proxyVendor=true` |
| pre-commit-hooks.nix | ✅ | Added `git-hooks-nix` with gofmt, end-of-file-fixer, trim-trailing-whitespace |

### library-policy — SystemNix Integration (COMPLETE)

| Step | Status | Details |
|------|--------|---------|
| Flake input | ✅ | `git+ssh://git@github.com/LarsArtmann/library-policy?ref=master` |
| Overlay | ✅ | `libraryPolicyOverlay` in sharedOverlays |
| Global install | ✅ | Added to `platforms/common/packages/base.nix` |
| perSystem.packages | ✅ | Inherited from pkgs |
| AGENTS.md docs | ✅ | Added to sharedOverlays list + Flake Inputs table |

### SystemNix — Documentation (COMPLETE)

| Item | Status | Details |
|------|--------|---------|
| AGENTS.md library-policy section | ✅ | sharedOverlays list updated, Flake Inputs table updated |
| Status report | ✅ | This document |

---

## b) PARTIALLY DONE ⚠️

### SystemNix — `harden()` Refactoring with `lib.mkDefault` (22 unstaged files)

**What:** Previous session refactored `lib/systemd.nix` to accept `lib` parameter and wrap all security defaults with `lib.mkDefault`, allowing downstream modules to override individual settings without `//` merging.

**Status:** All 22 files modified, `nix flake check --no-build` passes, but NOT committed yet.

**Files affected:**

| Category | Files | Change |
|----------|-------|--------|
| Core lib | `lib/default.nix`, `lib/systemd.nix` | Add `{lib, ...}:` param, wrap values in `mkDefault` |
| Services (×15) | authelia, caddy, comfyui, file-and-image-renamer, gatus, gitea, gitea-repos, hermes, homepage, immich, minecraft, monitor365, photomap, signoz, taskchampion | `import ../../../lib/systemd.nix { inherit lib; }` |
| System | dns-blocker-config, scheduled-tasks | Same import fix |
| Platform | rpi3/default.nix | Same import fix |
| Voice agents | voice-agents.nix | Same import fix |
| Removed | caddy: `unsloth.${domain}` vhost | Unsloth service removed from Caddy routing |
| Removed | homepage: Unsloth dashboard card | Removed from homepage dashboard |
| Removed | rpi3, dns-blocker: `unsloth` subdomain | Removed from DNS records |
| Refactored | file-and-image-renamer | Inlined service config instead of harden()+serviceDefaults() |

**Risk:** Medium. The `mkDefault` change means downstream modules CAN now override individual hardening settings, which is the intent — but we haven't tested `just switch` yet.

### SystemNix — Unsloth Service Removal (PARTIAL)

The Unsloth service references have been removed from Caddy, Homepage, and DNS configs, but the actual `modules/nixos/services/` Unsloth module (if it existed as a standalone file) may still be present. The AI models centralized storage at `/data/ai/workspaces/unsloth/` likely still exists on disk.

---

## c) NOT STARTED ○

| # | Item | Priority | Effort |
|---|------|----------|--------|
| 1 | `just switch` to verify harden() mkDefault changes work on evo-x2 | HIGH | 5min |
| 2 | Nix build of library-policy lint check (verify proxyVendor works in sandbox) | HIGH | 30min |
| 3 | Commit the 22 unstaged harden() mkDefault files | HIGH | 2min |
| 4 | Add `library-policy dogfood` to CI pipeline (self-scan in nix checks) | MEDIUM | 15min |
| 5 | library-policy AGENTS.md update with new nix commands and pre-commit info | MEDIUM | 10min |
| 6 | SystemNix dead code cleanup: `lib/default.nix` aggregator, `lib/types.nix` | LOW | 30min |
| 7 | DNS failover cluster: Pi 3 hardware provisioning + testing | LOW | Hours |
| 8 | Twenty CRM service module (currently imported but unclear status) | MEDIUM | 1hr |
| 9 | Gatus monitoring service (currently imported, needs health checks) | MEDIUM | 30min |
| 10 | Pre-commit hook installation via `nix develop` in library-policy | LOW | 5min |

---

## d) TOTALLY FUCKED UP 💥

| # | Issue | Severity | Details |
|---|-------|----------|---------|
| 1 | **22 unstaged files in SystemNix** | 🔴 HIGH | harden() mkDefault refactoring + unsloth removal from previous sessions — NOT committed. Working tree is dirty. Could be lost if someone force-pushes or disk corrupts. |
| 2 | **`/tmp/go.mod` pollution** | 🟡 MEDIUM | Stale `/tmp/go.mod` from library-policy BDD tests causes `FindGoModFile` "not found" test to fail locally. Cleaned up this session but will recur unless test helpers clean up after themselves. The test creates `go.mod` files in temp dirs that aren't always cleaned before the "not found" test runs. |
| 3 | **library-policy `go.work` file** | 🟡 MEDIUM | Requires `GOWORK=off` in every nix derivation. If forgotten on any new derivation, builds fail with confusing workspace errors. Not documented in library-policy AGENTS.md. |
| 4 | **`lib/types.nix` — mostly dead code** | 🟢 LOW | Only used by `hermes.nix`. Should be consolidated or removed. AGENTS.md says "mostly dead, only used by hermes.nix" but nobody has cleaned it up. |
| 5 | **`lib/default.nix` — dead code aggregator** | 🟢 LOW | Zero references from any module. The `harden` and `serviceDefaults` are imported directly from `lib/systemd.nix` and `lib/systemd/service-defaults.nix` in every consumer. |

---

## e) WHAT WE SHOULD IMPROVE 📈

### Architecture

1. **Commit hygiene:** The 22 unstaged files are a symptom of "work across sessions without committing." Rule: every session should end with a commit, even if WIP. The pre-commit hook in SystemNix should enforce this.
2. **`harden()` API design:** The current `harden { MemoryMax = "1G"; }` pattern is clean, but adding `mkDefault` everywhere means overrides require `lib.mkForce` instead of simple `//` merging. This is more correct but harder to discover.
3. **library-policy AGENTS.md is stale** — still references justfile as primary, doesn't document the nix commands, pre-commit hooks, or the `GOWORK=off` requirement.
4. **SystemNix has no CI pipeline** — library-policy has nix-based CI, but SystemNix doesn't. Should add at minimum `nix flake check --no-build` as a GitHub Action.

### Code Quality

5. **`lib/default.nix` should be removed or actually used** — currently a dead aggregator.
6. **`lib/types.nix` should be inlined into hermes.nix** — the only consumer.
7. **file-and-image-renamer.nix** was refactored to inline service config instead of using `harden()` + `serviceDefaults()`. This is inconsistent with the pattern used by every other service.
8. **library-policy `getProjectGoVersion()` fallback** — returns `""` when `pass.Module` is nil. Should we log a warning? Version-gated rules silently skip when version is unknown.

### Operational

9. **No automated test for `just switch`** — we haven't verified the mkDefault changes actually deploy. Should test before committing.
10. **No nix build cache for library-policy** — CI builds from source every time. Should set up Cachix or GitHub Actions cache.

---

## f) Top 25 Things We Should Get Done Next

### Critical (Do First)

| # | Task | Effort | Impact |
|---|------|--------|--------|
| 1 | **Commit 22 unstaged SystemNix files** (harden mkDefault + unsloth removal) | 2min | 🔴 Uncommitted work at risk |
| 2 | **`just switch` to verify mkDefault changes deploy** | 10min | 🔴 Untested infra change |
| 3 | **Nix build library-policy lint check** (verify proxyVendor works) | 30min | 🔴 Untested nix check change |
| 4 | **Clean up `/tmp/go.mod` race in library-policy tests** | 15min | 🟡 Test pollution source |

### High Impact

| # | Task | Effort | Impact |
|---|------|--------|--------|
| 5 | **Update library-policy AGENTS.md** with nix commands, pre-commit, GOWORK=off gotcha | 15min | 🟡 Developer onboarding |
| 6 | **Add SystemNix CI pipeline** (`nix flake check --no-build` at minimum) | 30min | 🟡 Prevent regressions |
| 7 | **Remove `lib/default.nix` dead code aggregator** | 5min | 🟢 Code hygiene |
| 8 | **Inline or remove `lib/types.nix`** (only used by hermes.nix) | 10min | 🟢 Code hygiene |
| 9 | **Fix file-and-image-renamer to use harden() + serviceDefaults()** | 10min | 🟡 Consistency |
| 10 | **Add `library-policy dogfood` to nix checks** (self-scan) | 15min | 🟢 Dogfooding |

### Medium Impact

| # | Task | Effort | Impact |
|---|------|--------|--------|
| 11 | **Add Cachix or GitHub cache for library-policy CI** | 30min | 🟢 Build speed |
| 12 | **Document GOWORK=off requirement in library-policy AGENTS.md** | 5min | 🟡 Prevent gotcha |
| 13 | **Add `gomod2nix` to library-policy** (deferred — reconsider when deps change frequently) | 1hr | 🟢 Hash management |
| 14 | **Verify Twenty CRM service** is functional or remove | 30min | 🟢 Dead code audit |
| 15 | **Verify Gatus monitoring service** health checks work | 30min | 🟢 Observability |
| 16 | **Add `pre-commit` installation to library-policy README** | 5min | 🟢 DX |
| 17 | **Research: nix develop auto-install pre-commit hooks** | 15min | 🟢 DX |
| 18 | **Add `getProjectGoVersion()` fallback logging** | 10min | 🟢 Debuggability |
| 19 | **Create `gci` alternative for treefmt-nix** (was removed due to nixpkgs breakage) | 1hr | 🟢 Import ordering |

### Lower Priority / Future

| # | Task | Effort | Impact |
|---|------|--------|--------|
| 20 | **Pi 3 DNS failover cluster hardware provisioning** | Hours | 🟡 HA |
| 21 | **Add `nix-appimage` for portable library-policy binary** | 1hr | 🟢 Distribution |
| 22 | **Add SigNoz alerts for critical services** (caddy, authelia, dns) | 1hr | 🟢 Observability |
| 23 | **Migrate remaining justfile recipes to pure nix** in library-policy | 30min | 🟢 Cleanup |
| 24 | **Add `go mod tidy` check to library-policy nix checks** | 10min | 🟢 Dependency hygiene |
| 25 | **SystemNix boot.nix was modified at session start** but reverted — investigate | 5min | 🟢 Audit trail |

---

## g) Top #1 Question I Cannot Answer Myself

**The 22 unstaged files in SystemNix include a mix of:**

1. `harden()` mkDefault refactoring (intentional, from previous session)
2. Unsloth service removal from Caddy, Homepage, DNS records (intentional)
3. `file-and-image-renamer.nix` inline refactoring (questionable — breaks pattern consistency)

**Question: Should I commit all 22 files as-is, or should I:**
- **A)** Split into 2 commits: one for harden() mkDefault + one for unsloth removal?
- **B)** Revert the `file-and-image-renamer.nix` change to keep it using `harden()` + `serviceDefaults()` like all other services?
- **C)** Commit everything as one "refactor: harden mkDefault + remove unsloth" commit?

**Also: Has `just switch` been run with these changes, or are we committing blind?** If blind, I recommend committing but NOT pushing until verified with `just test` or `just switch`.

---

## Build & Test Status

| Repo | Build | Tests | Lint | Flake Check | Pushed |
|------|-------|-------|------|-------------|--------|
| library-policy | ✅ | ✅ 198 pass | ✅ | ✅ `--no-build` | ✅ master@8b039b1 |
| SystemNix | ✅ | N/A | ✅ | ✅ `--no-build` | ✅ master@242bff1 |
| SystemNix (unstaged) | ✅ `--no-build` | Untested | Untested | ✅ `--no-build` | ⚠️ NOT committed |

## Git Status

### library-policy
```
On branch master, up to date with 'origin/master'
Nothing to commit, working tree clean
```

### SystemNix
```
On branch master, up to date with 'origin/master'
22 modified files NOT staged (harden mkDefault + unsloth removal)
```

---

_Generated by Crush — Session 25_
