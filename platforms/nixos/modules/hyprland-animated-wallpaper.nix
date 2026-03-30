{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.programs.hyprland-animated-wallpaper;
in {
  options.programs.hyprland-animated-wallpaper = {
    enable = lib.mkEnableOption "Hyprland animated wallpaper with swww";

    updateInterval = lib.mkOption {
      type = lib.types.int;
      default = 30;
      description = "Wallpaper update interval in seconds";
    };

    transitionType = lib.mkOption {
      type = lib.types.str;
      default = "any";
      description = "swww transition type: any, left, right, top, bottom, center, outer, random";
    };

    transitionStep = lib.mkOption {
      type = lib.types.int;
      default = 90;
      description = "Transition step (0-255, higher = faster)";
    };

    transitionDuration = lib.mkOption {
      type = lib.types.int;
      default = 3;
      description = "Transition duration in seconds";
    };

    enableGradient = lib.mkEnableOption "Use gradient animations instead of static wallpapers";

    wallpaperDir = lib.mkOption {
      type = lib.types.str;
      default = "$HOME/.local/share/wallpapers";
      description = "Directory containing wallpaper images";
    };
  };

  config = lib.mkIf cfg.enable {
    # Wallpapers directory (only when gradient mode enabled)
    xdg.dataFile."wallpapers" = lib.mkIf cfg.enableGradient {
      source = pkgs.linkFarm "wallpapers" [
      {
        name = "gradient1.png";
        path = pkgs.writeText "gradient1.svg" ''
          <svg xmlns="http://www.w3.org/2000/svg" width="1920" height="1080">
            <defs>
              <linearGradient id="grad1" x1="0%" y1="0%" x2="100%" y2="100%">
                <stop offset="0%" style="stop-color:#0f0c29;stop-opacity:1" />
                <stop offset="50%" style="stop-color:#302b63;stop-opacity:1" />
                <stop offset="100%" style="stop-color:#24243e;stop-opacity:1" />
              </linearGradient>
            </defs>
            <rect width="100%" height="100%" fill="url(#grad1)"/>
          </svg>
        '';
      }
      {
        name = "gradient2.png";
        path = pkgs.writeText "gradient2.svg" ''
          <svg xmlns="http://www.w3.org/2000/svg" width="1920" height="1080">
            <defs>
              <linearGradient id="grad2" x1="0%" y1="0%" x2="100%" y2="100%">
                <stop offset="0%" style="stop-color:#141E30;stop-opacity:1" />
                <stop offset="100%" style="stop-color:#243B55;stop-opacity:1" />
              </linearGradient>
            </defs>
            <rect width="100%" height="100%" fill="url(#grad2)"/>
          </svg>
        '';
      }
      {
        name = "gradient3.png";
        path = pkgs.writeText "gradient3.svg" ''
          <svg xmlns="http://www.w3.org/2000/svg" width="1920" height="1080">
            <defs>
              <linearGradient id="grad3" x1="0%" y1="0%" x2="100%" y2="100%">
                <stop offset="0%" style="stop-color:#0f2027;stop-opacity:1" />
                <stop offset="50%" style="stop-color:#203a43;stop-opacity:1" />
                <stop offset="100%" style="stop-color:#2c5364;stop-opacity:1" />
              </linearGradient>
            </defs>
            <rect width="100%" height="100%" fill="url(#grad3)"/>
          </svg>
        '';
      }
      {
        name = "gradient4.png";
        path = pkgs.writeText "gradient4.svg" ''
          <svg xmlns="http://www.w3.org/2000/svg" width="1920" height="1080">
            <defs>
              <linearGradient id="grad4" x1="0%" y1="0%" x2="100%" y2="100%">
                <stop offset="0%" style="stop-color:#654ea3;stop-opacity:1" />
                <stop offset="100%" style="stop-color:#eaafc8;stop-opacity:1" />
              </linearGradient>
            </defs>
            <rect width="100%" height="100%" fill="url(#grad4)"/>
          </svg>
        '';
      }
      {
        name = "gradient5.png";
        path = pkgs.writeText "gradient5.svg" ''
          <svg xmlns="http://www.w3.org/2000/svg" width="1920" height="1080">
            <defs>
              <linearGradient id="grad5" x1="0%" y1="0%" x2="100%" y2="100%">
                <stop offset="0%" style="stop-color:#ff0099;stop-opacity:1" />
                <stop offset="50%" style="stop-color:#493240;stop-opacity:1" />
                <stop offset="100%" style="stop-color:#0f0c29;stop-opacity:1" />
              </linearGradient>
            </defs>
            <rect width="100%" height="100%" fill="url(#grad5)"/>
          </svg>
        '';
      }
    ];
    };

    # swww daemon and control scripts
    home.packages = [
      (pkgs.writeShellScriptBin "swww-anim-wallpaper" ''
        #!/bin/bash
        # Hyprland Animated Wallpaper Script with swww

        WALLPAPER_DIR="${cfg.wallpaperDir}"
        INTERVAL=${toString cfg.updateInterval}
        TRANSITION="${cfg.transitionType}"
        STEP=${toString cfg.transitionStep}
        DURATION=${toString cfg.transitionDuration}

        # Initialize swww daemon
        echo "🎨 Initializing swww..."
        ${pkgs.swww}/bin/swww-daemon &

        # Wait for daemon to start
        sleep 1

        # Get list of wallpapers
        WALLPAPERS=("$WALLPAPER_DIR"/*)
        WALLPAPER_COUNT=''${#WALLPAPERS[@]}

        if [ $WALLPAPER_COUNT -eq 0 ]; then
          echo "❌ No wallpapers found in $WALLPAPER_DIR"
          exit 1
        fi

        echo "🖼️  Found $WALLPAPER_COUNT wallpapers"

        # Set initial wallpaper
        echo "🎨 Setting initial wallpaper..."
        ${pkgs.swww}/bin/swww img "''${WALLPAPERS[0]}" \
          --transition-type "$TRANSITION" \
          --transition-step "$STEP" \
          --transition-fps 60 \
          --transition-duration "$DURATION"

        # Cycle through wallpapers
        INDEX=0
        while true; do
          sleep "$INTERVAL"
          INDEX=$(( (INDEX + 1) % WALLPAPER_COUNT ))
          echo "🎨 Changing wallpaper to: $(basename "''${WALLPAPERS[$INDEX]}")"
          ${pkgs.swww}/bin/swww img "''${WALLPAPERS[$INDEX]}" \
            --transition-type "$TRANSITION" \
            --transition-step "$STEP" \
            --transition-fps 60 \
            --transition-duration "$DURATION"
        done
      '')

      (pkgs.writeShellScriptBin "swww-next" ''
        #!/bin/bash
        # Switch to next wallpaper manually

        WALLPAPER_DIR="${cfg.wallpaperDir}"
        WALLPAPERS=("$WALLPAPER_DIR"/*)
        WALLPAPER_COUNT=''${#WALLPAPERS[@]}

        if [ $WALLPAPER_COUNT -eq 0 ]; then
          echo "❌ No wallpapers found"
          exit 1
        fi

        # Get current wallpaper index
        CURRENT=$(${pkgs.swww}/bin/swww query | grep -oP 'image: \K[^[:space:]]+')
        CURRENT_INDEX=0
        for i in "''${!WALLPAPERS[@]}"; do
          if [[ "''${WALLPAPERS[$i]}" == *"$CURRENT"* ]]; then
            CURRENT_INDEX=$i
            break
          fi
        done

        # Get next wallpaper
        NEXT_INDEX=$(( (CURRENT_INDEX + 1) % WALLPAPER_COUNT ))

        echo "🎨 Switching to: $(basename "''${WALLPAPERS[$NEXT_INDEX]}")"
        ${pkgs.swww}/bin/swww img "''${WALLPAPERS[$NEXT_INDEX]}" \
          --transition-type "${cfg.transitionType}" \
          --transition-step ${toString cfg.transitionStep} \
          --transition-fps 60 \
          --transition-duration ${toString cfg.transitionDuration}
      '')

      (pkgs.writeShellScriptBin "swww-prev" ''
        #!/bin/bash
        # Switch to previous wallpaper manually

        WALLPAPER_DIR="$HOME/.local/share/wallpapers"
        WALLPAPERS=("$WALLPAPER_DIR"/*)
        WALLPAPER_COUNT=''${#WALLPAPERS[@]}

        if [ $WALLPAPER_COUNT -eq 0 ]; then
          echo "❌ No wallpapers found"
          exit 1
        fi

        # Get current wallpaper index
        CURRENT=$(${pkgs.swww}/bin/swww query | grep -oP 'image: \K[^[:space:]]+')
        CURRENT_INDEX=0
        for i in "''${!WALLPAPERS[@]}"; do
          if [[ "''${WALLPAPERS[$i]}" == *"$CURRENT"* ]]; then
            CURRENT_INDEX=$i
            break
          fi
        done

        # Get previous wallpaper
        PREV_INDEX=$(( (CURRENT_INDEX - 1 + WALLPAPER_COUNT) % WALLPAPER_COUNT ))

        echo "🎨 Switching to: $(basename "''${WALLPAPERS[$PREV_INDEX]}")"
        ${pkgs.swww}/bin/swww img "''${WALLPAPERS[$PREV_INDEX]}" \
          --transition-type "${cfg.transitionType}" \
          --transition-step ${toString cfg.transitionStep} \
          --transition-fps 60 \
          --transition-duration ${toString cfg.transitionDuration}
      '')
    ];

    # Auto-start in Hyprland
    wayland.windowManager.hyprland = lib.mkIf (!pkgs.stdenv.isDarwin && config.wayland.windowManager.hyprland.enable) {
      settings = {
        exec-once = ["swww-anim-wallpaper"];
      };
    };
  };
}
