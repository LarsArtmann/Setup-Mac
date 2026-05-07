# Common systemd service defaults for long-running daemons.
#
# Usage in service modules:
#   serviceDefaults = import ../../../lib/systemd/service-defaults.nix lib;
#   serviceConfig = harden {MemoryMax = "1G";} // serviceDefaults {};
#
# All values use lib.mkForce to override nixpkgs module defaults where needed.
#
# WatchdogSec is NOT included by default — it requires sd_notify() support
# in the service binary. Only pass it for services that implement sd_notify
# (e.g., Caddy, Gitea). For all others, omit it.
#
# StartLimitBurst/StartLimitIntervalSec are NOT included here because they
# belong in [Unit], not [Service]. Set them as top-level service options:
#   systemd.services.foo = {
#     startLimitBurst = 3;
#     startLimitIntervalSec = 60;
#     serviceConfig = harden {} // serviceDefaults {};
#   };
lib: {
  Restart ? "always",
  RestartSec ? "5s",
}: {
  Restart = lib.mkForce Restart;
  RestartSec = lib.mkForce RestartSec;
}
