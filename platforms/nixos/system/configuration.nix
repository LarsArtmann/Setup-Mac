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
      # MacBook SSH key - matches git@lars.software
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCf94DAHsLLwuc9CMlAZE2GGlp84BR2IG9LoAcBGCR1orOQgkx2lvvQZXnLkwGR+8C8wqjSLM05KeI4v7Fig+AaoRomWQHESqMESXgJmoS87oP3BwOCCxFcQJonPwLSamsHRKdDvEPwQYN82C91cPW4VL0ZCxsqAATZotK5945YVPaL/WUjUlE9n4NTuO6JF8yw28QgO9QzWvqSywWPD1tZp3S3CpVluCKqgzn3CTusJpbcAbbvMGN2BzeUW/wyLguOn/64OaxlXFR45hv/OmS3NEoQ/1suHErMNrRu3EJ68LBliC6OEGAVkImtEBMn/hlTEi3L2w4XDiAiax7zvOUB4TPD2SdJ/1yVQVmjkyizpIhtEc0lkvdguf8kzHrPBSJOMwQrUPLxesUUmhJWqqxJVHdnKhhtINxxJ3q3ejZ1+X5p0MspGpKqtPUdq+nl2Gn3Rf5qcHtnhoLKIeN7whHN/+PHaN1AZkX/eFyIR+O3bZtQZPTHJWn+mCoRpYW60b0= git@lars.software"
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
