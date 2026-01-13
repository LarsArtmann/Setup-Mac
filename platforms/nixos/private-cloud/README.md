# Technitium DNS Server for Private Cloud

This module configures Technitium DNS Server as a network-wide DNS service for your private cloud infrastructure.

## Architecture

- Network-wide DNS server (accessible to all devices)
- Ad blocking for entire network
- Privacy features (DoH/DoT forwarders)
- Persistent caching (shared across devices)
- Web console for management

## Configuration

The DNS server runs on:
- Port 53 (DNS - UDP/TCP) - **Open to network**
- Port 5380 (Web Console - HTTP) - **Open to network**
- Port 53443 (Web Console - HTTPS) - **Open to network**
- Port 443 (DNS-over-HTTPS - DoH) - **Open to network**
- Port 853 (DNS-over-TLS - DoT) - **Open to network**

**Web Console:** `http://<private-cloud-ip>:5380`
**Default Credentials:** admin / admin (CHANGE IMMEDIATELY!)

## Security Considerations

### Web Console Access
- ⚠️ **WARNING:** Web console is exposed to network!
- **RECOMMENDED:** Use reverse proxy with authentication
- **ALTERNATIVE:** Use VPN for remote access
- **REQUIRED:** Change default password immediately

### Firewall Configuration
- All DNS ports are open to network
- Allows any device on network to use this DNS server
- Consider restricting to specific subnets if needed

## Network Deployment

### Option 1: Configure Router DHCP (Recommended)
```bash
# 1. Access router admin panel
#    Usually: http://192.168.1.1 or http://router
#
# 2. Navigate to DHCP settings
#    Look for: DNS Server, DHCP Options, LAN Settings
#
# 3. Set DNS server to Private Cloud IP
#    Example: 192.168.1.100 (replace with actual IP)
#
# 4. Save and restart router
#
# 5. Test from client device:
#    dig @192.168.1.100 google.com
```

### Option 2: Manual Configuration
```bash
# Configure each device individually

# Linux (via NetworkManager or resolvconf)
sudo echo "nameserver 192.168.1.100" > /etc/resolv.conf.d/private-cloud

# macOS (via System Preferences)
# System Preferences > Network > Wi-Fi > DNS
# Add: 192.168.1.100 (Private Cloud IP)

# Windows (via Control Panel)
# Control Panel > Network and Sharing Center > Change Adapter Settings
# Right-click adapter > Properties > Internet Protocol Version 4 (TCP/IPv4)
# Use the following DNS server addresses:
#   Preferred: 192.168.1.100

# Test configuration
dig @192.168.1.100 google.com
```

### Option 3: Use Technitium's Built-in DHCP
```nix
# Uncomment in dns.nix configuration:
# services.dhcpcd.enable = false;
# services.dhcpd4.enable = false;

# Then configure via web console:
# Settings > DHCP Server > Enable DHCP Server
```

## Setup Steps

### 1. Deploy Module
```bash
# Import this module in Private Cloud configuration
# platforms/nixos/private-cloud/default.nix

imports = [
  ./dns.nix  # Add this line
  # ... other imports
];

# Rebuild
sudo nixos-rebuild switch --flake .#private-cloud-hostname
```

### 2. Access Web Console
```bash
# Replace with actual Private Cloud IP
xdg-open http://192.168.1.100:5380
# or
firefox http://192.168.1.100:5380
```

### 3. Configure DNS Server (via Web Console)

#### Initial Setup
1. **Security:** Change admin password
   - Settings > General > Admin Password
   - Use strong password

2. **Forwarders:** Configure DNS forwarders
   - DNS Settings > Forwarders
   - Add Cloudflare (1.1.1.1, 1.0.0.1)
   - Add Quad9 (9.9.9.10, 9.9.9.11)
   - Enable DNS-over-TLS/HTTPS for each

3. **Blocklists:** Enable network-wide ad blocking
   - Block Lists > Quick Add
   - Select popular blocklists (StevenBlack, AdGuard, EasyList)
   - Download blocklists

4. **Caching:** Configure persistent cache
   - DNS Settings > Cache
   - Enable Persistent Cache
   - Cache Size: 500 MB (higher for network usage)
   - Enable Serve Stale, Prefetching

5. **DNSSEC:** Enable validation
   - DNS Settings > DNSSEC
   - Enable DNSSEC Validation

6. **Logging:** Enable query logging
   - Settings > Logging
   - Enable Log Queries, Log Responses

