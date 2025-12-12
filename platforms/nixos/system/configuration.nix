{ config, pkgs, ... }:

{
  imports = [
    # Import common packages shared with macOS
    ../../common/packages/base.nix
    # Include hardware configuration - essential for NixOS to boot
    ../hardware/hardware-configuration.nix
    # TEMPORARILY COMMENTED OUT FOR TIMEOUT DEBUGGING
    # ./boot.nix
    # ./networking.nix
    # ../services/ssh.nix
    # ../hardware/amd-gpu.nix
    # ../desktop/hyprland-system.nix
  ];


  # Fix for Home Manager + xdg.portal integration
  environment.pathsToLink = [ "/share/applications" "/share/xdg-desktop-portal" ];

  # Boot configuration - required for system bootability
  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";  # Placeholder - would be set to actual disk on target system
  };

  # User account
  users.users.lars = {
    isNormalUser = true;
    description = "Lars";
    extraGroups = [ "networkmanager" "wheel" "docker" "input" "video" "audio" ];
    # INFO: Set password manually with `passwd lars` after installation
    # NOTE: After SSH hardening, password auth will be disabled - you MUST set up SSH keys
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      # IMPORTANT: Replace this placeholder with your actual SSH public key!
      # You can add multiple keys - one per line
      # "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... your-key-comment"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGPlbcK0pvybFGNvQWDVxHmMZkjUHXa9JcnPcKWSZWE8 lars@MacBook-Air.local"
    ];
    packages = with pkgs; [
      firefox
      # Desktop packages are now managed via Home Manager (see platforms/nixos/desktop/hyprland.nix)
    ];
  };

  # Enable Fish shell system-wide
  programs.fish.enable = true;



  # AMD GPU Support - imported from hardware module

  # Fonts
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    jetbrains-mono
  ];

  # Experimental features
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # System state version
  system.stateVersion = "25.11";
}
