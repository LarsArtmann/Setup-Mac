# Cross-Platform Consistency Check - 2025-12-26

**Created:** 2025-12-26 21:00 CET
**Purpose:** Compare Darwin and NixOS configurations for consistency and identify optimization opportunities
**Scope:** All platform-specific and common configurations

---

## 📊 Summary

**Platforms Compared:** Darwin (macOS) vs NixOS
**Files Analyzed:** 31 total files
**Inconsistencies Found:** 3 confirmed, 2 potential
**Recommendations:** 8 actionable items
**Priority:** Medium-High

---

## 🎯 Platform Architecture Overview

### Shared Components (Common)
```
platforms/common/
├── packages/
│   ├── base.nix (48-51 cross-platform packages)
│   └── fonts.nix (1 font package)
├── environment/
│   └── variables.nix (platform-agnostic env vars)
├── programs/
│   ├── fish.nix
│   ├── starship.nix
│   ├── activitywatch.nix
│   └── tmux.nix
└── home-base.nix (Home Manager base)
```

### Darwin-Specific Components
```
platforms/darwin/
├── default.nix (main entry point)
├── environment.nix (Darwin-specific env vars + iterm2)
├── nix/settings.nix (Nix settings)
├── programs/shells.nix (shell configs)
├── security/pam.nix (PAM configuration)
├── system/activation.nix (system activation)
├── system/settings.nix (system settings)
├── networking/default.nix (networking)
└── services/default.nix (system services)
```

### NixOS-Specific Components
```
platforms/nixos/
├── system/configuration.nix (main system config)
├── users/home.nix (Home Manager config)
├── hardware/
│   ├── hardware-configuration.nix (hardware)
│   └── amd-gpu.nix (AMD GPU support)
├── services/
│   └── ssh.nix (SSH daemon)
└── desktop/ (desktop environment)
    ├── hyprland-system.nix
    ├── hyprland-config.nix
    ├── hyprland.nix (Home Manager)
    ├── waybar.nix
    ├── display-manager.nix
    ├── audio.nix
    ├── monitoring.nix
    ├── ai-stack.nix
    ├── security-hardening.nix
    └── multi-wm.nix
```

---

## 🔴 CONFIRMED INCONSISTENCIES

### 1. Locale Inconsistency

**Severity:** Medium

**Platform 1: Common Environment Variables**
```nix
# platforms/common/environment/variables.nix
commonEnvVars = {
  ...
  LANG = "en_GB.UTF-8";  # British English
  LC_ALL = "en_GB.UTF-8";  # British English
  LC_CTYPE = "en_GB.UTF-8";  # British English
  ...
};
```

**Platform 2: Home Manager Base**
```nix
# platforms/common/home-base.nix
home = {
  sessionVariables = {
    EDITOR = "nano";
    LANG = "en_US.UTF-8";  # American English - INCONSISTENT!
  };
};
```

**Issue:** Two different locale settings in the same codebase
- Common environment: British English (en_GB)
- Home Manager: American English (en_US)

**Impact:** Confusing locale settings, potential date/time formatting differences

**Recommendation:** Standardize on one locale
- **Option A:** Use en_GB throughout (consistent with common/env)
- **Option B:** Use en_US throughout (standard US locale)
- **Option C:** Make locale configurable (most flexible)

**My Recommendation:** Option B - Use en_US.UTF-8 throughout
- US locale is more common and compatible
- Fewer date/time formatting issues
- Consistent with most development environments

**Effort:** 5 minutes
**Priority:** Medium

---

### 2. Shell Configuration Coverage

**Severity:** Low

**Darwin:**
```nix
# platforms/common/environment/variables.nix
environment.shells = with pkgs; [fish zsh bash];
```

**NixOS:**
```nix
# platforms/nixos/system/configuration.nix
programs.fish.enable = true;  # Only fish enabled system-wide

# platforms/nixos/users/home.nix (Home Manager)
# Imports home-base.nix which includes all shells
```

**Issue:** Inconsistent shell availability configuration
- Darwin: All three shells (fish, zsh, bash) available system-wide
- NixOS: Only fish enabled system-wide (but all available via Home Manager)