### 4. Configure Network Devices
```bash
# Option A: Configure router DHCP (recommended)
# See "Option 1" above

# Option B: Manual configuration
# See "Option 2" above

# Option C: Use built-in DHCP
# See "Option 3" above
```

### 5. Test from Client Devices
```bash
# From another device on network
dig @192.168.1.100 google.com

# Expected: Returns IP address

# Test ad blocking
dig @192.168.1.100 doubleclick.net

# Expected: NXDOMAIN or 0.0.0.0

# Test DNSSEC
dig @192.168.1.100 +dnssec example.net

# Expected: Returns IP with AD flag (Authenticated Data)
```

## Monitoring

### Web Console Monitoring
- Query Log: Real-time DNS requests from all devices
- Statistics: Request rates, cache hit rate, blocked queries
- Dashboard: Overview of DNS server status

### Command Line Monitoring
```bash
# Check service status
systemctl status technitium-dns-server

# View logs
journalctl -u technitium-dns-server -f

# Check DNS resolution from server
dig google.com

# Check firewall rules
sudo iptables -L -n | grep 53
```

## Advanced Configuration

### Split DNS (Internal vs External)
```bash
# Configure internal zones for local network
# DNS Settings > Zones > Add Zone

# Example: internal.local (local network)
# Zone Type: Primary
# Add A records for internal services:
#   - nas.internal.local -> 192.168.1.200
#   - printer.internal.local -> 192.168.1.201
```

### Conditional Forwarding
```bash
# Forward specific domains to specific DNS servers
# DNS Settings > Conditional Forwarders

# Example: Forward internal.corp.com to internal DNS
# Domain: internal.corp.com
# Forward to: 10.0.0.1 (corporate DNS)
```

### DNS-over-HTTPS/TLS for Privacy
```bash
# Enable encrypted DNS to forwarders
# DNS Settings > Forwarders > Edit Forwarder

# Protocol: DNS-over-TLS or DNS-over-HTTPS
# Address: dns.quad9.net or 1.1.1.1
# Port: 853 (DoT) or 443 (DoH)

# Benefits:
# - Encrypts DNS traffic between server and forwarders
# - Prevents ISP snooping
# - Better privacy
```

### Clustering (Multiple DNS Servers)
```bash
# Set up clustering for redundancy
# Settings > Clustering > Configure Clustering

# Benefits:
# - High availability
# - Load balancing
# - Centralized management
# - Single point of configuration
```

## Troubleshooting

### DNS Resolution Fails from Client
```bash
# Check if DNS server is running
systemctl status technitium-dns-server

# Check firewall (ports open?)
sudo iptables -L -n | grep 53

# Test from server itself
dig @127.0.0.1 google.com

# Test from client
dig @192.168.1.100 google.com

# Check logs
journalctl -u technitium-dns-server -n 50
```

### Ad Blocking Not Working
```bash
# Check blocklists in web console
# Block Lists tab > Verify lists downloaded

# Test blocked domain from client
dig @192.168.1.100 doubleclick.net

# Should return NXDOMAIN or 0.0.0.0
```

### Slow DNS Resolution
```bash
# Check cache hit rate
# Web Console > Statistics > Cache Hit Rate

# If low hit rate:
# - Increase cache size
# - Enable prefetching
# - Check forwarder latency

# Test forwarders directly
dig @9.9.9.10 google.com +time=5
dig @1.1.1.1 google.com +time=5
```

### Web Console Inaccessible
```bash
# Check if service is listening
ss -tulpn | grep 5380

# Check firewall (port 5380 open?)
sudo iptables -L -n | grep 5380

# Restart service
sudo systemctl restart technitium-dns-server
```

### High Resource Usage
```bash
# Check resource usage
systemctl status technitium-dns-server

# If using >1GB RAM:
# - Reduce cache size
# - Clear cache (web console)
# - Reduce blocklist count

# If using >10% CPU:
# - Check query rate (unusual traffic?)
# - Reduce concurrent queries
# - Check for DNS amplification attacks
```

## Backup & Recovery

### Backup Configuration
```bash
# Backup state directory
sudo tar -czf backups/technitium-dns-$(date +%Y%m%d).tar.gz \
  /var/lib/technitium-dns-server/

# Backup NixOS configuration
git add platforms/nixos/private-cloud/dns.nix
git commit -m "backup: Technitium DNS configuration"
```

