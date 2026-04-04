# SystemNix — Comprehensive Executive Status Report

**Date:** 2026-04-04 06:59 CEST  
**Branch:** master  
**Platform:** NixOS (evo-x2) + macOS (Lars-MacBook-Air)  
**Total Files:** 709 | **Nix:** 9,229 lines (85 files) | **Shell:** 12,289 lines (62 files) | **Docs:** 201,174 lines (472 files)

---

## A) FULLY DONE

### Core Infrastructure
- **NixOS configuration (evo-x2):** Complete. AMD Ryzen AI Max+ 395, ROCm GPU, NPU, BTRFS snapshots, ZRAM, security hardening. `nix flake check --no-build` passes clean.
- **macOS configuration (Lars-MacBook-Air):** Complete. nix-darwin + Home Manager, Touch ID, KeyChain, Homebrew, Chrome/Chromium management.
- **Cross-platform Home Manager:** Shared base (`platforms/common/home-base.nix`) with 14 program imports. Fish, Zsh, Bash, Nushell, Starship, Tmux, Git, FZF, pre-commit, KeepassXC all declarative.
- **Flake architecture:** 17 inputs, flake-parts modules, overlays for Go 1.26.1, custom packages. Both darwinConfigurations and nixosConfigurations eval clean.
- **Secrets management (sops-nix):** Active. TLS certs for dnsblockd, Grafana credentials, GitHub tokens. All consumed by Caddy, Grafana, Gitea, dnsblockd modules.
- **Pre-commit hooks:** 8 hooks active (gitleaks, deadnix, statix, alejandra, nix-check, flake-lock-validate, trailing-whitespace, merge-conflicts).
- **Justfile:** 99 recipes covering full lifecycle — setup, switch, test, deploy, backup, benchmark, monitoring, Go/Node dev, DNS, Immich.
- **Crush AI agent config:** Synced via flake input (`crush-config`), deployed via Home Manager on both platforms.
- **DNS blocker:** Complete custom solution — Go daemon (`dnsblockd`), blocklist processor, Caddy TLS reverse proxy, scheduled blocklist hash updater.
- **SigNoz observability:** Deployed with Caddy reverse proxy, ClickHouse, custom Grafana dashboard, Homepage integration.
- **Ollama migration to /data partition:** Complete. ~44GB models migrated, upgraded to v0.20.0, ROCm GPU acceleration working (gfx1151). 5 models verified.
- **AI stack:** Ollama + llama-cpp (ROCWMMA/MFMA) + Unsloth Studio. Custom ROCm builds with HSA_OVERRIDE_GFX_VERSION=11.5.1.
- **ActivityWatch:** Cross-platform. NixOS via Home Manager conditional, macOS via LaunchAgent. aw-watcher-utilization packaged for system resource monitoring.
- **SSH configuration:** Extracted to standalone `nix-ssh-config` flake, no more `builtins.pathExists`.
- **Gitea:** Self-hosted with sops-managed tokens, automated repo provisioning module.

### Custom Packages (5)
| Package | Status | Used By |
|---------|--------|---------|
| `modernize` (Go 1.26) | Active | `base.nix` dev tools |
| `dnsblockd` | Active | dns-blocker module |
| `dnsblockd-processor` | Active | blocklist processing |
| `aw-watcher-utilization` | Active | ActivityWatch integration |
| `geekbench-ai` | Built but unused | Not imported anywhere |

---

## B) PARTIALLY DONE

### Security Hardening (`platforms/nixos/desktop/security-hardening.nix`)
- Audit framework: **DISABLED** — 2 TODO markers for re-enabling after NixOS bug fixes
- AppArmor conflicts with audit kernel module — unresolved upstream
- Other hardening (firewall, fail2ban, kernel params) is active

### Desktop Environment
- Niri (scrollable-tiling compositor): Wrapped with custom keybindings via wrapper-modules pattern
- Waybar: Nix-managed config, but `dotfiles/.config/waybar/security-status.sh` orphan exists
- Display manager (SDDM + silent-sddm): Configured
- Multi-WM support: Skeleton exists
- Rofi, wlogout, swaylock, zellij, yazi: All declared

### Monitoring Stack
- Netdata: Referenced but setup guide only
- SigNoz: Deployed but collector config may need tuning
- Grafana: Dashboard JSON exists, admin credentials via sops
- Homepage: Service dashboard configured
- `scripts/monitor-gpu-live.sh`, `check-gpu-status.sh`, `check-npu-status.sh`, `monitor-ollama-gpu.sh` — all exist but NONE referenced from justfile or Nix (orphaned)

### Documentation
- 149 status reports accumulated in `docs/status/` — relevance audit started but cleanup not done
- 472 total .md files (201K lines) — massive documentation sprawl
- AGENTS.md references stale `dotfiles/nix/` paths that no longer exist after restructure

