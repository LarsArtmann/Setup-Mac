_: {
  # Networking configuration
  networking = {
    hostName = "evo-x2"; # Machine name
    networkmanager.enable = true;
    enableIPv6 = false; # IPv6 is unreachable, disable entirely

    # Force IPv4-only DNS servers (Quad9 IPv4 addresses)
    # Prevents DNS from returning IPv6 addresses that cause timeouts
    nameservers = ["9.9.9.10" "9.9.9.11"];
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
