# Dotfiles Migration to Home Manager Guide

**Status:** Phase 1 - In Progress
**Date:** 2026-01-12

## Overview

This guide documents the migration of manually managed dotfiles to declarative Home Manager configuration. This eliminates the need for manual file linking (`manual-linking.sh`) and provides reproducible, atomic configuration management.

## Migration Status

### ✅ Completed

1. **Git Configuration**
   - Status: ✅ ALREADY IN HOME MANAGER
   - Location: `platforms/common/programs/git.nix`
   - Action: None needed (already properly configured)
   - Cleanup: Can remove `dotfiles/.gitconfig` after verification

2. **SSH Configuration**
   - Status: ✅ ALREADY IN HOME MANAGER
   - Location: `platforms/common/programs/ssh.nix`
   - Action: None needed (already properly configured)
   - Cleanup: Can remove `dotfiles/.ssh/config` after verification

3. **Starship Prompt Configuration**
   - Status: ✅ MIGRATED
   - Location: `platforms/common/programs/starship.nix`
   - Changes: Full config migrated from `dotfiles/.config/starship.toml`
   - Cleanup: Can remove `dotfiles/.config/starship.toml` after verification

4. **Zsh Shell Configuration**
   - Status: ✅ MIGRATED
   - Location: `platforms/common/programs/zsh.nix`
   - Changes: Full config migrated from `dotfiles/.zshrc` with async loading support
   - Cleanup: Can remove `dotfiles/.zshrc` after verification

### 🔄 In Progress

5. **Remove manual-linking.sh**
   - Status: In Progress
   - Action: Document which files are still needed and update justfile
   - Cleanup: Remove `scripts/manual-linking.sh` after migration complete

### 📋 Pending

6. **Nushell Configuration**
   - Status: Pending
   - Location: Currently in `dotfiles/.config/nushell/`
   - Action: Migrate to Home Manager's `programs.nushell`
   - Cleanup: Remove `dotfiles/.config/nushell/*` after migration

7. **Bash Configuration**
   - Status: Pending
   - Location: Currently in `dotfiles/.bashrc` and `dotfiles/.bash_profile`
   - Action: Migrate to Home Manager's `programs.bash`
   - Cleanup: Remove `dotfiles/.bash*` after migration

8. **Fish Shell Configuration**
   - Status: Pending
   - Location: `platforms/common/programs/fish.nix` (already Home Manager)
   - Action: Verify it matches `dotfiles/` if any exists
   - Cleanup: N/A

9. **ActivityWatch Configuration**
   - Status: Pending
   - Location: `dotfiles/activitywatch/`
   - Action: Migrate to Home Manager's `home.file` or `home.xdg.configFile`
   - Cleanup: Remove `dotfiles/activitywatch/*` after migration

10. **Sublime Text Configuration**
    - Status: Pending
    - Location: `dotfiles/sublime-text/`
    - Action: Consider if should be in Home Manager or stay as is
    - Cleanup: Depends on decision (GUI app config often stays outside Nix)

11. **UBlock Origin Configuration**
    - Status: Pending
    - Location: `dotfiles/ublock-origin/`
    - Action: Consider if should be in Home Manager or stay as is
    - Cleanup: Depends on decision (browser extension config often stays outside Nix)

12. **Pre-commit Configuration**
    - Status: Pending
    - Location: `dotfiles/.pre-commit-config.yaml`
    - Action: Migrate to Home Manager's `home.file`
    - Cleanup: Remove `dotfiles/.pre-commit-config.yaml` after migration

13. **FZF Configuration**
    - Status: Pending
    - Location: `dotfiles/.fzf.zsh`
    - Action: Migrate to Zsh config or use Home Manager's `programs.fzf`
    - Cleanup: Remove `dotfiles/.fzf.zsh` after migration

14. **Git Config Backups**
    - Status: Pending
    - Location: `dotfiles/.gitconfig.old`, `dotfiles/.gitignore_global.old`
    - Action: Delete (these are just backups)
    - Cleanup: Remove all `*.old` files

15. **Zsh Config Backups**
    - Status: Pending
    - Location: Multiple `.zshrc.*` backup files
    - Action: Delete (these are just backups)
    - Cleanup: Remove all `*.pre-automation-backup`, `*.optimized`, etc. files