### Type Safety System (`platforms/common/core/`)
- 9 files defined but only 2 actually imported (`nix-settings.nix`, `UserConfig.nix`)
- 7 files form a "Ghost Systems" type-safety framework that was built but never wired in: `Types.nix`, `State.nix`, `SystemAssertions.nix`, `TypeAssertions.nix`, `Validation.nix`, `PathConfig.nix`, `security.nix`

---

## C) NOT STARTED

### Dead Code Cleanup
- **~79 orphaned files identified** but not yet removed:
  - 45 orphaned scripts in `scripts/` (82% of directory)
  - 10 orphaned patches in `patches/` (entire directory)
  - 7 unused type-safety files in `platforms/common/core/`
  - 3 unused packages in `pkgs/`
  - 5 obsolete dotfiles
  - 3 one-off Python scripts
  - 5 benchmark files in `dev/testing/`

### Remote Branch Cleanup
- 18 stale remote branches (`copilot/fix-*`, `organize-packages`, `feature/nushell-configs`) — not pruned

### Documentation Consolidation
- No archival of 149+ status reports
- No deduplication of overlapping guides
- AGENTS.md stale path references not updated

### Binary Artifacts in Repo
- `pkgs/dnsblockd-processor/dnsblockd-processor` — compiled binary committed to repo
- `pkgs/signoz/` — directory with only a README, no actual config

### CI/CD
- `.github/workflows/nix-check.yml` exists but scope unclear
- No automated testing pipeline beyond pre-commit hooks

---

## D) TOTALLY FUCKED UP

### Orphaned Scripts with Stale Paths (~15 scripts)
These scripts reference `dotfiles/nix/` and `dotfiles/nixos/` paths that **no longer exist** after the project restructure to `platforms/`. They are **silently broken**:
- `scripts/smart-fix.sh` → `cd dotfiles/nix`
- `scripts/nix-diagnostic.sh` → `cd dotfiles/nix`
- `scripts/test-config.sh` → `dotfiles/nixos/configuration.nix`
- `scripts/validate-deployment.sh` → `dotfiles/nixos/configuration.nix`
- `scripts/simple-test.sh` → `dotfiles/nixos/configuration.nix`
- `scripts/backup-config.sh` → `dotfiles/nixos/configuration.nix`
- `scripts/activitywatch-config.sh` → `./dotfiles/activitywatch`

### Dual Pre-commit System
- `.pre-commit-config.yaml` (8 hooks) AND `.githooks/pre-commit` both implement the same checks. Duplicated effort, confusing.

### PathConfig.nix Hardcodes Dead Paths
- `platforms/common/core/PathConfig.nix` hardcodes `/Users/larsartmann/projects/SystemNix/dotfiles/nix` — path doesn't exist, file never imported, misleading if discovered.

### `scripts/lib/paths.sh`
- Defines shared path constants referencing `dotfiles/nix/` (dead). Only sourced by `automation-setup.sh` which itself is orphaned. Entire `lib/` effectively dead.

### 201K Lines of Documentation
- 472 .md files (66% of all files). Documentation-to-code ratio is **21:1** by line count. Extreme doc sprawl creates noise, makes finding relevant info harder.

---

## E) WHAT WE SHOULD IMPROVE

### High Impact
1. **Delete orphaned files** — 79 dead files add confusion, slow searches, increase clone size
2. **Consolidate documentation** — Archive historical status reports, keep only active references
3. **Single pre-commit system** — Choose `.pre-commit-config.yaml` OR `.githooks/`, not both
4. **Remove compiled binary from repo** — `pkgs/dnsblockd-processor/dnsblockd-processor` should be built by Nix
5. **Update AGENTS.md** — Fix stale `dotfiles/nix/` references to reflect `platforms/` structure
6. **Wire or remove type-safety system** — 7 unused files in `common/core/` are dead weight
7. **Prune remote branches** — 18 stale `copilot/fix-*` branches clutter the remote

### Medium Impact
8. **Script consolidation** — Reduce 62 shell scripts to ~15 actually-used ones; migrate logic to justfile
9. **Add `.gitignore` for generated files** — `glm_flash_benchmark_results.json`, compiled binaries
10. **Add nix flake check to CI** — Ensure flake eval passes on every push
11. **Consider removing `patches/` entirely** — Old Crush patches, nothing references them
12. **Validate all justfile recipes** — Some may reference scripts that no longer work

### Low Impact / Nice to Have
13. **Reduce documentation-to-code ratio** — Target <5:1 instead of current 21:1
14. **Consolidate monitoring scripts** — Multiple GPU/NPU/health check scripts that overlap
15. **Add `just doctor` command** — Single entry point for system diagnostics

---

## F) Top 25 Things to Get Done Next

