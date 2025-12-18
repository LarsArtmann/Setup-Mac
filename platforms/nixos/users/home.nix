{ config, pkgs, lib, ... }:

{
  imports = [
    ../../common/home-base.nix
    ../desktop/hyprland.nix  # RE-ENABLED for desktop functionality
  ];

  # NixOS-specific session variables
  home.sessionVariables = {
    # Wayland/Hyprland specific
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland";
    NIXOS_OZONE_WL = "1";
  };

  # NixOS-specific packages
  home.packages = with pkgs; [
    # GUI Tools
    pavucontrol # Audio control
    rofi # Launcher (Secondary)

    # System Tools
    xdg-utils
  ];

  # Fish Shell Configuration
  programs.fish = {
    enable = true;
    shellAliases = {
      l = "ls -laSh";
      t = "tree -h -L 2 -C --dirsfirst";
      # NixOS specific aliases
      nixup = "sudo nixos-rebuild switch --flake .";
      nixbuild = "nixos-rebuild build --flake .";
      nixcheck = "nixos-rebuild check --flake .";
    };
    interactiveShellInit = ''
      set -g fish_greeting
    '';
  };

  # Starship Prompt
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      add_newline = false;
      format = "$all$character";
    };
  };

  # ActivityWatch (Time Tracking)
  services.activitywatch = {
    enable = true;
    package = pkgs.activitywatch;
    watchers = {
      # Enable AFK watcher
      aw-watcher-afk = {
        package = pkgs.activitywatch;
      };
      # Enable Wayland window watcher (compatible with Hyprland)
      aw-watcher-window-wayland = {
        package = pkgs.aw-watcher-window-wayland;
      };
    };
  };

  # XDG Directories (Linux specific)
  xdg.enable = true;
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };


}
