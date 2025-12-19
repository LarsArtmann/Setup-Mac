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
  } // lib.optionalAttrs pkgs.stdenv.isLinux {
    # Linux-specific watchers (Wayland)
    aw-watcher-window-wayland = {
      package = pkgs.aw-watcher-window-wayland;
    };
  } // lib.optionalAttrs pkgs.stdenv.isDarwin {
    # macOS-specific watchers can be added here
    # Note: macOS window watchers may have different packages
  };
}