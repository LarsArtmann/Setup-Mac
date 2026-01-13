# Technitium DNS Server Configuration for NixOS

This module configures Technitium DNS Server for local DNS caching and ad blocking.

## Architecture

- Local DNS caching (faster resolution)
- Ad blocking (via blocklists)
- Privacy features (DoH/DoT forwarders)
- Persistent caching to disk

## Configuration

The DNS server runs on:
- Port 53 (DNS - UDP/TCP)
- Port 5380 (Web Console - HTTP)
- Port 53443 (Web Console - HTTPS)

Web Console: http://localhost:5380
Default Credentials: admin / admin (CHANGE IMMEDIATELY!)

## Setup Steps

### 1. Enable DNS Server
This module is automatically imported via `platforms/nixos/system/configuration.nix`.

### 2. Access Web Console
```bash
# From local machine
xdg-open http://localhost:5380
# or
firefox http://localhost:5380
```

### 3. Configure DNS Server (via Web Console)

#### Initial Setup
1. **Security:** Change admin password immediately
   - Go to: Settings > General > Admin Password

2. **Forwarders:** Configure DNS forwarders
   - Go to: DNS Settings > Forwarders
   - Add Quad9: 9.9.9.10, 9.9.9.11
   - Add Cloudflare: 1.1.1.1, 1.0.0.1
   - Enable DNS-over-TLS/HTTPS for each forwarder

3. **Blocklists:** Enable ad blocking
   - Go to: Block Lists
   - Click "Quick Add" and select popular blocklists:
     - StevenBlack (hosts)
     - AdGuard DNS filter
     - EasyList
   - Click "Download" to fetch blocklists

4. **Caching:** Enable persistent cache
   - Go to: DNS Settings > Cache
   - Enable "Persistent Cache"
   - Set "Cache Size" to recommended (100MB or higher)

5. **DNSSEC:** Enable validation
   - Go to: DNS Settings > DNSSEC
   - Enable "Enable DNSSEC Validation"

6. **Logging:** Enable query logging
   - Go to: Settings > Logging
   - Enable "Log Queries"

### 4. Test DNS Resolution

```bash
# Test basic resolution
dig google.com

# Test ad blocking (should return 0.0.0.0 or NXDOMAIN)
dig doubleclick.net

# Test cached query (run twice)
time dig github.com  # First run: ~50-100ms
time dig github.com  # Second run: ~1-5ms (from cache)

# Test DNSSEC validation
dig +dnssec example.net
```

### 5. Monitor DNS Server

#### Via Web Console
- Query Log: Real-time DNS requests
- Statistics: Request rates, cache hit rate, blocked queries

#### Via Command Line
```bash
# Check service status
systemctl status technitium-dns-server

# View logs
journalctl -u technitium-dns-server -f

# Check resource usage
htop  # Look for technitium-dns-server process
```

## Troubleshooting

### DNS Resolution Fails
```bash
# Check if DNS server is running
systemctl status technitium-dns-server

# Check logs for errors
journalctl -u technitium-dns-server -n 50

# Verify DNS configuration
cat /etc/resolv.conf

# Test DNS directly
dig @127.0.0.1 google.com
```

### Web Console Inaccessible
```bash
# Check if port is open
ss -tulpn | grep 5380

# Check firewall rules
sudo nixos-rebuild switch --flake .#evo-x2  # Rebuild to apply firewall rules
```

### Ad Blocking Not Working
```bash
# Check blocklists in web console
# Block Lists tab > Verify lists are downloaded

# Test blocked domain
dig @127.0.0.1 doubleclick.net

# Check query log for blocked requests
```

### Performance Issues
```bash
# Check cache hit rate (via web console)
# Higher hit rate = better performance

# Clear cache if needed (via web console)
# DNS Settings > Cache > Clear Cache

# Reduce cache size if using too much disk space
```

## Advanced Configuration

### Custom Blocklists
```bash
# Add custom blocklist URL
# Block Lists > Add Block List URL
# Example: https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts
```

### Conditional Forwarding
```bash
# Forward specific domains to specific DNS servers
# DNS Settings > Conditional Forwarders
# Example: Forward internal.local to 192.168.1.100
```

