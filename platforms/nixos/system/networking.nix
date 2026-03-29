_: {
  # Networking configuration
  networking = {
    hostName = "evo-x2"; # Machine name
    # Disable NetworkManager - use dhcpcd instead for simpler DNS management
    # networkmanager.enable = true;
    enableIPv6 = false; # IPv6 is unreachable, disable entirely

    # Firewall - deny by default, only allow needed ports
    firewall = {
      enable = true;
      allowedTCPPorts = [22 80 443];
      allowedUDPPorts = [53];
    };

    # Use dhcpcd for network and DNS management
    # This provides better control over DNS settings
    useDHCP = true;

    # dhcpcd specific configuration
    dhcpcd = {
      enable = true;
      persistent = true; # Keep DHCP lease across reboots
      extraConfig = ''
        # Let NixOS networking.nameservers manage DNS
        # Uses unbound (dns-blocker-config.nix) on 127.0.0.1
        nooption domain_name_servers
        # Disable IPv6 completely
        noipv6
        noipv6rs
        # Prevent dhcpcd from managing /etc/resolv.conf
        # This avoids conflicts with NixOS's network-setup.service
        nohook resolv.conf
      '';
    };

    # DNS uses unbound via dns-blocker-config.nix
    nameservers = ["127.0.0.1"];
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

  # Automatic Nix garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  # Automatic Nix store optimization
  nix.settings.auto-optimise-store = true;
}
