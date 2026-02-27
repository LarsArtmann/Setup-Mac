{pkgs, ...}: {
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
}
