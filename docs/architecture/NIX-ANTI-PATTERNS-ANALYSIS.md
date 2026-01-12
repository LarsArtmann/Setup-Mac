# Nix Anti-Patterns Analysis Report

**Date:** 2026-01-12
**Analysis:** Comprehensive review of Setup-Mac codebase for Nix anti-patterns

## Executive Summary

This analysis identifies multiple areas where the codebase is **fighting Nix** instead of leveraging it. The codebase mixes declarative Nix configuration with imperative shell scripts, manual file linking, and external package management, which undermines Nix's core benefits of reproducibility, immutability, and declarative configuration.

**Key Findings:**
- 🚨 **Critical**: Manual dotfiles management bypassing Home Manager
- 🚨 **Critical**: Imperative LaunchAgent setup instead of nix-darwin module
- ⚠️ **High**: Homebrew packages that should be in Nix
- ⚠️ **High**: Complex bash scripts duplicating Nix capabilities
- ℹ️ **Medium**: Over-engineered wrapper system
- ℹ️ **Medium**: Scattered environment variable configuration

---

## Critical Issues (P0 - Must Fix)

### 1. Manual Dotfiles Linking Instead of Home Manager

**Location:** `scripts/manual-linking.sh`

**Problem:**
```bash
# ❌ Manual symlink creation with bash
verified_link "$CURRENT_DIR/dotfiles/.ssh/config" ~/.ssh/config
verified_link "$CURRENT_DIR/dotfiles/.bash_profile" ~/.bash_profile
verified_link "$CURRENT_DIR/dotfiles/.zshrc" ~/.zshrc
verified_link "$CURRENT_DIR/dotfiles/.gitconfig" ~/.gitconfig
verified_link "$CURRENT_DIR/dotfiles/.config/starship.toml" ~/.config/starship.toml
```

**Why This Is Fighting Nix:**
- Nix/ Home Manager has built-in `home.file` and `home.xdg.configFile` for this exact purpose
- Manual linking is fragile, error-prone, and not reproducible
- Breaks atomic updates and rollback capabilities
- Mixes imperative and declarative paradigms

**Leveraging Nix Solution:**
```nix
# ✅ Declarative file management via Home Manager
{
  home.file.".ssh/config" = {
    source = ../dotfiles/.ssh/config;
  };

  home.xdg.configFile."starship.toml" = {
    source = ../dotfiles/.config/starship.toml;
  };

  # Or even better: use Home Manager programs directly
  programs.starship = {
    enable = true;
    settings = { /* ... */ };
  };
}
```

**Impact:**
- **Reproducibility**: ❌ Manual linking varies per system
- **Atomic Updates**: ❌ Symlinks can be broken during updates
- **Rollback**: ❌ No rollback capability for manual changes
- **Maintenance**: ❌ Must maintain bash script + Nix config

---

### 2. Imperative LaunchAgent Setup Instead of nix-darwin Module

**Location:** `scripts/nix-activitywatch-setup.sh`

**Problem:**
```bash
# ❌ Imperative LaunchAgent creation
cat > "$LAUNCH_AGENT_PLIST" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>net.activitywatch.ActivityWatch</string>
    <!-- ... -->
</dict>
</plist>
EOF

launchctl load -w "$LAUNCH_AGENT_PLIST" 2>/dev/null
```

**Why This Is Fighting Nix:**
- nix-darwin has native `launchd.agents` module for declarative service management
- Manual creation bypasses Nix's activation system
- Breaks atomic updates and rollback
- Creates imperative state outside Nix's control

**Leveraging Nix Solution:**
```nix
# ✅ Declarative LaunchAgent management
{
  launchd.agents = {
    "net.activitywatch.ActivityWatch" = {
      enable = true;
      config = {
        ProgramArguments = [
          "${pkgs.activitywatch}/bin/aw-qt"
          "--background"
        ];
        RunAtLoad = true;
        KeepAlive = {
          SuccessfulExit = false;
        };
        ProcessType = "Background";
      };
    };
  };
}
```

**Impact:**
- **Declarative**: ❌ Manual script vs ✅ Nix module
- **Reproducible**: ❌ System-specific vs ✅ Nix-controlled
- **Atomic**: ❌ Manual load/unload vs ✅ Nix activation
- **Package References**: ❌ Hardcoded paths vs ✅ Nix store paths

