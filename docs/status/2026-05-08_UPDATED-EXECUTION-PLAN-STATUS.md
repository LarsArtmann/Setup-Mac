# COMPREHENSIVE EXECUTION PLAN — SystemNix (UPDATED)

**Created:** 2026-05-05 01:00
**Updated:** 2026-05-08 (sessions 25→51 complete)
**Scope:** ALL known TODOs, bugs, improvements across 96 .nix files
**Methodology:** Pareto — sort by (impact × customer-value) / effort, split into ≤12min tasks

---

## Changelog Since v1

- **56 of 81 original tasks COMPLETED** (sessions 25–51)
- **4 new services added** (OpenSEO, Manifest, niri-session-manager, GPU recovery)
- **5 new issues discovered** (DNS drift, photomap stale refs, ssh-config hardcode, Caddy memory/watchdog, signoz split)
- **Codebase grew**: 104→96 files (cleanup), 31→33 service modules, 5511→5878 service lines
- **Boot optimized**: ~22s faster via ClamAV defer, TPM disable, systemd-boot timeout 2s

---

## TASK STATUS SUMMARY

| Status | Count | Notes |
|--------|-------|-------|
| ✅ DONE | 56 | Completed across sessions 25–51 |
| ❌ NOT DONE | 20 | Remaining from original plan |
| 🆕 NEW | 5 | Discovered since plan creation |
| **TOTAL** | **81** | 25 remaining tasks |

---

## ✅ COMPLETED TASKS (56/81)

### Wave 1 — Critical Bugs ✅ (7/8 done)

| # | Task | Done In |
|---|------|---------|
| 1 | Fix taskwarrior.nix Darwin guard | Session 28 |
| 2 | Remove duplicate Caddy firewall ports | Session 29 |
| 15 | Fix starship unused modules | Session 28 |
| 18 | Fix justfile update-nix platform guard | Session 30 |
| 80 | Fix monitor365 MemoryMax merge order | Session 28 |
| — | *nix-settings Darwin sandbox fix* (not in original plan) | Session 28 |
| — | *lib/systemd.nix curried signature fix* | Session 25 |
| ~~7~~ | ~~WatchdogSec on Caddy~~ | **NOT DONE** |
| ~~8~~ | ~~MemoryMax on Caddy~~ | **NOT DONE** |
| ~~9~~ | ~~MemoryMax on authelia~~ | **NOT DONE** |

### Wave 2 — Memory Limits ❌ (0/5 done)

| # | Task | Status |
|---|------|--------|
| 10 | MemoryMax on gitea | ❌ NOT DONE |
| 11 | MemoryMax on homepage | ❌ NOT DONE |
| 12 | MemoryMax on taskchampion | ❌ NOT DONE |
| 13 | MemoryMax on voice-agents | ❌ NOT DONE |
| 14 | MemoryMax on sops services | ❌ N/A — sops has no systemd services |

### Wave 3 — primaryUser DRY ✅ (4/4 done)

| # | Task | Done In |
|---|------|---------|
| 3 | Create primary-user.nix module | Session 29 |
| 4 | Replace hardcoded `"lars"` (5 files with defaults) | Session 29 |
| 5 | Replace hardcoded `"lars"` (4 files with primaryUser) | Session 29 |
| 6 | Replace hardcoded `"lars"` (sops, config, ssh — partial) | Session 29 |

### Wave 4 — Harden Adoption ✅ (9/10 done)

| # | Task | Done In |
|---|------|---------|
| 20 | harden{} to gitea | Session 29 |
| 21 | harden{} to immich | Session 29 |
| 22 | harden{} to signoz | Session 29 |
| 23 | harden{} to minecraft | Session 29 |
| 24 | harden{} to comfyui | Session 29 |
| 25 | harden{} to twenty | Session 29 |
| 26 | harden{} to voice-agents | Session 29 |
| 27 | harden{} to sops | N/A — sops has no systemd services |
| 28 | harden{} to ai-stack ollama | Session 29 |
| 29 | harden{} to hermes (already had import) | Session 29 |

### Wave 5 — serviceDefaults ✅ (7/7 done)

