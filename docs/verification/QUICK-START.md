# Home Manager Deployment - Quick Start Guide

**Last Updated:** 2025-12-27
**Status:** ✅ Ready for Deployment

---

## 🚀 3 Commands to Deploy

### 1. Deploy Configuration

```bash
cd ~/Desktop/Setup-Mac
sudo darwin-rebuild switch --flake .
```

**What this does:**
- Downloads and builds all packages
- Applies Home Manager configuration
- Activates all programs and settings
- Takes 5-10 minutes (first run)

### 2. Open New Terminal

**IMPORTANT:** You MUST open a new terminal window for shell changes to take effect!

```bash
# Close current terminal
# Open new terminal (Cmd+N)
```

**Why:** Shell configuration (Fish, aliases, environment variables) only applies to new shell sessions.

### 3. Verify Deployment

```bash
# Run verification script
cd ~/Desktop/Setup-Mac
just verify
```

**What this checks:**
- ✅ Starship prompt is working
- ✅ Fish shell is configured
- ✅ Fish aliases are available
- ✅ Environment variables are set
- ✅ Tmux is configured

---

## 🎯 Quick Verification Steps

After deployment, verify these basics:

### Check Starship Prompt
```bash
# Open new terminal
# You should see:
# - Colorful prompt with git branch (if in git repo)
# - Current directory
# - User and host information
```

### Check Fish Aliases
```bash
# These should work:
type nixup      # Should show: darwin-rebuild switch --flake .
type nixbuild    # Should show: darwin-rebuild build --flake .
type nixcheck    # Should show: darwin-rebuild check --flake .
type l           # Should show: ls -laSh
type t           # Should show: tree -h -L 2 -C --dirsfirst
```

### Check Environment Variables
```bash
echo $EDITOR     # Should show: micro
echo $LANG       # Should show: en_GB.UTF-8
echo $LC_ALL     # Should show: en_GB.UTF-8
```

### Check Tmux
```bash
tmux new-session
# You should see:
# - Clock in status bar (24h format)
# - Mouse enabled (click to select)
# - Numbered windows starting at 1

# Exit: Ctrl+B, then D
```

---

## 🛠️ Troubleshooting

### Starship Prompt Not Appearing

**Problem:** Default Fish prompt instead of Starship

**Solution:**
```bash
# Restart shell
exec fish

# Check Starship config
cat ~/.config/starship.toml

# Verify Starship is installed
which starship
```

### Fish Aliases Not Working

**Problem:** `nixup` command not found

**Solution:**
```bash
# Reload Fish config
source ~/.config/fish/config.fish

# Check aliases
type nixup
# Should show: darwin-rebuild switch --flake .
```

### Environment Variables Not Set

**Problem:** `EDITOR` or `LANG` not set

**Solution:**
```bash
# Check environment
echo $EDITOR
echo $LANG

# Restart shell
exec fish
```

### Tmux Not Configured

**Problem:** Default Tmux config instead of custom

**Solution:**
```bash
# Check Tmux config
cat ~/.config/tmux/tmux.conf

# Restart Tmux
tmux kill-server && tmux new-session
```

### Something Broke After Deployment

**Problem:** Deployment caused issues

**Solution:**
```bash
# Rollback to previous generation
cd ~/Desktop/Setup-Mac
just rollback

# Or manual rollback
sudo darwin-rebuild switch --rollback
```

---

## 🔄 Updates and Maintenance

### Update System

```bash
cd ~/Desktop/Setup-Mac

# Update flake inputs
just update

# Apply updates
just switch

# Open new terminal
```

### Rollback Changes

```bash
cd ~/Desktop/Setup-Mac

# Rollback to previous generation
just rollback

# List available generations
just list-generations
```

---

## 📚 For Detailed Information

- **[Deployment Guide](./HOME-MANAGER-DEPLOYMENT-GUIDE.md)** - Comprehensive step-by-step guide
- **[Verification Template](./HOME-MANAGER-VERIFICATION-TEMPLATE.md)** - Detailed verification checklist
- **[Cross-Platform Report](./CROSS-PLATFORM-CONSISTENCY-REPORT.md)** - Architecture analysis
- **[ADR-001](../architecture/adr-001-home-manager-for-darwin.md)** - Architecture Decision Record
- **[AGENTS.md](../../AGENTS.md)** - Home Manager architecture for AI assistants

---

## ✅ Success Criteria

Deployment is successful if:
- ✅ Starship prompt appears (colorful with git branch)
- ✅ Fish shell is active (`echo $SHELL` shows Fish)
- ✅ Fish aliases work (`nixup`, `nixbuild`, `nixcheck`)
- ✅ Environment variables set (`EDITOR=micro`, `LANG=en_GB.UTF-8`)
- ✅ Tmux configuration loaded (24h clock, mouse enabled)
- ✅ Verification script passes (`just verify`)

---

## 🆘 Getting Help

If you encounter issues:

1. **Check troubleshooting section** above
2. **Run verification script:** `just verify`
3. **Check deployment guide:** [HOME-MANAGER-DEPLOYMENT-GUIDE.md](./HOME-MANAGER-DEPLOYMENT-GUIDE.md)
4. **Run health check:** `just health`
5. **Check GitHub issues:** [LarsArtmann/Setup-Mac/issues](https://github.com/LarsArtmann/Setup-Mac/issues)

---

**Status:** ✅ Quick Start Guide Complete
**Ready for Deployment:** Yes
**Estimated Deployment Time:** 5-10 minutes (first run)
