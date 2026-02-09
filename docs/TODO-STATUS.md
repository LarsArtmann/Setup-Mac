# TODO Registry

Comprehensive registry of all TODO and FIXME markers across the codebase.

**Last Updated**: 2026-01-13
**Total TODOs**: 10 items
**Status**: Active (all items tracked)

---

## 📊 Summary

- **High Priority**: 3 items (security, sandbox, networking)
- **Medium Priority**: 4 items (refactoring, research, architecture)
- **Low Priority**: 3 items (documentation, future enhancements)

---

## 🚨 High Priority TODOs

### 1. Fix Audit Kernel Module (NixOS)

**File**: `platforms/nixos/desktop/security-hardening.nix`
**Line**: 11, 18
**Marker**: `# TODO: Re-enable after fixing audit kernel module`
**Priority**: HIGH
**Category**: Security

**Context**:
Audit kernel module was disabled for compatibility reasons, but should be re-enabled for proper security hardening.

**Action Items**:

1. Research audit kernel module compatibility issues
2. Test with NixOS current kernel version
3. Re-enable if compatibility issues resolved
4. Document reason if permanently disabled

**Related Files**:

- `docs/status/2026-01-13_17-40_DEEP-RESEARCH-COMPREHENSIVE-ANALYSIS.md` (item: "badly done - no disaster recovery")
- `platforms/nixos/desktop/security-hardening.nix` (lines 11, 18)

**Est. Effort**: 2-4 hours

---

### 2. Fix Sandbox Override (Darwin)

**File**: `platforms/darwin/nix/settings.nix`
**Line**: 3
**Marker**: `# TODO: Refactor to properly override sandbox setting`
**Priority**: HIGH
**Category**: Security / Nix Configuration

**Context**:
Current sandbox override implementation is not following proper Nix best practices. Should use correct override mechanism.

**Action Items**:

1. Research proper sandbox configuration for nix-darwin
2. Implement correct override using lib.mkForce or similar
3. Test that sandbox settings apply correctly
4. Remove anti-pattern code (if any)

**Related Files**:

- `platforms/darwin/nix/settings.nix` (line 3)
- Nix-darwin documentation for sandbox settings

**Est. Effort**: 4-6 hours

---

### 3. Add Darwin-Specific Networking Settings

**File**: `platforms/darwin/networking/default.nix`
**Line**: 5
**Marker**: `# TODO: Add any Darwin-specific networking settings here`
**Priority**: MEDIUM
**Category**: Networking / Configuration

**Context**:
Darwin networking configuration file is mostly empty. Should populate with macOS-specific networking settings.

**Action Items**:

1. Research macOS networking settings via nix-darwin
2. Add common networking configuration (DNS, firewall, proxies)
3. Document differences between Darwin and NixOS networking
4. Test networking changes on macOS

**Related Files**:

- `platforms/darwin/networking/default.nix` (line 5)
- `platforms/nixos/networking.nix` (for comparison)

**Est. Effort**: 2-3 hours

---

## 📝 Medium Priority TODOs

### 4. Re-enable Hyprland Type Safety Assertions

**File**: `platforms/nixos/desktop/hyprland.nix`
**Line**: 6
**Marker**: `# TODO: Re-enable type safety assertions once path is fixed`
**Priority**: MEDIUM
**Category**: Type Safety / Ghost Systems

**Context**:
Type safety assertions for Hyprland configuration were disabled due to path issues. Should be re-enabled once path resolution is fixed.

**Action Items**:

1. Investigate path resolution issues
2. Fix underlying path problem
3. Re-enable type safety assertions
4. Verify assertions pass

**Related Files**:

- `platforms/nixos/desktop/hyprland.nix` (line 6)
- `platforms/common/core/Types.nix` (type definitions)
- `platforms/common/core/SystemAssertions.nix` (assertion framework)

**Est. Effort**: 3-4 hours

---

### 5. Research TouchID Authentication Extensions

