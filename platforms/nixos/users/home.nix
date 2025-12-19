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
  } // (home.sessionVariables or {});

  # NixOS-specific packages
  home.packages = with pkgs; [
    # GUI Tools
    pavucontrol # Audio control
    rofi # Launcher (Secondary)

    # System Tools
    xdg-utils
  ];

  # NixOS-specific Fish shell overrides
  programs.fish.shellAliases = {
    # NixOS specific aliases
    nixup = "sudo nixos-rebuild switch --flake .";
    nixbuild = "nixos-rebuild build --flake .";
    nixcheck = "nixos-rebuild check --flake .";
  } // (programs.fish.shellAliases or {});

  # XDG Directories (Linux specific)
  xdg.enable = true;
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };


}