### DNS-over-HTTPS/TLS
```bash
# Enable encrypted DNS to forwarders
# DNS Settings > Forwarders > Edit Forwarder
# Select Protocol: DNS-over-TLS or DNS-over-HTTPS
# Enter URL or IP address
```

### Split DNS (Internal vs External)
```bash
# Configure internal zones for local network
# DNS Settings > Zones > Add Zone
# Zone Type: Primary
# Add A records for internal services
```

## Backup & Recovery

### Backup Configuration
```bash
# Backup state directory
sudo tar -czf technitium-dns-backup-$(date +%Y%m%d).tar.gz \
  /var/lib/technitium-dns-server/

# Store backup in safe location
mv technitium-dns-backup-*.tar.gz ~/backups/
```

### Restore Configuration
```bash
# Stop service
sudo systemctl stop technitium-dns-server

# Restore backup
sudo tar -xzf technitium-dns-backup-YYYYMMDD.tar.gz -C /

# Start service
sudo systemctl start technitium-dns-server
```

### NixOS Rollback
```bash
# If DNS configuration causes issues, rollback NixOS
sudo nixos-rebuild switch --rollback

# Or rollback to specific generation
sudo nixos-rebuild switch --profile /nix/var/nix/profiles/system \
  -p /nix/var/nix/profiles/system-XXX-link
```

## Integration with Other Services

### Docker DNS Configuration
```nix
# platforms/nixos/services/default.nix
virtualisation.docker = {
  enable = true;
  extraOptions = "--dns 127.0.0.1";  # Use local Technitium DNS
};
```

### Systemd Services DNS Configuration
```bash
# For services that don't use system DNS
# Add to service unit:
[Service]
Environment="DNS_SERVER=127.0.0.1"
```

### VPN Configuration
```bash
# Configure VPN to use local DNS
# Prevents DNS leaks via VPN
```

## Security Considerations

### Web Console Access
- **Default:** Localhost only (http://localhost:5380)
- **Remote Access:** NOT recommended (exposes management interface)
- **If Remote Access Needed:**
  - Use reverse proxy with authentication
  - Enable HTTPS (port 53443)
  - Use strong password
  - Enable TOTP 2FA

### DNS Over HTTPS/TLS
- Encrypts DNS traffic between server and forwarders
- Prevents ISP/Network snooping
- Recommended for privacy

### Firewall Configuration
- Default: Localhost only (no firewall ports open)
- If exposing to network: Enable `openFirewall` in configuration
- Recommended: Use VPN for remote DNS access

## Performance Tuning

### Cache Settings
- **Cache Size:** 100MB-500MB (adjust based on usage)
- **Persistent Cache:** Enabled (faster startup)
- **Prefetching:** Enabled (pre-populates cache)

### Blocklist Optimization
- Too many blocklists = slower DNS resolution
- Start with 3-5 popular blocklists
- Monitor performance and adjust
- Remove unnecessary blocklists

### Concurrent Queries
- Default: 100 concurrent queries
- Increase for high-traffic networks
- Decrease for low-resource systems

## Comparison: Before vs After

### Before (Quad9 via dhcpcd)
- ✅ Simple, zero configuration
- ❌ No ad blocking
- ❌ No caching
- ❌ No logging
- ❌ No privacy features
- ❌ No web console

### After (Technitium DNS)
- ✅ Ad blocking (network-wide)
- ✅ Persistent caching (10-100x faster for cached entries)
- ✅ Query logging (full visibility)
- ✅ Privacy features (DoH/DoT)
- ✅ Web console (easy management)
- ⚠️ Moderate complexity (one-time setup)

## Resources

- Technitium DNS Website: https://technitium.com/dns/
- GitHub Repository: https://github.com/TechnitiumSoftware/DnsServer
- Web Console Documentation: http://localhost:5380/help.html
- API Documentation: https://github.com/TechnitiumSoftware/DnsServer/blob/master/APIDOCS.md

## Support

For issues specific to this Setup-Mac configuration:
```bash
# Check DNS configuration
cat platforms/nixos/system/dns.nix

# Check networking configuration
cat platforms/nixos/system/networking.nix

# Run diagnostics
./scripts/dns-diagnostics.sh
```

For general Technitium DNS issues:
- Check logs: `journalctl -u technitium-dns-server`
- Web Console Help: http://localhost:5380/help.html
- GitHub Issues: https://github.com/TechnitiumSoftware/DnsServer/issues
