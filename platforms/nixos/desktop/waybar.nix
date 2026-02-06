{pkgs, ...}: {
  programs.waybar = {
    enable = true;

    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 55;
        spacing = 8;

        modules-left = [
          "hyprland/workspaces"
          "hyprland/submap"
          "hyprland/window"
          "custom/gpu"
        ];

        modules-center = [
          "idle_inhibitor"
          "clock"
          "custom/media"
        ];

        modules-right = [
          "custom/privacy"
          "pulseaudio"
          "network"
          "custom/netbandwidth"
          "cpu"
          "memory"
          "temperature"
          "backlight"
          "battery"
          "custom/sudo"
          "custom/clipboard"
          "tray"
          "custom/power"
        ];

        # Modules configuration
        "hyprland/workspaces" = {
          disable-scroll = true;
          all-outputs = true;
          format = "{name}";
          swap-icon-label = false;
          format-icons = {
            persistent = "";
            default = "";
            urgent = "";
            active = "󰮯";
          };
        };

        "hyprland/submap" = {
          format = "<span style='italic'> {text}</span>";
        };

        "idle_inhibitor" = {
          format = "{icon}";
          format-icons = {
            activated = "";
            deactivated = "";
          };
        };

        "clock" = {
          format = "<span>󰥔</span> {:%H:%M}";
          format-alt = "<span>󰃭</span> {:%Y-%m-%d}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        };

        "cpu" = {
          format = "{usage}% ";
          tooltip = true;
          tooltip-format = "CPU: {usage}%\nLoad: {load}";
          interval = 2;
          min-length = 6;
          # Tiered states for dynamic coloring
          states = {
            low = 0;
            lower-medium = 30;
            medium = 50;
            upper-medium = 70;
            high = 85;
          };
        };

        "memory" = {
          format = "{percentage}% ";
          tooltip = true;
          tooltip-format = "RAM: {used:0.1f}GB / {total:0.1f}GB\nSwap: {swapUsed:0.1f}GB / {swapTotal:0.1f}GB";
          interval = 3;
          min-length = 6;
          # Tiered states for dynamic coloring
          states = {
            low = 0;
            lower-medium = 40;
            medium = 60;
            upper-medium = 75;
            high = 90;
          };
        };

        "temperature" = {
          critical-threshold = 80;
          format = "{temperatureC}°C {icon}";
          format-icons = ["" "" ""];
          tooltip = true;
          tooltip-format = "Temperature: {temperatureC}°C\nCritical at: 80°C";
        };

        "battery" = {
          states = {
            low = 0;
            lower-medium = 20;
            medium = 40;
            upper-medium = 60;
            high = 80;
            warning = 30;
            critical = 15;
          };
          format = "{capacity}% {icon}";
          format-charging = "{capacity}% ";
          format-plugged = "{capacity}% ";
          format-alt = "{time} {icon}";
          format-icons = ["" "" "" "" ""];
          tooltip = true;
          tooltip-format = "{timeTo}\n{capacity}% remaining";
        };

        "network" = {
          format-wifi = "{essid} ({signalStrength}%) ";
          format-ethernet = "{ipaddr}/{cidr} ";
          tooltip-format = "{ifname} via {gwaddr} \nUp: {bandwidthUpBits}\nDown: {bandwidthDownBits}";
          format-linked = "{ifname} (No IP) ";
          format-disconnected = "Disconnected ⚠";
          format-alt = "{ifname}: {ipaddr}/{cidr}";
          interval = 5;
        };

        "pulseaudio" = {
          format = "{volume}% {icon} {format_source}";
          format-bluetooth = "{volume}% {icon} {format_source}";
          format-bluetooth-muted = " {icon} {format_source}";
          format-muted = " {format_source}";
          format-source = "{volume}% ";
          format-source-muted = "";
          format-icons = {
            headphone = "";
            hands-free = "";
            headset = "";
            phone = "";
            portable = "";
            car = "";
            default = ["" "" ""];
          };
          on-click = "pavucontrol";
          on-scroll-up = "pamixer -i 5";
          on-scroll-down = "pamixer -d 5";
          tooltip = true;
          tooltip-format = "{desc}\nVolume: {volume}%";
        };

        "custom/media" = {
          format = "{icon} {text}";
          format-icons = {
            DEFAULT = "🎵";
            spotify = "";
            firefox = "";
            chromium = "";
          };
          exec = "playerctl metadata --format '{artist} - {title}' 2>/dev/null || echo 'Nothing playing'";
          interval = 5;
          tooltip = false;
          on-click = "playerctl play-pause";
          on-scroll-up = "playerctl next";
          on-scroll-down = "playerctl previous";
        };

        "backlight" = {
          format = "{icon} {percent}%";
          format-icons = ["🌑" "🌒" "🌓" "🌔" "🌕"];
          on-scroll-up = "brightnessctl set +1%";
          on-scroll-down = "brightnessctl set 1%-";
          tooltip = true;
          tooltip-format = "Brightness: {percent}%";
        };

        "custom/privacy" = {
          format = "{icon}";
          exec = pkgs.writeShellScript "waybar-privacy" ''
            # Check for privacy-sensitive conditions
            WEBCAM=$(${pkgs.lsof}/bin/lsof /dev/video0 2>/dev/null | ${pkgs.gawk}/bin/awk 'NR>1 {print $1}' | sort -u | tr '\n' ' ' || echo "")
            MIC=$(${pkgs.lsof}/bin/lsof /dev/snd/pcmC0D0c 2>/dev/null | ${pkgs.gawk}/bin/awk 'NR>1 {print $1}' | sort -u | tr '\n' ' ' || echo "")

            # Check for screen sharing (common screen capture processes)
            SCREENSHARE=$(pgrep -x "wf-recorder|ffmpeg|obs|simplescreenrec" 2>/dev/null | wc -l)

            ICON=""
            if [ -n "$WEBCAM" ]; then
              ICON="󰖠"
            elif [ -n "$MIC" ]; then
              ICON="󰍬"
            elif [ "$SCREENSHARE" -gt 0 ]; then
              ICON="󰹑"
            fi

            echo "$ICON"
          '';
          exec-if = "which lsof";
          interval = 5;
          tooltip = true;
          tooltip-format = "Privacy Status:\n󰖠 Webcam in use\n󰍬 Microphone in use\n󰹑 Screen sharing active";
        };

        "custom/sudo" = {
          format = "{text}";
          exec = pkgs.writeShellScript "waybar-sudo-status" ''
            if pgrep -x sudo >/dev/null 2>&1; then
              echo "⚠️"
            else
              echo ""
            fi
          '';
          interval = 2;
          tooltip = true;
          tooltip-format = "Sudo status: {text}";
          on-click = pkgs.writeShellScript "waybar-sudo-reset" ''
            # Check if sudo timestamp exists
            if sudo -n true 2>/dev/null; then
              # Timestamp exists, invalidate it
              sudo -k
              notify-send "Sudo" "Sudo timestamp cleared"
            else
              notify-send "Sudo" "No active sudo session"
            fi
          '';
        };

        "custom/clipboard" = {
          format = "📋 {text}";
          exec = pkgs.writeShellScript "waybar-clipboard" ''
            CLIP_CONTENT=$(${pkgs.cliphist}/bin/cliphist list | head -1 | ${pkgs.gawk}/bin/awk -F'\t' '{print $2}' || echo "Empty")
            # Truncate and escape
            CLIP_TRUNCATED=$(echo "$CLIP_CONTENT" | head -c 20)
            if [ "''${#CLIP_CONTENT}" -gt 20 ]; then
              CLIP_TRUNCATED="''${CLIP_TRUNCATED}..."
            fi
            # Escape special characters for Pango markup
            echo "$CLIP_TRUNCATED" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'
          '';
          interval = 5;
          tooltip = true;
          tooltip-format = "Clipboard History\nClick to open menu";
          on-click = pkgs.writeShellScript "waybar-clipboard-menu" ''
            ${pkgs.cliphist}/bin/cliphist list | ${pkgs.rofi}/bin/rofi -dmenu -p 'Clipboard:' -theme-str 'window {width: 50%;}' | ${pkgs.cliphist}/bin/cliphist decode | ${pkgs.wl-clipboard}/bin/wl-copy
          '';
        };

        "custom/power" = {
          format = "⏻";
          on-click = "wlogout";
          tooltip = "Power menu";
        };

        "custom/gpu" = {
          format = "🌡️ {text}";
          exec = pkgs.writeShellScript "waybar-gpu-temp" ''
            ${pkgs.lm_sensors}/bin/sensors | grep 'Tctl' | awk '{print $2}' | tr -d '+'
          '';
          exec-if = "which sensors";
          interval = 2;
          tooltip = "AMD GPU Temperature";
          tooltip-format = "Tctl: {text}°C";
        };

        "custom/netbandwidth" = {
          format = "📶 {text}";
          exec = pkgs.writeShellScript "waybar-netbandwidth" ''
            # Get active network interface
            IFACE=$(${pkgs.iproute2}/bin/ip route | ${pkgs.gawk}/bin/awk '/default/ {print $5}')
            [ -z "$IFACE" ] && IFACE="eth0"

            # Get IP address
            IP=$(${pkgs.iproute2}/bin/ip -4 addr show dev "$IFACE" 2>/dev/null | ${pkgs.gawk}/bin/awk '/inet/ {print $2}' | cut -d'/' -f1)
            [ -z "$IP" ] && IP="No IP"

            echo "$IFACE: $IP"
          '';
          exec-if = "which ip";
          interval = 10;
          tooltip-format = "Network Interface: {text}\nIP Address: {text}";
          tooltip = true;
        };
      };
    };

    style = ''
      * {
        border: none;
        border-radius: 8px;
        font-family: "JetBrainsMono Nerd Font";
        font-size: 18px;
        min-height: 0;
        margin: 3px 2px;
        padding: 0 8px;
        transition: all 0.15s ease;
      }

      window#waybar {
        background: rgba(26, 27, 38, 0.85);
        color: #cdd6f4;
        border-radius: 8px;
        border: 1px solid rgba(137, 180, 250, 0.15);
        box-shadow: 0 2px 8px rgba(0, 0, 0, 0.25);
      }

      #workspaces button {
        padding: 0 6px;
        background-color: transparent;
        color: #bac2de;
        border-radius: 6px;
        transition: all 0.2s ease;
        font-weight: 500;
      }

      #workspaces button:hover {
        background: rgba(137, 180, 250, 0.15);
        color: #cdd6f4;
      }

      #workspaces button.active {
        background: linear-gradient(45deg, #89b4fa, #b4befe);
        color: #1e1e2e;
        font-weight: bold;
        box-shadow: 0 1px 4px rgba(137, 180, 250, 0.3);
      }

      #workspaces button.persistent {
        color: #6c7086;
        font-weight: normal;
      }

      #workspaces button.urgent {
        background: rgba(243, 139, 168, 0.3);
        color: #f38ba8;
      }

      #custom-media,
      #idle_inhibitor,
      #submap,
      #clock,
      #battery,
      #backlight,
      #cpu,
      #memory,
      #temperature,
      #network,
      #pulseaudio,
      #custom-security,
      #custom-clipboard,
      #custom-power,
      #custom-privacy,
      #tray {
        padding: 0 8px;
        margin: 0 2px;
        border-radius: 6px;
        transition: all 0.15s ease;
      }

      #custom-media {
        background: rgba(166, 227, 233, 0.15);
        color: #94e2d5;
      }

      #idle_inhibitor {
        background: rgba(245, 224, 220, 0.15);
        color: #f5e0dc;
      }

      #idle_inhibitor.activated {
        background: rgba(243, 139, 168, 0.3);
        color: #f38ba8;
      }

      #submap {
        background: rgba(203, 166, 247, 0.15);
        color: #cba6f7;
      }

      #clock {
        background: linear-gradient(45deg, #89b4fa, #b4befe);
        color: #1e1e2e;
        font-weight: bold;
      }

      /* CPU tiered colors - dynamic based on usage */
      #cpu.low {
        background: rgba(166, 227, 161, 0.15);
        color: #a6e3a1;
      }

      #cpu.lower-medium {
        background: rgba(249, 226, 175, 0.15);
        color: #f9e2af;
      }

      #cpu.medium {
        background: rgba(250, 179, 135, 0.15);
        color: #fab387;
      }

      #cpu.upper-medium {
        background: rgba(243, 139, 168, 0.15);
        color: #f38ba8;
      }

      #cpu.high {
        background: rgba(243, 139, 168, 0.3);
        color: #f38ba8;
        font-weight: bold;
      }

      /* Memory tiered colors - dynamic based on usage */
      #memory.low {
        background: rgba(166, 227, 161, 0.15);
        color: #a6e3a1;
      }

      #memory.lower-medium {
        background: rgba(249, 226, 175, 0.15);
        color: #f9e2af;
      }

      #memory.medium {
        background: rgba(250, 179, 135, 0.15);
        color: #fab387;
      }

      #memory.upper-medium {
        background: rgba(243, 139, 168, 0.15);
        color: #f38ba8;
      }

      #memory.high {
        background: rgba(243, 139, 168, 0.3);
        color: #f38ba8;
        font-weight: bold;
      }

      /* Battery tiered colors - dynamic based on level */
      #battery.low {
        background: rgba(243, 139, 168, 0.3);
        color: #f38ba8;
        font-weight: bold;
      }

      #battery.lower-medium {
        background: rgba(250, 179, 135, 0.15);
        color: #fab387;
      }

      #battery.medium {
        background: rgba(249, 226, 175, 0.15);
        color: #f9e2af;
      }

      #battery.upper-medium {
        background: rgba(166, 227, 161, 0.15);
        color: #a6e3a1;
      }

      #battery.high {
        background: rgba(166, 227, 161, 0.15);
        color: #a6e3a1;
      }

      #battery.charging, #battery.plugged {
        color: #a6e3a1;
        background: rgba(166, 227, 161, 0.25);
      }

      #battery.critical:not(.charging) {
        background: rgba(243, 139, 168, 0.4);
        color: #f38ba8;
        font-weight: bold;
        animation: blink 1s infinite;
      }

      @keyframes blink {
        0% { opacity: 1; }
        50% { opacity: 0.5; }
        100% { opacity: 1; }
      }

      #backlight {
        background: rgba(249, 226, 175, 0.15);
        color: #f9e2af;
      }

      #temperature {
        background: rgba(250, 179, 135, 0.15);
        color: #fab387;
      }

      #temperature.critical {
        background: rgba(243, 139, 168, 0.3);
        color: #f38ba8;
        font-weight: bold;
        animation: blink 1s infinite;
      }

      #network {
        background: rgba(137, 180, 250, 0.15);
        color: #89b4fa;
      }

      #network.disconnected {
        background: rgba(243, 139, 168, 0.15);
        color: #f38ba8;
      }

      #pulseaudio {
        background: rgba(249, 226, 175, 0.15);
        color: #f9e2af;
      }

      #pulseaudio.muted {
        background: rgba(108, 112, 134, 0.15);
        color: #6c7086;
      }

      #pulseaudio.bluetooth {
        background: rgba(137, 180, 250, 0.15);
        color: #89b4fa;
      }

      #custom-clipboard {
        background: rgba(243, 139, 168, 0.15);
        color: #f38ba8;
        font-size: 16px;
      }

      #custom-gpu {
        background: rgba(250, 179, 135, 0.15);
        color: #fab387;
      }

      #custom-netbandwidth {
        background: rgba(137, 180, 250, 0.15);
        color: #89b4fa;
      }

      #custom-privacy {
        background: rgba(243, 139, 168, 0.2);
        color: #f38ba8;
        font-size: 16px;
      }

      #custom-security {
        background: rgba(166, 227, 161, 0.15);
        color: #a6e3a1;
        font-weight: bold;
      }

      #custom-power {
        background: rgba(243, 139, 168, 0.15);
        color: #f38ba8;
        padding: 0 8px;
      }

      #custom-power:hover {
        background: rgba(243, 139, 168, 0.3);
      }

      #tray {
        background: rgba(180, 190, 254, 0.15);
        color: #b4befe;
        padding: 0 8px;
      }

      #tray > .passive {
        -gtk-icon-effect: dim;
      }

      #tray > .needs-attention {
        -gtk-icon-effect: highlight;
        background: rgba(243, 139, 168, 0.3);
        border-radius: 6px;
      }
    '';
  };
}
