{pkgs, config, ...}: {
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
    };
  };
}
