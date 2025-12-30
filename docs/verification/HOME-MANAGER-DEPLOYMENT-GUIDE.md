# Home Manager Integration - Deployment Guide

**Purpose:** Manual deployment and verification of Home Manager integration for Darwin (macOS)

**Prerequisites:**
- ✅ Configuration fixed and committed (commit 248a9d1)
- ✅ Build verified via `nix build`
- ⚠️  Requires sudo access for `darwin-rebuild switch`

---

## Step 1: Deploy Configuration

### Option A: Apply New Configuration
```bash
# From Setup-Mac directory
cd ~/Desktop/Setup-Mac

# Apply new Home Manager configuration
sudo darwin-rebuild switch --flake .
```

**Expected Output:**
```
building the system configuration...
setting up /etc/run/current-system/sw/bin
setting up /etc/static
activating the configuration
...
```

**What This Does:**
- Builds Home Manager user configuration
- Installs Fish shell with Starship prompt
- Configures Tmux and other programs
- Activates new system generation

### Option B: Test Without Applying (Dry Run)
```bash
# Build only, don't apply
nix build .#darwinConfigurations.Lars-MacBook-Air.config.system.build.toplevel

# Inspect built configuration
ls -la result/system
```

---

## Step 2: Verify Deployment

### 2.1 Open New Terminal

**Why?** Shell changes require new terminal session

**Verify:**
- Terminal opens successfully
- Prompt appears (not stuck)
- No immediate errors

### 2.2 Test Starship Prompt

**Expected Behavior:**
- ✅ Starship prompt appears (not default Fish prompt)
- ✅ Git branch indicator shows (if in git repo)
- ✅ Current directory displayed
- ✅ Character symbol at end of prompt (usually ➜)

**Test Commands:**
```bash
# Change directory to see prompt update
cd platforms

# Check if Starship is active
starship --version
# Expected: starship 1.x.x or higher
```

**Visual Verification:**
```
❯ Prompt should look like this:
[git:branch] 📂 platforms ➜
  (Starship with icons, colors, and git integration)

❌ NOT like this:
~
  (Default Fish prompt without Starship)
```

**Check Starship Config:**
```bash
# Verify Starship config is loaded
cat ~/.config/starship.toml
# Expected: Should contain format settings from platforms/common/programs/starship.nix
```

### 2.3 Test Fish Shell

**Expected Behavior:**
- ✅ Fish shell active (check with `echo $SHELL`)
- ✅ Starship Fish integration enabled (no manual `starship init fish | source` needed)
- ✅ Carapace completions available

**Test Commands:**
```bash
# Check current shell
echo $SHELL
# Expected: /nix/store/...-fish-.../bin/fish or similar Nix store path

# Check Fish version
fish --version
# Expected: fish 3.x.x or higher

# Check Fish config
cat ~/.config/fish/config.fish
# Expected: Should contain common aliases and Darwin-specific overrides
```

**Test Darwin-Specific Aliases:**
```bash
# Test nixup alias
nixup
# Should execute: darwin-rebuild switch --flake .

# Test nixbuild alias
nixbuild
# Should execute: darwin-rebuild build --flake .

# Test nixcheck alias
nixcheck
# Should execute: darwin-rebuild check --flake .

# Test common aliases (from platforms/common/programs/fish.nix)
l
# Should execute: ls -laSh (detailed list)
t
# Should execute: tree -h -L 2 -C --dirsfirst
```

**Expected Errors:** None

### 2.4 Test Carapace Completions

**Expected Behavior:**
- ✅ Tab completion works for many commands
- ✅ No errors on shell startup

**Test Commands:**
```bash
# Test completion
git <TAB>
# Should show git completion options

# Check if carapace is active
which carapace
# Expected: /nix/store/...-carapace-.../bin/carapace
```

**Note:** Carapace integration is set via `carapace _carapace fish | source` in darwin/home.nix shellInit

### 2.5 Test Tmux

**Expected Behavior:**
- ✅ Tmux launches without errors
- ✅ Tmux configuration loaded (from platforms/common/programs/tmux.nix)
- ✅ Keybindings work (if configured)

**Test Commands:**
```bash
# Start Tmux session
tmux new-session
# Expected: New terminal session opens in Tmux

# Check Tmux version
tmux -V
# Expected: tmux 3.x or higher

# Exit Tmux
# Press Ctrl+B then D (default exit keybinding)
# Or: tmux kill-session
```

**Check Tmux Config:**
```bash
# Verify Tmux config
cat ~/.config/tmux/tmux.conf
# Expected: Should contain settings from platforms/common/programs/tmux.nix
```

**Note:** If Tmux configuration is empty, check platforms/common/programs/tmux.nix for settings

### 2.6 Verify Environment Variables

**Expected Variables:**
- `EDITOR`: Should be `micro` (from common/environment/variables.nix)
- `LANG`: Should be `en_GB.UTF-8` (from common/environment/variables.nix)
- `LC_ALL`: Should be `en_GB.UTF-8` (from common/environment/variables.nix)

