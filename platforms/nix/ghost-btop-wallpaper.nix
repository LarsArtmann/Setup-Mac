{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.services.ghost-btop-wallpaper;
  user = "larsartmann";
  homeDir = "/Users/${user}";
in
{
  options.services.ghost-btop-wallpaper = {
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

    autoStart = mkOption {
      type = types.bool;
      default = true;
      description = "Enable auto-start via launchd";
    };
  };

  config = mkIf cfg.enable {
    # Install required packages system-wide
    environment.systemPackages = with pkgs; [
      btop
      kitty
    ];

    # Create Kitty configuration for btop wallpaper
    environment.etc."kitty/btop-bg.conf".text = ''
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

    # Create btop configuration
    environment.etc."btop/btop.conf".text = ''
      # Minimalist settings for wallpaper use
      color_theme = "tty"
      theme_background = False
      update_ms = ${toString cfg.updateRate}
      cpu_graph_upper = "Total"
      cpu_graph_lower = "Total"
      show_battery = False
      check_temp = True
    '';

    # Create launch script as Nix derivation
    environment.etc."ghost-btop/launch-btop-bg.sh".source = pkgs.writeShellScript "launch-btop-bg" ''
      # Check if already running to prevent duplicates on reload
      if pgrep -f "kitty --class btop-bg"; then
        echo "🦀 Ghost btop already running"
        exit 0
      fi

      echo "👻 Launching Ghost btop..."
      # Launch Kitty with specific class, title, and config
      ${pkgs.kitty}/bin/kitty \
        --config /etc/kitty/btop-bg.conf \
        --class "btop-bg" \
        --title "System Monitor Wallpaper" \
        --hold \
        ${pkgs.btop}/bin/btop --utf-force
    '';

    # Make launch script executable via system activation script
    system.activationScripts.ghost-btop-wallpaper = mkIf cfg.enable ''
      # Create user directories if they don't exist
      mkdir -p ${homeDir}/.local/bin
      mkdir -p ${homeDir}/.local/share
      mkdir -p ${homeDir}/.config/kitty
      mkdir -p ${homeDir}/.config/btop

      # Link configurations to user directories
      ln -sf /etc/kitty/btop-bg.conf ${homeDir}/.config/kitty/btop-bg.conf
      ln -sf /etc/btop/btop.conf ${homeDir}/.config/btop/btop.conf
      ln -sf /etc/ghost-btop/launch-btop-bg.sh ${homeDir}/.local/bin/launch-btop-bg

      # Make launch script executable
      chmod +x ${homeDir}/.local/bin/launch-btop-bg
    '';

    # Create launchd agent for auto-start
    launchd.agents.btop-wallpaper = mkIf cfg.autoStart {
      enable = true;
      config = {
        Label = "com.user.btop-wallpaper";
        ProgramArguments = [
          "${pkgs.bash}/bin/bash"
          "-c"
          "${homeDir}/.local/bin/launch-btop-bg"
        ];
        RunAtLoad = true;
        KeepAlive = false;
        StandardOutPath = "${homeDir}/.local/share/btop-wallpaper.log";
        StandardErrorPath = "${homeDir}/.local/share/btop-wallpaper.error.log";
        ProcessType = "Background";
      };
    };

    # User management - ensure user exists
    users.users.${user} = {
      name = user;
      home = homeDir;
      shell = pkgs.fish;
    };

    # Create management scripts
    environment.etc."ghost-btop/manage-btop-wallpaper.sh".source = pkgs.writeShellScript "manage-btop-wallpaper" ''
      case "$1" in
        start)
          echo "🚀 Starting btop wallpaper..."
          ${homeDir}/.local/bin/launch-btop-bg
          ;;
        stop)
          echo "🛑 Stopping btop wallpaper..."
          pkill -f "kitty --class btop-bg"
          ;;
        restart)
          echo "🔄 Restarting btop wallpaper..."
          pkill -f "kitty --class btop-bg"
          sleep 2
          ${homeDir}/.local/bin/launch-btop-bg
          ;;
        status)
          if pgrep -f "kitty --class btop-bg"; then
            echo "✅ btop wallpaper is running"
          else
            echo "❌ btop wallpaper is not running"
          fi
          ;;
        *)
          echo "Usage: $0 {start|stop|restart|status}"
          exit 1
          ;;
      esac
    '';

    # Link management script to user bin
    system.activationScripts.ghost-btop-management = mkIf cfg.enable ''
      ln -sf /etc/ghost-btop/manage-btop-wallpaper.sh ${homeDir}/.local/bin/manage-btop-wallpaper
      chmod +x ${homeDir}/.local/bin/manage-btop-wallpaper
    '';
  };
}