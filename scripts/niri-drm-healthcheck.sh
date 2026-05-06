#!/bin/sh
# Detects niri DRM zombie state and force-restarts the compositor.
# When niri loses DRM master (e.g. after dbus-broker killed by OOM),
# it stays alive but spams "Permission denied" or "DeviceMissing" DRM errors.
# Since the process never exits, Restart=always never triggers.
# This script checks for that condition and kills niri so systemd can restart it.

set -eu

# Only run if niri is actually running
pids=$(pgrep -x niri 2>/dev/null) || exit 0

# Check the last 20 niri log lines for persistent DRM errors
drm_errors=$(journalctl --user -u niri --no-pager -n 20 --since "30 sec ago" 2>/dev/null |
  grep -cE "Permission denied|DeviceMissing" || true)

if [ "$drm_errors" -ge 10 ]; then
  echo "niri DRM zombie detected ($drm_errors DRM errors in 30s). Killing niri for restart."
  kill -9 $pids
fi
