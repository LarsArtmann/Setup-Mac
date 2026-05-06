#!/bin/sh
# Detects niri DRM zombie state and triggers GPU recovery.
# When niri loses DRM master (e.g. after dbus-broker killed by OOM),
# it stays alive but spams "Permission denied" or "DeviceMissing" DRM errors.
# Simple restart doesn't fix it because the GPU driver state is corrupted.
# This triggers a full GPU driver rebind via the gpu-recovery system service.

set -eu

# Only run if niri is actually running
pgrep -x niri >/dev/null 2>&1 || exit 0

# Check the last 20 niri log lines for persistent DRM errors
drm_errors=$(journalctl --user -u niri --no-pager -n 20 --since "30 sec ago" 2>/dev/null \
  | grep -cE "Permission denied|DeviceMissing" || true)

if [ "$drm_errors" -ge 10 ]; then
  echo "niri DRM zombie detected ($drm_errors DRM errors in 30s). Triggering GPU recovery."
  systemctl start gpu-recovery.service 2>/dev/null || {
    # Fallback: just kill niri if system service isn't available yet
    kill -9 $(pgrep -x niri) 2>/dev/null || true
  }
fi