16. **Other Shell Configs**
    - Status: Pending
    - Location: `dotfiles/.zprofile`, `dotfiles/.zshrc.automation-integration`
    - Action: Review and migrate if needed, otherwise delete
    - Cleanup: Remove obsolete config files

17. **Waybar Security Status Script**
    - Status: Pending
    - Location: `dotfiles/.config/waybar/security-status.sh`
    - Action: Already referenced in `platforms/nixos/desktop/waybar.nix`
    - Cleanup: Keep but consider moving to a better location

## Migration Steps

### Step 1: Test Current Configurations
```bash
# Verify Home Manager configuration works
just test

# Apply configuration
just switch

# Open new terminal for shell changes to take effect
# Test all configured programs
```

### Step 2: Verify Migrated Configurations
```bash
# Test Starship prompt
starship prompt

# Test Zsh with async loading
zsh -i

# Test Git configuration
git config --list

# Test SSH configuration
ssh -G github.com
```

### Step 3: Update justfile
Remove or update `just link` recipe to no longer call `manual-linking.sh`

### Step 4: Clean Up Migrated Files
```bash
# After verification, remove migrated dotfiles
trash dotfiles/.gitconfig
trash dotfiles/.ssh/config
trash dotfiles/.config/starship.toml
trash dotfiles/.zshrc
```

### Step 5: Migrate Remaining Files
Follow the pending items above to migrate remaining configurations.

## Benefits of Migration

### 1. Declarative Configuration
- **Before**: Imperative bash script (`manual-linking.sh`)
- **After**: Declarative Nix configuration
- **Benefit**: Reproducible, testable, version-controlled

### 2. Atomic Updates
- **Before**: Manual symlinks can break during updates
- **After**: All updates applied atomically or rolled back
- **Benefit**: No broken intermediate states

### 3. Single Source of Truth
- **Before**: Configuration scattered across multiple files
- **After**: All configuration in Nix modules
- **Benefit**: Easier to maintain and understand

### 4. Platform Consistency
- **Before**: Different configurations for macOS and Linux
- **After**: Shared configurations in `platforms/common/`
- **Benefit**: Consistent experience across platforms

### 5. Rollback Capability
- **Before**: Manual changes difficult to undo
- **After**: `nix-env --rollback` to previous generation
- **Benefit**: Safety net for configuration changes

## Testing Checklist

After each migration, verify:

- [ ] Configuration file is linked to correct location
- [ ] Program starts and uses configuration
- [ ] Settings are applied correctly
- [ ] No errors in program output
- [ ] Performance is acceptable (especially for shell)
- [ ] Works on both platforms (if cross-platform)

## Rollback Plan

If migration causes issues:

```bash
# Rollback to previous generation
just rollback

# Or manually restore from backup
just restore <backup_name>

# Then restore dotfiles manually
cd ~/projects/SystemNix
./scripts/manual-linking.sh
```

## Documentation Updates

After migration complete, update:

1. **README.md** - Remove references to manual linking
2. **AGENTS.md** - Update to reflect Home Manager configuration
3. **justfile** - Update `just link` recipe or remove it

## Future Improvements

1. **Nushell**: Migrate to `programs.nushell` module
2. **Bash**: Migrate to `programs.bash` module
3. **Pre-commit**: Migrate to `home.file`
4. **FZF**: Migrate to `programs.fzf` module
5. **ActivityWatch**: Migrate to `home.xdg.configFile`

## Notes

- **GUI Application Configs**: Some configs (Sublime Text, browser extensions) may be kept outside Nix as they don't benefit from declarative management
- **Secret Files**: Files with sensitive data (`.env.private`) should never be in Nix store, use environment variables or agenix for secrets
- **Backup Files**: Remove all `*.old`, `*.backup`, `*.pre-*` files - they're just history
- **Platform-Specific**: Use `lib.mkIf pkgs.stdenv.isDarwin` or `lib.mkIf pkgs.stdenv.isLinux` for platform-specific configs

## References

- Home Manager Manual: https://nix-community.github.io/home-manager/
- Nix Options Search: https://search.nixos.org/options
- flake-parts: https://flake.parts/

---

**Last Updated:** 2026-01-12
**Status:** Phase 1 - In Progress