---

### 3. Hardcoded System Paths

**Location:** Multiple scripts

**Problem:**
```bash
# ❌ Hardcoded paths
ACTIVITYWATCH_APP="/Applications/ActivityWatch.app"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
```

**Why This Is Fighting Nix:**
- Nix packages have store paths like `/nix/store/...-package-name`
- Hardcoded paths break if packages change or update
- Not reproducible across systems

**Leveraging Nix Solution:**
```nix
# ✅ Nix store paths are automatically resolved
{
  launchd.agents = {
    "net.activitywatch.ActivityWatch" = {
      config = {
        ProgramArguments = [
          "${pkgs.activitywatch}/bin/aw-qt"  # ✅ Nix store path
        ];
      };
    };
  };
}
```

---

## High Priority Issues (P1 - Should Fix)

### 4. Duplicate Nushell Configuration

**Location:** `scripts/manual-linking.sh`

**Problem:**
```bash
# ❌ Same config linked to two locations
verified_link "$CURRENT_DIR/dotfiles/.config/nushell/aliases.nu" ~/.config/nushell/aliases.nu
verified_link "$CURRENT_DIR/dotfiles/.config/nushell/config.nu" "$HOME/Library/Application Support/nushell/config.nu"
```

**Why This Is Fighting Nix:**
- Nushell looks in both locations - only need one
- Redundant configuration management
- Home Manager can handle this correctly

**Leveraging Nix Solution:**
```nix
# ✅ Single source of truth
{
  programs.nushell = {
    enable = true;
    envFile.text = '';
    configFile.text = ''
      # Nushell config
    '';
    envVarFile.text = '';
  };
}
```

---

### 5. Darwin System Files Linked Manually

**Location:** `scripts/manual-linking.sh`

**Problem:**
```bash
# ❌ Manual linking to /etc/nix-darwin/
verified_link "$CURRENT_DIR/dotfiles/nix/core.nix" /etc/nix-darwin/core.nix
verified_link "$CURRENT_DIR/dotfiles/nix/environment.nix" /etc/nix-darwin/environment.nix
```

**Why This Is Fighting Nix:**
- These should be imported as Nix modules, not symlinked
- Bypasses nix-darwin's module system
- Manual file management vs declarative imports

**Leveraging Nix Solution:**
```nix
# ✅ Proper module imports
{
  imports = [
    ./core.nix
    ./environment.nix
    ./system.nix
  ];
}
```

---

### 6. Multiple Bash Setup Scripts

**Location:** `scripts/setup-animated-wallpapers.sh`, `scripts/activitywatch-config.sh`, etc.

**Problem:**
- Multiple imperative scripts doing configuration
- Scripts can fail midway, leaving system in inconsistent state
- No rollback capability
- Not tracked in Nix store

**Why This Is Fighting Nix:**
- Nix activation scripts are the proper place for setup
- Nix ensures atomic updates
- Nix tracks all state changes

**Leveraging Nix Solution:**
```nix
# ✅ Declarative activation scripts
{
  system.activationScripts.setupWallpaper = {
    text = ''
      # Setup wallpaper - runs atomically with system activation
    '';
  };
}
```

---

### 7. Scattered Environment Variables

**Location:** Multiple files

**Problem:**
- Variables defined in multiple locations
- No single source of truth
- Hard to maintain consistency

**Locations:**
- `platforms/darwin/environment.nix`
- `platforms/common/environment/variables.nix`
- `platforms/common/home-base.nix`
- Shell init files in `dotfiles/`

**Leveraging Nix Solution:**
```nix
# ✅ Centralized environment variables
{
  # System-wide environment variables
  environment.sessionVariables = {
    EDITOR = "nvim";
    LANG = "en_US.UTF-8";
  };

  # User-level via Home Manager
  home.sessionPath = [ ... ];
  home.sessionVariables = { ... };
}
```

---

## Medium Priority Issues (P2 - Nice to Fix)

### 8. Over-Engineered Wrapper System

**Location:** `platforms/common/core/WrapperTemplate.nix`

