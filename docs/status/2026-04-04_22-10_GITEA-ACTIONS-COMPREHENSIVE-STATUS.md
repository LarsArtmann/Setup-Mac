# SystemNix: Comprehensive Executive Status Report

**Date:** 2026-04-04 22:10  
**Session Focus:** Gitea Actions (CI/CD) enablement  
**Platform:** NixOS `evo-x2` (x86_64-linux) + macOS `Lars-MacBook-Air` (aarch64-darwin)

---

## a) FULLY DONE ✅

### Gitea Actions CI/CD (THIS SESSION)

Enabled full Gitea Actions pipeline in `modules/nixos/services/gitea.nix`:

| Component | Status | Details |
|-----------|--------|---------|
| Server-side Actions | ✅ | `actions.ENABLED = true`, `DEFAULT_ACTIONS_URL = "github"` |
| Runner token auto-gen | ✅ | `gitea-runner-token` systemd oneshot, idempotent, uses `gitea actions generate-runner-token` |
| act-runner service | ✅ | `services.gitea-actions-runner` instance named `evo-x2` |
| Docker labels | ✅ | `ubuntu-latest:docker://node:22-bookworm`, `ubuntu-22.04:docker://node:22-bookworm` |
| Native host label | ✅ | `native:host` for NixOS-native CI jobs |
| Systemd dependencies | ✅ | Runner requires `gitea-runner-token.service`, starts after token gen |
| Syntax validation | ✅ | `just test-fast` passes — all NixOS modules + flake checks clean |

### ActivityWatch Dark Theme (THIS SESSION)

- Added `activitywatch-theme` systemd user service in `platforms/common/programs/activitywatch.nix`
- Sets theme to dark via API (`PUT /api/0/settings/theme`) after AW starts

### Existing Infrastructure (All Verified Working)

| Service | Module | Status |
|---------|--------|--------|
| Docker | `modules/nixos/services/default.nix` | ✅ Running, overlay2 on /data/docker |
| Gitea | `modules/nixos/services/gitea.nix` | ✅ SQLite, LFS, weekly backups, admin provisioned |
| Gitea Mirror | Same module | ✅ GitHub → Gitea every 6h, 30min cron sync |
| Gitea Repos | `modules/nixos/services/gitea-repos.nix` | ✅ Declarative repo management |
| Caddy | `modules/nixos/services/caddy.nix` | ✅ Reverse proxy with TLS via sops |
| Grafana | `modules/nixos/services/grafana.nix` | ✅ Dashboards + Prometheus |
| Prometheus | `modules/nixos/services/monitoring.nix` | ✅ Metrics collection + exporters |
| Homepage | `modules/nixos/services/homepage.nix` | ✅ Service dashboard |
| Immich | `modules/nixos/services/immich.nix` | ✅ Photo/video management |
| SigNoz | `modules/nixos/services/signoz.nix` | ✅ Observability (OTel traces/metrics/logs) |
| PhotoMap | `modules/nixos/services/photomap.nix` | ✅ AI photo geolocation |
| sops-nix | `modules/nixos/services/sops.nix` | ✅ Age-encrypted secrets via SSH host key |
| Niri | `platforms/nixos/desktop/niri-config.nix` | ✅ Primary Wayland compositor |
| Waybar | `platforms/nixos/desktop/waybar.nix` | ✅ Status bar |
| SDDM + SilentSDDM | `platforms/nixos/desktop/display-manager.nix` | ✅ Login manager |
| AMD GPU | `platforms/nixos/hardware/amd-gpu.nix` | ✅ ROCm/Vulkan/VAAPI |
| AMD NPU | `platforms/nixos/hardware/amd-npu.nix` | ✅ XDNA driver (Ryzen AI Strix Halo) |
| DNS Blocker | `platforms/nixos/system/dns-blocker-config.nix` | ✅ Unbound + dnsblockd, 2.5M+ domains |
| AI Stack | `platforms/nixos/desktop/ai-stack.nix` | ✅ Ollama, Unsloth, LLM tools |
| Security | `platforms/nixos/desktop/security-hardening.nix` | ✅ AppArmor, fail2ban, ClamAV |
| BTRFS Snapshots | `platforms/nixos/system/snapshots.nix` | ✅ Timeshift |
| SSH Server | `platforms/nixos/system/configuration.nix` | ✅ Keys-only, fail2ban |
| Fish Shell | Cross-platform | ✅ Default shell on both platforms |
| Starship | Cross-platform | ✅ Prompt on both platforms |
| 14 Common Programs | `platforms/common/programs/` | ✅ Shared across macOS + NixOS |
| Justfile | Root | ✅ 88 recipes, comprehensive task runner |
| Pre-commit | `platforms/common/programs/pre-commit.nix` | ✅ Hooks configured |
| Helium Browser | Flake overlay | ✅ Widevine + VAAPI wrapped |
| 20 Flake Inputs | `flake.nix` | ✅ All active, no commented-out |

