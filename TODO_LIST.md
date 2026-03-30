# SystemNix - Comprehensive TODO List

**Last Updated**: 2026-03-29
**Status**: Active

---

## Summary

| Category | Count |
|----------|-------|
| **Code TODOs** | 3 |
| **Desktop Improvements (Phase 1)** | 21 |
| **Desktop Improvements (Phase 2)** | 21 |
| **Desktop Improvements (Phase 3)** | 13 |
| **Security Hardening** | 2 |
| **Nix Architecture (Ghost Systems)** | 14 |
| **Documentation/Research** | 1 |

---

## Code TODOs (Active in Source)

### 1. Re-enable Audit Daemon (NixOS)
**File**: `platforms/nixos/desktop/security-hardening.nix:14`
**Priority**: MEDIUM | **Blocked by**: Upstream NixOS bug #483085
```nix
# TODO: Re-enable after NixOS resolves the audit-rules service bug
```
**Action**: Monitor https://github.com/NixOS/nixpkgs/issues/483085

### 2. Re-enable Audit Kernel Module (NixOS)
**File**: `platforms/nixos/desktop/security-hardening.nix:21`
**Priority**: MEDIUM | **Blocked by**: AppArmor conflicts
```nix
# TODO: Re-enable after fixing audit kernel module (AppArmor conflicts)
```
**Action**: Research and resolve AppArmor/audit compatibility

