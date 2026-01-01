_: {
  # Networking configuration
  networking = {
    hostName = "evo-x2"; # Machine name
    networkmanager.enable = true;

    # Force IPv4 resolution for binary caches (IPv6 is unreachable)
    extraHosts = ''
      151.101.1.91 cache.nixos.org
      172.67.74.194 nix-community.cachix.org
      172.67.74.194 hyprland.cachix.org
    '';
  };

  # Set your time zone.
  time.timeZone = "Europe/Berlin"; # Adjust as needed

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Enable CUPS to print documents.
  services.printing.enable = true;
  # Note: Fonts are now handled by hyprland-system.nix
  # to avoid duplication and maintain consistency
}
