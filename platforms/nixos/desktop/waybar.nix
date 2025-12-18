{ pkgs, ... }:

{
  programs.waybar = {
    enable = true;
    systemd.enable = true;

    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 30;
        spacing = 4;

        modules-left = [
          "hyprland/workspaces"
          "hyprland/submap"
          "hyprland/window"
        ];

        modules-center = [
          "idle_inhibitor"
          "clock"
          "custom/media"
        ];

        modules-right = [
          "pulseaudio"
          "network"
          "cpu"
          "memory"
          "temperature"
          "backlight"
          "battery"
          "custom/clipboard"
          "tray"
          "custom/power"
        ];

        # Modules configuration
        "hyprland/workspaces" = {
          disable-scroll = true;
          all-outputs = true;
          format = "{name}";
          format-icons = {
            persistent = "";
            default = "";
            urgent = "";
            active = "󰮯";
          };
        };

        "hyprland/submap" = {
          format = "<span style='italic'> {}</span>";
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
          tooltip = false;
        };

        "memory" = {
          format = "{}% ";
        };

        "temperature" = {
          critical-threshold = 80;
          format = "{temperatureC}°C {icon}";
          format-icons = ["" "" "ZE"];
        };

        "battery" = {
          states = {
            warning = 30;
            critical = 15;
          };
          format = "{capacity}% {icon}";
          format-charging = "{capacity}% ";
          format-plugged = "{capacity}% ";
          format-alt = "{time} {icon}";
          format-icons = ["" "" "" "" ""];
        };

        "network" = {
          format-wifi = "{essid} ({signalStrength}%) ";
          format-ethernet = "{ipaddr}/{cidr} ";
          tooltip-format = "{ifname} via {gwaddr} ";
          format-linked = "{ifname} (No IP) ";
          format-disconnected = "Disconnected ⚠";
          format-alt = "{ifname}: {ipaddr}/{cidr}";
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
        };

        "custom/media" = {
          format = "{icon} {}";
          format-icons = {
            DEFAULT = "🎵";
            spotify = "";
          };
          exec = "playerctl metadata --format '{{artist}} - {{title}}' || echo 'Nothing playing'";
          interval = 5;
          tooltip = false;
        };

        "backlight" = {
          # Remove intel_backlight for AMD systems
          # device = "intel_backlight";
          format = "{icon} {percent}%";
          format-icons = ["🌑" "🌒" "🌓" "🌔" "🌕"];
          on-scroll-up = "brightnessctl set +1%";
          on-scroll-down = "brightnessctl set 1%-";
        };

        "custom/clipboard" = {
          format = "📋 {}";
          exec = "cliphist list | head -1 | cut -d'\t' -f2- || echo 'Empty'";
          interval = 5;
          tooltip = false;
          on-click = "cliphist list | rofi -dmenu -p 'Clipboard:' | cliphist decode | wl-copy";
        };

        "custom/power" = {
          format = "⏻";
          on-click = "wlogout";
          tooltip = "Power menu";
        };
      };
    };

    style = ''
      * {
        border: none;
        border-radius: 8px;
        font-family: "JetBrainsMono Nerd Font";
        font-size: 14px;
        min-height: 0;
        margin: 4px 2px;
        padding: 0 8px;
      }

      window#waybar {
        background: rgba(26, 27, 38, 0.8);
        color: #cdd6f4;
        border-radius: 12px;
        border: 1px solid rgba(137, 180, 250, 0.2);
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
        backdrop-filter: blur(10px);
      }

      #workspaces button {
        padding: 0 8px;
        background-color: transparent;
        color: #bac2de;
        border-radius: 8px;
        transition: all 0.3s ease;
      }

      #workspaces button:hover {
        background: rgba(137, 180, 250, 0.2);
        color: #cdd6f4;
        transform: scale(1.05);
      }

      #workspaces button.active {
        background: linear-gradient(45deg, #89b4fa, #b4befe);
        color: #1e1e2e;
        font-weight: bold;
        box-shadow: 0 2px 8px rgba(137, 180, 250, 0.4);
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
      #custom-clipboard,
      #custom-power,
      #tray {
        padding: 0 12px;
        margin: 0 4px;
        border-radius: 8px;
        transition: all 0.2s ease;
      }

      #custom-media {
        background: rgba(166, 227, 233, 0.15);
        color: #94e2d5;
      }

      #idle_inhibitor {
        background: rgba(245, 224, 220, 0.15);
        color: #f5e0dc;
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

      #battery {
        background: rgba(250, 179, 135, 0.15);
        color: #fab387;
      }

      #backlight {
        background: rgba(249, 226, 175, 0.15);
        color: #f9e2af;
      }

      #battery.charging, #battery.plugged {
        color: #a6e3a1;
        background: rgba(166, 227, 161, 0.15);
      }

      #battery.critical:not(.charging) {
        background: rgba(243, 139, 168, 0.3);
        color: #f38ba8;
        animation-name: blink;
        animation-duration: 0.5s;
        animation-timing-function: linear;
        animation-iteration-count: infinite;
        animation-direction: alternate;
      }

      @keyframes blink {
        to {
          background: rgba(243, 139, 168, 0.6);
        }
      }

      #cpu {
        background: rgba(166, 227, 161, 0.15);
        color: #a6e3a1;
      }

      #memory {
        background: rgba(203, 166, 247, 0.15);
        color: #cba6f7;
      }

      #temperature {
        background: rgba(250, 179, 135, 0.15);
        color: #fab387;
      }

      #network {
        background: rgba(137, 180, 250, 0.15);
        color: #89b4fa;
      }

      #pulseaudio {
        background: rgba(249, 226, 175, 0.15);
        color: #f9e2af;
      }

      #pulseaudio.muted {
        background: rgba(108, 112, 134, 0.15);
        color: #6c7086;
      }

      #custom-clipboard {
        background: rgba(243, 139, 168, 0.15);
        color: #f38ba8;
        font-size: 12px;
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
    '';
  };
}
