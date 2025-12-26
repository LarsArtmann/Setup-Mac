# Comprehensive Package Audit - 2025-12-26

**Created:** 2025-12-26 20:30 CET
**Purpose:** Complete audit of all packages across the codebase to identify duplications and optimization opportunities
**Scope:** All Nix package definitions in platforms/ directory

---

## 📊 Summary

**Total Package Files Analyzed:** 11
**Total Packages Listed:** ~200+
**Duplications Found:** 4 confirmed, 3 potential
**Easy Wins Identified:** 7 packages
**Consolidation Opportunities:** Medium effort

---

## 📁 Package Files Analyzed

### Cross-Platform Files
1. **platforms/common/packages/base.nix** - Core system packages
2. **platforms/common/packages/fonts.nix** - Font configuration
3. **platforms/common/home-base.nix** - Home Manager base (empty packages)

### Darwin-Specific Files
4. **platforms/darwin/environment.nix** - macOS environment packages

### NixOS-Specific Files
5. **platforms/nixos/system/configuration.nix** - System configuration packages
6. **platforms/nixos/users/home.nix** - User-level packages
7. **platforms/nixos/desktop/hyprland.nix** - Hyprland window manager packages
8. **platforms/nixos/hardware/amd-gpu.nix** - AMD GPU monitoring packages
9. **platforms/nixos/desktop/monitoring.nix** - Performance monitoring packages
10. **platforms/nixos/desktop/ai-stack.nix** - AI/ML tools
11. **platforms/nixos/desktop/security-hardening.nix** - Security tools
12. **platforms/nixos/desktop/multi-wm.nix** - Multi- WM packages
13. **platforms/nixos/desktop/hyprland-config.nix** - Hyprland integration packages

---

## 📦 Package Breakdown by File

### 1. platforms/common/packages/base.nix (System Packages)

#### essentialPackages (39 packages)
```
# Version control
git, git-town

# Essential editors
vim, micro-full

# Terminal emulator
alacritty-graphics

# Shells and prompts
fish, starship, carapace

# File operations and browsing
curl, wget, tree, ripgrep, fd, eza, bat

# Data manipulation
jq, yq-go

# Task runner
just

# Security tools
gitleaks, pre-commit, openssh

# Modern CLI productivity tools
glow

# System monitoring
bottom, procs, btop

# File utilities
sd, dust

# GNU utilities (cross-platform)
coreutils, findutils, gnused

# Graph visualization
graphviz

# Task management
taskwarrior3, timewarrior

# Clipboard management
cliphist
```

#### developmentPackages (7-8 packages)
```
# JavaScript/TypeScript
bun

# Go development
go, gopls, golangci-lint

# Infrastructure as Code
terraform

# Nix helper tools
nh

# Wallpaper management tools (Linux-only)
imagemagick
swww (Linux-only, conditional)
```

#### guiPackages (1-2 packages)
```
# Import Helium browser (cross-platform)
helium (from ./helium.nix)

google-chrome (Darwin-only, conditional)
```

#### aiPackages (0-1 packages)
```
crush (conditional, from llm-agents)
```

**Total base.nix Packages:** 48-51 packages (conditional on platform)

---

### 2. platforms/common/packages/fonts.nix

```
jetbrains-mono
```

**Total fonts.nix Packages:** 1 package

---

### 3. platforms/darwin/environment.nix

```
iterm2
```

**Total darwin/environment.nix Packages:** 1 package

---

### 4. platforms/nixos/system/configuration.nix

#### User packages
```
firefox
```

#### Fonts
```
jetbrains-mono (DUPLICATE - also in fonts.nix)
```

**Total configuration.nix Packages:** 2 packages (1 duplicate)

---

### 5. platforms/nixos/users/home.nix

```
pavucontrol  # Audio control
rofi          # Launcher (Secondary)
xdg-utils     # System Tools
```

**Total home.nix Packages:** 3 packages

---

