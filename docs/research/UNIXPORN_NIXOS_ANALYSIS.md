# r/unixporn + Sourcegraph Research: NixOS Hyprland Config Analysis

## Summary of Research

Analyzed top NixOS + Hyprland configurations from:
- github.com/notusknot/dotfiles-nix (588 stars)
- github.com/sioodmy/dotfiles
- github.com/XNM1/linux-nixos-hyprland-config-dotfiles
- github.com/elythh/flake
- github.com/anotherhadi/nixy
- github.com/fufexan/dotfiles

## Cool Features Found in Community Configs

### 1. **Animations & Visual Effects**
- **elythh**: Material Design 3 (MD3) bezier curves - `md3_decel`, `md3_accel`, `md3_standard`
- **anotherhadi**: Custom animation speeds (slow/medium/fast) with dynamic duration calculation
- **XNM1**: Opacity transitions with `active_opacity = 0.7`, shadow effects with blur
- **fufexan**: Smart gaps (no gaps when only one window)

### 2. **Window Management Features**
- **elythh**: Zellij integration with rofi session selector
- **anotherhadi**: UWSM (Universal Wayland Session Manager) integration
- **XNM1**: Pypr scratchpads (terminal, volume, expose, zoom)
- **fufexan**: Toggle helpers (`pkill ${prog} || uwsm app -- ${program}`)

### 3. **Status Bar (Waybar) Enhancements**
- **XNM1**: Dynamic CSS with tiered colors (low/lower-medium/medium/upper-medium/high) for CPU, memory, battery
- **XNM1**: Privacy indicators (webcam, screenshare, audio-in, recording, geo)
- **XNM1**: Multiple bar positions (top, bottom, left) with different styles
- **sioodmy**: Wrapped waybar with custom config/style paths

### 4. **Theming & Colors**
- **All repos**: Catppuccin variants (Mocha, Macchiato)
- **anotherhadi**: Stylix integration for system-wide theming
- **XNM1**: Hyprcursor themes (Catppuccin-Macchiato-Teal)
- **fufexan**: Bibata hyprcursor custom package

### 5. **Cool Tools Discovered**
- **hyprpicker**: Color picker with clipboard integration
- **hyprpolkitagent**: Authentication agent
- **hypridle**: Idle management (better than swayidle)
- **hyprlock**: Modern lock screen
- **cliphist**: Clipboard history manager
- **clipse**: TUI clipboard manager
- **swappy**: Screenshot annotation tool
- **imv**: Minimal image viewer
- **wf-recorder**: Screen recorder
- **brillo**: Brightness control (alternative to brightnessctl)
- **pamixer**: PulseAudio command line mixer
- **zellij**: Terminal multiplexer (alternative to tmux)
- **bemoji**: Emoji picker
- **rofi-rbw**: Bitwarden password manager integration

### 6. **Hyprland Plugins Used**
- **hyprwinwrap**: Background windows (already in current config)
- **hy3**: i3-style tiling with tabs/stacks (already in current config)
- **hyprsplit**: Dynamic window splitting (already in current config)
- **hyprbars**: Window title bars (commented out in fufexan)
- **hyprexpo**: Workspace overview (commented out in fufexan)

### 7. **Smart Configuration Patterns**
- **fufexan**: Smart gaps - removes gaps when only one window
- **elythh**: Submap for resize mode with escape to reset
- **XNM1**: Dual monitor workspace binding (workspaces 1-10 on eDP-1, 11-20 on HDMI)
- **anotherhadi**: Conditional animation speeds based on user preference

### 8. **Notification & Clipboard**
- **elythh**: Cliphist + wl-clipboard integration
- **XNM1**: Dunst with Catppuccin theming
- **anotherhadi**: SwayNC (alternative notification daemon)
- **XNM1**: Custom clipboard management scripts

### 9. **Display Manager Themes**
- **anotherhadi**: SDDM with sddm-astronaut-theme
- **fufexan**: Greetd with custom greeter