**Impact:** Minor - shells still available, just configured differently

**Recommendation:** Ensure consistent shell availability
- Either enable all shells system-wide on NixOS
- Or remove system-wide shell config on Darwin (use Home Manager only)

**My Recommendation:** Use Home Manager for all shell configuration
- Remove `environment.shells` from common/variables.nix
- Configure shells per-user via Home Manager
- More consistent approach across platforms

**Effort:** 15 minutes
**Priority:** Low

---

### 3. Editor Configuration Inconsistency

**Severity:** Low

**Common Environment:**
```nix
# platforms/common/environment/variables.nix
EDITOR = "nano";
```

**Darwin Environment:**
```nix
# platforms/darwin/environment.nix (none - uses common)
```

**NixOS User Config:**
```nix
# platforms/nixos/users/home.nix (none - uses home-base)
```

**Available Editors:**
```nix
# platforms/common/packages/base.nix
essentialPackages = with pkgs; [
  vim         # Terminal editor
  micro-full  # Modern terminal editor
];
```

**Issue:** EDITOR set to nano, but nano is NOT in packages!
- vim and micro-full are installed
- nano is not in any package list
- EDITOR variable points to non-existent editor

**Impact:** Medium - editor commands will fail

**Verification:**
```bash
$ grep -r "nano" platforms/common/packages/*.nix
# No results - nano not in packages!
```

**Recommendation:** Either install nano or change EDITOR to vim/micro

**Option A:** Install nano
```nix
# Add to platforms/common/packages/base.nix
essentialPackages = with pkgs; [
  nano  # Add this
  vim
  micro-full
  ...
];
```

**Option B:** Change EDITOR to micro (more modern than nano)
```nix
# Change in platforms/common/environment/variables.nix
commonEnvVars = {
  EDITOR = "micro";  # Change from nano
  ...
};
```

**Option C:** Change EDITOR to vim (most widely used)
```nix
# Change in platforms/common/environment/variables.nix
commonEnvVars = {
  EDITOR = "vim";  # Change from nano
  ...
};
```

**My Recommendation:** Option B - Use micro
- micro-full is already installed
- More modern than nano
- Better terminal experience
- Consistent with modern tooling

**Effort:** 2 minutes
**Priority:** Medium

---

## 🟡 POTENTIAL INCONSISTENCIES

### 4. Browser Preference Inconsistency

**Severity:** Low

**Darwin Environment:**
```nix
# platforms/darwin/environment.nix
environment.variables = {
  BROWSER = "google-chrome";  # TODO: <-- Helium?
};
```

**NixOS Configuration:**
```nix
# platforms/nixos/system/configuration.nix
users.users.lars.packages = with pkgs; [
  firefox
];

# platforms/nixos/desktop/hyprland.nix
bind = [
  "$mod, B, exec, firefox"  # Browser binding
];
```

**Issue:** Different browsers preferred on each platform
- Darwin: Chrome (google-chrome)
- NixOS: Firefox
- Both platforms have Chrome installed (Darwin via base.nix, NixOS not)

**Available Browsers:**
```nix
# platforms/common/packages/base.nix
guiPackages = with pkgs; [
  helium        # Cross-platform
];

# Darwin-only
google-chrome  # Only on Darwin (conditional)
```

**Impact:** Low - functional but inconsistent

**Recommendation:** Standardize on one browser or make explicit platform choice

**Option A:** Use Chrome on both platforms
- Add Chrome to NixOS packages
- Change NixOS keybinding to Chrome

**Option B:** Use Firefox on both platforms
- Remove Chrome from Darwin (or make optional)
- Keep Firefox on NixOS

**Option C:** Use Helium on both platforms
- Remove Chrome/Firefox preference
- Use Helium everywhere

**My Recommendation:** Option A - Use Chrome on both platforms
- Chrome is already installed on Darwin
- Better developer tools
- Add Chrome to NixOS user packages
- Make explicit platform choice in documentation

**Effort:** 10 minutes
**Priority:** Low

---

### 5. Terminal Emulator Preference

**Severity:** Low

