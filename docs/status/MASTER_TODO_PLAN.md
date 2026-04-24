# MASTER TODO PLAN — SystemNix Review Action Items

**Generated:** 2026-04-24
**Source:** REVIEW_DOCS.md + all 44 status docs (2026-04-10 to 2026-04-24)
**Rule:** Every task ≤12 min. Sorted by: Impact → Security → Effort → Customer Value.

---

## P0 — CRITICAL (Do NOW, 0–5 min each, catastrophic if skipped)

| # | Task | Category | Est. | Why |
|---|------|----------|------|-----|
| 1 | `git push` — push all local commits to origin | DEPLOY | 1m | Unpushed work = work that can vanish. This has been recommended in 15+ status docs and never done. |
| 2 | `git stash clear` — drop 3 stale stashes (Hyprland, vendorHash, line-endings) | HYGIENE | 1m | Orphaned since pre-niri migration. Mentioned in 10+ docs. |
| 3 | Delete 17 remote `copilot/fix-*` branches | HYGIENE | 2m | `git branch -r \| grep copilot/fix \| xargs -n1 git push --delete origin`. Stale since April. |
| 4 | Archive 39 redundant status docs to `archive/` | DOCS | 5m | Keep only 5: `21-10_FULL-SYSTEM-STATUS`, `03-36_SERVICE-DEPENDENCY`, `07-32_GPU-CRASH`, `11-00_SECURITY-OBSERVABILITY`, `debug-map.md`. Move rest to `archive/`. |
| 5 | Rewrite `docs/status/README.md` (3 lines max) | DOCS | 2m | Current: 84 lines, stale since 04-04, references non-existent files. Replace with: "Current status: newest dated file. Archive: `archive/`. Policy: one doc per session, max 100 lines." |
| 6 | Fix inaccurate "29 modules" → "27" in 3 docs (04-24 files) | DOCS | 2m | Verified false. Search-replace in the 3 04-24 status files. |

**P0 subtotal: ~13 min**

---

## P1 — SECURITY (Fix this session, 5–12 min each)

| # | Task | Category | Est. | Why |
|---|------|----------|------|-----|
| 7 | Move Taskwarrior encryption secret to sops-nix | SECURITY | 10m | `sha256("taskchampion-sync-encryption-systemnix")` is public in repo. Anyone can decrypt synced tasks. Replace with sops secret. |
| 8 | Add systemd hardening to `gitea-ensure-repos` service | SECURITY | 8m | Zero hardening directives — the ONLY service with none. Add: `PrivateTmp`, `NoNewPrivileges`, `ProtectHome`, `ProtectSystem`, `MemoryMax`. Follow hermes.nix pattern. |
| 9 | Pin Docker image digests for Voice Agents (`latest` → sha256) | SECURITY | 5m | `beecave/insanely-fast-whisper-rocm:latest` — silent breakage on redeploy, no rollback. Pull digest, pin it. |
| 10 | Pin Docker image digest for PhotoMap (`latest` → sha256) | SECURITY | 5m | `lstein/photomapai:latest` — same issue. |
| 11 | Secure VRRP auth_pass with sops-nix | SECURITY | 8m | `auth_pass "DNSClusterVRRP"` is plaintext in `dns-failover.nix`. Move to sops secret. |
| 12 | Remove dead `ublock-filters.nix` module entirely | CLEANUP | 5m | `enable = false`, timer just echoes, no browser integration. Dead code in `home-base.nix`. Remove the import and the file. |
| 13 | Fix `gitea-ensure-repos` missing `Restart` + `StartLimitBurst` | RELIABILITY | 3m | Service can infinite-restart on failure. Add `Restart=on-failure`, `RestartSec=5`, `StartLimitBurst=3`, `StartLimitIntervalSec=300`. |

**P1 subtotal: ~44 min**

---

## P2 — RELIABILITY (Fix this week, 5–12 min each)

