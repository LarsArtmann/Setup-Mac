_: {
  # Networking configuration
  networking = {
    hostName = "evo-x2"; # Machine name
    # Disable NetworkManager - use dhcpcd instead for simpler DNS management
    # networkmanager.enable = true;
    enableIPv6 = false; # IPv6 is unreachable, disable entirely

    # Use dhcpcd for network and DNS management
    # This provides better control over DNS settings
    useDHCP = true;

    # dhcpcd specific configuration
    dhcpcd = {
      enable = true;
      persistent = true; # Keep DHCP lease across reboots
      extraConfig = ''
        # Ignore router DNS
        nooption routers
        nooption domain_name_servers
        # Use static Quad9 DNS
        static domain_name_servers=9.9.9.10 9.9.9.11
        # Disable IPv6 completely
        noipv6
        noipv6rs
      '';
    };

    # DNS configuration - FORCE Quad9 only
    nameservers = ["9.9.9.10" "9.9.9.11"];

    # Note: DNS options like timeout/attempts are managed by glibc resolver
    # and can be set in /etc/resolv.conf manually if needed
  };

  # Use NetworkManager for WiFi management only (if needed)
  # networking.networkmanager.enable = true;
  # networking.networkmanager.wifi.backend = "iwd";

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