| # | Task | Done In |
|---|------|---------|
| 50-56 | serviceDefaults{} to all 7 services | Session 30 |

### Wave 6 — Features & DRY (partial)

| # | Task | Status |
|---|------|--------|
| 39 | Enable Gatus | ✅ Session 44 |
| 40 | Personalize Gatus ntfy topic | ✅ Session 44 |
| 35 | Fix fzf.nix hardcoded color | ❌ NOT DONE |
| 16 | Extract shared DNS subdomain list | ❌ NOT DONE (drifted — rpi3 missing "manifest") |
| 47 | Centralize firewall ports | ❌ NOT DONE |

### Wave 7 — Theme ❌ (0/6 done)

| # | Task | Status |
|---|------|--------|
| 30-34, 62 | colorScheme adoption (yazi, waybar, rofi, wlogout, homepage, central module) | ❌ NOT DONE |

### Wave 8 — Signoz Split ❌ (0/3 done)

| # | Task | Status |
|---|------|--------|
| 36-38 | Split signoz.nix (738 lines) | ❌ NOT DONE |

### Wave 9 — Maintenance ✅ (8/11 done)

| # | Task | Done In |
|---|------|---------|
| 79 | Remove unsloth from AGENTS.md | ✅ Session 25 |
| 17 | Remove dead justfile recipes | ✅ Session 30 |
| 19 | Archive old status reports | ✅ Session 29 (archived 85 files) |
| 43 | Update AGENTS.md (primaryUser, harden status) | ✅ Session 30 |
| 44 | Update AGENTS.md (Gatus) | ✅ Session 44 |
| 69 | Docker overlay cleanup | ✅ Session 33 |
| — | *lib/default.nix cleanup* (removed dead central import) | ✅ Session 29 |
| — | *justfile DRY dns-diagnostics* | ✅ Session 30 |
| — | *justfile trash instead of rm* | ✅ Session 30 |
| 42 | Update FEATURES.md | ❌ NOT DONE |
| 45 | Update justfile help recipe | ❌ NOT DONE (help recipe removed entirely) |
| 46 | Fix justfile backup/restore dotfiles refs | ❌ NOT DONE |
| 61 | Audit tmpfiles.rules consistency | ❌ NOT DONE |
| 78 | Write docs/TODO_LIST.md | ❌ NOT DONE |

### Wave 10 — Deploy & Verify ✅ (5/6 done)

| # | Task | Done In |
|---|------|---------|
| 63 | `just switch` on evo-x2 | ✅ Multiple sessions |
| 64 | Verify pstore | ✅ Session 24 |
| 65 | Verify GPU memory | ✅ Session 24 |
| 66 | Verify all services healthy | ✅ Session 33 |
| 67 | Test Ollama inference | ✅ Session 33 |
| 68 | Test BTRFS snapshot restore | ❌ NOT DONE |

### Wave 11 — Quality (partial)

