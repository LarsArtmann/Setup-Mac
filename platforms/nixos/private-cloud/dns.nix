# Technitium DNS Server for Private Cloud
# This configures Technitium DNS Server for network-wide DNS service
{
  config,
  lib,
  pkgs,
  ...
}: {
  # Enable Technitium DNS Server
  services.technitium-dns-server = {
    enable = true;

    # Open firewall for network access
    # This allows other devices on the network to use this DNS server
    openFirewall = true;

    # Firewall port configuration
    # Standard ports: 53 (DNS), 5380 (HTTP), 53443 (HTTPS)
    # Additional ports for encrypted DNS: 443 (DoH), 853 (DoT)
    firewallUDPPorts = [53];
    firewallTCPPorts = [
      53 # Standard DNS (TCP)
      5380 # Web Console (HTTP)
      53443 # Web Console (HTTPS)
      443 # DNS-over-HTTPS (DoH)
      853 # DNS-over-TLS (DoT)
    ];
  };

  # Configure system to use local DNS
  # Note: This server will be used by other devices on the network
  networking.nameservers = ["127.0.0.1"];

  # Optional: Replace existing DHCP server with Technitium's built-in DHCP
  # Uncomment if you want Technitium DNS to manage DHCP
  #
  # services.dhcpcd.enable = false;
  # services.dhcpd4.enable = false;
  # services.dhcpd6.enable = false;

  # Note: Additional configuration (forwarders, blocklists, caching, etc.)
  # is done via web console at http://<private-cloud-ip>:5380
  #
  # Recommended setup for Private Cloud:
  #
  # 1. Access web console: http://<private-cloud-ip>:5380
  #    Replace <private-cloud-ip> with actual IP (e.g., http://192.168.1.100:5380)
  #
  # 2. Security: Change admin password (Settings > General)
  #
  # 3. Forwarders: Configure DNS forwarders (DNS Settings > Forwarders):
  #    - Primary: Cloudflare (1.1.1.1, 1.0.0.1)
  #    - Secondary: Quad9 (9.9.9.10, 9.9.9.11)
  #    - Enable DNS-over-TLS/HTTPS for privacy
  #
  # 4. Blocklists: Enable ad blocking (Block Lists > Quick Add):
  #    - StevenBlack (hosts)
  #    - AdGuard DNS filter
  #    - EasyList
  #    - OISD Blocklist (malware)
  #    - Phishing URL Blocklist
  #
  # 5. Caching: Enable persistent caching (DNS Settings > Cache):
  #    - Enable Persistent Cache
  #    - Cache Size: 200-500 MB (higher for more devices)
  #    - Enable Serve Stale
  #    - Enable Prefetching
  #
  # 6. DNSSEC: Enable validation (DNS Settings > DNSSEC):
  #    - Enable DNSSEC Validation
  #    - Validation Mode: Strict
  #
  # 7. Logging: Enable query logging (Settings > Logging):
  #    - Log Queries
  #    - Log Responses
  #
  # 8. Network Configuration:
  #    - Configure router DHCP to use this DNS server
  #    - OR manually configure devices to use this DNS server
  #    - Use DNS-over-HTTPS/TLS for privacy if desired
  #
  # 9. Optional: Configure DHCP Server (if replacing existing DHCP):
  #    - Go to: Settings > DHCP Server
  #    - Enable DHCP Server
  #    - Configure IP range (e.g., 192.168.1.100-192.168.1.200)
  #    - Set DNS server to 127.0.0.1 (this server)
  #    - Disable existing DHCP server (services.dhcpcd.enable = false)
  #
  # 10. Test: Verify DNS resolution from other devices:
  #     dig @<private-cloud-ip> google.com
  #     dig @<private-cloud-ip> doubleclick.net  # Should be blocked
  #
  # See README.md in this directory for detailed setup instructions.
}
