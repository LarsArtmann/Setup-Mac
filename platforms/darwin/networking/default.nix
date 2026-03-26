_: {
  # Darwin-specific networking configuration
  # This is primarily handled through the networking.nix at root level

  # Network settings for macOS
  # Note: Most networking is configured via nix-darwin's networking module
  # These are Darwin-specific enhancements

  networking = {
    # Use system DNS resolution (macOS default)
    # Custom DNS is configured via nix-darwin's networking options
    # or via /etc/resolver/*.conf for domain-specific DNS

    # Enable IPv6 for modern networks
    ipv6.enable = true;

    # Use natural sort order for network interfaces
    # (This affects interface naming on macOS)
    # naturalSortInterfaces = true;
  };

  # Firewall configuration for macOS
  # Note: macOS uses PF (Packet Filter) via /etc/pf.conf
  # Little Snitch is used for per-app network rules
  # This is primarily for system-level firewall settings
}
