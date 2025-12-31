{pkgs, ...}: {
  imports = [
    ../../common/home-base.nix
    ../desktop/hyprland.nix # RE-ENABLED for desktop functionality
    ../../common/modules/ghost-wallpaper.nix
  ];

  # Enable ghost btop wallpaper
  programs.ghost-btop-wallpaper = {
    enable = true;
    updateRate = 2000;
    backgroundOpacity = "0.0";
  };

  # NixOS-specific session variables
  home.sessionVariables = {
    # Wayland/Hyprland specific
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland";
    NIXOS_OZONE_WL = "1";
  };

  # NixOS-specific Fish shell overrides
  programs.fish.shellAliases = {
    # NixOS specific aliases
    nixup = "sudo nixos-rebuild switch --flake .";
    nixbuild = "nixos-rebuild build --flake .";
    nixcheck = "nixos-rebuild check --flake .";
  };

  # NixOS-specific packages
  home.packages = with pkgs; [
    # GUI Tools
    pavucontrol # Audio control (user-level access for audio settings)

    # System Tools
    # Note: rofi moved to multi-wm.nix for system-wide availability
    # Note: xdg-utils moved to base.nix for cross-platform consistency
  ];

  # XDG Directories (Linux specific)
  xdg.enable = true;
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };
}
