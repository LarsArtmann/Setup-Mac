{
  pkgs,
  config,
  lib,
  wallpapers,
  colorScheme,
  ...
}: let
  colors = colorScheme.palette;
  wallpaperDir = wallpapers;
  cfg = config.services.niri-session;

  niri-session-save = pkgs.writeShellApplication {
    name = "niri-session-save";
    runtimeInputs = with pkgs; [niri-unstable jq procps coreutils];
    text = ''
      STATE_DIR="''${XDG_STATE_HOME:-$HOME/.local/state}/niri-session"
      mkdir -p "$STATE_DIR"

      tmp=$(mktemp)
      if ! niri msg -j windows > "$tmp" 2>/dev/null || [ ! -s "$tmp" ]; then
        rm -f "$tmp"
        exit 0
      fi

      if ! jq '.' "$tmp" >/dev/null 2>&1; then
        echo "niri-session-save: windows.json is not valid JSON, discarding" >&2
        rm -f "$tmp"
        exit 1
      fi
      mv "$tmp" "$STATE_DIR/windows.json"

      tmp=$(mktemp)
      if ! niri msg -j workspaces > "$tmp" 2>/dev/null || [ ! -s "$tmp" ]; then
        rm -f "$tmp"
        exit 0
      fi

      if ! jq '.' "$tmp" >/dev/null 2>&1; then
        echo "niri-session-save: workspaces.json is not valid JSON, discarding" >&2
        rm -f "$tmp"
        exit 1
      fi
      mv "$tmp" "$STATE_DIR/workspaces.json"

      kitty_entries=()
      for pid in $(jq -r '.[] | select(.app_id == "kitty") | .pid' "$STATE_DIR/windows.json" 2>/dev/null || true); do
        [ -z "$pid" ] && continue
        [ -d "/proc/$pid" ] || continue

        kitty_args=$(cat "/proc/$pid/cmdline" 2>/dev/null | jq -R -s 'split("\u0000") | map(select(length > 0))' 2>/dev/null || echo '[]')
        kitty_cwd=$(readlink "/proc/$pid/cwd" 2>/dev/null || echo "$HOME")

        child_cmd=""
        child_cwd=""
        current=$pid
        for _ in $(seq 1 20); do
          [ -d "/proc/$current" ] || break
          children=$(pgrep -P "$current" 2>/dev/null || true)
          if [ -z "$children" ]; then
            tpgid_field=$(cat "/proc/$current/stat" 2>/dev/null | cut -d' ' -f8)
            if [ -n "$tpgid_field" ] && [ "$tpgid_field" -gt 0 ] 2>/dev/null; then
              fg_pid=$(ps --no-headers -p "$tpgid_field" -o pid= 2>/dev/null | tr -d ' ')
              if [ -n "$fg_pid" ] && [ "$fg_pid" != "$current" ] && [ -d "/proc/$fg_pid" ]; then
                fg_comm=$(cat "/proc/$fg_pid/comm" 2>/dev/null || echo "")
                if [ -n "$fg_comm" ] && ! echo "$fg_comm" | grep -qxE '(fish|bash|zsh|sh|dash|sudo|doas)'; then
                  child_cmd=$(cat "/proc/$fg_pid/cmdline" 2>/dev/null | tr '\0' ' ' | sed 's/ $//' || true)
                  child_cwd=$(readlink "/proc/$fg_pid/cwd" 2>/dev/null || echo "$HOME")
                fi
              fi
            fi
            break
          fi
          current=$(echo "$children" | head -1)
          proc_name=$(cat "/proc/$current/comm" 2>/dev/null || echo "")
          if echo "$proc_name" | grep -qxE '(fish|bash|zsh|sh|dash|kitten|-fish|-bash|-zsh|-sh|sudo|doas)'; then
            continue
          fi
          child_cmd=$(cat "/proc/$current/cmdline" 2>/dev/null | tr '\0' ' ' | sed 's/ $//' || true)
          child_cwd=$(readlink "/proc/$current/cwd" 2>/dev/null || echo "$HOME")
          break
        done

        kitty_entries+=("$(jq -n \
          --argjson pid "$pid" \
          --argjson args "$kitty_args" \
          --arg cwd "$kitty_cwd" \
          --arg child_cmd "$child_cmd" \
          --arg child_cwd "$child_cwd" \
          '{pid: $pid, args: $args, cwd: $cwd, child_cmd: $child_cmd, child_cwd: $child_cwd}')")
      done

      tmp=$(mktemp)
      if [ ''${#kitty_entries[@]} -gt 0 ]; then
        printf '[%s]\n' "$(IFS=,; echo "''${kitty_entries[*]}")" > "$tmp"
      else
        echo '[]' > "$tmp"
      fi
      mv "$tmp" "$STATE_DIR/kitty-state.json"

      tmp=$(mktemp)
      date +%s > "$tmp"
      mv "$tmp" "$STATE_DIR/timestamp"

      win_count=$(jq 'length' "$STATE_DIR/windows.json" 2>/dev/null || echo "?")
      echo "niri-session-save: saved $win_count windows" >&2
    '';
  };

  niri-session-restore = pkgs.writeShellScriptBin "niri-session-restore" ''
    export PATH="${lib.makeBinPath (with pkgs; [niri-unstable jq coreutils procps libnotify])}:$PATH"
    set -euo pipefail

    STATE_DIR="''${XDG_STATE_HOME:-$HOME/.local/state}/niri-session"

    fallback() {
      ${lib.concatStringsSep "\n      " (lib.forEach (lib.range 0 ((lib.length cfg.fallbackApps) - 1)) (i: let
      app = lib.elemAt cfg.fallbackApps i;
      cmd =
        if app.args == []
        then app.app_id
        else "${app.app_id} ${lib.concatStringsSep " " app.args}";
    in
      if i == 0
      then "${cmd} &"
      else "sleep 0.3\n      ${cmd} &"))}
    }

    if [ ! -f "$STATE_DIR/windows.json" ]; then
      fallback
      exit 0
    fi

    if ! jq '.' "$STATE_DIR/windows.json" >/dev/null 2>&1; then
      echo "niri-session-restore: windows.json is corrupt, using fallback" >&2
      fallback
      exit 0
    fi

    if [ -f "$STATE_DIR/timestamp" ]; then
      saved=$(cat "$STATE_DIR/timestamp")
      now=$(date +%s)
      max_age=$(( ${toString cfg.maxSessionAgeDays} * 86400 ))
      [ $((now - saved)) -gt $max_age ] && { fallback; exit 0; }
    fi

    if [ -f "$STATE_DIR/workspaces.json" ] && ! jq '.' "$STATE_DIR/workspaces.json" >/dev/null 2>&1; then
      echo "niri-session-restore: workspaces.json is corrupt, ignoring" >&2
      echo '[]' > "$STATE_DIR/workspaces.json"
    fi

    deduped=$(jq '[
      group_by(.app_id)[]
      | if .[0].app_id == "kitty" then .[] else .[0] end
    ]' "$STATE_DIR/windows.json" 2>/dev/null)

    [ -z "$deduped" ] || [ "$deduped" = "[]" ] && { fallback; exit 0; }

    kitty_state=$(cat "$STATE_DIR/kitty-state.json" 2>/dev/null || echo '[]')

    ws_json=$(cat "$STATE_DIR/workspaces.json" 2>/dev/null || echo '[]')
    ws_names=$(echo "$ws_json" | jq -r '.[].name // empty' 2>/dev/null || true)
    for name in $ws_names; do
      niri msg action focus-workspace "$name" 2>/dev/null || true
    done

    declare -A spawned
    spawned_windows=()
    focused_app=""
    focused_ws=""
    highest_ts=0

    while IFS= read -r win; do
      [ -z "$win" ] && continue
      app_id=$(echo "$win" | jq -r '.app_id')
      pid=$(echo "$win" | jq -r '.pid')
      ws_id=$(echo "$win" | jq -r '.workspace_id')
      is_floating=$(echo "$win" | jq -r '.is_floating // false')
      col_width=$(echo "$win" | jq -r '.layout.tile_size[0] // 0' 2>/dev/null || echo "0")
      focus_ts=$(echo "$win" | jq -r '.focus_timestamp // 0' 2>/dev/null || echo "0")

      ws_ref=""
      if [ -n "$ws_id" ] && [ "$ws_id" != "null" ]; then
        ws_ref=$(echo "$ws_json" | jq -r --argjson id "$ws_id" '.[] | select(.id == $id) | .name // (.idx | tostring)' 2>/dev/null || true)
      fi

      if [ "$app_id" != "kitty" ]; then
        if [ "''${spawned[$app_id]:-}" = "1" ]; then
          continue
        fi
        if pgrep -x "$app_id" >/dev/null 2>&1; then
          echo "niri-session-restore: $app_id already running, skipping" >&2
          spawned[$app_id]=1
          continue
        fi
      fi
      spawned[$app_id]=1

      if [ -n "$ws_ref" ]; then
        niri msg action focus-workspace "$ws_ref" >/dev/null 2>&1 || true
        sleep 0.1
      fi

      case "$app_id" in
        kitty | foot | helium | emacs | firefox | Firefox)
          skip_width=1 ;;
        *)
          skip_width=0 ;;
      esac
      case "$app_id" in
        pavucontrol | com.saivert.pwvucontrol | floating | xdg-desktop-portal-gtk)
          skip_float=1 ;;
        *)
          skip_float=0 ;;
      esac

      case "$app_id" in
        kitty)
          entry=$(echo "$kitty_state" | jq -c --argjson pid "$pid" '.[] | select(.pid == $pid)' 2>/dev/null | head -1 || true)

          if [ -n "$entry" ]; then
            child_cmd=$(echo "$entry" | jq -r '.child_cmd // empty')
            child_cwd=$(echo "$entry" | jq -r '.child_cwd // empty')
            has_e=$(echo "$entry" | jq -r '.args | index("-e") // empty')

            if [ -n "$child_cmd" ] && echo "$child_cmd" | grep -q '__atexit__'; then
              child_cmd=""
              child_cwd=""
            fi

            if [ -n "$child_cmd" ]; then
              cwd_arg=()
              [ -n "$child_cwd" ] && [ "$child_cwd" != "$HOME" ] && cwd_arg=(--directory "$child_cwd")
              child_safe=$(echo "$child_cmd" | jq -r -R @sh)
              kitty "''${cwd_arg[@]}" -e sh -c "$child_safe; exec fish" &
            elif [ -n "$has_e" ]; then
              e_args=()
              idx=$(echo "$entry" | jq -r '.args | index("-e")')
              rest=$(echo "$entry" | jq -r --argjson idx "$idx" '.args[($idx + 1):][]')
              while IFS= read -r arg; do
                e_args+=("$arg")
              done < <(echo "$rest")
              kitty -e "''${e_args[@]}" &
            else
              kitty &
            fi
          else
            kitty &
          fi
          ;;
        signal)
          signal-desktop &
          ;;
        *)
          if command -v "$app_id" &>/dev/null; then
            "$app_id" &
          fi
          ;;
      esac
      sleep 0.5

      new_id=$(niri msg -j focused-window 2>/dev/null | jq -r '.id // empty' 2>/dev/null || true)

      if [ -n "$new_id" ] && [ "$is_floating" = "true" ] && [ "$skip_float" = "0" ]; then
        niri msg action move-window-to-floating 2>/dev/null || true
        sleep 0.1
      fi

      if [ -n "$new_id" ] && [ "$col_width" != "0" ] && [ "$is_floating" != "true" ] && [ "$skip_width" = "0" ]; then
        output_width=$(niri msg -j focused-output 2>/dev/null | jq -r '.logical_width // 0' 2>/dev/null || echo "0")
        if [ "$output_width" != "0" ] && [ "$output_width" != "null" ]; then
          pct=$(echo "$col_width $output_width" | awk '{printf "%.0f", ($1 / $2) * 100}')
          niri msg action set-column-width "''${pct}%" 2>/dev/null || true
          sleep 0.1
        fi
      fi

      if [ -n "$new_id" ]; then
        spawned_windows+=("$new_id")
      fi

      if [ "$focus_ts" != "null" ] && [ "$focus_ts" != "0" ]; then
        ts_int=$(echo "$focus_ts" | awk '{printf "%d", $1}')
        highest_int=$(echo "$highest_ts" | awk '{printf "%d", $1}')
        if [ "$ts_int" -gt "$highest_int" ] 2>/dev/null; then
          highest_ts=$focus_ts
          if [ -n "$new_id" ]; then
            focused_id="$new_id"
          fi
          focused_ws="$ws_ref"
        fi
      fi
    done < <(echo "$deduped" | jq -c '.[]')

    count=''${#spawned_windows[@]}
    echo "niri-session-restore: restored $count windows" >&2

    if [ -n "$focused_ws" ]; then
      niri msg action focus-workspace "$focused_ws" >/dev/null 2>&1 || true
      sleep 0.2
    fi
    if [ -n "$focused_id" ]; then
      niri msg action focus-window --id "$focused_id" >/dev/null 2>&1 || true
    fi

    notify-send "Session Restored" "Restored $count windows from crash recovery" 2>/dev/null || true
  '';
in {
  options.services.niri-session = {
    sessionSaveInterval = lib.mkOption {
      type = lib.types.str;
      default = "60s";
      description = "Systemd timer interval for saving niri session state";
    };

    maxSessionAgeDays = lib.mkOption {
      type = lib.types.int;
      default = 7;
      description = "Maximum age in days before session snapshot is discarded";
    };

    fallbackApps = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          app_id = lib.mkOption {
            type = lib.types.str;
            description = "Application ID to spawn";
          };
          args = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            description = "Arguments to pass to the application";
          };
        };
      });
      default = [
        {
          app_id = "kitty";
          args = [];
        }
        {
          app_id = "kitty";
          args = ["-e" "btop"];
        }
        {
          app_id = "kitty";
          args = ["-e" "nvtop"];
        }
        {
          app_id = "amdgpu_top";
          args = [];
        }
        {
          app_id = "helium";
          args = [];
        }
        {
          app_id = "signal-desktop";
          args = [];
        }
      ];
      description = "Fallback applications to spawn when no valid session exists";
    };
  };

  config = {
    programs.niri.settings = {
      prefer-no-csd = true;

      screenshot-path = "~/Pictures/screenshots/%Y-%m-%d %H-%M-%S.png";

      spawn-at-startup = [
        {argv = ["${niri-session-restore}/bin/niri-session-restore"];}
      ];

      xwayland-satellite.path = lib.getExe pkgs.xwayland-satellite;

      input = {
        keyboard = {
          xkb = {
            layout = "us";
            variant = "";
          };
          repeat-delay = 300;
          repeat-rate = 50;
          track-layout = "window";
        };

        touchpad = {
          tap = true;
          dwt = true;
          dwtp = true;
          natural-scroll = true;
          tap-button-map = "left-middle-right";
          click-method = "clickfinger";
          drag = true;
          disabled-on-external-mouse = true;
        };

        mouse = {
          natural-scroll = false;
          accel-profile = "flat";
        };

        trackball = {
          accel-profile = "flat";
          scroll-method = "on-button-down";
          scroll-button = 273;
        };

        tablet = {
          map-to-output = "eDP-1";
        };

        warp-mouse-to-focus.enable = true;
        focus-follows-mouse = {
          max-scroll-amount = "10%";
        };
        workspace-auto-back-and-forth = true;
      };

      cursor = {
        theme = "Bibata-Modern-Classic";
        size = 96;
      };

      layout = {
        gaps = 8;
        center-focused-column = "on-overflow";
        always-center-single-column = true;
        background-color = "#${colors.base00}";

        preset-column-widths = [
          {proportion = 0.33333;}
          {proportion = 0.5;}
          {proportion = 0.66667;}
        ];

        default-column-width = {proportion = 0.5;};

        focus-ring = {
          width = 2;
          active = {
            color = "#${colors.base0D}";
          };
          inactive = {
            color = "#${colors.base03}";
          };
          urgent = {
            color = "#${colors.base08}";
          };
        };

        border = {
          width = 0;
        };

        shadow = {
          enable = true;
          softness = 30;
          spread = 5;
          offset = {
            x = 0;
            y = 5;
          };
          draw-behind-window = true;
          color = "#00000060";
        };

        struts = {
          left = 0;
          right = 0;
          top = 0;
          bottom = 0;
        };
      };

      binds = let
        sh = cmd: ["sh" "-c" cmd];
      in {
        "Mod+Return".action.spawn = ["kitty"];
        "Mod+Shift+Return".action.spawn = ["foot"];

        "Mod+Q".action.close-window = {};
        "Mod+Shift+Q".action.quit = {};
        "F11".action.fullscreen-window = {};
        "Mod+Shift+Space".action.toggle-window-floating = {};
        "Mod+Shift+M".action.maximize-column = {};
        "Mod+T".action.toggle-column-tabbed-display = {};

        "Mod+Left".action.focus-column-left = {};
        "Mod+Right".action.focus-column-right = {};
        "Mod+Up".action.focus-window-up = {};
        "Mod+Down".action.focus-window-down = {};

        "Mod+H".action.focus-column-left = {};
        "Mod+L".action.focus-column-right = {};
        "Mod+K".action.focus-window-up = {};
        "Mod+J".action.focus-window-down = {};

        "Mod+Shift+Left".action.move-column-left = {};
        "Mod+Shift+Right".action.move-column-right = {};
        "Mod+Shift+Up".action.move-window-up = {};
        "Mod+Shift+Down".action.move-window-down = {};

        "Mod+Shift+H".action.move-column-left = {};
        "Mod+Shift+L".action.move-column-right = {};
        "Mod+Shift+K".action.move-window-up = {};
        "Mod+Shift+J".action.move-window-down = {};

        "Mod+BracketLeft".action.consume-window-into-column = {};
        "Mod+BracketRight".action.expel-window-from-column = {};
        "Mod+R".action.switch-preset-column-width = {};
        "Mod+Shift+R".action.reset-window-height = {};
        "Mod+Minus".action.set-column-width = "-10%";
        "Mod+Equal".action.set-column-width = "+10%";

        "Mod+1".action.focus-workspace = 1;
        "Mod+2".action.focus-workspace = 2;
        "Mod+3".action.focus-workspace = 3;
        "Mod+4".action.focus-workspace = 4;
        "Mod+5".action.focus-workspace = 5;
        "Mod+6".action.focus-workspace = 6;
        "Mod+7".action.focus-workspace = 7;
        "Mod+8".action.focus-workspace = 8;
        "Mod+9".action.focus-workspace = 9;

        "Mod+Shift+1".action.move-column-to-workspace = 1;
        "Mod+Shift+2".action.move-column-to-workspace = 2;
        "Mod+Shift+3".action.move-column-to-workspace = 3;
        "Mod+Shift+4".action.move-column-to-workspace = 4;
        "Mod+Shift+5".action.move-column-to-workspace = 5;
        "Mod+Shift+6".action.move-column-to-workspace = 6;
        "Mod+Shift+7".action.move-column-to-workspace = 7;
        "Mod+Shift+8".action.move-column-to-workspace = 8;
        "Mod+Shift+9".action.move-column-to-workspace = 9;

        "Mod+Page_Up".action.focus-workspace-up = {};
        "Mod+Page_Down".action.focus-workspace-down = {};
        "Mod+Shift+Page_Up".action.move-column-to-workspace-up = {};
        "Mod+Shift+Page_Down".action.move-column-to-workspace-down = {};

        "Mod+D".action.spawn = ["rofi" "-show" "drun"];
        "Mod+Space".action.spawn = ["rofi" "-show" "drun"];
        "Mod+Shift+Slash".action.spawn = sh "niri msg binds | rofi -dmenu -p 'Keybindings:' -theme-str 'window {width: 80%; height: 80%;}'";
        "Alt+C".action.spawn = sh "cliphist list | rofi -dmenu -p 'Clipboard:' -kb-delete-entry 'Ctrl+Delete' -theme-str 'window {width: 50%;} listview {columns: 1; lines: 12; scrollbar: true; } element {orientation: horizontal; padding: 8px; spacing: 8px; } element-text {horizontal-align: 0.0; vertical-align: 0.5; } scrollbar {enabled: true; width: 4px; padding: 0; } scrollbar-handle {background-color: @selected; border-radius: 2px; }' | cliphist decode | wl-copy";
        "Mod+period".action.spawn = sh "rofi -modi emoji -show emoji -theme-str 'window {width: 40%;}'";
        "Mod+Shift+C".action.spawn = sh "rofi -show calc -modi calc -no-show-match -no-sort -theme-str 'window {width: 30%;}'";
        "Mod+Shift+N".action.spawn = sh "dunstctl history | jq -r '.data[0][] | \"\\(.summary.data[0] // \\\"\\\") — \\(.body.data[0] // \\\"\\\") [\\(.timestamp.data[0] / 1000000 | strftime(\\\"%H:%M\\\"))]\"' 2>/dev/null | rofi -dmenu -p 'Notifications:' -theme-str 'window {width: 60%; height: 60%;} listview {columns: 1; lines: 15;} element {padding: 10px;}' || true";
        "Mod+Shift+E".action.spawn = ["emacs"];
        "Mod+Shift+B".action.spawn = ["firefox"];
        "Mod+Z".action.spawn = ["zed"];
        "Mod+Shift+F".action.spawn = sh "kitty --class floating -e yazi";
        "Mod+Shift+D".action.spawn = sh "zellij --layout dev";

        "Mod+Shift+Escape".action.spawn = ["swaylock"];
        "Mod+Shift+P".action.power-off-monitors = {};
        "Mod+Shift+S".action.suspend = {};

        "Mod+W".action.spawn = sh "img=$(${pkgs.coreutils}/bin/ls ${wallpaperDir}/*.{jpg,jpeg,png,webp} 2>/dev/null | ${pkgs.coreutils}/bin/shuf -n1) && [ -n \"$img\" ] && ${pkgs.awww}/bin/awww img \"$img\" --transition-type random --transition-duration 3";

        "Mod+Shift+F11".action.spawn = sh "mkdir -p ~/Pictures/screenshots && grim -g \"$(slurp)\" /tmp/screenshot.png && wl-copy < /tmp/screenshot.png && swappy -f /tmp/screenshot.png";
        "Mod+F11".action.spawn = sh "mkdir -p ~/Pictures/screenshots && grim /tmp/screenshot.png && wl-copy < /tmp/screenshot.png && swappy -f /tmp/screenshot.png";
        "Mod+Ctrl+F11".action.spawn = sh "mkdir -p ~/Pictures/screenshots && grim -o $(niri msg focused-output | head -1) /tmp/screenshot.png && wl-copy < /tmp/screenshot.png && swappy -f /tmp/screenshot.png";

        "XF86AudioRaiseVolume" = {
          action.spawn = sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+ -l 1.5";
          allow-when-locked = true;
        };
        "XF86AudioLowerVolume" = {
          action.spawn = sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-";
          allow-when-locked = true;
        };
        "XF86AudioMute" = {
          action.spawn = sh "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
          allow-when-locked = true;
        };
        "XF86AudioMicMute" = {
          action.spawn = sh "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
          allow-when-locked = true;
        };

        "XF86AudioPlay" = {
          action.spawn = sh "playerctl play-pause";
          allow-when-locked = true;
        };
        "XF86AudioNext" = {
          action.spawn = sh "playerctl next";
          allow-when-locked = true;
        };
        "XF86AudioPrev" = {
          action.spawn = sh "playerctl previous";
          allow-when-locked = true;
        };

        "XF86MonBrightnessUp" = {
          action.spawn = sh "ddcutil setvcp 10 + 10 2>/dev/null || brightnessctl set +5%";
          allow-when-locked = true;
        };
        "XF86MonBrightnessDown" = {
          action.spawn = sh "ddcutil setvcp 10 - 10 2>/dev/null || brightnessctl set 5%-";
          allow-when-locked = true;
        };
      };

      window-rules = [
        {
          matches = [{is-floating = false;}];
          opacity = 0.95;
          geometry-corner-radius = {
            top-left = 8.0;
            top-right = 8.0;
            bottom-left = 8.0;
            bottom-right = 8.0;
          };
          clip-to-geometry = true;
          draw-border-with-background = false;
        }
        {
          matches = [{title = "^Picture-in-Picture$";}];
          open-floating = true;
        }
        {
          matches = [
            {app-id = "^pavucontrol$";}
            {app-id = "^com.saivert.pwvucontrol$";}
          ];
          open-floating = true;
        }
        {
          matches = [{app-id = "^floating$";}];
          open-floating = true;
          default-floating-position = {
            x = 0.25;
            y = 0.15;
            relative-to = "top-left";
          };
          default-column-width = {proportion = 0.5;};
          default-window-height = {proportion = 0.7;};
        }
        {
          matches = [
            {app-id = "^steam_app_.*";}
          ];
          open-fullscreen = true;
          opacity = 1.0;
        }
        {
          matches = [
            {app-id = "^steam_app_.*";}
            {app-id = "^steam$";}
            {title = "^Counter-Strike";}
          ];
          open-fullscreen = true;
          opacity = 1.0;
        }
        {
          matches = [{app-id = "^xdg-desktop-portal-gtk$";}];
          open-floating = true;
        }
        {
          matches = [
            {
              app-id = "^org.keepassxc.KeePassXC$";
              title = "Generate Password";
            }
          ];
          open-floating = true;
        }
        {
          matches = [
            {app-id = "^firefox$";}
            {app-id = "^Firefox$";}
          ];
          open-on-workspace = "browser";
          default-column-width = {proportion = 0.75;};
        }
        {
          matches = [
            {app-id = "^kitty$";}
            {app-id = "^foot$";}
            {app-id = "^helium$";}
          ];
          open-on-workspace = "main";
          default-column-width = {proportion = 0.75;};
        }
        {
          matches = [{app-id = "^emacs$";}];
          open-on-workspace = "dev";
          default-column-width = {proportion = 0.66667;};
        }
        {
          matches = [
            {app-id = "^Slack$";}
            {app-id = "^discord$";}
            {app-id = "^vesktop$";}
            {app-id = "^telegramdesktop$";}
            {app-id = "^signal$";}
          ];
          open-on-workspace = "chat";
        }
        {
          matches = [
            {app-id = "^Spotify$";}
            {app-id = "^spotify$";}
          ];
          open-on-workspace = "media";
        }
      ];

      workspaces = {
        main = {};
        browser = {};
        dev = {};
        chat = {};
        media = {};
      };

      animations = {
        horizontal-view-movement = {
          kind.spring = {
            damping-ratio = 0.8;
            stiffness = 1000;
            epsilon = 0.0001;
          };
        };
        window-open = {
          kind.spring = {
            damping-ratio = 0.7;
            stiffness = 800;
            epsilon = 0.0001;
          };
        };
        window-close = {
          kind.spring = {
            damping-ratio = 0.7;
            stiffness = 800;
            epsilon = 0.0001;
          };
        };
        window-movement = {
          kind.spring = {
            damping-ratio = 0.8;
            stiffness = 1000;
            epsilon = 0.0001;
          };
        };
        window-resize = {
          kind.spring = {
            damping-ratio = 0.8;
            stiffness = 800;
            epsilon = 0.0001;
          };
        };
        workspace-switch = {
          kind.spring = {
            damping-ratio = 0.8;
            stiffness = 1000;
            epsilon = 0.0001;
          };
        };
      };
    };

    systemd.user.services = {
      awww-daemon = {
        Unit = {
          Description = "awww wallpaper daemon";
          # No After=graphical-session.target — avoids ordering cycle with awww-wallpaper
          PartOf = ["graphical-session.target"];
        };
        Service = {
          ExecStart = "${pkgs.awww}/bin/awww-daemon";
          Restart = "on-failure";
        };
        Install.WantedBy = ["graphical-session.target"];
      };

      awww-wallpaper = {
        Unit = {
          Description = "Set random wallpaper";
          After = ["awww-daemon.service"];
          Requires = ["awww-daemon.service"];
          PartOf = ["graphical-session.target"];
        };
        Service = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${pkgs.bash}/bin/bash -c 'img=$(${pkgs.coreutils}/bin/ls ${wallpaperDir}/*.{jpg,jpeg,png,webp} 2>/dev/null | ${pkgs.coreutils}/bin/shuf -n1) && [ -n \"$img\" ] && for i in $(${pkgs.coreutils}/bin/seq 1 30); do ${pkgs.awww}/bin/awww img \"$img\" --transition-type random --transition-duration 3 && break; ${pkgs.coreutils}/bin/sleep 1; done'";
          Restart = "on-failure";
          RestartSec = "2s";
        };
        Install.WantedBy = ["graphical-session.target"];
      };

      swayidle = {
        Unit = {
          Description = "Idle management daemon";
          After = ["graphical-session.target"];
          PartOf = ["graphical-session.target"];
        };
        Service = {
          ExecStart = "${pkgs.swayidle}/bin/swayidle -w timeout 43200 ${
            pkgs.writeShellScript "swayidle-suspend" ''
              ${pkgs.systemd}/bin/systemctl suspend
            ''
          } before-sleep ${pkgs.swaylock}/bin/swaylock";
          Restart = "on-failure";
          RestartSec = "5s";
          TimeoutStartSec = "10s";
          StartLimitBurst = 3;
          StartLimitIntervalSec = 120;
        };
        Install.WantedBy = ["graphical-session.target"];
      };

      cliphist = {
        Unit = {
          Description = "Clipboard history watcher";
          After = ["graphical-session.target"];
          PartOf = ["graphical-session.target"];
        };
        Service = {
          ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --watch ${pkgs.cliphist}/bin/cliphist store";
          Restart = "on-failure";
          RestartSec = "5s";
          TimeoutStartSec = "10s";
          StartLimitBurst = 3;
          StartLimitIntervalSec = 120;
        };
        Install.WantedBy = ["graphical-session.target"];
      };
      niri-session-save = {
        Unit = {
          Description = "Save niri session state for crash recovery";
          After = ["graphical-session.target"];
          PartOf = ["graphical-session.target"];
          OnFailure = ["niri-session-save-failure.service"];
        };
        Service = {
          Type = "oneshot";
          ExecStart = "${niri-session-save}/bin/niri-session-save";
        };
      };
      niri-session-save-failure = {
        Unit.Description = "Notify on niri session save failure";
        Service = {
          Type = "oneshot";
          ExecStart = "${pkgs.libnotify}/bin/notify-send -u critical 'Session Save Failed' 'The niri session save timer failed. Check systemctl --user status niri-session-save'";
        };
      };
    };

    systemd.user.timers.niri-session-save = {
      Unit.Description = "Periodically save niri session state";
      Timer = {
        OnBootSec = cfg.sessionSaveInterval;
        OnUnitActiveSec = cfg.sessionSaveInterval;
      };
      Install.WantedBy = ["timers.target"];
    };
  };
}
