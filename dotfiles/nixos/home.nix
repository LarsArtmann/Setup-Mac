{ config, pkgs, lib, TypeAssertions, ConfigAssertions, ModuleAssertions, Types, UserConfig, PathConfig, State, Validation, ... }:

{
  imports = [
    ../common/home.nix
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
    wl-clipboard # Clipboard
    wofi # Launcher
    waybar # Status bar

    # System Tools
    libnotify
    xdg-utils
  ];

  # XDG Directories (Linux specific)
  xdg.enable = true;
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };

  # Ghost Systems integration verification
  assertions = [
    {
      assertion = TypeAssertions != null;
      message = "Ghost Systems TypeAssertions not injected!";
    }
  ];
}
