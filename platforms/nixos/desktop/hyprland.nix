{ pkgs, ... }:

{
  imports = [
    ./waybar.nix
  ];

  # Enable Hyprland via Home Manager
  wayland.windowManager.hyprland = {
    enable = true;

    # Enable Hyprland plugins
    plugins = [
      pkgs.hyprlandPlugins.hyprwinwrap
    ];

    # Recommended settings for best experience
    systemd.enable = true;  # Try enabling for better keybinding support
    xwayland.enable = true;

    settings = {
      "$mod" = "SUPER";
      "$terminal" = "kitty";
      "$menu" = "rofi -show drun -show-icons";

      # For TV display - 200% scaling
      monitor = "HDMI-A-1,preferred,auto,2";  # Adjust HDMI-A-1 to actual output
      # Fallback if above doesn't work:
      # monitor = "preferred,auto,2,transform,1";  # 2x scale + normal orientation

      exec-once = [
        ''waybar''
        ''dunst''
        ''wl-paste --watch cliphist store''
        # Desktop consoles setup
        ''${pkgs.kitty}/bin/kitty --class btop-bg --hold -e btop''                    # System monitor
        ''${pkgs.kitty}/bin/kitty --class htop-bg --hold -e htop''                    # Process monitor
        ''${pkgs.kitty}/bin/kitty --class logs-bg --hold -e journalctl -f''           # System logs
        ''${pkgs.kitty}/bin/kitty --class nvim-bg --hold -e nvim ~/.config/hypr/hyprland.conf'' # Config editor
      ];

      # Hyprwinwrap plugin configuration
      plugin = {
        hyprwinwrap = {
          class = "btop-bg";
        };
      };

      windowrulev2 = [
        # Btop system monitor
        "float,class:^(btop-bg)$"
        "fullscreen,class:^(btop-bg)$"
        "noanim,class:^(btop-bg)$"
        "nofocus,class:^(btop-bg)$"
        "noblur,class:^(btop-bg)$"
        "noshadow,class:^(btop-bg)$"
        "noborder,class:^(btop-bg)$"

        # Htop process monitor
        "float,class:^(htop-bg)$"
        "nofocus,class:^(htop-bg)$"
        "noblur,class:^(htop-bg)$"
        "noshadow,class:^(htop-bg)$"
        "noborder,class:^(htop-bg)$"
        "size 800 600,class:^(htop-bg)$"
        "move 100 100,class:^(htop-bg)$"

        # System logs
        "float,class:^(logs-bg)$"
        "nofocus,class:^(logs-bg)$"
        "noblur,class:^(logs-bg)$"
        "noshadow,class:^(logs-bg)$"
        "noborder,class:^(logs-bg)$"
        "size 800 600,class:^(logs-bg)$"
        "move 920 100,class:^(logs-bg)$"

        # Config editor
        "float,class:^(nvim-bg)$"
        "nofocus,class:^(nvim-bg)$"
        "noblur,class:^(nvim-bg)$"
        "noshadow,class:^(nvim-bg)$"
        "noborder,class:^(nvim-bg)$"
        "size 800 600,class:^(nvim-bg)$"
        "move 100 720,class:^(nvim-bg)$"
      ];

      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
        "col.inactive_border" = "rgba(595959aa)";
        layout = "dwindle";
      };

      # MEMORY & PERFORMANCE OPTIMIZED DECORATION
      decoration = {
        rounding = 8;  # Reduced from 10 for performance
        blur = {
          enabled = true;
          size = 2;  # Reduced from 3
          passes = 1;
          noise = 0.0117;
          contrast = 0.8916;
          brightness = 0.8172;
          ignore_opacity = true;
          new_optimizations = true;  # Enable new blur optimizations
          xray = true;  # X-ray blur for better performance
        };
        drop_shadow = {
          enabled = false;  # Disabled for maximum performance
        };
      };

      # OPTIMIZED ANIMATIONS - BALANCED PERFORMANCE & SMOOTHNESS
      animations = {
        enabled = true;
        # Optimized bezier for smooth but fast animations
        bezier = "myBezier, 0.25, 0.46, 0.45, 0.94";
        # Reduced animation count and speed for better performance
        animation = [
          "windows, 1, 3, myBezier, slide"
          "windowsOut, 1, 2, default, popin 90%"
          "border, 1, 5, default"
          "borderangle, 1, 6, default"
          "fade, 1, 3, default"
          "workspaces, 1, 4, default, slidefadevert"
          "specialWorkspace, 1, 4, default, slidefadevert"
        ];
      };

      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };

      master = {
        # new_is_master = true; # Deprecated in newer Hyprland
      };

      gestures = {
        workspace_swipe = true;
      };

      # PERFORMANCE OPTIMIZATIONS
      misc = {
        force_default_wallpaper = 0;
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        mouse_refocus = false;
        new_window_takes_over_fullscreen = true;
        animate_manual_resizes = false;
        animate_mouse_windowdragging = false;
        enable_swallow = false;
        swallow_regex = "";
        focus_on_activate = true;
        no_direct_scanout = false;
        disable_hyprland_qtutils_workaround = false;
        mouse_move_enables_dpms = false;
        key_press_enables_dpms = false;
        always_follow_on_dnd = true;
        layers_hog_keyboard_focus = true;
      };

      # RENDERING OPTIMIZATIONS - MAXIMUM PERFORMANCE
      render = {
        explicit_sync = true;
        direct_scanout = true;
        expand_undersized_textures = true;
        ignore_performance_warnings = true;
        vrr = 2;
        vfr = true;
        allow_tearing = false;
      };

      # DEBUG & PERFORMANCE MONITORING
      debug = {
        disable_logs = false;
        disable_time = false;
        overlay = false;
        damage_blink = false;
        errors = false;
        disable_vrr = false;
      };

      bind = [
        # APPLICATION LAUNCHING
        "$mod, Q, exec, $terminal"
        "$mod, Return, exec, $terminal"
        "$mod, Space, exec, $menu"
        "$mod, R, exec, $menu"
        "$mod, N, exec, dolphin"
        "$mod, E, exec, dolphin" # File manager (should probably ensure one is installed)
        "$mod, B, exec, firefox" # Browser
        "$mod, D, exec, $menu -show run" # Run command

        # WINDOW MANAGEMENT
        "$mod, C, killactive,"
        "$mod, V, togglefloating,"
        "$mod, F, fullscreen,"
        "$mod, M, fullscreen, 1" # Maximize
        "$mod, P, pseudo," # dwindle
        "$mod, J, togglesplit," # dwindle
        "$mod, T, togglefloating,"

        # FOCUS NAVIGATION
        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"
        "$mod, H, movefocus, l"
        "$mod, L, movefocus, r"
        "$mod, K, movefocus, u"
        "$mod, J, movefocus, d"

        # WINDOW MOVEMENT
        "$mod SHIFT, left, movewindow, l"
        "$mod SHIFT, right, movewindow, r"
        "$mod SHIFT, up, movewindow, u"
        "$mod SHIFT, down, movewindow, d"
        "$mod SHIFT, H, movewindow, l"
        "$mod SHIFT, L, movewindow, r"
        "$mod SHIFT, K, movewindow, u"
        "$mod SHIFT, J, movewindow, d"

        # WORKSPACES
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"
        "$mod, 7, workspace, 7"
        "$mod, 8, workspace, 8"
        "$mod, 9, workspace, 9"
        "$mod, 0, workspace, 10"

        # MOVE TO WORKSPACE
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        "$mod SHIFT, 6, movetoworkspace, 6"
        "$mod SHIFT, 7, movetoworkspace, 7"
        "$mod SHIFT, 8, movetoworkspace, 8"
        "$mod SHIFT, 9, movetoworkspace, 9"
        "$mod SHIFT, 0, movetoworkspace, 10"

        # MOVE WITH WINDOW TO WORKSPACE
        "ALT SHIFT, 1, movetoworkspacesilent, 1"
        "ALT SHIFT, 2, movetoworkspacesilent, 2"
        "ALT SHIFT, 3, movetoworkspacesilent, 3"
        "ALT SHIFT, 4, movetoworkspacesilent, 4"
        "ALT SHIFT, 5, movetoworkspacesilent, 5"
        "ALT SHIFT, 6, movetoworkspacesilent, 6"
        "ALT SHIFT, 7, movetoworkspacesilent, 7"
        "ALT SHIFT, 8, movetoworkspacesilent, 8"
        "ALT SHIFT, 9, movetoworkspacesilent, 9"
        "ALT SHIFT, 0, movetoworkspacesilent, 10"

        # SPECIAL WORKSPACE
        "$mod, S, togglespecialworkspace, magic"
        "$mod SHIFT, S, movetoworkspace, special:magic"

        # SCROLL THROUGH WORKSPACES
        "$mod, mouse_down, workspace, e+1"
        "$mod, mouse_up, workspace, e-1"

        # SYSTEM CONTROLS
        "$mod, Escape, exec, hyprlock" # Lock screen
        "$mod, X, exec, wlogout" # Power menu
        "$mod SHIFT, R, reload" # Reload config
        "$mod SHIFT, E, exec, wlogout" # Power menu
        "$mod, Print, exec, grimblast copy area" # Screenshot area
        "$mod SHIFT, Print, exec, grimblast copy screen" # Screenshot screen
        "$mod CTRL, Print, exec, grimblast copy window" # Screenshot window

        # AUDIO CONTROLS
        ", XF86AudioRaiseVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ +5%"
        ", XF86AudioLowerVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ -5%"
        ", XF86AudioMute, exec, pactl set-sink-mute @DEFAULT_SINK@ toggle"
        ", XF86AudioPlay, exec, playerctl play-pause"
        ", XF86AudioNext, exec, playerctl next"
        ", XF86AudioPrev, exec, playerctl previous"

        # SCREEN BRIGHTNESS
        ", XF86MonBrightnessUp, exec, brightnessctl set +5%"
        ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"

        # DESKTOP TERMINALS TOGGLE (placeholders - need implementation)
        "$mod, F1, exec, hyprctl dispatch focuswindow ^btop-bg$"
        "$mod, F2, exec, hyprctl dispatch focuswindow ^htop-bg$"
        "$mod, F3, exec, hyprctl dispatch focuswindow ^logs-bg$"
        "$mod, F4, exec, hyprctl dispatch focuswindow ^nvim-bg$"
      ];

      bindm = [
        # Move/resize windows with mod + LMB/RMB and dragging
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];
    };
  };

  # Essential packages for this config
  home.packages = with pkgs; [
    # Terminal & Core Tools
    kitty # Terminal
    ghostty # Modern terminal emulator
    kdePackages.dolphin # File manager
    rofi # App launcher (wayland support included)

    # Hyprland Ecosystem - Essential tools
    hyprpaper # Wallpaper utility (official)
    hyprlock # GPU-accelerated screen lock
    hypridle # Idle daemon for automatic lock/suspend
    hyprpicker # Color picker
    hyprsunset # Blue light filter
    hyprpolkitagent # Modern polkit agent for Hyprland

    # Status Bar & Notifications
    waybar # Status bar
    dunst # Notifications
    libnotify # Notification library

    # Clipboard & Utilities
    wl-clipboard # Clipboard support
    cliphist # Clipboard history

    # Animated wallpapers (optional but cool)
    swww # Animated wallpapers with transitions
    imagemagick # Image manipulation for wallpaper management

    # System Monitoring
    btop # System monitor (used for background)
    nvtopPackages.amd # AMD GPU/process monitor
    radeontop # AMD GPU specific monitor
    amdgpu_top # Advanced AMD GPU monitoring

    # Additional useful tools
    pavucontrol # Audio control GUI
    xdg-utils # XDG utilities
    gnome-keyring # Keyring for passwords

    # Enhanced tools for superb setup
    wlogout # Modern logout menu
    grimblast # Enhanced screenshot utility (requires grim and slurp)
    grim # Screenshot tool
    slurp # Area selection tool
    playerctl # Media player control
    brightnessctl # Brightness control

    # LOCAL AI SETUP - vLLM + Ollama for Ryzen AI Max+ 395
    # AMD ROCm for GPU acceleration
    rocmPackages.rocm-runtime
    rocmPackages.rocblas
    rocmPackages.hipblas
    rocmPackages.rocrand
    
    # Python AI packages
    python311

    # Standard nixpkgs packages (CLI tools, not Python libraries)
    ollama  # Model server CLI
    vllm  # Inference server CLI
    
    # OCR Tools
    tesseract  # OCR engine
    tesseract4  # Better OCR
    poppler-utils  # PDF utilities for OCR
    
    # Model quantization and optimization
    llama-cpp
    
    # AI monitoring and tools
    nvtopPackages.amd  # GPU monitoring
    
    # SECURITY MONITORING TOOLS
    # Network & Connection Monitoring
    nethogs # Network process monitoring
    iftop # Network bandwidth monitoring
    iptraf-ng # IP traffic monitoring
    bmon # Network bandwidth monitor
    netsniff-ng # Network packet capture
    wireshark # Network protocol analyzer
    aircrack-ng # WiFi security testing
    
    # System Security Monitoring
    lynis # Security auditing tool
    aide # File integrity monitoring
    osquery # OS monitoring & security analytics
    fail2ban # Intrusion prevention
    
    # Authentication & Access Control
    pamtester # PAM testing
    openssl # Cryptographic toolkit
    gnupg # Encryption & signing
    pass # Password manager
    
    # Process & File Monitoring
    lsof # List open files
    strace # System call tracer
    inotify-tools # File system monitoring
    iotop # I/O monitoring
    perf # Performance analysis
    
    # Log Analysis & Security
    goaccess # Web log analyzer
    ccze # Log colorizer
    
    # Privacy & Anonymity
    tor-browser # Anonymous browsing
    openvpn # VPN client
    wireguard-tools # Modern VPN
    
    # Vulnerability Assessment
    nmap # Network scanning
    masscan # Fast port scanner
    sqlmap # SQL injection testing
    nikto # Web server scanner
    nuclei # Fast vulnerability scanner
    
    # Incident Response
    sleuthkit # Forensic toolkit
    wireshark-cli # Command-line packet analysis
    tcpdump # Packet capture

    # Modern alternatives for desktop terminals
    htop # Process monitor
    neovim # Text editor

    # Privacy-focused browser
    firefox # Standard browser
  ];
}