**File**: `platforms/darwin/security/pam.nix`
**Line**: 7
**Marker**: `# TODO: Are there other touchIdAuth's we should enable? RESEARCH REQUIRED`
**Priority**: MEDIUM
**Category**: Security / macOS

**Context**:
Current PAM configuration enables TouchID for sudo, but there may be other services that could benefit from TouchID authentication.

**Action Items**:

1. Research all available touchIdAuth options for macOS
2. Identify which services should use TouchID authentication
3. Test additional touchIdAuth configurations
4. Document security implications

**Related Files**:

- `platforms/darwin/security/pam.nix` (line 7)
- macOS TouchID documentation
- nix-darwin security options

**Est. Effort**: 2-3 hours

---

### 6. Move Terminal Environment to Dedicated Config

**File**: `platforms/darwin/environment.nix`
**Line**: 13
**Marker**: `TERMINAL = "iTerm2"; ## TODO: <-- should we move this to dedicated iterm2 config?`
**Priority**: LOW
**Category**: Refactoring / Architecture

**Context**:
Terminal environment variable is mixed in with general environment settings. Should be moved to dedicated iTerm2 configuration file.

**Action Items**:

1. Create dedicated iTerm2 configuration file
2. Move TERMINAL environment variable to iTerm2 config
3. Update import if needed
4. Test that iTerm2 still works correctly

**Related Files**:

- `platforms/darwin/environment.nix` (line 13)
- Potential: `platforms/darwin/programs/iterm2.nix` (new file)

**Est. Effort**: 1-2 hours

---

### 7. Move Nixpkgs Configuration to Common

**File**: `platforms/darwin/default.nix`
**Line**: 16
**Marker**: `## TODO: Should we move these nixpkgs configs to ../common/?`
**Priority**: LOW
**Category**: Architecture / Refactoring

**Context**:
Nixpkgs configuration (allowUnfree, allowBroken) is duplicated between Darwin and NixOS. Should be moved to shared common configuration.

**Action Items**:

1. Create `platforms/common/nixpkgs-config.nix`
2. Move allowUnfree, allowBroken settings to common config
3. Update Darwin and NixOS to import common config
4. Test that both platforms still work

**Related Files**:

- `platforms/darwin/default.nix` (line 16)
- `platforms/nixos/system/configuration.nix` (has nixpkgs.config)
- `flake.nix` (perSystem nixpkgs config)

**Est. Effort**: 2-3 hours

---

## 🔧 Low Priority / Future TODOs

### 8. Move Activation Script to Environment Module

**File**: `platforms/darwin/system/activation.nix`
**Line**: 36
**Marker**: `## TODO: Why is this not in platforms/darwin/environment.nix?`
**Priority**: LOW
**Category**: Architecture / Code Organization

**Context**:
Activation script contains environment settings that could be in dedicated environment module. Need to investigate why it's separate.

**Action Items**:

1. Understand reason for separation (if any)
2. Move environment settings to `platforms/darwin/environment.nix` if appropriate
3. Update activation script to import environment module
4. Test that activation still works

**Related Files**:

- `platforms/darwin/system/activation.nix` (line 36)
- `platforms/darwin/environment.nix` (target location)

**Est. Effort**: 1-2 hours

---

### 9. Migrate ActivityWatch to Nix Package

**File**: `platforms/darwin/services/launchagents.nix`
**Line**: 13
**Marker**: `# TODO: Migrate ActivityWatch to Nix package when available (currently only in unstable)`
**Priority**: LOW
**Category**: Migration / Nix Packages

**Context**:
ActivityWatch is installed via Homebrew but should be managed by Nix. Currently only available in Nixpkgs unstable channel.

**Action Items**:

1. Check if ActivityWatch is now in stable Nixpkgs
2. If yes, add to common/packages/base.nix
3. Remove LaunchAgent configuration (will be managed by Nix)
4. Test ActivityWatch installation
5. Update documentation

**Related Files**:

- `platforms/darwin/services/launchagents.nix` (line 13)
- `platforms/common/packages/base.nix` (add package here)
- `platforms/common/programs/activitywatch.nix` (update if needed)

**Est. Effort**: 2-3 hours

---

### 10. Fix LaunchAgent Working Directory

**File**: `platforms/darwin/services/launchagents.nix`
**Lines**: 5
**Marker**: Implicit (comment in code about userHome fallback)
**Priority**: MEDIUM
**Category**: Security / Configuration

**Context**:
LaunchAgent configuration uses fallback for `config.users.users.larsartmann.home`. This workaround was removed from `platforms/darwin/default.nix` (2026-01-13), but LaunchAgent still references it with fallback.

**Action Items**:

1. Test if LaunchAgent works without workaround
2. If yes, remove fallback and use direct reference
3. If no, investigate proper way to get user home directory
4. Update documentation accordingly

**Related Files**:

- `platforms/darwin/services/launchagents.nix` (line 5)
- `platforms/darwin/default.nix` (workaround removed)
- `docs/reports/home-manager-users-workaround-bug-report.md` (analysis)

**Est. Effort**: 1-2 hours

---

## 📊 Statistics

### By Priority

- **High Priority**: 3 items (30%)
- **Medium Priority**: 4 items (40%)
- **Low Priority**: 3 items (30%)

### By Category

- **Security**: 2 items (20%)
- **Architecture**: 3 items (30%)
- **Nix Configuration**: 2 items (20%)
- **Type Safety**: 1 item (10%)
- **Migration**: 1 item (10%)
- **Networking**: 1 item (10%)

### By Platform

- **Darwin**: 5 items (50%)
- **NixOS**: 3 items (30%)
- **Common**: 2 items (20%)

---

## ✅ Completed TODOs (for reference)

The following TODOs have been resolved and are tracked for historical purposes:

1. ✅ **Remove Home Manager users definition workaround** (2026-01-13)
   - Resolved by testing without workaround
   - Bug report created: `docs/reports/home-manager-users-workaround-bug-report.md`

2. ✅ **Migrate setup-animated-wallpapers.sh to Nix** (2026-01-13)
   - Resolved by using existing Nix module: `platforms/nixos/modules/hyprland-animated-wallpaper.nix`
   - Script archived to `scripts/archive/setup-animated-wallpapers.sh`

3. ✅ **Migrate uBlock Origin setup to Nix** (2026-01-13)
   - Resolved by creating `platforms/common/programs/ublock-filters.nix`
   - Partial migration (filter lists), script still useful for backup/restore

4. ✅ **Archive December 2025 status reports** (2026-01-13)
   - Moved 30 status reports to `docs/archive/status/`
   - Reduced documentation bloat from 41 to 11 active status reports

---

## 🎯 Next Steps

**Immediate Priority (This Week)**:

1. Fix audit kernel module (HIGH - security)
2. Fix sandbox override (HIGH - security)
3. Test LaunchAgent working directory (MEDIUM - may break services)

**Short Term Priority (This Month)**: 4. Add Darwin networking settings (MEDIUM) 5. Research TouchID authentication (MEDIUM) 6. Re-enable Hyprland type safety (MEDIUM)

**Long Term Priority (This Quarter)**: 7. Move terminal environment to dedicated config (LOW) 8. Move Nixpkgs config to common (LOW) 9. Migrate ActivityWatch to Nix (LOW) 10. Move activation script to environment module (LOW)

---

## 📋 Tracking

This TODO registry is maintained as part of the Setup-Mac project. All TODOs should be:

1. Tracked in this document
2. Linked to related files
3. Categorized by priority
4. Resolved and marked as completed

**TODO Removal Policy**: When a TODO is completed, move it to "Completed TODOs" section rather than deleting the entry. This provides historical tracking of technical debt resolution.

---

**Last Scan**: 2026-01-13
**Next Scan**: After next major refactoring milestone
**Maintainer**: Lars Artmann (Setup-Mac project)