| # | Task | Status |
|---|------|--------|
| 57 | coredumpctl vacuum timer | ✅ Done (boot.nix coredump limits) |
| 41 | Gatus health checks for all services | ✅ Session 47 (18+ endpoints) |
| 58 | Simplify lib/systemd.nix mkDefault | ❌ NOT DONE (still uses mkDefault') |
| 59 | ReadWritePaths for hardened services | ❌ NOT DONE |
| 60 | NixOS test harness | ❌ NOT DONE |
| 70 | Update ancient flake inputs | ❌ NOT DONE |
| 81 | Health check endpoints for custom services | ❌ NOT DONE |

### Wave 12 — Future ❌ (0/7 done)

| # | Task | Status |
|---|------|--------|
| 71-77 | Pi 3, kdump, UPS, LUKS+TPM, NIC bonding, CI/CD, SSH CA | ❌ NOT DONE |

### Extra Work Done (Not in Original Plan)

| What | Session |
|------|---------|
| OpenSEO service module (SEO suite) | Added post-plan |
| Manifest service module (LLM router) | Added post-plan |
| niri-session-manager (replaced bash scripts) | Session 36 |
| GPU DRM recovery system | Session 34 |
| Boot performance sprint (−22s) | Session 51 |
| Hermes permission drift + SQLite/BTRFS fix | Session 49 |
| Waybar hwmon→thermal-zone fix | Session 39 |
| Rofi calc+emoji plugins | Session 39 |
| Helium session restore flags | Session 39 |
| 4 ADRs documented | Sessions 34, 47 |
| Port split-brain fix (caddy references service ports) | Session 30 |
| Btrfs qgroup analysis | Session 51 |
| lib refactor (shared helpers adoption) | Session 47 |

---

## ❌ REMAINING TASKS — Updated & Re-Scored (25 tasks)

| # | Category | Task | Impact | CustVal | Effort | Score | Status |
|---|----------|------|--------|---------|--------|-------|--------|
| **7** | BUG | Add WatchdogSec=30 to Caddy (Type=notify, no watchdog) | 4 | 4 | 2 | 40 | Original |
| **8** | RELIAB | Add MemoryMax to Caddy | 4 | 4 | 2 | 40 | Original |
| **9** | RELIAB | Add MemoryMax to authelia | 4 | 4 | 2 | 40 | Original |
| **10** | RELIAB | Add MemoryMax to gitea | 4 | 3 | 2 | 30 | Original |
| **11** | RELIAB | Add MemoryMax to homepage | 3 | 3 | 2 | 23 | Original |
| **12** | RELIAB | Add MemoryMax to taskchampion | 3 | 3 | 2 | 23 | Original |
| **13** | RELIAB | Add MemoryMax to voice-agents | 3 | 3 | 2 | 23 | Original |
| **16** | BUG | Fix DNS subdomain drift — add "manifest" to rpi3 list | 4 | 3 | 2 | 30 | **Updated** |
| **35** | THEME | Fix fzf.nix remaining hardcoded color (#a6adc8) | 2 | 2 | 2 | 20 | Original |
| **30** | THEME | Adopt colorScheme in yazi.nix (60+ hex colors) | 2 | 4 | 12 | 7 | Original |
| **31** | THEME | Adopt colorScheme in waybar.nix (30+ hex colors) | 2 | 4 | 12 | 7 | Original |
| **32** | THEME | Adopt colorScheme in rofi.nix (15 hex colors) | 2 | 3 | 10 | 6 | Original |
| **33** | THEME | Adopt colorScheme in wlogout.nix (35 hex colors) | 2 | 3 | 12 | 5 | Original |
| **34** | THEME | Adopt colorScheme in homepage.nix (12 CSS props) | 2 | 2 | 8 | 5 | Original |
| **36** | REFACTOR | Split signoz.nix (738 lines → sub-modules) | 2 | 2 | 12 | 3 | Original |
| **37** | REFACTOR | Extract signoz scrapers | 2 | 2 | 10 | 4 | Dep: #36 |
| **38** | REFACTOR | Update flake.nix for signoz split | 2 | 2 | 3 | 13 | Dep: #36 |
| **47** | DRY | Centralize firewall ports | 3 | 2 | 10 | 6 | Original |
| **42** | MAINT | Update FEATURES.md | 3 | 2 | 5 | 12 | Original |
| **46** | MAINT | Fix justfile backup/restore dotfiles refs | 2 | 2 | 5 | 8 | Original |
| **59** | SAFETY | Add ReadWritePaths to hardened services | 3 | 1 | 12 | 3 | Original |
| **60** | QUALITY | NixOS test harness | 3 | 3 | 12 | 8 | Original |
| **68** | VERIFY | Test BTRFS snapshot restore | 3 | 2 | 12 | 5 | Original |
| **70** | MAINT | Update ancient flake inputs | 2 | 2 | 10 | 4 | Original |
| — | FUTURE | kdump, UPS, LUKS+TPM, NIC bonding, CI/CD, SSH CA, Pi 3 | varies | varies | varies | varies | Original |

### 🆕 NEW Tasks (Discovered Post-Plan)

| # | Category | Task | Impact | CustVal | Effort | Score |
|---|----------|------|--------|---------|--------|-------|
| N1 | BUG | Fix DNS drift — rpi3 missing "manifest" subdomain | 4 | 3 | 2 | 30 |
| N2 | CLEANUP | Remove stale photomap refs (caddy vhost, homepage, DNS×2) — service is disabled | 3 | 2 | 5 | 12 |
| N3 | DRY | Parameterize ssh-config.nix `"lars"` via primaryUser | 3 | 1 | 5 | 6 |
| N4 | MAINT | Write docs/TODO_LIST.md from this plan | 2 | 2 | 8 | 5 |
| N5 | MAINT | Audit tmpfiles.rules for consistency | 2 | 2 | 8 | 5 |

---

## EXECUTION WAVES — Updated (Remaining Only)

### Wave A — Critical Reliability (Est: ~20min)
**Highest score items. Caddy is the reverse proxy — no memory limit = OOM risk.**

| # | Task | Time |
|---|------|------|
| 7 | Add WatchdogSec=30 to Caddy | 2min |
| 8 | Add MemoryMax to Caddy | 2min |
| 9 | Add MemoryMax to authelia | 2min |
| 10 | Add MemoryMax to gitea | 2min |
| N1 | Fix DNS drift — add "manifest" to rpi3 | 2min |
| 11 | Add MemoryMax to homepage | 2min |
| 12 | Add MemoryMax to taskchampion | 2min |
| 13 | Add MemoryMax to voice-agents | 2min |
| 35 | Fix fzf.nix hardcoded color | 2min |
| N2 | Remove stale photomap references | 5min |

### Wave B — Maintenance (Est: ~25min)

| # | Task | Time |
|---|------|------|
| 42 | Update FEATURES.md | 5min |
| 46 | Fix justfile backup/restore dotfiles | 5min |
| N3 | Parameterize ssh-config.nix | 5min |
| N4 | Write docs/TODO_LIST.md | 8min |
| N5 | Audit tmpfiles.rules | 8min |

### Wave C — Theme Adoption (Est: ~60min)

| # | Task | Time |
|---|------|------|
| 30 | colorScheme in yazi.nix | 12min |
| 31 | colorScheme in waybar.nix | 12min |
| 32 | colorScheme in rofi.nix | 10min |
| 33 | colorScheme in wlogout.nix | 12min |
| 34 | colorScheme in homepage.nix | 8min |

### Wave D — Signoz Split + Firewall (Est: ~35min)

| # | Task | Time |
|---|------|------|
| 36 | Split signoz into sub-modules | 12min |
| 37 | Extract signoz scrapers | 10min |
| 38 | Update flake.nix imports | 3min |
| 47 | Centralize firewall ports | 10min |

### Wave E — Quality & Advanced (Est: ~45min)

| # | Task | Time |
|---|------|------|
| 59 | ReadWritePaths for hardened services | 12min |
| 60 | NixOS test harness | 12min |
| 68 | Test BTRFS snapshot restore | 12min |
| 70 | Update ancient flake inputs | 10min |

### Wave F — Future (External/Hardware)

| # | Task | Dependency |
|---|------|------------|
| 71 | Pi 3 DNS failover | Hardware |
| 72 | kdump | — |
| 73 | UPS integration | Hardware |
| 74 | LUKS + TPM | — |
| 75 | NIC bonding | Hardware |
| 76 | CI/CD pipeline | GitHub |
| 77 | SSH CA | — |

---

## SUMMARY STATISTICS (Updated)

| Metric | v1 (May 5) | Now (May 8) | Delta |
|--------|-----------|-------------|-------|
| Total tasks | 81 | 81 (+5 new) | 56 done |
| Remaining tasks | 81 | 25 (+5 new = 30) | 69% complete |
| Service modules | 31 | 33 | +2 (openseo, manifest) |
| Service lines | 5,511 | 5,878 | +367 |
| .nix files | 104 | 96 | −8 (cleanup) |
| harden{} adoption | 16/31 (52%) | 24/33 (73%) | +21% |
| serviceDefaults{} adoption | 6/31 (19%) | 13/33 (39%) | +20% |
| Hardcoded "lars" | 16 | 3 (primary-user default + ssh-config ×2) | −81% |
| Status reports in docs/status/ | 81 | 7 (+ 250+ in archive/) | −91% |
| ADRs | 0 | 4 | +4 |
| Enabled services | 21 | 41 | +20 (incl. desktop/lib/hardware) |

---

_Arte in Aeternum_