### 10. **Unique Keybindings**
- **elythh**: Grouped windows (tabbed) with SUPER+G, SUPER+TAB cycling
- **XNM1**: Resize submap (SUPER+ALT+R), Move submap (SUPER+ALT+M)
- **XNM1**: Quake terminal dropdown (SUPER+grave)
- **elythh**: Zellij attach via rofi (SUPERSHIFT+Z)
- **anotherhadi**: UWSM app launching (uwsm app -- ${program})

## Comparison with Current Setup

### ✅ What's Already Good
1. **Catppuccin Mocha theme** - Already using nix-colors
2. **Waybar configuration** - Comprehensive with custom modules
3. **Hyprland plugins** - hyprwinwrap, hy3, hyprsplit
4. **Basic theming** - Dunst, Kitty already themed
5. **Background widgets** - htop-bg, logs-bg with transparency

### 🔧 Gaps to Address

| Feature | Current | Community Standard | Priority |
|---------|---------|-------------------|----------|
| **Rofi theme** | System default | Catppuccin custom rasi | HIGH |
| **Wlogout** | Unstyled | Catppuccin CSS styling | HIGH |
| **Hyprlock** | Unstyled | Beautiful lock screen | HIGH |
| **Hypridle** | Not configured | Auto-dim, lock, suspend | HIGH |
| **GTK/Qt theme** | Default | Catppuccin via stylix | MEDIUM |
| **Additional fonts** | JetBrains only | Fira Code, Iosevka | MEDIUM |
| **Clipboard manager** | Basic cliphist | rofi integration | MEDIUM |
| **Foot terminal** | Not installed | Alternative to Kitty | LOW |
| **Hyprcursor** | X cursor | Bibata hyprcursor | LOW |
| **Zellij** | Not installed | Modern tmux alt | LOW |
| **Smart gaps** | No | No gaps when single window | LOW |
| **Animation curves** | Basic bezier | MD3 curves | LOW |

## Recommended Implementation Priority

### Phase 1 (Immediate - High Impact)
1. Rofi Catppuccin theme
2. Wlogout styling
3. Hyprlock configuration
4. Hypridle setup

### Phase 2 (Polish - Medium Impact)
5. GTK/Qt theming
6. Additional fonts (Fira Code Nerd, Iosevka)
7. Clipboard manager improvements
8. Kitty -> Foot comparison/config

### Phase 3 (Enhancement - Nice to Have)
9. Smart gaps implementation
10. Hyprcursor setup
11. Animation curve improvements
12. Zellij exploration

## Cool UI Patterns to Adopt

### 1. **Dynamic Waybar Colors**
```css
#cpu.low { color: @rosewater; }
#cpu.lower-medium { color: @yellow; }
#cpu.medium { color: @peach; }
#cpu.upper-medium { color: @maroon; }
#cpu.high { color: @red; }
```

### 2. **Submap for Resize Mode**
```conf
submap = resize
binde = , right, resizeactive, 10 0
bind = , escape, submap, reset
submap = reset
```

### 3. **Smart Gaps Toggle**
```nix
"SUPER, M, exec, hyprctl keyword dwindle:no_gaps_when_only $(($(hyprctl getoption dwindle:no_gaps_when_only -j | jaq -r '.int') ^ 1))"
```

### 4. **UWSM App Launching**
```nix
bind = "$mod, RETURN, exec, uwsm app -- ${pkgs.ghostty}/bin/ghostty"
```

### 5. **Grouped Windows**
```conf
bind = SUPER, G, togglegroup
bind = SUPER, TAB, changegroupactive, f
bind = SUPERSHIFT, TAB, changegroupactive, b
```

## Next Steps

1. Implement Phase 1 items (Rofi, Wlogout, Hyprlock, Hypridle)
2. Add missing programs to packages
3. Update Hyprland configuration with new keybindings
4. Test and refine
