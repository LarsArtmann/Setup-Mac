{ pkgs, lib, ... }:

{
  # ActivityWatch Configuration (Cross-Platform)
  services.activitywatch = {
    enable = true;
    package = pkgs.activitywatch;
    watchers = {
      # Enable AFK watcher (works on both platforms)
      aw-watcher-afk = {
        package = pkgs.activitywatch;
      };
    };
  };
}