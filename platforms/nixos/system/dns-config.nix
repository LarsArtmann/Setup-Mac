# Local Technitium DNS Server for evo-x2
# This configures Technitium DNS Server for local DNS caching and ad blocking

{ config, lib, pkgs, ... }:

{
  # Enable Technitium DNS Server
  services.technitium-dns-server = {
    enable = true;

    # Firewall settings
    # Set to false for local-only access (recommended for laptop)
    # Set to true to expose DNS to local network
    openFirewall = false;

    # Custom port configuration (optional - uses defaults)
    # firewallUDPPorts = [ 53 ];      # Standard DNS (UDP)
    # firewallTCPPorts = [
    #   53      # Standard DNS (TCP)
    #   5380    # Web Console (HTTP)
    #   53443   # Web Console (HTTPS)
    # ];
  };

  # Configure system to use local Technitium DNS
  networking.nameservers = [ "127.0.0.1" ];

  # Note: Additional configuration (forwarders, blocklists, etc.)
  # is done via the web console at http://localhost:5380
  #
  # Recommended initial setup:
  # 1. Access web console: http://localhost:5380
  # 2. Change admin password (Settings > General)
  # 3. Configure forwarders (DNS Settings > Forwarders):
  #    - Primary: Private Cloud (via DoH/DoT)
  #    - Fallback: Quad9 (9.9.9.10, 9.9.9.11)
  # 4. Enable ad blocking (Block Lists > Quick Add):
  #    - StevenBlack (hosts)
  #    - AdGuard DNS filter
  #    - EasyList
  # 5. Enable persistent caching (DNS Settings > Cache)
  # 6. Enable DNSSEC validation (DNS Settings > DNSSEC)
  # 7. Enable query logging (Settings > Logging)
  #
  # See README.md in this directory for detailed setup instructions.
}
