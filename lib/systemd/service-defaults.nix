# Common systemd service defaults for long-running daemons.
#
# Usage in service modules:
#   serviceDefaults = import ../../../lib/systemd/service-defaults.nix;
#   serviceConfig = harden {MemoryMax = "1G";} // serviceDefaults {};
#   serviceConfig = harden {} // serviceDefaults {WatchdogSec = "60";};
#
# WatchdogSec is NOT included by default — it requires sd_notify() support
# in the service binary. Only pass it for services that implement sd_notify
# (e.g., Caddy, Gitea). For all others, omit it.
{
  Restart ? "always",
  RestartSec ? "5s",
  StartLimitBurst ? 3,
  StartLimitIntervalSec ? 60,
}: {
  inherit Restart RestartSec StartLimitBurst StartLimitIntervalSec;
}
