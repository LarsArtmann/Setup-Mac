# Local Technitium DNS Server for evo-x2
# This configures Technitium DNS Server for local DNS caching and ad blocking
{
  pkgs,
  ...
}: {
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
  networking.nameservers = ["127.0.0.1"];

  # Automated backup - Daily backups at 2 AM
  systemd = {
    timers.technitium-dns-backup = {
      description = "Daily Technitium DNS backup";
      timerConfig = {
        OnCalendar = "02:00";
        Persistent = true;
      };
      wantedBy = ["timers.target"];
    };

    services.technitium-dns-backup = {
      description = "Backup Technitium DNS configuration";
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        ExecStart = pkgs.writeShellScript "backup-technitium-dns" ''
          #!/bin/sh
          set -e

          DATE=$(${pkgs.coreutils}/bin/date +%Y%m%d_%H%M%S)
          BACKUP_DIR="/var/backups/technitium-dns"

          # Create backup directory
          ${pkgs.coreutils}/bin/mkdir -p "$BACKUP_DIR"

          # Backup state directory
          ${pkgs.coreutils}/bin/tar -czf "$BACKUP_DIR/backup-$DATE.tar.gz" \
            -C /var/lib/technitium-dns-server .

          # Keep last 7 backups
          ${pkgs.findutils}/bin/find "$BACKUP_DIR" -name "backup-*.tar.gz" -mtime +7 -delete

          ${pkgs.coreutils}/bin/echo "Backup completed: $BACKUP_DIR/backup-$DATE.tar.gz"
        '';
      };
    };

    # Health check - Verify DNS server is responding
    services.technitium-dns-healthcheck = {
      description = "Technitium DNS health check";
      after = ["technitium-dns-server.service" "network-online.target"];
      wants = ["network-online.target"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.bind.dnsutils}/bin/dig @127.0.0.1 +short google.com";
        ExecStartPost = "${pkgs.coreutils}/bin/echo 'DNS health check passed'";
      };
    };

    timers.technitium-dns-healthcheck = {
      description = "Run Technitium DNS health check every 5 minutes";
      timerConfig = {
        OnUnitActiveSec = "5min";
        AccuracySec = "1s";
      };
      wantedBy = ["timers.target"];
    };
  };

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