**Problem:**
- Complex wrapper system with custom types
- Reinventing Nix's `makeWrapper`
- 165 lines for functionality Nix provides natively

**Why This Is Fighting Nix:**
- Nix has built-in `pkgs.makeWrapper` for this
- Custom implementation adds complexity
- Native solution is better tested

**Leveraging Nix Solution:**
```nix
# ✅ Use native makeWrapper
{
  packages = with pkgs; [
    (writeShellApplication {
      name = "bat-themed";
      runtimeInputs = [bat];
      text = ''
        BAT_THEME=GitHub exec bat "$@"
      '';
    })
  ];
}
```

---

### 9. Homebrew Packages That Should Be in Nix

**Location:** `justfile` and implicit usage

**Problem:**
- ActivityWatch managed via Homebrew instead of Nix
- GUI applications using Homebrew instead of Nix
- Breaks Nix's reproducibility guarantees

**Leveraging Nix Solution:**
```nix
# ✅ Use Nix packages instead
{
  home.packages = with pkgs; [
    activitywatch  # Available in nixpkgs
    other-gui-apps
  ];
}
```

---

### 10. Go Tools Managed via `go install`

**Location:** `justfile` Go tool recipes

**Problem:**
```bash
# ❌ Manual Go tool installation
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
```

**Why This Is Fighting Nix:**
- Not reproducible (version changes with @latest)
- No rollback capability
- Not tracked in Nix store

**Leveraging Nix Solution:**
```nix
# ✅ Declarative Go tools via Nix
{
  home.packages = with pkgs; [
    golangci-lint
    gopls
    gofumpt
    gotests
    wire
    # ... all Go tools
  ];
}
```

---

### 11. Imperative Cleanup Scripts

**Location:** `justfile` clean recipes

**Problem:**
```bash
# ❌ Manual cleanup
brew autoremove
brew cleanup --prune=all -s
rm -rf ~/.bun/install/cache
rm -rf ~/.gradle/caches/*
```

**Why This Is Fighting Nix:**
- Nix has built-in garbage collection
- Manual cleanup is fragile
- Not atomic or reproducible

**Leveraging Nix Solution:**
```bash
# ✅ Use Nix's garbage collection
nix-collect-garbage -d
nix-store --optimize
```

---

## Low Priority Issues (P3 - Consider)

### 12. Justfile Complexity

**Location:** `justfile`

**Problem:**
- 1000+ lines of task runner
- Many recipes duplicate Nix functionality
- Adds maintenance burden

**Consideration:**
- Keep Just for developer convenience
- Simplify by leveraging Nix more
- Use `nix run` patterns

---

## Migration Plan

### Phase 1: Critical Fixes (Week 1)
1. **Migrate dotfiles to Home Manager**
   - Move all dotfiles to `home.file` or `home.xdg.configFile`
   - Remove `manual-linking.sh`
   - Test on single system first

2. **Migrate LaunchAgents to nix-darwin**
   - Convert bash scripts to `launchd.agents` module
   - Remove `nix-activitywatch-setup.sh`
   - Test service startup/stop

3. **Consolidate environment variables**
   - Move to single location
   - Use `environment.sessionVariables` system-wide
   - Use `home.sessionVariables` user-level

### Phase 2: High Priority (Week 2)
4. **Remove hardcoded paths**
   - Replace all hardcoded `/Applications/` with Nix packages
   - Use Nix store paths consistently

5. **Migrate Homebrew packages to Nix**
   - Find Nix equivalents for Homebrew packages
   - Test GUI applications via Nix
   - Remove Homebrew dependency where possible

6. **Simplify setup scripts**
   - Convert bash scripts to Nix activation scripts
   - Remove imperative setup scripts
   - Ensure atomic updates

### Phase 3: Medium Priority (Week 3)
7. **Simplify wrapper system**
   - Evaluate if custom wrappers are needed
   - Replace with native `makeWrapper` where possible
   - Keep only essential custom wrappers

8. **Migrate Go tools to Nix**
   - Convert all `go install` to Nix packages
   - Update justfile recipes to use Nix tools
   - Remove manual Go tool management

### Phase 4: Documentation & Cleanup (Week 4)
9. **Update documentation**
   - Remove references to bash scripts
   - Document Nix-way of doing things
   - Create troubleshooting guide