| # | Task | Category | Est. | Why |
|---|------|----------|------|-----|
| 14 | Add `WatchdogSec` to services missing it: caddy, gitea, authelia, taskchampion | RELIABILITY | 10m | 4 long-running services with no crash detection. Add `WatchdogSec=30` to each. |
| 15 | Add `Restart=on-failure` to services missing it: caddy, gitea, authelia, taskchampion, sops | RELIABILITY | 8m | These services won't auto-recover from crashes. |
| 16 | Fix 3 dead `let` bindings (twenty.nix, dns-blocker.nix, aw-watcher-utilization.nix) | CLEANUP | 5m | `appSecretFile`, `pgPasswordFile`, `addIPScript`, `poetry` — bound but never used. |
| 17 | Fix `core.pager` vs `pager.diff` conflict in git.nix | QUALITY | 3m | `core.pager = "cat"` overrides `pager.diff = "bat"`. Remove one or reorder. |
| 18 | Fix `fonts.packages` darwin compatibility | CROSS-PLAT | 5m | `fonts.packages` is NixOS-only option. Guard with `lib.mkIf pkgs.stdenv.isLinux` in `platforms/common/packages/fonts.nix`. |
| 19 | Enable `services.udisks2` on NixOS | USABILITY | 2m | Auto-mounting USB/SD cards doesn't work without it. One-line addition to configuration.nix. |
| 20 | Add `.editorconfig` (2-space indent, UTF-8, LF) | QUALITY | 2m | No consistent editor settings. Create standard `.editorconfig`. |
| 21 | Make deadnix check strict (`--fail` flag) in flake.nix | QUALITY | 3m | deadnix returns exit 0 for warnings — `nix flake check` gives false confidence. Add `--fail`. |
| 22 | Fix pre-commit statix hook | TOOLING | 10m | Failed on wallpapers commit. Debug the hook, fix path handling for new flake inputs. |
| 23 | Add date + commit hash to `debug-map.md` header | DOCS | 1m | Currently undated, no commit reference. Makes the forensic doc traceable. |
| 24 | Add `homepage` URL to `emeet-pixyd` package meta | QUALITY | 1m | All other packages have it. Missing `meta.homepage`. |

**P2 subtotal: ~50 min**

---

## P3 — CODE QUALITY (Fix this week, 5–12 min each)

| # | Task | Category | Est. | Why |
|---|------|----------|------|-----|
| 25 | Fix deadnix unused params: batch 1 (6 service modules with unused `inputs`) | QUALITY | 10m | Prefix `inputs:` with `_:` in 6 files. |
| 26 | Fix deadnix unused params: batch 2 (6 more service modules) | QUALITY | 10m | Continue prefix sweep. |
| 27 | Fix deadnix unused params: batch 3 (5 platform files) | QUALITY | 10m | Unused `config`, `lib`, `pkgs` in platforms/nixos/ and platforms/common/. |
| 28 | Fix deadnix unused params: batch 4 (remaining files) | QUALITY | 10m | Unused lambda args: `final`/`oldAttrs` in darwin overlay, `old` in ai-stack, `subdomain` in caddy, etc. |
| 29 | Remove duplicate entries in git global ignores | QUALITY | 3m | `.so`, `*~`, `*.log`, `target/` appear twice in git.nix. |
| 30 | Fix GPG program path for cross-platform (`/run/current-system/sw/bin/gpg` is NixOS-only) | CROSS-PLAT | 5m | Wrap with `if pkgs.stdenv.isLinux`. |
| 31 | Fix bash.nix — add history config + shopt settings | QUALITY | 8m | Minimal bash config has no `HISTCONTROL`, no `shopt`, no completion. Add baseline. |
| 32 | Fix Fish `$GOPATH` init timing and fake history variables | QUALITY | 5m | `$GOPATH` may be empty at init. `fish_history_size` is not a real variable. |
| 33 | Clean unfree allowlist (remove `signal-desktop-bin`, `castlabs-electron`, `cursor`) | CLEANUP | 3m | Listed in allowUnfree but not installed. |

**P3 subtotal: ~64 min**

---

## P4 — ARCHITECTURE (Plan + execute, 10–12 min each)

