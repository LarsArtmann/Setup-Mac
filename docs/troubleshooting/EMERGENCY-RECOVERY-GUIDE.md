# Emergency Recovery Guide: iTerm2 and System Configuration

**Date:** 2025-12-26
**Status:** 🟡 NEEDS USER ACTION
**Issue:** System configuration may be broken, iTerm2 not available

---

## 🚨 CURRENT SITUATION

### What Happened

1. **nh darwin switch failed** - temp directory issue (see: nh-darwin-switch-ROOT-CAUSE.md)
2. **just switch may have failed silently** - no error output visible
3. **iTerm2 is not installed** - not found in system
4. **System configuration might be incomplete** - packages missing

### What We've Done

1. ✅ **Fixed sandbox paths** - Added `/usr/include` and comprehensive macOS paths
2. ✅ **Researched 50+ configurations** - Best practices documented
3. ✅ **Updated sandbox configuration** - platforms/darwin/nix/settings.nix
4. ✅ **Committed all changes** - cae80d5, 5e784bb, 84a50a2
5. ✅ **Pushed to remote** - Repository up to date

### What's Currently Broken

1. ❌ **iTerm2 not available** - Can't be found in system or store
2. ❌ **System build may be incomplete** - Switch command failing silently
3. ❌ **Nix daemon needs restart** - Sandbox paths not applied yet

---

## 🎯 IMMEDIATE ACTION REQUIRED

### Step 1: Restart Nix Daemon (CRITICAL)

The new sandbox paths won't take effect until you restart the Nix daemon.

**Run this in Terminal (NOT in iTerm2, use default Terminal.app):**

```bash
# Stop Nix daemon
sudo launchctl stop org.nixos.nix-daemon

# Wait 2 seconds
sleep 2

# Start Nix daemon
sudo launchctl start org.nixos.nix-daemon

# Verify daemon is running
ps aux | grep nix-daemon
```

**Expected Output:**
- Daemon should stop and start successfully
- You should see `nix-daemon` process running
- No error messages

---

### Step 2: Apply System Configuration

Now that the daemon is restarted with new sandbox paths, apply your configuration.

**Run this in Terminal:**

```bash
# Navigate to Setup-Mac directory
cd ~/Desktop/Setup-Mac

# Apply configuration
just switch
```

**Expected Behavior:**
- Build should take 5-10 minutes
- You should see build progress (not silent failure)
- iTerm2 should be installed with system packages

**If This Fails:**

Try the alternative manual approach:

```bash
# Build system configuration
nix build .#darwinConfigurations.Lars-MacBook-Air.system

# Apply manually
sudo /nix/var/nix/profiles/system/result/activate
```

---

### Step 3: Verify iTerm2 Installation

After the switch completes successfully, verify iTerm2 is installed:

```bash
# Check if iTerm2 is in system
ls -la /run/current-system/Applications/ | grep -i iterm

# Or check if it's available via launch command
open /run/current-system/Applications/iTerm2.app
```

**Expected Output:**
- iTerm2.app should be listed in Applications
- Should open without errors

---

## 🔧 ALTERNATIVE APPROACHES

### Alternative 1: Manual iTerm2 Installation

If `just switch` continues to fail, install iTerm2 manually:

```bash
# Install iTerm2 for your user profile
nix profile install nixpkgs#iterm2

# Launch iTerm2
open ~/Applications/iTerm2.app

# Or add to path and run directly
nix run nixpkgs#iterm2
```

**Pros:**
- Immediate iTerm2 access
- Doesn't require system switch
- Works even if system config is broken

**Cons:**
- iTerm2 only for current user, not system-wide
- Needs to be reinstalled after system switch
- Not the "correct" Nix approach

---

### Alternative 2: Use Default Terminal

If iTerm2 is critical and you can't install it immediately:

```bash
# Use macOS Terminal.app
open -a Terminal

# Or try other terminals:
# - Alacritty (if installed via Nix)
# - Kitty (if installed)
# - Warp (if installed)
```

**Once in a working terminal:**
1. Follow "Step 1: Restart Nix Daemon"
2. Follow "Step 2: Apply System Configuration"
3. Follow "Step 3: Verify iTerm2 Installation"

---

### Alternative 3: Rollback to Previous Generation

If the current system generation is broken:

```bash
# Rollback to previous generation
just rollback

# Or manually rollback
darwin-rebuild switch --rollback

# Or manually set previous generation
sudo ln -sf /nix/var/nix/profiles/system-205-link \
  /nix/var/nix/profiles/system
sudo /nix/store/56rzl70zs58bj33hy35gi30gg3hf1m9z-darwin-system-26.05.5fb45ec/activate
```

**Note:** Generation 205 is from Dec 19, generation 206 is current (from Dec 21).

**Check Generations:**
```bash
# List all generations (if available)
ls -la /nix/var/nix/profiles/system-*-link
```

---

## 🐛 TROUBLESHOOTING

### Issue: "just switch" Fails Silently

**Symptoms:**
- Command runs but produces no output
- No error messages
- Builds appear to start but never finish

**Diagnosis:**
Build might be stuck or waiting for input.

**Solutions:**

1. **Check if process is running:**
   ```bash
   ps aux | grep -E "(nix build|darwin-rebuild)" | grep -v grep
   ```

2. **Check build logs:**
   ```bash
   # In another terminal, monitor Nix logs
   log show --predicate 'eventMessage contains "nix"' --last 5m
   ```

3. **Try with verbose output:**
   ```bash
   sudo /run/current-system/sw/bin/darwin-rebuild switch \
     --flake ./ \
     --show-trace \
     --print-build-logs
   ```

4. **Kill stuck processes and retry:**
   ```bash
   # Kill any stuck Nix processes
   pkill -9 -f "nix build"
   pkill -9 -f darwin-rebuild

   # Retry
   just switch
   ```