### 3. Update Home Manager Issue Reference (Darwin) — RESOLVED
**File**: `platforms/darwin/default.nix:85`
**Priority**: LOW ~~nix
# See: https://github.com/nix-community/home-manager/issues/6036
```
**Status**: Done - tracked to issue #6036 about darwin user home directory requirement

---

## Desktop Improvements (from DESKTOP-IMPROVEMENT-ROADMAP.md)

### Phase 1: High Priority (21 items)

#### Config Reloader
- [ ] **Add hot-reload capability** - Ctrl+Alt+R keybinding for Hyprland config reload
  - **File**: `platforms/nixos/desktop/hyprland.nix`
  - **Time**: 10min | **Impact**: High

#### Privacy & Locking (7 items)
- [ ] Add blur effect for lock screen (hyprlock blur) - 1h
- [ ] Add privacy mode (grayscale screen toggle) - 1h
- [ ] Add screenshot detection indicator in Waybar - 1h
- [ ] Add lock screen with camera preview - 1h
- [ ] Add per-workspace privacy mode - 1h
- [ ] Add temporary privacy toggle (Ctrl+Alt+P) - 1h
- [ ] Add visual feedback when taking screenshots - 1h

#### Productivity Scripts (5 items)
- [ ] Create Quake Terminal dropdown script (F12) - 2h
- [ ] Create Screenshot + OCR script (extract text) - 2h
- [ ] Create Color Picker script - 2h
- [ ] Create Clipboard History Viewer - 2h
- [ ] Create App Workspace Spawner - 2h

#### Monitoring (5 items)
- [ ] Add GPU temperature module (AMD GPU) - 1.5h
- [ ] Add CPU usage module (per-core) - 1.5h
- [ ] Add Memory usage module (used/total) - 1.5h
- [ ] Add Network bandwidth module (up/down) - 1.5h
- [ ] Add Disk usage module (key mount points) - 1.5h

#### Window Management (4 items)
- [ ] Add Scratchpad Workspaces (Alt+S) - 30m
- [ ] Add Better Floating Rules (size/position defaults) - 30m
- [ ] Add Focus Follows Mouse toggle - 30m
- [ ] Add Auto Back-and-Forth toggle - 30m

### Phase 2: Medium Priority (21 items)

#### Keyboard & Input (4 items)
- [ ] Optimize keyboard repeat rate (faster typing) - 20m
- [ ] Map Caps Lock to Escape/Control - 20m
- [ ] Add keyboard layout switcher in Waybar - 20m
- [ ] Improve trackpad gestures (3-finger swipe) - 20m

#### Audio & Media (7 items)
- [ ] Add audio visualizer (real-time) - 1h
- [ ] Add microphone status indicator - 1h
- [ ] Add media player integration (Now playing) - 1h
- [ ] Add volume control with visual feedback - 1h
- [ ] Add per-app volume control - 1h
- [ ] Add noise suppression toggle - 1h
- [ ] Add Bluetooth device switcher - 1h

#### Dev Tools (4 items)
- [ ] Add Git branch display in Waybar - 1h
- [ ] Add terminal multiplexer integration (tmux/zellij) - 1h
- [ ] Add editor-specific window rules (nvim/vscode) - 1h
- [ ] Create dev environment launcher - 1h

#### Desktop Environment (4 items)
- [ ] Add better window borders and shadows - 30m
- [ ] Tune animations (smoother transitions) - 30m
- [ ] Add workspace naming persistence - 30m
- [ ] Add application autostart management - 30m

### Phase 3: Long-term (13 items)

#### Backup & Config (4 items)
- [ ] Create automated config backups (hourly/daily) - 3h
- [ ] Add workspace state preservation (remember apps) - 3h
- [ ] Create one-click config sync (multiple machines) - 3h
- [ ] Add config versioning with rollback - 3h

#### Gaming (4 items)
- [ ] Create game mode toggle (disable compositor) - 2h
- [ ] Add GPU optimization profiles - 2h
- [ ] Add frame rate statistics in Waybar - 2h
- [ ] Add game-specific workspace themes - 2h

#### Window Rules (4 items)
- [ ] Add auto-group similar windows (tabs) - 1h
- [ ] Add per-application layout rules - 1h
- [ ] Add smart window positioning - 1h
- [ ] Add window grouping by workflow - 1h

#### AI Integration (4 items)
- [ ] Add AI-powered workspace suggestions - 8h+
- [ ] Add smart window arrangement - 8h+
- [ ] Add voice command integration - 8h+
- [ ] Add activity-based automation - 8h+

---

## Nix Architecture (from nix-architecture-refactoring-plan.md)

### 1% Effort (51% Value) - Critical
- [ ] Import core/Types.nix in flake - 15min
- [ ] Import core/State.nix in flake - 15min
- [ ] Import core/Validation.nix in flake - 15min
- [ ] Enable TypeSafetySystem in flake - 30min

### 4% Effort (13% Additional Value) - High Impact
- [ ] Consolidate user config (eliminate split brain) - 45min
- [ ] Consolidate path config - 30min
- [ ] Enable SystemAssertions - 30min
- [ ] Enable ModuleAssertions - 30min

### 20% Effort (16% Additional Value) - Comprehensive
- [ ] Split system.nix (397 lines → 3 files) - 90min
- [ ] Replace bool with State enum - 60min
- [ ] Replace debug bool with LogLevel enum - 45min
- [ ] Split BehaviorDrivenTests.nix - 60min
- [ ] Split ErrorManagement.nix - 60min
- [ ] Add ConfigAssertions integration - 45min

---

## Security Hardening Tasks

- [ ] Research audit kernel module compatibility issues - 2-4h
- [ ] Test with NixOS current kernel version - 30min
- [ ] Re-enable if compatibility issues resolved - 15min
- [ ] Document reason if permanently disabled - 30min

---

## Bluetooth Setup (NixOS)

- [ ] Rebuild NixOS - Required for kernel modules
- [ ] Reboot - Required for Bluetooth kernel modules to load
- [ ] Pair with Nest Audio - Use blueman-manager or bluetoothctl
- [ ] Set Nest Audio as Default Audio Output - Use pactl or pavucontrol
- [ ] Test audio output - Play test sound or music
- [ ] Enable auto-connect for Nest Audio
- [ ] Test Bluetooth range - Walk around
- [ ] Check A2DP profile active - pactl list cards

---

## Research & Investigation

- [ ] Research TouchID authentication extensions for macOS - 2-3h
  - **Source**: `platforms/darwin/security/pam.nix:7`
  - **Question**: Are there other touchIdAuth services to enable?

---

## Verification Commands

```bash
# Find TODOs in source code
grep -rn "TODO\|FIXME\|XXX\|HACK" \
  --include="*.nix" --include="*.sh" \
  --exclude-dir=.git --exclude-dir=.crush \
  --exclude-dir=patches \
  .

# List all markdown files in docs/status/
ls -la docs/status/*.md | wc -l

# List all planning documents
ls -la docs/planning/*.md | wc -l
```

---

## Notes

- Desktop improvements sourced from `DESKTOP-IMPROVEMENT-ROADMAP.md`
- Architecture tasks sourced from `2025-11-15_14-10-nix-architecture-refactoring-plan.md`
- Code TODOs are the only items with inline markers in source files
- Planning document tasks are high-level and may need refinement before execution

---

**Total Tracked Items**: ~75+ actionable tasks across all categories
