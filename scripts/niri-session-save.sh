#!/usr/bin/env bash
# Niri session save — snapshot current windows/workspaces for crash recovery
set -euo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/niri-session"
mkdir -p "$STATE_DIR"

tmp=$(mktemp)
if ! niri msg -j windows >"$tmp" 2>/dev/null || [ ! -s "$tmp" ]; then
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
if ! niri msg -j workspaces >"$tmp" 2>/dev/null || [ ! -s "$tmp" ]; then
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
if [ ${#kitty_entries[@]} -gt 0 ]; then
  printf '[%s]\n' "$(
    IFS=,
    echo "${kitty_entries[*]}"
  )" >"$tmp"
else
  echo '[]' >"$tmp"
fi
mv "$tmp" "$STATE_DIR/kitty-state.json"

tmp=$(mktemp)
date +%s >"$tmp"
mv "$tmp" "$STATE_DIR/timestamp"

win_count=$(jq 'length' "$STATE_DIR/windows.json" 2>/dev/null || echo "?")
echo "niri-session-save: saved $win_count windows" >&2
