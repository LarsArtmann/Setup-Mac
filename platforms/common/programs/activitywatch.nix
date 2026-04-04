{
  pkgs,
  lib,
  ...
}: {
  # ActivityWatch Configuration (Linux only - NixOS)
  # ActivityWatch does not support Darwin (macOS) - only Linux platforms
  services.activitywatch = {
    enable = pkgs.stdenv.isLinux;
    package = pkgs.activitywatch;
    watchers = {
      # Enable AFK watcher (works on both platforms)
      aw-watcher-afk = {
        package = pkgs.activitywatch;
      };
      # Enable utilization watcher (monitors CPU, RAM, disk, network, sensors)
      # https://github.com/Alwinator/aw-watcher-utilization
      aw-watcher-utilization = {
        package = pkgs.aw-watcher-utilization;
        settings = {
          poll_time = 5; # seconds between data collection (default: 5)
        };
      };
    };
  };

  # Set ActivityWatch web UI theme to dark via API
  # The theme is stored in localStorage but synced to server via API
  systemd.user.services.activitywatch-theme = lib.mkIf pkgs.stdenv.isLinux {
    Unit = {
      Description = "Set ActivityWatch theme to dark";
      After = ["activitywatch.service"];
      PartOf = ["activitywatch.service"];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.curl}/bin/curl -X PUT -d 'dark' http://localhost:5600/api/0/settings/theme";
      RemainAfterExit = true;
    };
    Install.WantedBy = ["activitywatch.target"];
  };
}