### 6. platforms/nixos/desktop/hyprland.nix

```
kitty        # Terminal
ghostty      # Modern terminal emulator
hyprpaper    # Wallpaper utility (official)
hyprlock     # GPU-accelerated screen lock
hypridle     # Idle daemon for automatic lock/suspend
hyprpicker   # Color picker
hyprsunset   # Blue light filter
hyprpolkitagent # Modern polkit agent for Hyprland
dunst        # Notifications
libnotify    # Notification library
wlogout      # Modern logout menu
grimblast    # Enhanced screenshot utility
playerctl    # Media player control
brightnessctl # Brightness control
```

**Total hyprland.nix Packages:** 13 packages

**Note:** Many packages moved to other modules to avoid duplication:
- kdePackages.dolphin → multi-wm.nix
- rofi → multi-wm.nix (but also in home.nix - DUPLICATE)
- waybar → multi-wm.nix
- wl-clipboard → multi-wm.nix
- cliphist → base.nix
- swww → base.nix
- imagemagick → base.nix
- radeontop → monitoring.nix
- amdgpu_top → amd-gpu.nix
- btop, nvtopPackages.amd → monitoring.nix
- pavucontrol, grim, slurp → multi-wm.nix (but pavucontrol also in home.nix - DUPLICATE)
- AI/ML tools → ai-stack.nix

---

### 7. platforms/nixos/hardware/amd-gpu.nix

```
amdgpu_top    # GPU monitoring tool
corectrl      # AMD CPU control
vulkan-tools  # Vulkan utilities
mesa-demos    # GPU testing tools
```

**Total amd-gpu.nix Packages:** 4 packages

---

### 8. platforms/nixos/desktop/monitoring.nix

```
nvtopPackages.amd  # GPU monitoring
radeontop          # AMD GPU specific monitor (CLI, lightweight)
strace             # System call tracer
ltrace             # Library call tracer
nethogs            # Network process monitoring
iftop              # Network bandwidth
```

**Total monitoring.nix Packages:** 6 packages

**Note:**
- btop moved to base.nix (available cross-platform)
- amdgpu_top moved to amd-gpu.nix (available system-wide)

---

### 9. platforms/nixos/desktop/ai-stack.nix

```
ollama        # Model server
llama-cpp     # Alternative inference
vllm          # High-performance inference server
tesseract4    # Better OCR (includes tesseract binary)
poppler-utils # PDF utilities
jupyter       # Interactive development
python311     # Python for AI/ML development
```

**Total ai-stack.nix Packages:** 7 packages

**Service:**
- ollama-rocm (service package, with GPU support)

---

### 10. platforms/nixos/desktop/security-hardening.nix

```
polkit_gnome
xdg-utils (DUPLICATE - also in home.nix)
gnome-keyring
pamtester
openssl
gnupg
pass
iptraf-ng
bmon
netsniff-ng
wireshark
aircrack-ng
aide
osquery
lsof
inotify-tools
iotop
perf
goaccess
ccze
tor-browser
openvpn
wireguard-tools
masscan
sqlmap
nikto
nuclei
sleuthkit
tcpdump
wireshark-cli
nmap
lynis
```

**Total security-hardening.nix Packages:** 33 packages

**Note:**
- xdg-utils is DUPLICATE with home.nix

---

### 11. platforms/nixos/desktop/multi-wm.nix

#### Sway extra packages
```
swaylock
swayidle
waybar
wofi
foot
```

#### System packages
```
foot          # Common terminal for all WMs (DUPLICATE - also in sway extra packages)
wofi          # Application launcher for all WMs (DUPLICATE - also in sway extra packages)
swaylock      # Screen lockers (DUPLICATE - also in sway extra packages)
kdePackages.dolphin
mako          # Notification daemon
swaybg        # Background settings
grim          # Screenshot tools
slurp         # Screenshot tools
wl-clipboard  # Clipboard
```

