_: {
  # Networking configuration
  networking = {
    hostName = "evo-x2"; # Machine name
    networkmanager.enable = true;
    enableIPv6 = false; # IPv6 is unreachable, disable entirely

    # DNS configuration - FORCE Quad9 only
    nameservers = ["9.9.9.10" "9.9.9.11"];

    # Force Quad9 DNS via dhcpcd, ignore router DNS
    dhcpcd.extraConfig = ''
      nohook resolv.conf
      static domain_name_servers=9.9.9.10 9.9.9.11
    '';

    # Force IPv4-only for DNS to prevent IPv6 queries
    resolvconf.extraConfig = ''
      options inet6
    '';
  };

  # Configure NetworkManager DNS settings
  # This ensures Quad9 DNS is used instead of router's DNS
  networking.networkmanager.dns = "none"; # Disable automatic DNS handling

  # Disable systemd-resolved to prevent DNS conflicts
  services.resolved.enable = false;

  # Increase file descriptor limits to prevent "Too many open files" errors
  systemd.settings.Manager = {
    DefaultLimitNOFILE = 65536;
    DefaultLimitNPROC = 4096;
  };

  # Reload Nix daemon after config changes to apply settings
  systemd.services.nix-daemon = {
    restartIfChanged = true;
    serviceConfig = {
      LimitNOFILE = 65536;
    };
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
