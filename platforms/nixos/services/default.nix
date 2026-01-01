_: {
  # NixOS-specific services configuration

  # Enable Docker for container-based services
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  # Add user to docker group (already done in configuration.nix)
  users.users.lars.extraGroups = ["docker"];

  # Enable basic services that would be common to NixOS installations
  services = {
    # Add NixOS-specific services here
    # For example:
    # openssh.enable = true;
    # printing.enable = true;
  };
}