**Darwin Environment:**
```nix
# platforms/darwin/environment.nix
environment.variables = {
  TERMINAL = "iTerm2";  # TODO: <-- should we move this to dedicated iterm2 config?
};
```

**NixOS Configuration:**
```nix
# platforms/common/packages/base.nix
essentialPackages = with pkgs; [
  alacritty-graphics  # Terminal emulator
];

# platforms/nixos/desktop/hyprland.nix
settings = {
  "$terminal" = "kitty";  # Terminal binding
  ...
};
```

**Darwin Packages:**
```nix
# platforms/darwin/environment.nix
environment.systemPackages = with pkgs; [
  iterm2
];
```

**NixOS Packages:**
```nix
# platforms/nixos/desktop/hyprland.nix
home.packages = with pkgs; [
  kitty   # Terminal
  ghostty  # Modern terminal emulator
];
```

**Issue:** Multiple terminal emulators with inconsistent preferences
- Darwin: iTerm2 preferred (variable), alacritty installed (base)
- NixOS: kitty preferred (binding), ghostty installed (home)

**Impact:** Low - all terminals functional, just inconsistent

**Recommendation:** Standardize on one terminal emulator per platform or make explicit choice

**Option A:** Use kitty on both platforms (modern, fast)
- Remove iTerm2 from Darwin
- Use kitty everywhere

**Option B:** Use alacritty on both platforms (already in base)
- Keep iTerm2 optional for Darwin
- Use alacritty everywhere

**Option C:** Platform-specific choices (current approach, documented)
- Keep Darwin: iTerm2 + alacritty
- Keep NixOS: kitty + ghostty
- Add documentation explaining choices

**My Recommendation:** Option C - Document platform-specific choices
- Different terminals make sense for different platforms
- iTerm2 is best-in-class on macOS
- kitty/gpotty are excellent on Linux
- Add clear documentation explaining rationale

**Effort:** 15 minutes (documentation only)
**Priority:** Low

---

## 📊 Package Distribution Analysis

### Cross-Platform Packages (base.nix)
```
Essential: 39 packages
  - Version control: git, git-town
  - Editors: vim, micro-full
  - Terminal: alacritty-graphics
  - Shells: fish, starship, carapace
  - File ops: curl, wget, tree, ripgrep, fd, eza, bat
  - Data: jq, yq-go
  - Task runner: just
  - Security: gitleaks, pre-commit, openssh
  - Productivity: glow
  - Monitoring: bottom, procs, btop
  - Utilities: sd, dust
  - GNU tools: coreutils, findutils, gnused
  - Graphviz: graphviz
  - Task mgmt: taskwarrior3, timewarrior
  - Clipboard: cliphist, xdg-utils

Development: 7-8 packages
  - JS/TS: bun
  - Go: go, gopls, golangci-lint
  - IaC: terraform
  - Nix: nh
  - Wallpaper: imagemagick, swww (Linux-only)

GUI: 1-2 packages
  - Cross-platform: helium
  - Darwin-only: google-chrome

AI: 0-1 packages
  - crush (conditional)
```

### Darwin-Only Packages
```
platforms/darwin/environment.nix:
  - iterm2

Total: 1 package
```

### NixOS-Only Packages
```
platforms/nixos/system/configuration.nix:
  - firefox

platforms/nixos/users/home.nix:
  - pavucontrol

platforms/nixos/desktop/hyprland.nix:
  - kitty, ghostty, hyprpaper, hyprlock, hypridle,
    hyprpicker, hyprsunset, hyprpolkitagent,
    dunst, libnotify, wlogout, grimblast,
    playerctl, brightnessctl

platforms/nixos/hardware/amd-gpu.nix:
  - amdgpu_top, corectrl, vulkan-tools, mesa-demos

platforms/nixos/desktop/monitoring.nix:
  - nvtopPackages.amd, radeontop, strace, ltrace,
    nethogs, iftop

platforms/nixos/desktop/ai-stack.nix:
  - ollama, llama-cpp, vllm, tesseract4,
    poppler-utils, jupyter, python311

platforms/nixos/desktop/security-hardening.nix:
  - polkit_gnome, gnome-keyring, pamtester, openssl,
    gnupg, pass, iptraf-ng, bmon, netsniff-ng,
    wireshark, aircrack-ng, aide, osquery, lsof,
    inotify-tools, iotop, perf, goaccess, ccze,
    tor-browser, openvpn, wireguard-tools, masscan,
    sqlmap, nikto, nuclei, sleuthkit, tcpdump,
    wireshark-cli, nmap, lynis

platforms/nixos/desktop/multi-wm.nix:
  - foot, wofi, swaylock, kdePackages.dolphin,
    mako, swaybg, grim, slurp, wl-clipboard

platforms/nixos/desktop/hyprland-config.nix:
  - qt5.qtwayland, qt6.qtwayland, glib

Total NixOS-only: ~73 packages
```