10. **Clean up legacy code**
    - Remove obsolete bash scripts
    - Remove manual linking script
    - Update justfile recipes

---

## Benefits of Migration

### Immediate Benefits
- **Reproducibility**: All configuration declarative and tracked
- **Atomic Updates**: Changes applied atomically or rolled back entirely
- **Simplified Maintenance**: Single source of truth for configuration
- **Better Testing**: Config can be tested without applying

### Long-term Benefits
- **Reduced Technical Debt**: Less code to maintain
- **Improved Security**: All packages built from Nix store
- **Easier Onboarding**: Clear declarative configuration
- **Better Rollback**: Time-machine-like system rollbacks

---

## Risk Assessment

### Low Risk
- Environment variable consolidation
- Go tool migration (Nix has all major tools)

### Medium Risk
- Homebrew to Nix migration (some GUI apps may not be available)
- Dotfiles to Home Manager (need thorough testing)

### High Risk
- LaunchAgent migration (critical services must remain functional)
- Removing manual linking (must ensure all files migrated first)

---

## Success Criteria

- ✅ All dotfiles managed via Home Manager
- ✅ All LaunchAgents managed via nix-darwin
- ✅ Zero manual file linking
- ✅ All packages installed via Nix (where possible)
- ✅ All configuration in Nix files, no bash scripts
- ✅ Environment variables centralized
- ✅ Justfile simplified to < 500 lines

---

## Implementation Progress

### 2026-01-12 Updates

**✅ Completed Fixes:**

1. **LaunchAgent Migration (Issue #2 - CRITICAL)**
   - ✅ Fixed: Changed `launchd.userAgents` → `environment.userLaunchAgents` in `platforms/darwin/services/launchagents.nix`
   - ✅ Fixed: Corrected module structure to use plist XML text instead of config attributes
   - ✅ Test: Configuration test passed successfully (`just test`)
   - ✅ Status: Ready for `just switch` to apply changes

   **Technical Details:**
   - Original file used incorrect `launchd.userAgents` option (doesn't exist in nix-darwin)
   - Corrected to `environment.userLaunchAgents` with proper plist XML structure
   - Added proper user home directory handling via `config.users.users.larsartmann.home`
   - Using proper XDG-compliant log paths: `${userHome}/.local/share/activitywatch/`

2. **Locale Configuration for Git**
   - ✅ Found: English locale settings already configured in `platforms/common/programs/fish.nix`
   - ✅ Settings: `LANG=en_US.UTF-8`, `LC_ALL=en_US.UTF-8`, `LC_CTYPE=en_US.UTF-8`
   - ⏳ Status: Will take effect after `just switch` (applies Home Manager changes)
   - 📝 Note: Current shell has German locale from macOS system settings (AppleLanguages: en-DE, de-DE, zh-Hant-DE)

**🔄 Work in Progress:**

None currently - both critical fixes completed.

**📋 Pending (from original report):**

**Critical (P0):**
- ⏳ Manual dotfiles linking still using `scripts/manual-linking.sh`
- ⏳ LaunchAgent bash script `scripts/nix-activitywatch-setup.sh` still exists (can be removed after switch)
- ⏳ Hardcoded system paths in multiple scripts

**High Priority (P1):**
- ⏳ Homebrew packages that should be in Nix
- ⏳ Complex bash scripts duplicating Nix capabilities
- ⏳ Scattered environment variable configuration

**Next Immediate Actions:**
1. Run `just switch` to apply LaunchAgent and locale fixes
2. Test ActivityWatch auto-start after switch
3. Remove obsolete `scripts/nix-activitywatch-setup.sh` (backup first)
4. Begin Phase 2 of migration plan (High Priority issues)

---

## Next Steps

1. **Review this report** with team/stakeholders
2. **Approve migration plan** and timeline
3. **Start with Phase 1** (Critical fixes)
4. **Test on single system** before rollout
5. **Document changes** in commit messages
6. **Monitor for issues** after each phase

---

**Report Generated:** 2026-01-12
**Analyst:** AI Architecture Review
**Status:** In Progress - Critical Issue #2 Fixed, Ready for Apply