### Restore Configuration
```bash
# Stop service
sudo systemctl stop technitium-dns-server

# Restore backup
sudo tar -xzf backups/technitium-dns-YYYYMMDD.tar.gz -C /

# Start service
sudo systemctl start technitium-dns-server

# Verify
systemctl status technitium-dns-server
```

### NixOS Rollback
```bash
# If DNS configuration causes issues
sudo nixos-rebuild switch --rollback

# Or specific generation
sudo nixos-rebuild switch --profile /nix/var/nix/profiles/system \
  -p /nix/var/nix/profiles/system-XXX-link
```

## Performance Tuning

### Cache Settings
- **Cache Size:** 500 MB - 2 GB (network-wide usage)
- **Persistent Cache:** Enabled (faster startup)
- **Serve Stale:** Enabled (works offline)
- **Prefetching:** Enabled (pre-populates cache)
- **Concurrent Queries:** 100-500 (depending on network size)

### Blocklist Optimization
- Start with 5-10 blocklists
- Monitor performance impact
- Remove underperforming blocklists
- Update weekly (automatic)

### Forwarder Optimization
- Use multiple forwarders (redundancy)
- Prefer encrypted protocols (DoH/DoT)
- Test latency (choose fastest)
- Configure latency-based selection

## Security Hardening

### Web Console Security
- **Change default password** (critical!)
- Enable HTTPS (port 53443) instead of HTTP
- Use reverse proxy with authentication
- Restrict access via firewall if possible
- Enable TOTP 2FA

### DNS Security
- Enable DNSSEC validation
- Use encrypted forwarders (DoH/DoT)
- Enable query logging (audit trail)
- Monitor for unusual traffic
- Use VPN for remote management

### Network Security
- Restrict access to trusted subnets
- Use VPN for remote DNS access
- Enable firewall logging
- Monitor for DNS amplification attacks
- Regular security audits

## Integration with Services

### Docker DNS Configuration
```nix
# Configure Docker to use Private Cloud DNS
virtualisation.docker = {
  enable = true;
  extraOptions = "--dns 192.168.1.100";
};
```

### Kubernetes DNS Configuration
```bash
# Configure CoreDNS to use Private Cloud
# Edit CoreDNS ConfigMap

forward . 192.168.1.100 {
  policy sequential
}
```

### VPN DNS Configuration
```bash
# Configure VPN clients to use Private Cloud DNS
# Prevents DNS leaks

# WireGuard:
# DNS = 192.168.1.100

# OpenVPN:
# push "dhcp-option DNS 192.168.1.100"
```

## Monitoring & Alerting

### System Monitoring
```bash
# Monitor with Netdata
# Netdata dashboard: DNS section

# Monitor with Prometheus
# Export DNS metrics via HTTP API
```

### Alerting
```bash
# Set up alerts for:
# - DNS server down
# - High error rate
# - High resource usage
# - Unusual query patterns
# - Blocklist update failures
```

## Benefits

### Before (Individual Device DNS)
- ❌ No ad blocking
- ❌ No caching (per-device)
- ❌ No DNS visibility
- ❌ No centralized management
- ❌ No privacy features

### After (Private Cloud DNS)
- ✅ Network-wide ad blocking
- ✅ Shared cache (better performance)
- ✅ Full DNS visibility (all devices)
- ✅ Centralized management
- ✅ Privacy features (DoH/DoT)
- ✅ Custom internal zones
- ✅ Split DNS capability

## Resources

- Technitium DNS Website: https://technitium.com/dns/
- GitHub Repository: https://github.com/TechnitiumSoftware/DnsServer
- NixOS Module: https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/networking/technitium-dns-server.nix
- API Documentation: https://github.com/TechnitiumSoftware/DnsServer/blob/master/APIDOCS.md

## Support

For Private Cloud-specific issues:
```bash
# Check DNS configuration
cat platforms/nixos/private-cloud/dns.nix

# Check network configuration
cat platforms/nixos/private-cloud/networking.nix

# Run diagnostics
./scripts/dns-diagnostics.sh
```

For general Technitium DNS issues:
- Web Console Help: http://192.168.1.100:5380/help.html
- GitHub Issues: https://github.com/TechnitiumSoftware/DnsServer/issues
- Technitium Support: https://technitium.com/contact/

---

**Next Steps:**

1. Deploy Technitium DNS on Private Cloud
2. Configure router DHCP to use Private Cloud DNS
3. Test from all devices on network
4. Monitor performance and adjust configuration
5. (Optional) Configure NixOS laptop to use Private Cloud DNS
