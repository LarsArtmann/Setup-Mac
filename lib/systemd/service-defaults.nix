# Common systemd service defaults for long-running daemons.
#
# Usage in service modules:
#   serviceDefaults = import ../../../lib/systemd/service-defaults.nix;
#   serviceConfig = harden {MemoryMax = "1G";} // serviceDefaults {};
#   serviceConfig = harden {} // serviceDefaults {WatchdogSec = "60";};
{
  Restart ? "on-failure",
  RestartSec ? "5s",
  StartLimitBurst ? 3,
  StartLimitIntervalSec ? 60,
  WatchdogSec ? "60",
}: {
  inherit Restart RestartSec StartLimitBurst StartLimitIntervalSec WatchdogSec;
}
