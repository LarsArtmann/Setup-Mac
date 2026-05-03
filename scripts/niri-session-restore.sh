#!/usr/bin/env bash
# Niri session restore — crash recovery system
# Re-spawns applications on their original workspaces with floating state and column widths
# Template variables (replaced by Nix substituteAll):
#   @maxSessionAgeDays@ — max session age before fallback
#   @fallbackCommands@  — shell function body for fallback app spawning
set -euo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/niri-session"

fallback() {
  @fallbackCommands@
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
  max_age=$(( @maxSessionAgeDays@ * 86400 ))
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
    if [ "${spawned[$app_id]:-}" = "1" ]; then
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
          kitty "${cwd_arg[@]}" -e sh -c "$child_safe; exec fish" &
        elif [ -n "$has_e" ]; then
          e_args=()
          idx=$(echo "$entry" | jq -r '.args | index("-e")')
          rest=$(echo "$entry" | jq -r --argjson idx "$idx" '.args[($idx + 1):][]')
          while IFS= read -r arg; do
            e_args+=("$arg")
          done < <(echo "$rest")
          kitty -e "${e_args[@]}" &
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
      niri msg action set-column-width "${pct}%" 2>/dev/null || true
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

count=${#spawned_windows[@]}
echo "niri-session-restore: restored $count windows" >&2

if [ -n "$focused_ws" ]; then
  niri msg action focus-workspace "$focused_ws" >/dev/null 2>&1 || true
  sleep 0.2
fi
if [ -n "$focused_id" ]; then
  niri msg action focus-window --id "$focused_id" >/dev/null 2>&1 || true
fi

notify-send "Session Restored" "Restored $count windows from crash recovery" 2>/dev/null || true
