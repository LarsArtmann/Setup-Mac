# Network & DNS Troubleshooting Guide for evo-x2

## Quick Diagnostics

Run the diagnostic script on evo-x2:
```bash
./scripts/dns-diagnostics.sh
```

## Common Issues & Fixes

### 1. File Descriptor Limits

**Symptoms:**
- `error: opening directory "/nix/store": Too many open files`
- Multiple cache timeouts simultaneously

**Fix:** Add to `platforms/nixos/system/networking.nix`:
```nix
# Increase file descriptor limits for Nix builds
systemd.extraConfig = ''
  DefaultLimitNOFILE=65536
  DefaultLimitNPROC=4096
'';
```

### 2. systemd-resolved Conflicts

**Symptoms:**
- Router DNS (10.43.255.55) still being used
- DNS switching between Quad9 and router
- Inconsistent resolution

**Fix A:** Disable systemd-resolved in `platforms/nixos/system/networking.nix`:
```nix
services.resolved.enable = false;
```

**Fix B:** Configure NetworkManager to use systemd-resolved (preferred):
```nix
networking.networkmanager.dns = "systemd-resolved";
```

### 3. IPv6 Link-Local DNS

**Symptoms:**
- `/etc/resolv.conf` contains `nameserver fe80::...`
- DNS tries IPv6 first, times out, then falls back to IPv4

**Fix A:** Force IPv4-only DNS in `platforms/nixos/system/networking.nix`:
```nix
networking.networkmanager = {
  dns = "none";
  ipv6.dns.ipv4-only = true;  # Only use IPv4 for DNS
};
```

**Fix B:** Disable IPv6 completely in DNS (already done):
```nix
networking.enableIPv6 = false;
```

### 4. MTU Fragmentation Issues

**Symptoms:**
- Large DNS responses fail
- Intermittent DNS timeouts
- Works for simple queries, fails for complex ones

**Fix:** Set correct MTU in `platforms/nixos/hardware/hardware-configuration.nix`:
```nix
networking.interfaces.eno1.mtu = 1500;
# Or for WiFi
networking.interfaces.wlp...mtu = 1400;
```

### 5. Nix Daemon Settings Not Applied

**Symptoms:**
- Settings changed but timeouts still occur
- Daemon using old configuration

**Fix:** Reload Nix daemon after config changes:
```bash
sudo systemctl reload nix-daemon.socket
sudo systemctl restart nix-daemon
```

Or add systemd restart to apply changes:
```nix
systemd.services.nix-daemon.restartIfChanged = true;
```

### 6. Security Services Interference

**Symptoms:**
- ClamAV updater hammering network
- Fail2ban blocking legitimate requests
- Network storms from security tools

**Fix:** Configure update intervals in `platforms/nixos/desktop/security-hardening.nix`:
```nix
services.clamav = {
  updater = {
    enable = true;
    interval = "daily";  # Instead of default (may be hourly)
    frequency = 1;  # Check once per day
  };
};
```

### 7. Docker Network Conflicts

**Symptoms:**
- Docker using different DNS than host
- DNS works outside Docker but fails inside containers

**Fix:** Configure Docker DNS in `platforms/nixos/services/default.nix`:
```nix
virtualisation.docker = {
  enable = true;
  extraOptions = "--dns 9.9.9.10 --dns 9.9.9.11";
};
```

### 8. DNSSEC Delays

**Symptoms:**
- 5+ second delays on DNS queries
- Multiple DNS round-trips per request

**Fix:** Disable DNSSEC for faster resolution (optional security trade-off):
```nix
services.resolved = {
  enable = true;
  dnssec = "false";  # Disable DNSSEC for speed
};
```

## Recommended Fixes Priority

### High Priority (Implement First)
1. ✅ Increase Nix connect-timeout to 60s (DONE)
2. ✅ Reduce http-connections to 10 (DONE)
3. ✅ Add NetworkManager DNS override (DONE)
4. **NEW:** Increase file descriptor limits
5. **NEW:** Disable or properly configure systemd-resolved

### Medium Priority
6. **NEW:** Configure IPv4-only DNS in NetworkManager
7. **NEW:** Verify MTU settings match network
8. **NEW:** Configure Docker DNS to use Quad9

### Low Priority (Optional)
9. **NEW:** Adjust ClamAV update intervals
10. **NEW:** Consider DNSSEC vs speed trade-off

## Testing After Fixes

After applying fixes, test with:
```bash
# Test flake check
nix flake check

# Test DNS resolution
time host cache.nixos.org 9.9.9.10

# Test full rebuild
sudo nixos-rebuild test --flake .#evo-x2

# Monitor for issues
journalctl -u nix-daemon -f
journalctl -u NetworkManager -f
```

## Verification Commands

```bash
# Check what DNS is actually being used
resolvectl status
nmcli dev show | grep DNS
cat /etc/resolv.conf

# Check FD limits
ulimit -n
cat /proc/sys/fs/file-max

# Test DNS speed
time host cache.nixos.org
time host github.com

# Test cache accessibility
curl -I https://cache.nixos.org/
curl -I https://nix-community.cachix.org/
curl -I https://hyprland.cachix.org/
```

## Monitoring

Watch for DNS/network issues:
```bash
# Monitor Nix daemon
journalctl -u nix-daemon -f

# Monitor NetworkManager
journalctl -u NetworkManager -f

# Monitor systemd-resolved
journalctl -u systemd-resolved -f

# Monitor DNS queries (install dnstracer)
dnstracer cache.nixos.org

# Monitor network connections
netstat -an | grep :53
ss -tun | grep :53
```

## Emergency Rollback

If fixes make things worse:
```bash
# Rollback to previous generation
sudo nixos-rebuild switch --rollback

# Or specific generation
sudo nixos-rebuild switch --profile /nix/var/nix/profiles/system -p /nix/var/nix/profiles/system-XXX-link
```

## Documentation

For more information:
- NixOS DNS: https://nixos.org/manual/nixos/stable/#opt-networking.nameservers
- NetworkManager: https://networkmanager.dev/docs/
- DNSSEC: https://www.dnssec.net/