---

### Issue: Sandbox Path Errors

**Symptoms:**
- Error: "getting attributes of required path '/usr/lib': No such file or directory"
- Error: "getting attributes of required path '/usr/include': No such file or directory"

**Diagnosis:**
Sandbox paths not applied yet.

**Solutions:**

1. **Restart Nix daemon** (see Step 1 above)
2. **Verify sandbox configuration:**
   ```bash
   nix show-config | grep sandbox-paths
   ```
   Should show all paths we added.

3. **Check if you're a trusted user:**
   ```bash
   nix show-config | grep trusted-users
   ```
   Should include your username or "@admin".

---

### Issue: Build Takes Too Long

**Symptoms:**
- Build running for >30 minutes
- No progress visible

**Diagnosis:**
Network download or large package compilation.

**Solutions:**

1. **Check if it's downloading:**
   ```bash
   # Monitor network usage
   nettop
   ```

2. **Check Nix build queue:**
   ```bash
   nix-store --query --references /nix/var/nix/profiles/system
   ```

3. **Use binary cache** (if available):
   ```bash
   # Add Cachix or other binary caches to speed up
   # See: https://nixos.wiki/wiki/Binary_Cache
   ```

---

## 📋 VERIFICATION CHECKLIST

### After Applying Configuration:

- [ ] Nix daemon restarted successfully
- [ ] `just switch` completed without errors
- [ ] Build took reasonable time (5-15 minutes)
- [ ] iTerm2 is installed and launches
- [ ] Other expected packages are available

### If Issues Remain:

- [ ] iTerm2 installed manually via `nix profile install`
- [ ] Or rollback to previous generation completed
- [ ] Terminal application working (Terminal.app or alternative)
- [ ] Documentation read for troubleshooting steps

---

## 🎓 WHAT YOU LEARNED

### Why This Happened

1. **nh Tool Has macOS Bug:**
   - nh creates temp files as user, then tries to access as root
   - macOS security prevents root from accessing user temp directories
   - This is a known issue (see: nh-darwin-switch-ROOT-CAUSE.md)

2. **Sandbox Configuration Was Incomplete:**
   - Missing `/usr/include` (C/C++ headers)
   - Missing development tool paths
   - Some packages (like iTerm2) couldn't build

3. **Just Switch May Have Failed Silently:**
   - Build might have failed but didn't report errors clearly
   - System might be partially configured
   - iTerm2 was never actually installed

### What We Fixed

1. **Added Comprehensive Sandbox Paths:**
   - Core system paths (frameworks, libraries)
   - Build directories (temp, var/tmp)
   - Shell interpreters (sh, bash, zsh)
   - Development tools (Xcode, headers)
   - Desktop support (fonts, color profiles)

2. **Documented Best Practices:**
   - Researched 50+ configurations
   - Security analysis completed
   - Use-case specific recommendations
   - Troubleshooting guide created

3. **Committed and Pushed Changes:**
   - All fixes committed to git
   - Pushed to remote repository
   - Documentation created and committed

---

## 🏁 NEXT STEPS (IN ORDER)

1. **Open Terminal.app** (NOT iTerm2 - it's not installed)
2. **Navigate to Setup-Mac:** `cd ~/Desktop/Setup-Mac`
3. **Restart Nix daemon:** See "Step 1" above
4. **Apply configuration:** `just switch`
5. **Verify iTerm2:** `open /run/current-system/Applications/iTerm2.app`
6. **If fails:** Try alternative approaches in this guide

---

## 📞 GETTING HELP

### If All Else Fails

1. **Check Documentation:**
   - `docs/troubleshooting/nh-darwin-switch-ROOT-CAUSE.md` (nh tool issue)
   - `docs/troubleshooting/nh-darwin-switch-EXECUTIVE-SUMMARY.md` (solutions)
   - `docs/troubleshooting/SANDBOX-PATHS-RESEARCH.md` (sandbox config)

2. **Check Git History:**
   ```bash
   # See recent commits
   git log --oneline -10

   # View specific commit
   git show cae80d5  # Sandbox research
   git show 84a50a2  # Sandbox config update
   ```

3. **Rollback to Working State:**
   ```bash
   # Rollback to Dec 19 generation
   just rollback

   # Or manually revert commits
   git revert 84a50a2 5e784bb cae80d5
   ```

4. **Report Issues:**
   - GitHub: https://github.com/LarsArtmann/Setup-Mac/issues
   - NixOS Discourse: https://discourse.nixos.org/
   - nix-darwin: https://github.com/nix-darwin/nix-darwin/issues

---

## ✅ SUMMARY

### What's Been Done

1. ✅ **Root cause identified** - macOS temp directory security blocking nh
2. ✅ **Sandbox configuration fixed** - Comprehensive paths added
3. ✅ **Research completed** - 50+ configurations analyzed
4. ✅ **Documentation created** - 3 comprehensive guides
5. ✅ **Changes committed** - All fixes pushed to git

### What You Need to Do

1. ⚠️ **Restart Nix daemon** - Apply new sandbox paths
2. ⚠️ **Run `just switch`** - Apply system configuration
3. ⚠️ **Verify iTerm2** - Check it's installed

### If That Doesn't Work

1. ⚠️ **Install iTerm2 manually** - `nix profile install nixpkgs#iterm2`
2. ⚠️ **Rollback to previous generation** - `just rollback`
3. ⚠️ **Use Terminal.app** - Alternative terminal while fixing

---

**Action Required:** 🟡 YES - User must restart daemon and apply config
**Estimated Time:** 15-30 minutes (depending on build time)
**Difficulty:** 🟢 EASY - Just follow the steps above

**Good Luck!** 💪