| # | Task | Category | Est. | Why |
|---|------|----------|------|-----|
| 34 | Create `lib/systemd-harden.nix` shared helper | ARCH | 12m | 20 lines of hardening repeated per service. Extract to helper: `hardenService = { MemoryMax ? "512M", ... }: { ... }`. |
| 35 | Wire `preferences.nix` to actual GTK/Qt/cursor/font theming | ARCH | 12m | Options declared but nothing consumes them on NixOS. Start with GTK + cursor. |
| 36 | Convert niri session restore `let` block to NixOS module options | ARCH | 12m | `sessionSaveInterval`, `maxSessionAgeDays`, `fallbackApps` should be proper options. |
| 37 | Add `options` + `mkIf` to batch 1 of always-on modules (sops, caddy, gitea, immich) | ARCH | 12m | 16 modules have no enable toggle. Start with core 4. |
| 38 | Add `options` + `mkIf` to batch 2 of always-on modules (authelia, photomap, homepage, taskchampion) | ARCH | 12m | Continue with next 4. |
| 39 | Add `options` + `mkIf` to batch 3 of always-on modules (display-manager, audio, niri-config, security-hardening) | ARCH | 12m | Continue. |
| 40 | Add `options` + `mkIf` to batch 4 of always-on modules (monitoring, multi-wm, chromium-policies, steam) | ARCH | 12m | Final 4. |

**P4 subtotal: ~84 min**

---

## P5 — DEPLOYMENT & VERIFICATION (Runtime tasks)