**Total multi-wm.nix Packages:** 9 unique packages

**Duplications Within File:**
- foot (listed in sway extra packages AND system packages)
- wofi (listed in sway extra packages AND system packages)
- swaylock (listed in sway extra packages AND system packages)

---

### 12. platforms/nixos/desktop/hyprland-config.nix

```
qt5.qtwayland
qt6.qtwayland
glib
```

**Total hyprland-config.nix Packages:** 3 packages

---

## 🔴 CONFIRMED DUPLICATIONS

### 1. jetbrains-mono
- **File 1:** platforms/common/packages/fonts.nix
- **File 2:** platforms/nixos/system/configuration.nix (line 58)
- **Impact:** Low (font duplication, harmless)
- **Recommendation:** Remove from configuration.nix, keep in fonts.nix (cross-platform)
- **Effort:** 5 minutes
- **Priority:** Low

### 2. xdg-utils
- **File 1:** platforms/nixos/users/home.nix (line 30)
- **File 2:** platforms/nixos/desktop/security-hardening.nix (line 38)
- **Impact:** Medium (duplicate installation)
- **Recommendation:** Move to base.nix (cross-platform), remove from both files
- **Effort:** 10 minutes
- **Priority:** Medium

### 3. rofi
- **File 1:** platforms/nixos/users/home.nix (line 27)
- **File 2:** platforms/nixos/desktop/multi-wm.nix (line 55)
- **Impact:** Low (duplicate installation)
- **Recommendation:** Remove from home.nix, keep in multi-wm.nix (system-wide for all WMs)
- **Effort:** 5 minutes
- **Priority:** Low

### 4. pavucontrol
- **File 1:** platforms/nixos/users/home.nix (line 26)
- **File 2:** platforms/nixos/desktop/hyprland.nix (commented on line 339)
- **Impact:** Low (only one active instance)
- **Recommendation:** Keep in home.nix (user-level access is correct), keep comment in hyprland.nix
- **Effort:** 2 minutes (add comment clarifying)
- **Priority:** Very Low

---

## 🟡 INTERNAL DUPLICATIONS (Within Same File)

### multi-wm.nix Internal Duplications
- **foot:** Listed twice (lines 15 and 52)
- **wofi:** Listed twice (lines 14 and 55)
- **swaylock:** Listed twice (lines 11 and 58)

**Note:** This is actually by design! These packages are listed twice:
1. In `programs.sway.extraPackages` (Sway-specific)
2. In `environment.systemPackages` (available to all WMs)

**Impact:** None (Nix deduplicates automatically)
**Recommendation:** No action needed (Nix handles this efficiently)
**Effort:** N/A
**Priority:** None

---

## 🟢 POTENTIAL DUPLICATIONS (Further Investigation Needed)

### 1. waybar
- **File 1:** platforms/nixos/desktop/hyprland.nix (imported at line 3)
- **File 2:** platforms/nixos/desktop/multi-wm.nix (line 13)
- **Status:** Potentially duplicate import
- **Impact:** Medium
- **Recommendation:** Investigate if both needed or if one can be shared
- **Effort:** 15 minutes
- **Priority:** Medium

### 2. swaylock
- **File 1:** platforms/nixos/desktop/hyprland.nix (uses hyprlock instead)
- **File 2:** platforms/nixos/desktop/multi-wm.nix (uses swaylock)
- **Status:** Different lockers for different WMs
- **Impact:** None (intentional differentiation)
- **Recommendation:** No action needed
- **Effort:** N/A
- **Priority:** None

### 3. Notification Daemons
- **File 1:** platforms/nixos/desktop/hyprland.nix (dunst)
- **File 2:** platforms/nixos/desktop/multi-wm.nix (mako)
- **Status:** Different daemons for different WMs
- **Impact:** None (intentional differentiation)
- **Recommendation:** No action needed
- **Effort:** N/A
- **Priority:** None

---

