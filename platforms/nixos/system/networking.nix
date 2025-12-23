_: {
  # Networking configuration
  networking.hostName = "evo-x2"; # Machine name
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Berlin"; # Adjust as needed

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Enable CUPS to print documents.
  services.printing.enable = true;
  # Note: Fonts are now handled by hyprland-system.nix
  # to avoid duplication and maintain consistency
}