**Test Commands:**
```bash
# Check EDITOR
echo $EDITOR
# Expected: micro

# Check LANG
echo $LANG
# Expected: en_GB.UTF-8

# Check LC_ALL
echo $LC_ALL
# Expected: en_GB.UTF-8

# Check PATH additions (from platforms/common/home-base.nix)
echo $PATH | tr ':' '\n' | grep -E "(local/bin|go/bin|bun/bin)"
# Expected: Should see ~/.local/bin, ~/go/bin, ~/.bun/bin in PATH
```

**Expected Errors:** None

---

## Step 3: Verification Checklist

### 3.1 Starship Verification
- [ ] Starship prompt appears in terminal
- [ ] Starship version >= 1.0.0
- [ ] Git branch indicator works (if in git repo)
- [ ] Directory indicator works
- [ ] Prompt loads instantly (< 1 second)
- [ ] No errors in `starship --version`

### 3.2 Fish Shell Verification
- [ ] Fish shell is active
- [ ] Fish version >= 3.0.0
- [ ] `nixup` alias works
- [ ] `nixbuild` alias works
- [ ] `nixcheck` alias works
- [ ] Common aliases (`l`, `t`) work
- [ ] Carapace completions work
- [ ] No errors on shell startup
- [ ] Homebrew integration works (if using Homebrew)

### 3.3 Tmux Verification
- [ ] Tmux launches without errors
- [ ] Tmux version >= 3.0
- [ ] Tmux configuration loaded
- [ ] Can create new session
- [ ] Can exit session properly
- [ ] Keybindings work (if configured)

### 3.4 Environment Variables Verification
- [ ] `EDITOR` is set to `micro`
- [ ] `LANG` is set to `en_GB.UTF-8`
- [ ] `LC_ALL` is set to `en_GB.UTF-8`
- [ ] PATH includes `~/.local/bin`
- [ ] PATH includes `~/go/bin`
- [ ] PATH includes `~/.bun/bin`

### 3.5 Home Manager Verification
- [ ] Home Manager is enabled
- [ ] Home Manager version >= 24.05
- [ ] User home directory is correct
- [ ] No assertion failures
- [ ] No warnings during activation

---

## Step 4: Troubleshooting

### Issue: Starship Prompt Not Appearing
**Symptom:** Default Fish prompt instead of Starship
**Cause:** Starship not enabled or not in PATH
**Solution:**
```bash
# Check Starship is installed
which starship

# Check Starship config
cat ~/.config/starship.toml

# Restart shell
exec fish
```

### Issue: Aliases Not Working
**Symptom:** `nixup` command not found
**Cause:** Fish config not loaded
**Solution:**
```bash
# Reload Fish config
source ~/.config/fish/config.fish

# Check aliases
type nixup
# Should show: darwin-rebuild switch --flake .
```

### Issue: Tmux Not Configured
**Symptom:** Default Tmux config instead of custom
**Cause:** Tmux config not loaded
**Solution:**
```bash
# Check Tmux config location
ls ~/.config/tmux/

# Verify config exists
cat ~/.config/tmux/tmux.conf

# Restart Tmux
tmux kill-server && tmux new-session
```

### Issue: Environment Variables Not Set
**Symptom:** `EDITOR` or `LANG` not set
**Cause:** Environment config not loaded or overridden
**Solution:**
```bash
# Check environment files
ls ~/.config/environment.d/

# Check common/environment/variables.nix
cat platforms/common/environment/variables.nix

# Restart shell
exec fish
```

### Issue: Build Fails with "activitywatch"
**Symptom:** Error about ActivityWatch not supporting platform
**Cause:** Fixed in commit 248a9d1, but old cache may be used
**Solution:**
```bash
# Update flake lock
nix flake update

# Rebuild
sudo darwin-rebuild switch --flake .
```

---

## Step 5: Rollback (If Needed)

### Option A: Rollback One Generation
```bash
# Rollback to previous generation
darwin-rebuild switch --rollback
```

### Option B: List Generations
```bash
# List all available generations
darwin-rebuild --list-generations

# Switch to specific generation
darwin-rebuild switch --generation <number>
```

### Option C: Restore from Backup
```bash
# List available backups
just list-backups

# Restore specific backup
just restore <backup-name>
```

---

## Expected Success Criteria

**Deployment Success:**
- ✅ `sudo darwin-rebuild switch --flake .` completes without errors
- ✅ New terminal session opens successfully
- ✅ Starship prompt appears
- ✅ Fish aliases work
- ✅ Tmux launches with custom config
- ✅ Environment variables are set correctly

**Configuration Verification:**
- ✅ Home Manager is managing user configuration
- ✅ All shared modules from `platforms/common/` are working
- ✅ Darwin-specific overrides are applied
- ✅ No assertion failures or warnings

**Cross-Platform Ready:**
- ✅ Same programs work on both Darwin and NixOS
- ✅ Shared configuration in `platforms/common/` is correct
- ✅ Platform-specific overrides are minimal

---

## After Verification

### If All Tests Pass:
1. Update AGENTS.md with Home Manager architecture
2. Create ADR for Home Manager integration decision
3. Archive status reports to `docs/archive/`
4. Update README.md with Home Manager section

### If Tests Fail:
1. Document specific failure in status report
2. Troubleshoot using Step 4 above
3. Fix issues and redeploy
4. Re-verify until all tests pass

---

**Prepared by:** Crush AI Assistant
**For:** Manual deployment after automated build verification
**Next Step:** Execute verification checklist after `darwin-rebuild switch`