| # | Task | Category | Est. | Why |
|---|------|----------|------|-----|
| 41 | `just switch` — deploy all pending changes to evo-x2 | DEPLOY | 45m+ | hipblaslt fix, DNS cluster, module migration, wallpapers. Runtime task (can't be done by AI). |
| 42 | Verify Ollama works after rebuild | VERIFY | 5m | ROCm-dependent. Run `ollama list` and a test inference. |
| 43 | Verify Steam works after rebuild | VERIFY | 5m | ROCm-dependent. Launch a game. |
| 44 | Verify ComfyUI works after rebuild | VERIFY | 5m | ROCm-dependent. Run a pipeline. |
| 45 | Verify Caddy HTTPS block page serves correctly | VERIFY | 3m | New feature from 04-24. `curl -k https://<blocked-domain>`. |
| 46 | Verify SigNoz is collecting metrics/logs/traces | VERIFY | 5m | Built but unclear if active. Check `signoz.home.lan`. |
| 47 | Check Authelia SSO status | VERIFY | 3m | Unknown since 04-05. Login to `auth.lan`. |
| 48 | Check PhotoMap service status | VERIFY | 3m | Unknown since 03-31. Hit `photomap.home.lan`. |
| 49 | Verify AMD NPU with test workload | VERIFY | 10m | Driver installed, never tested. Run a simple inference. |
| 50 | Build Pi 3 SD image | DEPLOY | 30m+ | `nix build .#nixosConfigurations.rpi3-dns.config.system.build.sdImage`. Cross-compile. |
| 51 | Flash SD + boot Pi 3 | DEPLOY | 15m | Hardware task. |
| 52 | Test DNS failover (stop Unbound on evo-x2, verify Pi 3 takes over) | VERIFY | 10m | End-to-end test of Keepalived VRRP. |
| 53 | Configure all LAN devices to use DNS VIP `192.168.1.53` | DEPLOY | 10m | Manual per-device config. |

**P5 subtotal: ~150 min** (most is runtime/waiting)

---

## P6 — SERVICES IMPROVEMENT (Per-service, 5–12 min each)

| # | Task | Category | Est. | Why |
|---|------|----------|------|-----|
| 54 | Twenty CRM: add backup rotation/cleanup | RELIABILITY | 8m | Only creates new backups, never cleans old ones. Add `find -mtime +30 -delete`. |
| 55 | Twenty CRM: fix hardcoded container name `twenty-db-1` | RELIABILITY | 5m | Fragile — docker-compose may assign different name. Use label-based lookup. |
| 56 | ComfyUI: replace hardcoded `/home/lars/projects/anime-comic-pipeline/` paths | ARCH | 12m | Not portable, violates Nix philosophy. Move to module option with sensible default. |
| 57 | ComfyUI: add `WatchdogSec` + `MemoryMax` | RELIABILITY | 5m | No crash detection, no memory limit on GPU workloads. |
| 58 | ComfyUI: run as dedicated system user (not `lars`) | SECURITY | 8m | Currently runs as user `lars` — weaker isolation. |
| 59 | Voice agents: add health check for Whisper ASR | OBSERVABILITY | 8m | No health check defined. Add `ExecStartPost` curl to `/health`. |
| 60 | Voice agents: fix unused `pipecatPort = 8500` | CLEANUP | 2m | Defined but never referenced. Remove or wire up. |
| 61 | Voice agents: fix PIDFile declared but never created | CLEANUP | 3m | `PIDFile` points to nonexistent file. Remove the directive. |
| 62 | Hermes: add health check endpoint | OBSERVABILITY | 10m | No systemd health check. Add `ExecStartPost` or `WatchdogSec`. |
| 63 | Hermes: migrate remaining providers to `key_env` | SECURITY | 10m | Only ZAI uses `key_env`. Other API keys are inline in config.yaml. |
| 64 | SigNoz: fix signoz-provision duplicate rules on every reboot | RELIABILITY | 10m | Uses POST not PUT. Change to idempotent upsert. |
| 65 | SigNoz: add missing metrics for 10 services | OBSERVABILITY | 12m | gitea, immich, twenty, hermes, taskchampion, voice-agents, photomap, homepage, postgresql, redis have no metrics. |
| 66 | Authelia: add SMTP notifications (or push) | UX | 10m | Currently writes to `notification.txt`. No email on 2FA setup, password reset. |
| 67 | Add backup restore test for Immich | RELIABILITY | 12m | Daily backups exist but never verified. Test restore to temp location. |
| 68 | Add backup restore test for Twenty CRM | RELIABILITY | 12m | Same — verify the backup scripts actually produce restorable data. |

**P6 subtotal: ~127 min**

---

## P7 — TOOLING & CI (Infrastructure, 5–12 min each)

| # | Task | Category | Est. | Why |
|---|------|----------|------|-----|
| 69 | Add GitHub Actions: `nix flake check` on push | CI | 10m | Zero CI exists. Create `.github/workflows/nix-check.yml`. |
| 70 | Add GitHub Actions: Go test for emeet-pixyd and dnsblockd | CI | 10m | Go packages have tests but no CI to run them. |
| 71 | Add GitHub Actions: flake.lock auto-update (Renovate/Deps) | CI | 10m | Manual `just update` only. Add automated PRs for input updates. |
| 72 | Fix eval smoke tests (remove `|| true`) | QUALITY | 5m | Eval tests in flake.nix always pass. Remove `|| true`, make them fail on eval errors. |
| 73 | Consolidate duplicate justfile recipes (validate/check-nix-syntax, switch/deploy) | CLEANUP | 8m | `validate` ≈ `check-nix-syntax`, `switch` ≈ `deploy`. Remove duplicates. |
| 74 | Replace `nixpkgs-fmt` with `nixfmt-rfc-style` in pre-commit | MODERNIZE | 5m | `nixpkgs-fmt` is deprecated. Update `.pre-commit-config.yaml`. |
| 75 | Trim system monitors from 4 to 2 (`btop` + `bottom`) | CLEANUP | 3m | `bottom`, `procs`, `btop`, `htop` — pick 2. |
| 76 | Fix `LC_ALL` override redundancy with `LANG` | QUALITY | 2m | `LC_ALL = "en_US.UTF-8"` overrides all other locale settings. Redundant. |
| 77 | Remove `allowUnsupportedSystem = true` from nix-settings | QUALITY | 2m | Masks real build issues. Set to `false` or remove. |
| 78 | Setup Taskwarrior backup timer (systemd) | AUTOMATION | 8m | `just task-backup` exists but no timer. Add daily systemd timer. |

**P7 subtotal: ~63 min**

---

## P8 — DOCUMENTATION (Low urgency, high long-term value)

| # | Task | Category | Est. | Why |
|---|------|----------|------|-----|
| 79 | Write top-level `README.md` (project overview + quickstart) | DOCS | 12m | Exists but may be stale. Update with current architecture, commands, badges. |
| 80 | Document DNS cluster in AGENTS.md | DOCS | 8m | Pi 3 config, VRRP, blocklists not documented in AGENTS.md yet. |
| 81 | Write ADR for niri session restore design | DOCS | 10m | Complex system, no architectural decision record. |
| 82 | Add module option `description` fields to all 10 toggleable services | DOCS | 10m | `lib.mkEnableOption "..."` should have meaningful descriptions. |
| 83 | Create `docs/CONTRIBUTING.md` with module patterns | DOCS | 12m | AGENTS.md is AI-focused. Human contributors need a guide. |
| 84 | Add `MANPAGER` and `VISUAL` environment variables | QUALITY | 2m | Standard env vars missing from home-base.nix. |

**P8 subtotal: ~54 min**

---

## P9 — FUTURE / RESEARCH (Not actionable now, depends on decisions)

| # | Task | Category | Est. | Why |
|---|------|----------|------|-----|
| 85 | Investigate `just test` intermittent race (emeet-pixyd sandbox) | RESEARCH | 12m | Fails in parallel, succeeds alone. Root cause unknown. |
| 86 | Create `homeModules` pattern for HM configs via flake-parts | ARCH | 12m | waybar, rofi, etc. can't be `nixosModules`. New pattern needed. |
| 87 | Package ComfyUI as proper Nix derivation | ARCH | 60m+ | Currently hardcoded paths. Real fix = package it properly. |
| 88 | Investigate lldap/Kanidm for unified Authelia + PAM auth | ARCH | 60m+ | Two separate password stores. Requires research + decision. |
| 89 | Migrate Pi 3 from deprecated `linux-rpi` to `nixos-hardware` | ARCH | 12m | `linux-rpi` series will be removed. Migrate before it breaks. |
| 90 | Migrate SSH config from custom module to HM `programs.ssh.matchBlocks` | ARCH | 12m | Uses custom `ssh-config.nix` instead of standard HM option. |
| 91 | Add basic NixOS VM tests for Authelia + Caddy + DNS blocker | TESTING | 60m+ | Zero `nixosTests` in flake. Critical services untested. |
| 92 | Investigate binary cache (Cachix) for overlay-heavy builds | PERF | 30m+ | Custom overlays cause cache misses on ROCm packages. |
| 93 | Add Waybar module for niri session restore stats | FEATURE | 10m | Show last save time, window count in bar. |
| 94 | Add real-time save via `niri msg event-stream` | FEATURE | 12m | Currently polling timer. Event-stream would be real-time. |
| 95 | Add integration tests with mock niri IPC for session restore | TESTING | 12m | No automated tests for save/restore cycle. |
| 96 | File nixpkgs issue for hipblaslt Tensile gfx908 rejection | UPSTREAM | 10m | The sed patch is fragile. Upstream bug should be reported. |

**P9 subtotal: ~292 min**

---

## SUMMARY

| Priority | Tasks | Total Est. | Description |
|----------|-------|------------|-------------|
| **P0 CRITICAL** | 6 | ~13 min | Do NOW. Unpushed commits, stale stashes, doc cleanup. |
| **P1 SECURITY** | 7 | ~44 min | Fix this session. Encryption, hardening, image pinning. |
| **P2 RELIABILITY** | 11 | ~50 min | Fix this week. Watchdog, dead code, cross-platform. |
| **P3 CODE QUALITY** | 9 | ~64 min | Fix this week. Deadnix, linting, cleanup. |
| **P4 ARCHITECTURE** | 7 | ~84 min | Plan + execute. Module options, helpers. |
| **P5 DEPLOY/VERIFY** | 13 | ~150 min | Runtime tasks. `just switch`, verify services, Pi 3. |
| **P6 SERVICES** | 15 | ~127 min | Per-service improvements. Hardening, health checks. |
| **P7 TOOLING/CI** | 10 | ~63 min | GitHub Actions, justfile, pre-commit. |
| **P8 DOCS** | 6 | ~54 min | README, AGENTS.md, ADR. |
| **P9 FUTURE** | 12 | ~292 min | Research, large refactors, upstream. |
| **TOTAL** | **96** | **~891 min** | **~15 hours** |

### Quick Wins (P0 + P1 = 57 min for highest impact)
Tasks #1–#13 cover the most critical items in under 1 hour.