---

## b) PARTIALLY DONE 🔶

| Item | Status | What's Missing |
|------|--------|----------------|
| Gitea Actions | 🔶 Code done, not deployed | Needs `just switch` on evo-x2, verify runner appears in UI |
| CI/CD (GitHub Actions) | 🔶 Workflow exists but broken | `nix-check.yml` uses outdated actions (v22/v12), no `--no-build` flag, no NixOS build job |
| Security hardening | 🔶 Mostly done | 2 TODOs: auditd disabled (nixpkgs#483085), audit rules disabled (AppArmor conflict) |
| Monitoring | 🔶 Prometheus scrapes | No alert rules defined — no proactive notification |
| ActivityWatch | 🔶 Service + theme done | No custom watchers, utilization watcher pkg exists but may need testing |

---

## c) NOT STARTED ⬜

| Item | Priority | Notes |
|------|----------|-------|
| Gitea Actions: deploy & verify | P0 | `just switch` then check runner at `http://gitea.lan/admin/actions/runners` |
| Gitea Actions: example workflow | P1 | Create a `.gitea/workflows/test.yml` in a repo to validate end-to-end |
| CI workflow fix | P1 | Update actions, add `--no-build`, add NixOS syntax check |
| Alert rules for Prometheus | P2 | Define alertmanager rules for disk/CPU/service failures |
| NixOS VM tests | P2 | No `nixosTests` exist — would catch regressions before deploy |
| Stale flake input cleanup | P2 | `nix-colors` (Feb 2024), `nix-visualize` (Jan 2024) are 2+ years old |
| `docs/STATUS.md` update | P2 | 3+ months stale, still references Hyprland |
| `pkgs/superfile.nix` verification | P3 | Exists but not referenced in flake.nix — orphaned? |
| Root cleanup | P3 | `download_glm_model.py` at repo root, purpose unclear |
| Docs cleanup | P3 | ~100+ status reports in `docs/status/`, many should be archived |

---

## d) TOTALLY FUCKED UP 💥

| Issue | Severity | Impact | File/Location |
|-------|----------|--------|---------------|
| `docs/STATUS.md` is 3+ months stale | 🔴 High | Misleading project state, references Hyprland (replaced by Niri months ago) | `docs/STATUS.md` |
| CI workflow will fail on full builds | 🔴 High | `nix flake check` without `--no-build` on macOS runner tries to build Linux closure | `.github/workflows/nix-check.yml` |
| CI actions are 10+ versions behind | 🟡 Medium | `cachix/install-nix-action@v22` (current v31+), `cachix/cachix-action@v12` (current v16+) | `.github/workflows/nix-check.yml` |
| No NixOS build in CI at all | 🟡 Medium | Only Darwin build job — NixOS config never tested in CI | `.github/workflows/nix-check.yml` |
| 2 TODOs blocking full security hardening | 🟡 Medium | auditd + audit rules disabled due to upstream NixOS bugs | `platforms/nixos/desktop/security-hardening.nix:14,21` |

---

## e) WHAT WE SHOULD IMPROVE 📈

1. **CI pipeline is essentially non-functional** — update actions, add `--no-build`, add NixOS syntax check
2. **No automated testing** — no NixOS VM tests, no integration tests, no flake checks beyond syntax
3. **Documentation rot** — `docs/STATUS.md` 3+ months stale, ~100 status reports piling up, many referencing dead concepts (Hyprland, Setup-Mac)
4. **No alerting** — Prometheus collects metrics but nobody gets notified when things break
5. **Stale flake inputs** — 3 inputs 1-2.5 years old, may break with nixpkgs updates
6. **Orphaned code** — `pkgs/superfile.nix`, `download_glm_model.py`, `.buildflow.yml`
7. **Go version inconsistency** — overlay pins `go_1_26` but SigNoz builds with `go_1_25`
8. **No Gitea Actions example** — CI/CD is enabled but no workflow to validate it works end-to-end
9. **Hyprland remnants** — old validation scripts, status reports, config references still exist
10. **No secret rotation strategy** — tokens generated once, no rotation/expiry mechanism

---

## f) TOP 25 THINGS TO DO NEXT

| # | Priority | Task | Effort |
|---|----------|------|--------|
| 1 | P0 | **Deploy Gitea Actions**: `just switch` on evo-x2, verify runner online | 5min |
| 2 | P0 | **Create example Gitea workflow**: `.gitea/workflows/test.yml` in a test repo | 15min |
| 3 | P0 | **Fix CI workflow**: update actions to v31/v16, add `--no-build` | 30min |
| 4 | P1 | **Add NixOS syntax check to CI**: separate `--no-build` job for Linux | 15min |
| 5 | P1 | **Update `docs/STATUS.md`**: reflect current state (Niri, DNS blocker, all services) | 30min |
| 6 | P1 | **Resolve auditd TODOs**: check if nixpkgs#483085 is fixed, re-enable | 15min |
| 7 | P1 | **Add Prometheus alert rules**: disk >90%, service down, CPU sustained >80% | 1hr |
| 8 | P1 | **Clean stale flake inputs**: update or remove `nix-colors`, `nix-visualize` | 30min |
| 9 | P1 | **Verify/remove `pkgs/superfile.nix`**: orphaned package | 5min |
| 10 | P1 | **Remove `download_glm_model.py`** from repo root | 2min |
| 11 | P1 | **Align Go versions**: make SigNoz use same Go as overlay | 30min |
| 12 | P2 | **Archive old status reports**: move 80+ reports to `docs/status/archive/` | 15min |
| 13 | P2 | **Add NixOS VM test**: basic service startup test | 2hr |
| 14 | P2 | **Remove Hyprland remnants**: old validation scripts, status reports | 30min |
| 15 | P2 | **Add Gitea runner token rotation**: systemd timer to regenerate periodically | 1hr |
| 16 | P2 | **Consolidate monitoring dashboards**: single Grafana overview for all services | 1hr |
| 17 | P2 | **Add `just gitea-actions-status` recipe**: check runner health from CLI | 15min |
| 18 | P2 | **Implement Docker image caching** for Gitea runner: pre-pull node:22-bookworm | 15min |
| 19 | P2 | **Review `.buildflow.yml`**: determine if still needed | 5min |
| 20 | P3 | **Add sops secret for runner token**: move from plaintext file to sops-nix | 1hr |
| 21 | P3 | **Create backup/restore for Gitea Actions state**: runner registration data | 30min |
| 22 | P3 | **Add `just health` checks for CI/CD**: runner status, queue depth | 15min |
| 23 | P3 | **Document Gitea Actions usage**: how to write workflows, available labels | 30min |
| 24 | P3 | **Investigate Forgejo runner**: compare features with gitea-actions-runner | 1hr |
| 25 | P3 | **Clean up `scripts/` directory**: audit all scripts, remove orphans | 1hr |

---

## g) MY TOP #1 QUESTION ❓

**Should the Gitea runner token be managed via sops-nix instead of auto-generated at runtime?**

The current approach auto-generates the runner registration token into `/var/lib/gitea/.runner-token` via a systemd oneshot. This is convenient but means:
- The token is plaintext on disk
- Token is lost on `gitea.stateDir` wipe
- No rotation without manual intervention
- Can't be shared across machines declaratively

Alternative: store the token in `secrets.yaml` via sops-nix (like existing `gitea_token`, `github_token`). This would be more consistent with the existing secret management pattern. However, it requires manually generating the token first (via `gitea actions generate-runner-token`) and storing it.

---

## File Changes This Session

| File | Lines Changed | Description |
|------|---------------|-------------|
| `modules/nixos/services/gitea.nix` | +77 | Enabled Gitea Actions + act-runner + token auto-generation |
| `platforms/common/programs/activitywatch.nix` | +18 | Added dark theme systemd user service |
| `docs/status/2026-04-04_22-10_GITEA-ACTIONS-COMPREHENSIVE-STATUS.md` | +new | This report |

## Git Diff Summary

```
 modules/nixos/services/gitea.nix            | 77 +++++++++++++++++++++++++++++
 platforms/common/programs/activitywatch.nix | 18 ++++++-
 2 files changed, 94 insertions(+), 1 deletion(-)
```
