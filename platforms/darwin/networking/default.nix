{lib, ...}: {
  # Darwin-specific networking configuration
  # Configures macOS networking settings via nix-darwin

  # Network identity settings
  networking = {
    # Computer name for Bonjour/Sharing/AirDrop
    # Visible in Finder sidebar and network discovery
    computerName = "Lars-MacBook-Air";

    # System hostname (shown in terminal prompt)
    hostName = "lars-macbook-air";

    # Local hostname for Bonjour (.local domain)
    # Derived from computerName but can be customized
    localHostName = "Lars-MacBook-Air";

    # Enable IPv6 for modern networks
    ipv6.enable = true;

    # Use natural sort order for network interfaces
    # (affects interface naming consistency on macOS)
    # naturalSortInterfaces = true;
  };

  # macOS Application Firewall configuration
  # Note: This is the built-in macOS firewall (ALF - Application Layer Firewall)
  # For per-app network rules, Little Snitch is used instead
  system.defaults.alf = {
    # Enable firewall (0=off, 1=on for specific services, 2=block all incoming)
    globalstate = 1;

    # Allow built-in signed apps to receive connections
    allowsignedenabled = true;

    # Allow downloaded signed apps to receive connections
    allowdownloadsignedenabled = true;

    # Stealth mode - don't respond to ping/scan requests
    stealthenabled = false;
  };

  # Wake-on-LAN support - DISABLED
  # Wake-on-LAN is disabled for MacBook Air as it's a laptop
  # and wakes frequently when closed. Use Power Nap instead for
  # background updates while sleeping.
  # system.defaults.wakeOnLan = lib.mkDefault false;

  # Additional notes:
  # - DNS settings are managed via System Preferences > Network
  #   or via /etc/resolver/*.conf for domain-specific DNS
  # - Per-application network rules use Little Snitch (installed via Homebrew)
  # - VPN configurations are managed via System Preferences > Network
}
