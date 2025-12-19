{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.programs.ghost-btop-wallpaper;
in
{
  options.programs.ghost-btop-wallpaper = {
    enable = mkEnableOption "Ghost Window btop wallpaper (authentic btop)";

    updateRate = mkOption {
      type = types.int;
      default = 2000;
      description = "btop update rate in milliseconds";
    };

    backgroundOpacity = mkOption {
      type = types.str;
      default = "0.0";
      description = "Background opacity (0.0 = transparent, 1.0 = solid)";
    };
  };

  config = mkIf cfg.enable {
    # Step 1: Ghost terminal configuration
    xdg.configFile."kitty/btop-bg.conf".text = ''
      # FONT & COLORS
      font_family      JetBrainsMono Nerd Font
      font_size        13
      background_opacity ${cfg.backgroundOpacity}

      # REMOVE UI ELEMENTS
      window_padding_width 20
      cursor_shape     underline
      cursor_blink_interval 0
      enable_audio_bell no

      # INTERACTION SETTINGS
      mouse_hide_wait 0
      confirm_os_window_close 0
    '';

    # Step 2: Launch script and macOS support
    home.packages = [
      (pkgs.writeShellScriptBin "launch-btop-bg" ''
        # Check if already running to prevent duplicates on reload
        if pgrep -f "kitty --class btop-bg"; then
          echo "🦀 Ghost btop already running"
          exit 0
        fi

        echo "👻 Launching Ghost btop..."
        # Launch Kitty with specific class, title, and config
        ${pkgs.kitty}/bin/kitty \
          --config ${config.xdg.configHome}/kitty/btop-bg.conf \
          --class "btop-bg" \
          --title "System Monitor Wallpaper" \
          --hold \
          ${pkgs.btop}/bin/btop --utf-force
      '')

      (pkgs.writeShellScriptBin "setup-btop-wallpaper-macos" ''
        # Check if SketchyBar is available
        if command -v sketchybar >/dev/null 2>&1; then
          echo "🍎 Setting up btop wallpaper for macOS with SketchyBar..."

          # Start the ghost btop if not already running
          launch-btop-bg

          # Wait a moment for the window to appear
          sleep 2

          # Use SketchyBar to position and style the window
          # Note: This requires SketchyBar with window management capabilities
          sketchybar --query bar | grep -q "btop-bg" && {
            echo "✅ btop wallpaper configured for macOS"
          } || {
            echo "⚠️  SketchyBar window management not available"
          }
        else
          echo "🔴 SketchyBar not found. Install SketchyBar for macOS integration."
          echo "📋 To use without SketchyBar, manually start with: launch-btop-bg"
          echo "💡 Then use your preferred window manager to set it as desktop background"
        fi
      '')
    ];

    # Step 3: btop configuration for wallpaper use
    xdg.configFile."btop/btop.conf".text = ''
      # Minimalist settings for wallpaper use
      color_theme = "tty"
      theme_background = False
      update_ms = ${toString cfg.updateRate}
      cpu_graph_upper = "Total"
      cpu_graph_lower = "Total"
      show_battery = False
      check_temp = True
    '';

    # Step 4: Window manager configuration
    wayland.windowManager.hyprland = mkIf config.wayland.windowManager.hyprland.enable {
      settings = {
        # Auto-start the ghost script
        exec-once = [ "launch-btop-bg" ];

        # Ghost window rules
        windowrulev2 = [
          # GEOMETRY & POSITIONING
          "fullscreen, class:^(btop-bg)$"
          "float, class:^(btop-bg)$"
          "maximize, class:^(btop-bg)$"

          # LAYERING (The Secret Sauce)
          "keepbelow, class:^(btop-bg)$"
          "noborder, class:^(btop-bg)$"
          "noshadow, class:^(btop-bg)$"

          # INTERACTION
          "noinitialfocus, class:^(btop-bg)$"
          "noanim, class:^(btop-bg)$"
          "pin, class:^(btop-bg)$"
        ];
      };
    };

    # Step 5: macOS support via SketchyBar (if available)
    # Note: macOS setup script is included in home.packages above

    # Step 6: macOS auto-start (if requested)
    launchd.agents.btop-wallpaper = mkIf (config.programs.ghost-btop-wallpaper.enable && pkgs.stdenv.isDarwin) {
      enable = true;
      config = {
        Label = "com.user.btop-wallpaper";
        ProgramArguments = [ "${pkgs.bash}/bin/bash" "-c" "launch-btop-bg" ];
        RunAtLoad = true;
        KeepAlive = false;
        StandardOutPath = "${config.home.homeDirectory}/.local/share/btop-wallpaper.log";
        StandardErrorPath = "${config.home.homeDirectory}/.local/share/btop-wallpaper.error.log";
      };
    };
  };
}