### Package Ratio
- **Cross-Platform:** 57-59 packages (~44%)
- **Darwin-Only:** 1 package (~0.8%)
- **NixOS-Only:** 73 packages (~56%)

**Analysis:** Good separation of concerns
- Darwin is lightweight (mostly cross-platform)
- NixOS has extensive desktop environment
- Minimal duplication across platforms

---

## ✅ What's Working Well

### 1. Package Organization
- ✅ Clear separation between cross-platform and platform-specific
- ✅ Shared base.nix for common tools
- ✅ Platform-specific modules isolated

### 2. Configuration Architecture
- ✅ Common environment variables shared
- ✅ Platform-specific variables isolated
- ✅ Home Manager used for user-level config

### 3. Declarative Approach
- ✅ All packages explicitly declared
- ✅ No manual installation required
- ✅ Reproducible configurations

### 4. Modularity
- ✅ Desktop environment split into focused modules
- ✅ Hardware configurations isolated
- ✅ Security, monitoring, AI modules separated

---

## 🎯 Recommended Actions

### High Priority (Fix Immediately)

1. **Fix Locale Inconsistency** (5 min)
   - Change home-base.nix LANG to "en_US.UTF-8"
   - OR change common/environment to "en_GB.UTF-8"
   - Recommendation: Use en_US everywhere (more standard)

2. **Fix Missing Nano Editor** (2 min)
   - Add nano to base.nix OR change EDITOR to micro
   - Recommendation: Change EDITOR to micro (already installed)

### Medium Priority (Fix Soon)

3. **Document Terminal Emulator Choices** (15 min)
   - Add documentation explaining why different terminals per platform
   - Add AGENTS.md section on terminal choices

4. **Consider Browser Standardization** (10 min)
   - Decide on Chrome vs Firefox vs Helium
   - Document platform-specific browser preferences
   - Consider adding Chrome to NixOS

### Low Priority (Nice to Have)

5. **Standardize Shell Configuration** (15 min)
   - Consider using Home Manager for all shells
   - Remove system-wide shell config from common/variables.nix
   - More consistent approach

---

## 📈 Impact Analysis

### After Fixing High Priority Issues

**Before:**
- Locale inconsistency (en_GB vs en_US)
- EDITOR points to non-existent nano
- Potential confusion for users

**After:**
- Consistent locale across platforms
- EDITOR works correctly
- Clearer user experience

**Effort:** ~7 minutes
**Value:** High (fixes functional issues)

### After Fixing All Issues

**Before:**
- 3 confirmed inconsistencies
- 2 potential inconsistencies
- Some confusion in documentation

**After:**
- 0 confirmed inconsistencies
- Documented platform choices
- Clear, consistent user experience

**Effort:** ~45 minutes total
**Value:** Medium-High (improves clarity and consistency)

---

## 🚀 Next Steps

1. **M5: Fix configuration duplications** (45 min)
   - Consolidate repeated configuration blocks
   - Extract to common modules where appropriate

2. **M4: Update AGENTS.md documentation** (30 min)
   - Reflect current state after de-duplication
   - Add terminal and browser preferences
   - Document consistency standards

3. **H5: Fix Darwin build error** (TBD)
   - Investigate boost::too_few_args error
   - Fix Darwin configuration build

---

*Report completed: 2025-12-26 21:00 CET*
*Total time: ~30 minutes*
*Status: ✅ READY FOR ACTION*
*Priority Actions: 2 (7 minutes)*