| # | Priority | Task | Impact | Effort |
|---|----------|------|--------|--------|
| 1 | P0 | **Delete 45 orphaned scripts** from `scripts/` (keep only 11 referenced) | High | Low |
| 2 | P0 | **Delete entire `patches/` directory** (10 files, nothing imports them) | High | Low |
| 3 | P0 | **Delete 3 one-off Python files** (`test_speed.py`, `download_glm_model.py`, `dev/testing/`) | Medium | Low |
| 4 | P0 | **Delete `assets/` empty directory** | Low | Low |
| 5 | P0 | **Remove compiled binary** `pkgs/dnsblockd-processor/dnsblockd-processor` from git | Medium | Low |
| 6 | P1 | **Remove 7 unused type-safety files** from `platforms/common/core/` or wire them in | Medium | Medium |
| 7 | P1 | **Remove unused packages** (`superfile.nix`, `geekbench-ai/`) from `pkgs/` | Medium | Low |
| 8 | P1 | **Delete obsolete dotfiles** (`.zshrc.modular`, iTerm2 profile, Chrome plugins txt, waybar orphan) | Medium | Low |
| 9 | P1 | **Update AGENTS.md** to fix all `dotfiles/nix/` → `platforms/` references | High | Medium |
| 10 | P1 | **Consolidate pre-commit** — remove `.githooks/` or `.pre-commit-config.yaml`, keep one | Medium | Low |
| 11 | P1 | **Archive old status reports** — move 140+ historical files to `docs/archive/status/` | Medium | Low |
| 12 | P2 | **Prune 18 stale remote branches** (`copilot/fix-*`, `organize-packages`, etc.) | Low | Low |
| 13 | P2 | **Remove `tools/paths that can be cleaned.txt`** (stale macOS notes) | Low | Low |
| 14 | P2 | **Remove `scripts/lib/paths.sh`** and `scripts/automation-setup.sh` (dead dependency pair) | Low | Low |
| 15 | P2 | **Add `.gitignore` entries** for `*.pyc`, benchmark results, compiled binaries | Low | Low |
| 16 | P2 | **Fix security-hardening.nix TODOs** — re-enable audit framework when NixOS fixes land | High | High |
| 17 | P2 | **Validate all justfile recipes** work after orphaned script cleanup | Medium | Medium |
| 18 | P3 | **Wire monitoring scripts into justfile** or remove them (GPU/NPU/Ollama monitors) | Medium | Low |
| 19 | P3 | **Create `just doctor`** — unified diagnostic command | Medium | Medium |
| 20 | P3 | **Remove `pkgs/signoz/` directory** (only has README, no actual package) | Low | Low |
| 21 | P3 | **Remove `platforms/nixos/private-cloud/`** (only has README) | Low | Low |
| 22 | P3 | **Add CI pipeline** — nix flake check on push, not just pre-commit | Medium | Medium |
| 23 | P4 | **Consolidate overlapping docs** — merge similar guides, deduplicate status reports | Low | High |
| 24 | P4 | **Remove `dotfiles/activitywatch/tcc-profile.mobileconfig`** (not referenced) | Low | Low |
| 25 | P4 | **Review `scripts/buildflow-nix`** — remove if buildflow CLI not actively used | Low | Low |

---

## G) Top #1 Question I Cannot Figure Out Myself

**Should the "Ghost Systems" type-safety framework (`platforms/common/core/{Types,State,SystemAssertions,TypeAssertions,Validation,PathConfig,security}.nix`) be wired into the build or deleted?**

These 7 files represent a substantial type-safety architecture (assertions, validation, state management) that was clearly built with intent but never connected to any import chain. The AGENTS.md extensively documents this as a core feature. Two options:

1. **Wire it in** — Make the type system actually validate configurations at build time (original intent, adds safety)
2. **Delete it** — Remove dead code and the misleading AGENTS.md claims about "type safety" being active

This is a product/architecture decision that depends on whether you still want to invest in the type-safety direction or simplify the codebase. I cannot determine the strategic intent from code alone.

---

## Project Metrics Summary

| Metric | Value | Assessment |
|--------|-------|------------|
| Total files | 709 | Bloated |
| Nix code | 9,229 lines (85 files) | Healthy |
| Shell scripts | 12,289 lines (62 files) | Overbuilt (82% orphaned) |
| Documentation | 201,174 lines (472 files) | Excessive (21:1 doc-to-code ratio) |
| Flake inputs | 17 | Reasonable |
| Justfile recipes | 99 | Comprehensive |
| Pre-commit hooks | 8 | Good |
| Custom packages | 5 (1 unused) | Good |
| Orphaned files | ~79 | Critical cleanup needed |
| Flake check | PASSING | Healthy |
| Stale remote branches | 18 | Needs pruning |
| Dead path references | ~15 scripts | Broken code |
| TODO markers | 2 (security-hardening) | Tracked |