## 🎯 EASY WINS (Low Effort, High Value)

### Priority 1 (Immediate - 20 minutes total)
1. **Remove jetbrains-mono from configuration.nix** (5 min)
   - Keep only in fonts.nix
   - Value: Clean up duplication

2. **Remove rofi from home.nix** (5 min)
   - Keep only in multi-wm.nix
   - Value: System-wide availability

3. **Move xdg-utils to base.nix** (10 min)
   - Remove from home.nix and security-hardening.nix
   - Value: Cross-platform consistency

### Priority 2 (Medium - 15 minutes total)
4. **Add clarifying comment for pavucontrol** (2 min)
   - Document why it's in home.nix
   - Value: Clear documentation

5. **Investigate waybar duplication** (15 min)
   - Check if both imports are necessary
   - Value: Potential consolidation

---

## 📊 Package Statistics

### Total Package Count by Category
- **Base System Packages:** 48-51 packages
- **Font Packages:** 1 package
- **Darwin Packages:** 1 package
- **NixOS System Packages:** 2 packages
- **NixOS User Packages:** 3 packages
- **Hyprland Packages:** 13 packages
- **AMD GPU Packages:** 4 packages
- **Monitoring Packages:** 6 packages
- **AI/ML Packages:** 7 packages
- **Security Packages:** 33 packages
- **Multi-WM Packages:** 9 unique packages
- **Hyprland Config Packages:** 3 packages

**Total Unique Packages:** ~130 packages (after deduplication)

### Duplication Rate
- **Confirmed Duplications:** 4 packages
- **Internal Duplications:** 3 packages (by design)
- **Potential Duplications:** 1 package
- **Duplication Percentage:** ~3% (very good!)

---

## 💡 Recommendations

### Immediate Actions (M2 Task)
1. ✅ **Remove jetbrains-mono from configuration.nix**
2. ✅ **Move xdg-utils to base.nix**
3. ✅ **Remove rofi from home.nix**
4. ✅ **Add documentation for pavucontrol**

### Medium Priority (M3 Task)
1. **Investigate waybar duplication**
2. **Review cross-platform package consistency**

### Low Priority
1. **Add more packages to base.nix** (if commonly used)
2. **Consider consolidating monitoring tools**

---

## 🎉 Positive Findings

### What's Working Well
1. **Good separation of concerns** - Packages organized by function
2. **Cross-platform sharing** - base.nix for common packages
3. **Platform-specific isolation** - NixOS-only packages in dedicated modules
4. **Service-level configuration** - Correct pattern for GPU variables
5. **Low duplication rate** - Only ~3% duplication (excellent!)

### Architecture Strengths
1. **Modular organization** - Easy to maintain
2. **Clear boundaries** - Each module has specific purpose
3. **Cross-platform support** - Shared base with platform-specific overlays
4. **Declarative configuration** - All packages declared explicitly

---

## 🚀 Next Steps

1. **M2: Fix remaining package duplications** (60 min)
   - Execute Priority 1 easy wins (20 min)
   - Execute Priority 2 tasks (15 min)
   - Test and validate (10 min)
   - Document changes (15 min)

2. **M3: Cross-platform consistency check** (60 min)
   - Compare Darwin vs NixOS packages
   - Identify inconsistencies
   - Plan consolidation strategy

3. **M5: Fix configuration duplications** (45 min)
   - Consolidate repeated configuration blocks
   - Extract to common modules where appropriate

---

## 📈 Quality Metrics

**Before Optimization:**
- Total packages: ~133 packages
- Confirmed duplications: 4
- Duplication rate: 3%

**After Optimization (Projected):**
- Total packages: ~130 packages
- Confirmed duplications: 0
- Duplication rate: 0%

**Improvement:** 3 packages removed (~2.3% reduction)

---

*Audit completed: 2025-12-26 20:30 CET*
*Total time: ~30 minutes*
*Status: ✅ READY FOR DE-DUPLICATION*
