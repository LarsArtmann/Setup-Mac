{lib, ...}: let
  mkHardenedServiceConfig = {
    memoryMax ? "512M",
    protectHome ? true,
    protectSystem ? "strict",
    readWritePaths ? [],
    extraConfig ? {},
  }:
    {
      PrivateTmp = true;
      NoNewPrivileges = true;
      CapabilityBoundingSet = "";
      ProtectClock = true;
      ProtectHostname = true;
      ProtectKernelLogs = true;
      RestrictNamespaces = true;
      RestrictSUIDSGID = true;
      LockPersonality = true;
      ProtectSystem = protectSystem;
      ProtectHome = protectHome;
      MemoryMax = memoryMax;
    }
    // lib.optionalAttrs (readWritePaths != []) {
      inherit readWritePaths;
    }
    // extraConfig;

  mkOneshotHardenedConfig = {
    memoryMax ? "256M",
    protectHome ? "read-only",
    extraConfig ? {},
  }:
    mkHardenedServiceConfig {
      inherit memoryMax protectHome extraConfig;
      protectSystem = "strict";
    };

  mkServiceRestartConfig = {
    restartSec ? "5",
    startLimitBurst ? 3,
    startLimitIntervalSec ? 300,
    watchdogSec ? null,
    extraConfig ? {},
  }:
    {
      Restart = "on-failure";
      RestartSec = restartSec;
      StartLimitBurst = startLimitBurst;
      StartLimitIntervalSec = startLimitIntervalSec;
    }
    // lib.optionalAttrs (watchdogSec != null) {
      WatchdogSec = watchdogSec;
    }
    // extraConfig;
in {
  inherit mkHardenedServiceConfig mkOneshotHardenedConfig mkServiceRestartConfig;
}
