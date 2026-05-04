#!/usr/bin/env bash
set -euo pipefail

# Wallpaper setter for awww daemon.
# Usage: wallpaper-set.sh <mode> <wallpaper_dir>
#   mode: "random"  — pick a random image (for first start / keybind)
#         "restore" — restore last image, fall back to random (for daemon restart recovery)
#   wallpaper_dir: directory containing wallpaper images

mode="${1:-random}"
wallpaper_dir="${2:-$HOME/.local/share/wallpapers}"

wait_for_daemon() {
  for i in $(seq 1 60); do
    awww query >/dev/null 2>&1 && return 0
    sleep 1
  done
  return 1
}

set_random() {
  local img
  img=$(ls "$wallpaper_dir"/*.{jpg,jpeg,png,webp} 2>/dev/null | shuf -n1)
  if [[ -z "$img" ]]; then
    echo "No wallpaper images found in $wallpaper_dir" >&2
    return 1
  fi
  awww img "$img" --transition-type random --transition-duration 3
}

wait_for_daemon || exit 1

case "$mode" in
  restore)
    awww restore 2>/dev/null || set_random
    ;;
  random)
    set_random
    ;;
  *)
    echo "Usage: $0 <random|restore> [wallpaper_dir]" >&2
    exit 1
    ;;
esac
