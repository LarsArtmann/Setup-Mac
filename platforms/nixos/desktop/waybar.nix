{pkgs, ...}: {
  programs.waybar = {
    enable = true;
    systemd.enable = true;

    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 42;
        spacing = 4;

        modules-left = [
          "niri/workspaces"
          "niri/window"
        ];

        modules-center = [
          "clock"
          "custom/media"
        ];

        modules-right = [
          "custom/dns-stats"
          "custom/weather"
          "pulseaudio"
          "network"
          "cpu"
          "memory"
          "temperature"
          "custom/clipboard"
          "tray"
          "custom/power"
        ];

        "niri/workspaces" = {
          format = "{icon}";
          format-icons = {
            default = "";
            focused = "󰮯";
            active = "󰮯";
            urgent = "";
            empty = "";
          };
        };

        "niri/window" = {
          format = "{title}";
          icon = true;
          icon-size = 18;
          rewrite = {
            "(.+) — Mozilla Firefox" = " $1";
            "(.+) - Mozilla Firefox" = " $1";
          };
        };

        "custom/dns-stats" = {
          format = " {} {text}";
          exec = pkgs.writeShellScript "waybar-dns-stats" ''
            STATS=$(${pkgs.curl}/bin/curl -sf --connect-timeout 2 http://127.0.0.1:9090/stats 2>/dev/null || echo "")
            if [ -z "$STATS" ]; then
              echo "DNS: off"
              exit 0
            fi
            TOTAL=$(echo "$STATS" | ${pkgs.jq}/bin/jq -r '.totalBlocked // 0' 2>/dev/null)
            if [ "$TOTAL" = "null" ] || [ -z "$TOTAL" ]; then
              TOTAL=0
            fi
            if [ "$TOTAL" -ge 1000000 ]; then
              FMT=$(echo "scale=1; $TOTAL / 1000000" | ${pkgs.bc}/bin/bc)M
            elif [ "$TOTAL" -ge 1000 ]; then
              FMT=$(echo "scale=1; $TOTAL / 1000" | ${pkgs.bc}/bin/bc)K
            else
              FMT="$TOTAL"
            fi
            RECENT=$(echo "$STATS" | ${pkgs.jq}/bin/jq -r '.recentBlocks[:3] | map(.domain) | join(", ")' 2>/dev/null || echo "")
            echo "{\"text\": \"$FMT blocked\", \"tooltip\": \"DNS Blocker\\nTotal: $TOTAL domains\\nRecent: $RECENT\"}"
          '';
          return-type = "json";
          interval = 30;
          on-click = "xdg-open http://127.0.0.1:9090/stats";
        };

        "clock" = {
          format = "󰥔 {:%H:%M}";
          format-alt = "󰃭 {:%Y-%m-%d}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        };

        "cpu" = {
          format = " {usage}%";
          tooltip-format = "CPU: {usage}%  Load: {load}";
          interval = 2;
          min-length = 5;
          states = {
            high = 85;
          };
        };

        "memory" = {
          format = " {percentage}%";
          tooltip-format = "RAM: {used:0.1f}G / {total:0.1f}G";
          interval = 3;
          min-length = 5;
          states = {
            high = 90;
          };
        };

        "temperature" = {
          hwmon-path = "/sys/class/hwmon/hwmon2/temp1_input";
          critical-threshold = 80;
          format = "{icon} {temperatureC}°C";
          format-icons = ["" "" ""];
          tooltip-format = "CPU: {temperatureC}°C";
        };

        "network" = {
          format-wifi = " {essid}";
          format-ethernet = " {ipaddr}";
          format-disconnected = " Disconnected";
          tooltip-format = "{ifname} via {gwaddr}\n{ipaddr}/{cidr}";
          interval = 5;
        };

        "pulseaudio" = {
          format = "{volume}% {icon}";
          format-bluetooth = "{volume}% {icon}";
          format-muted = " Muted";
          format-icons = {
            headphone = "";
            headset = "";
            default = ["" "" ""];
          };
          on-click = "pwvucontrol";
          on-scroll-up = "pamixer -i 5";
          on-scroll-down = "pamixer -d 5";
          tooltip-format = "{desc}  {volume}%";
        };

        "custom/media" = {
          exec = pkgs.writeShellScript "waybar-media" ''
            status=$(playerctl status 2>/dev/null)
            if [ "$status" != "Playing" ] && [ "$status" != "Paused" ]; then
              echo ""
              exit 0
            fi

            artist=$(playerctl metadata artist 2>/dev/null || echo "")
            title=$(playerctl metadata title 2>/dev/null || echo "")
            album=$(playerctl metadata album 2>/dev/null || echo "")
            player=$(playerctl metadata --format '{{playerName}}' 2>/dev/null || echo "")

            case "$player" in
              spotify) icon="" ;;
              firefox) icon="" ;;
              *) icon="" ;;
            esac

            if [ "$status" = "Paused" ]; then
              icon=""
            fi

            artist=$(echo "$artist" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
            title=$(echo "$title" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')

            echo "{\"text\": \"$icon ''${artist} - ''${title}\", \"tooltip\": \"<b>''${status}</b>\\n''${title}\\n''${artist}\"}"
          '';
          return-type = "json";
          interval = 2;
          on-click = "playerctl play-pause";
          on-scroll-up = "playerctl next";
          on-scroll-down = "playerctl previous";
          max-length = 40;
        };

        "custom/clipboard" = {
          format = " {text}";
          exec = pkgs.writeShellScript "waybar-clipboard" ''
            CLIP_CONTENT=$(${pkgs.cliphist}/bin/cliphist list | head -1 | ${pkgs.gawk}/bin/awk -F'\t' '{print $2}' || echo "Empty")
            CLIP_TRUNCATED=$(echo "$CLIP_CONTENT" | head -c 15)
            if [ "''${#CLIP_CONTENT}" -gt 15 ]; then
              CLIP_TRUNCATED="''${CLIP_TRUNCATED}..."
            fi
            echo "$CLIP_TRUNCATED" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'
          '';
          interval = 5;
          on-click = pkgs.writeShellScript "waybar-clipboard-menu" ''
            ${pkgs.cliphist}/bin/cliphist list | ${pkgs.rofi}/bin/rofi -dmenu -p 'Clipboard:' -theme-str 'window {width: 50%;}' | ${pkgs.cliphist}/bin/cliphist decode | ${pkgs.wl-clipboard}/bin/wl-copy
          '';
        };

        "custom/power" = {
          format = "";
          on-click = "wlogout";
          tooltip = "Power menu";
        };

        "custom/weather" = {
          format = " {} {text}";
          exec = pkgs.writeShellScript "waybar-weather" ''
            WTTR=$(${pkgs.curl}/bin/curl -sf "wttr.in/?format=3" 2>/dev/null || echo "")
            if [ -z "$WTTR" ]; then
              echo "N/A"
              exit 0
            fi
            TEMP=$(echo "$WTTR" | cut -d' ' -f1)
            COND=$(echo "$WTTR" | cut -d' ' -f2- | tr -d '+')
            echo "{\"text\": \"$TEMP $COND\", \"tooltip\": \"Weather: $TEMP $COND\"}"
          '';
          return-type = "json";
          interval = 1800;
          on-click = "xdg-open https://wttr.in";
        };
      };
    };

    style = ''
      * {
        border: none;
        border-radius: 0;
        font-family: "JetBrainsMono Nerd Font";
        font-size: 14px;
        min-height: 0;
        padding: 0 6px;
        transition: none;
      }

      window#waybar {
        background: #1e1e2e;
        color: #cdd6f4;
        border-bottom: 1px solid #313244;
      }

      #workspaces button {
        padding: 0 8px;
        background: transparent;
        color: #6c7086;
      }

      #workspaces button:hover {
        color: #cdd6f4;
      }

      #workspaces button.active {
        color: #89b4fa;
      }

      #workspaces button.urgent {
        color: #f38ba8;
      }

      #niri-window {
        color: #a6adc8;
        padding: 0 12px;
      }

      #clock {
        color: #cdd6f4;
        font-weight: bold;
        padding: 0 12px;
      }

      #custom-media {
        color: #b4befe;
        font-size: 13px;
      }

      #cpu, #memory, #temperature, #network, #pulseaudio,
      #custom-clipboard, #custom-dns-stats, #tray, #custom-power {
        padding: 0 10px;
        color: #a6adc8;
      }

      #cpu.high, #memory.high {
        color: #f38ba8;
      }

      #temperature.critical {
        color: #f38ba8;
        font-weight: bold;
      }

      #network.disconnected {
        color: #f38ba8;
      }

      #pulseaudio.muted {
        color: #585b70;
      }

      #custom-clipboard:hover, #custom-power:hover, #custom-dns-stats:hover {
        color: #cdd6f4;
        background: #313244;
      }

      #tray {
        padding: 0 8px;
      }

      #custom-power {
        color: #f38ba8;
      }
    '';
  };
}
