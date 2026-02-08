{
  pkgs,
  nix-colors,
  lib,
  ...
}: {
  imports = [
    # Import common packages shared with macOS
    ../../common/packages/base.nix
    # Include hardware configuration - essential for NixOS to boot
    ../hardware/hardware-configuration.nix
    # ESSENTIAL MODULES FOR FUNCTIONAL DESKTOP
    ./boot.nix
    ./networking.nix
    ./dns-config.nix # Technitium DNS Server for local caching and ad blocking
    ./snapshots.nix # BTRFS snapshots with Timeshift
    ./sudo.nix # Passwordless sudo for wheel group
    ../services/ssh.nix
    ../services/default.nix
    ../hardware/amd-gpu.nix
    ../hardware/bluetooth.nix
    # Import common Nix settings for consistent configuration
    ../../common/core/nix-settings.nix
    # Desktop modules - reorganized for better separation of concerns
    # Note: hyprland-system.nix was split into separate modules (commit 5174b9b)
    ../desktop/display-manager.nix
    ../desktop/audio.nix
    ../desktop/hyprland-config.nix
    ../desktop/security-hardening.nix
    ../desktop/ai-stack.nix
    ../desktop/monitoring.nix
    ../desktop/multi-wm.nix
  ];

  # Define color scheme option
  options.colorScheme = lib.mkOption {
    type = lib.types.attrs;
    default = nix-colors.colorSchemes.catppuccin-mocha;
    description = "Color scheme for the system";
  };

  # Define colorSchemeLib option (different name to avoid conflict with lib)
  options.colorSchemeLib = lib.mkOption {
    type = lib.types.attrs;
    default = nix-colors.lib;
    description = "nix-colors library functions";
  };

  # Wrap all configuration in config attribute
  config = {
    # Define color scheme and utilities
    colorScheme = nix-colors.colorSchemes.catppuccin-mocha;
    colorSchemeLib = nix-colors.lib;

    # Fix for Home Manager + xdg.portal integration
    environment.pathsToLink = ["/share/applications" "/share/xdg-desktop-portal"];

    # Boot configuration is now handled by ./boot.nix module
    # which provides systemd-boot with proper nvme and Ryzen AI Max+ support

    # User account
    users.users.lars = {
      isNormalUser = true;
      description = "Lars";
      extraGroups = ["networkmanager" "wheel" "docker" "input" "video" "audio"];
      # INFO: Set password manually with `passwd lars` after installation
      # NOTE: After SSH hardening, password auth will be disabled - you MUST set up SSH keys
      shell = pkgs.fish;
      openssh.authorizedKeys.keys = lib.optional (builtins.pathExists ./ssh-keys/lars.pub)
        (builtins.readFile ./ssh-keys/lars.pub);
      packages = with pkgs; [
        firefox
        home-manager # Install Home Manager CLI for manual management
        # Desktop packages are now managed via Home Manager (see platforms/nixos/desktop/hyprland.nix)
      ];
    };

    # Ensure Home Manager profile directory exists for user lars
    # This is required for home-manager.useUserPackages = true to work properly
    system.activationScripts.home-manager-profile-dirs = ''
      mkdir -p /nix/var/nix/profiles/per-user/lars
      chown lars:users /nix/var/nix/profiles/per-user/lars
    '';

    # Enable Fish shell system-wide
    programs.fish.enable = true;

    # AMD GPU Support - imported from hardware module
    # AMD GPU Support - imported from hardware module
    #
    # Font configuration (cross-platform)
    # Note: Font packages are now imported from common/packages/fonts.nix
    # to avoid duplication across platforms
    fonts.fontconfig.defaultFonts = {
      monospace = ["JetBrains Mono"];
      sansSerif = ["DejaVu Sans"];
      serif = ["DejaVu Serif"];
    };

    # Experimental features
    # Note: Nix settings now imported from common/core/nix-settings.nix

    # System state version
    system.stateVersion = "25.11";
  };
}
