# Technitium DNS Migration Guide

**Date:** 2026-01-13
**Version:** 1.0
**Target:** NixOS Laptop (evo-x2)

---

## Overview

This guide walks you through migrating from Quad9 DNS (direct) to Technitium DNS Server with local caching and ad blocking.

## Prerequisites

- ✅ NixOS system (evo-x2) is running
- ✅ Current DNS configuration works (Quad9 via dhcpcd)
- ✅ Root/sudo access for system changes
- ✅ 30-60 minutes for complete migration

## Migration Timeline

| Phase | Duration | Description |
|-------|-----------|-------------|
| **Preparation** | 5 min | Backup current config, review documentation |
| **Deployment** | 10 min | Enable Technitium DNS, rebuild NixOS |
| **Configuration** | 15 min | Web console setup, forwarders, blocklists |
| **Testing** | 10 min | DNS resolution, ad blocking, performance |
| **Cleanup** | 5 min | Verify all systems working |
| **Total** | **45 min** | Complete migration |

---

## Phase 1: Preparation (5 minutes)

### Step 1.1: Review Current DNS Configuration
```bash
# Check current DNS servers
cat /etc/resolv.conf

# Expected output:
# nameserver 9.9.9.10
# nameserver 9.9.9.11
```

### Step 1.2: Create Backup
```bash
# Backup current DNS configuration
sudo cp /etc/resolv.conf /etc/resolv.conf.backup.$(date +%Y%m%d-%H%M%S)

# Backup Technitium DNS state (if exists)
sudo tar -czf ~/backups/technitium-dns-pre-migration-$(date +%Y%m%d-%H%M%S).tar.gz \
  /var/lib/technitium-dns-server/ 2>/dev/null || echo "  (No existing state to backup)"

# Create NixOS backup generation
sudo nixos-rebuild build --flake .#evo-x2
echo "Current generation: $(readlink /run/current-system)"
```

### Step 1.3: Review Documentation
```bash
# Read the DNS module documentation
cat platforms/nixos/system/dns.nix

# Read the evaluation document
cat docs/architecture/TECHNITIUM-DNS-EVALUATION.md
```

### Step 1.4: Verify Requirements
```bash
# Check if Technitium DNS package is available
nix search nixpkgs technitium-dns-server

# Should show: technitium-dns-server package

# Check web browser availability
which firefox || which chromium || which google-chrome
echo "✅ Web browser found"

# Check disk space (need ~500MB for persistent cache)
df -h / | grep -v Filesystem | awk '{print "Available space: " $4}'
echo "✅ Disk space check complete"
```

### Step 1.5: Prepare Rollback Plan
```bash
# Save current generation for rollback
sudo nixos-rebuild switch --flake .#evo-x2
CURRENT_GENERATION=$(readlink /run/current-system)
echo "Current working generation: $CURRENT_GENERATION"

# In case of issues, rollback with:
# sudo nixos-rebuild switch --rollback
```

---

## Phase 2: Deployment (10 minutes)

### Step 2.1: Verify DNS Module Import
```bash
# Check if dns-config.nix is imported in configuration.nix
grep "dns-config" platforms/nixos/system/configuration.nix

# Expected output:
# ./dns-config.nix
```

### Step 2.2: Test Configuration Syntax
```bash
# Validate Nix syntax
nix-instantiate --eval --show-trace \
  platforms/nixos/system/configuration.nix

# Expected: No errors
```

### Step 2.3: Build System
```bash
# Build with Technitium DNS enabled
sudo nixos-rebuild build --flake .#evo-x2 --print-build-logs

# Expected:
# - Builds Technitium DNS Server package
# - Creates new system generation
# - No errors

# If build fails:
# - Review error message
# - Check syntax
# - Rollback if needed: sudo nixos-rebuild switch --rollback
```

### Step 2.4: Switch to New Generation
```bash
# Apply new configuration
sudo nixos-rebuild switch --flake .#evo-x2 --print-build-logs

# Expected:
# - Activates new generation
# - Starts Technitium DNS service
# - Updates /etc/resolv.conf to use 127.0.0.1

# Verify service started
systemctl status technitium-dns-server

# Expected output:
# ● technitium-dns-server.service - Technitium DNS Server
#    Loaded: loaded (/etc/systemd/system/technitium-dns-server.service; enabled; vendor preset: enabled)
#    Active: active (running) since <timestamp>
```

### Step 2.5: Verify DNS Configuration
```bash
# Check /etc/resolv.conf (should now use local DNS)
cat /etc/resolv.conf

# Expected output:
# nameserver 127.0.0.1

# Check if Technitium DNS is listening
ss -tulpn | grep :53

# Expected output:
# udp   LISTEN 0  4096  127.0.0.1:53  0.0.0.0:*  users:(("technitium-dns",pid=XXX,fd=X))
# tcp   LISTEN 0  4096  127.0.0.1:53  0.0.0.0:*  users:(("technitium-dns",pid=XXX,fd=X))
```

---

## Phase 3: Configuration (15 minutes)

### Step 3.1: Access Web Console
```bash
# Open web console
just dns-console

# Or manually:
firefox http://localhost:5380

# Expected:
# - Opens Technitium DNS web console
# - Auto-logged in as admin/admin (CHANGE PASSWORD!)
```

### Step 3.2: Change Admin Password
```
1. Click "Settings" in the left menu
2. Click "General" tab
3. Enter current password: admin
4. Enter new password: [USE STRONG PASSWORD]
5. Confirm new password
6. Click "Save"

✅ Password changed
```

### Step 3.3: Configure Forwarders
```
1. Click "DNS Settings" in the left menu
2. Click "Forwarders" tab
3. Click "Add Forwarder"

4. Add Quad9 (Primary):
   - Name: Quad9
   - Protocol: DNS-over-TLS
   - Address: dns.quad9.net
   - Port: 853
   - Click "Save"

5. Add Cloudflare (Secondary):
   - Name: Cloudflare
   - Protocol: DNS-over-TLS
   - Address: 1.1.1.1
   - Port: 853
   - Click "Save"

6. Add Quad9 (Fallback - optional):
   - Name: Quad9 Fallback
   - Protocol: Plain DNS
   - Address: 9.9.9.10
   - Click "Save"

✅ Forwarders configured
```

### Step 3.4: Enable Ad Blocking
```
1. Click "Block Lists" in the left menu
2. Click "Quick Add" button

3. Add blocklists (select top 3-5):
   ☑ StevenBlack (hosts)
   ☑ AdGuard DNS filter
   ☑ EasyList
   ☑ OISD Blocklist (malware)
   ☑ Phishing URL Blocklist

4. Click "Download" button
5. Wait for download to complete

✅ Ad blocking enabled
```

### Step 3.5: Enable Persistent Caching
```
1. Click "DNS Settings" in the left menu
2. Click "Cache" tab

3. Configure cache:
   ☑ Enable Persistent Cache
   Cache Size: 100 MB (or 200 MB for better performance)
   ☑ Serve Stale (serves cached entries even after expiry)
   ☑ Prefetch (populates cache for frequently visited domains)
   ☑ Auto Prefetch (learns from query patterns)

4. Click "Save"

✅ Caching configured
```

### Step 3.6: Enable DNSSEC Validation
```
1. Click "DNS Settings" in the left menu
2. Click "DNSSEC" tab

3. Configure DNSSEC:
   ☑ Enable DNSSEC Validation
   Validation Mode: Strict

4. Click "Save"

✅ DNSSEC validation enabled
```

### Step 3.7: Enable Query Logging
```
1. Click "Settings" in the left menu
2. Click "Logging" tab

3. Configure logging:
   ☑ Log Queries
   ☑ Log Responses
   ☑ Log Request Headers

4. Click "Save"

✅ Logging enabled
```

### Step 3.8: Test Configuration
```
1. Click "DNS Client" in the left menu
2. Enter domain: google.com
3. Click "Lookup"

Expected output:
google.com
  A: 142.250.80.46
  Query Time: XX ms
  From: [forwarder name]

4. Test ad blocking:
   Enter domain: doubleclick.net
   Click "Lookup"

Expected output:
doubleclick.net
  Status: Blocked (or NXDOMAIN)
  Query Time: XX ms
  From: Cache

✅ Configuration verified
```

---

## Phase 4: Testing (10 minutes)

### Step 4.1: Test Basic DNS Resolution
```bash
# Test basic resolution
just dns-test

# Expected output:
# Testing basic resolution...
#   google.com:
#   142.250.80.46
#
# Testing ad blocking (should return 0.0.0.0 or NXDOMAIN)...
#   doubleclick.net
#   ✅ Domain blocked
```

### Step 4.2: Test Caching Performance
```bash
# Test uncached resolution
echo "Uncached resolution:"
time dig github.com +short > /dev/null

# Expected: ~50-100ms

# Test cached resolution
echo "Cached resolution:"
time dig github.com +short > /dev/null

# Expected: ~1-5ms (10-100x faster)

✅ Caching is working
```

### Step 4.3: Test Ad Blocking
```bash
# Test ad domain
dig doubleclick.net +short

# Expected: Empty output or NXDOMAIN

# Test malware domain
dig malwaredomain.com +short

# Expected: Empty output or NXDOMAIN

✅ Ad blocking is working
```

### Step 4.4: Test DNSSEC Validation
```bash
# Test DNSSEC-protected domain
dig +dnssec example.net +short

# Expected: Returns IP address (validation successful)

# Check if AD flag is set (Authenticated Data)
dig +dnssec +adflag example.net

# Expected: ; EDNS flags: ; ad (Authenticated Data)

✅ DNSSEC validation is working
```

### Step 4.5: Test with Real Applications
```bash
# Test web browsing
firefox https://google.com

# Expected: Page loads normally

# Test ad blocking
firefox https://doubleclick.net

# Expected: Page blocked or connection refused

# Test DNS cache
# Visit several websites, close browser, reopen
# Second visits should be faster (cached DNS)

✅ Real-world testing complete
```

### Step 4.6: Monitor DNS Logs
```bash
# Monitor query logs in real-time
just dns-logs

# Expected:
# Continuous stream of DNS queries
# Each query shows: domain, client IP, response time, forwarder used

# Press Ctrl+C to exit
```

### Step 4.7: Check Service Status
```bash
# Check service status
just dns-status

# Expected:
# ● technitium-dns-server.service - Technitium DNS Server
#    Active: active (running)
#    Memory: ~50-100 MB
#    CPU: <1%
```

---

## Phase 5: Cleanup & Verification (5 minutes)

### Step 5.1: Verify All Systems Working
```bash
# Run comprehensive diagnostics
just dns-diagnostics

# Expected:
# ✅ Service running
# ✅ DNS configuration correct
# ✅ DNS resolution working
# ✅ Ad blocking working
```

### Step 5.2: Check System Health
```bash
# Check system health
just health

# Expected:
# All checks passing
# No DNS-related errors
```

### Step 5.3: Remove Temporary Backups
```bash
# Remove temporary backup files (optional)
# Keep final backup for reference
sudo rm -f /etc/resolv.conf.backup.* 2>/dev/null

# Keep this for reference:
# ~/backups/technitium-dns-pre-migration-YYYYMMDD-HHMMSS.tar.gz
```

### Step 5.4: Document Changes
```bash
# Create migration notes
cat > ~/backups/migration-notes-$(date +%Y%m%d).md << 'EOF'
# Technitium DNS Migration Notes

**Date:** $(date +%Y-%m-%d)
**System:** NixOS (evo-x2)

## Changes Made
- ✅ Enabled Technitium DNS Server via NixOS module
- ✅ Configured forwarders (Quad9, Cloudflare)
- ✅ Enabled ad blocking (5 blocklists)
- ✅ Enabled persistent caching (100 MB)
- ✅ Enabled DNSSEC validation
- ✅ Enabled query logging

## Configuration Details
- Web Console: http://localhost:5380
- DNS Server: 127.0.0.1 (local)
- Forwarders: Quad9 (DoT), Cloudflare (DoT), Quad9 (Plain)
- Blocklists: StevenBlack, AdGuard, EasyList, OISD, Phishing
- Cache Size: 100 MB
- DNSSEC: Strict mode

## Test Results
- Basic DNS resolution: ✅
- Ad blocking: ✅
- Caching performance: ✅ (10-100x faster)
- DNSSEC validation: ✅

## Rollback Generation
$(readlink /run/current-system)

## Notes
- Migration completed successfully
- No issues encountered
- System performing as expected
EOF

echo "✅ Migration notes saved"
```

### Step 5.5: Final Verification Checklist
```bash
echo "📋 Final Verification Checklist"
echo ""

# [ ] DNS resolution works (google.com resolves)
# [ ] Ad blocking works (doubleclick.net blocked)
# [ ] Caching works (cached queries are fast)
# [ ] DNSSEC validation works
# [ ] Web console accessible
# [ ] Logs are being recorded
# [ ] Service is running and stable
# [ ] System health check passes
# [ ] No DNS-related errors in logs
# [ ] Rollback generation recorded

echo ""
echo "✅ If all items checked, migration is complete!"
```

---

## Troubleshooting

### Issue 1: DNS Resolution Fails
**Symptoms:**
- `dig google.com` returns SERVFAIL or timeout
- Web pages don't load

**Solutions:**
```bash
# Check if service is running
systemctl status technitium-dns-server

# Check logs for errors
journalctl -u technitium-dns-server -n 50

# Restart service
just dns-restart

# If still failing, rollback
sudo nixos-rebuild switch --rollback
```

### Issue 2: Web Console Inaccessible
**Symptoms:**
- Cannot access http://localhost:5380
- Connection refused or timeout

**Solutions:**
```bash
# Check if service is listening
ss -tulpn | grep 5380

# Check firewall (not applicable for localhost)
# But check if service is running
systemctl status technitium-dns-server

# Restart service
sudo systemctl restart technitium-dns-server

# Rebuild if needed
sudo nixos-rebuild switch --flake .#evo-x2
```

### Issue 3: Ad Blocking Not Working
**Symptoms:**
- Ad domains resolve normally
- Ads still visible in browser

**Solutions:**
```bash
# Check blocklists in web console
# Block Lists tab > Verify lists are downloaded

# Test blocked domain manually
dig @127.0.0.1 doubleclick.net

# Should return NXDOMAIN or 0.0.0.0

# If working in DNS but ads still show:
# - Check browser cache (clear cache)
# - Check browser extensions (might be interfering)
# - Check if ad domain uses different DNS (unlikely)
```

### Issue 4: Slow DNS Resolution
**Symptoms:**
- All queries take >100ms
- No performance improvement

**Solutions:**
```bash
# Check cache hit rate (via web console)
# Statistics tab > Cache Hit Rate

# If hit rate is low:
# - Increase cache size (200 MB or 500 MB)
# - Enable prefetching and auto-prefetching
# - Check if forwarders are slow

# Test forwarders directly
dig @9.9.9.10 google.com +time=5
dig @1.1.1.1 google.com +time=5

# If forwarders are slow:
# - Change to different forwarders
# - Use different protocol (DoH vs DoT vs plain)
```

### Issue 5: High Memory Usage
**Symptoms:**
- Technitium DNS using >500 MB RAM
- System slows down

**Solutions:**
```bash
# Check actual memory usage
systemctl status technitium-dns-server

# If using >500 MB:
# - Reduce cache size (100 MB instead of 500 MB)
# - Clear cache (via web console)
# - Reduce number of blocklists
# - Restart service
sudo systemctl restart technitium-dns-server
```

### Issue 6: Migration Failed Completely
**Symptoms:**
- NixOS rebuild failed
- System won't boot
- Can't access web console

**Solutions:**
```bash
# Emergency rollback from GRUB
# 1. Reboot to GRUB menu
# 2. Select previous generation
# 3. Boot successfully

# Or rollback from running system:
sudo nixos-rebuild switch --rollback

# Or rollback to specific generation:
sudo nixos-rebuild switch --profile /nix/var/nix/profiles/system \
  -p /nix/var/nix/profiles/system-XXX-link

# Check what went wrong:
# - Read error messages from rebuild
# - Check syntax
# - Review configuration
```

---

## Rollback Plan

If migration causes issues, follow these steps:

### Immediate Rollback (if system is running)
```bash
# Rollback to previous generation
sudo nixos-rebuild switch --rollback

# This restores Quad9 DNS configuration
# System returns to working state
```

### Emergency Rollback (if system won't boot)
```bash
# 1. Reboot to GRUB menu
# 2. Select "Advanced options" > Select previous generation
# 3. Boot successfully

# 4. Once booted, fix the issue:
#    - Review configuration
#    - Check syntax
#    - Test before switching
```

### Selective Rollback (disable Technitium DNS only)
```bash
# If you want to keep NixOS config but disable Technitium DNS:
nano platforms/nixos/system/configuration.nix

# Comment out this line:
# ./dns-config.nix

# Save and exit
# Rebuild:
sudo nixos-rebuild switch --flake .#evo-x2

# This restores Quad9 DNS while keeping other changes
```

---

## Post-Migration Monitoring

### First Week Monitoring
```bash
# Check daily (for first week)
just dns-diagnostics

# Look for:
# - Service stability
# - DNS resolution success rate
# - Cache hit rate improvement
# - Ad blocking effectiveness
# - Resource usage (CPU, memory)
```

### Weekly Maintenance
```bash
# Check blocklist updates (automatic, but verify)
# Web Console > Block Lists > Check "Last Updated"

# Check cache size
# Web Console > DNS Settings > Cache > Cache Usage

# Review logs for unusual patterns
# Web Console > Query Log > Look for:
# - Excessive failures
# - Unusual domains
# - Blocked queries count
```

### Monthly Review
```bash
# Review performance metrics
# Web Console > Statistics > Compare month-over-month

# Optimize if needed:
# - Add/remove blocklists
# - Adjust cache size
# - Tune forwarders
# - Update configuration
```

---

## Success Criteria

Migration is successful if:

- ✅ DNS resolution works for all domains
- ✅ Ad blocking blocks ads and malware domains
- ✅ Caching provides 10-100x performance improvement for cached entries
- ✅ DNSSEC validation enabled and working
- ✅ Web console accessible and functional
- ✅ Logs are being recorded
- ✅ Service is stable (no crashes)
- ✅ Resource usage is acceptable (<500 MB RAM, <5% CPU)
- ✅ System health check passes
- ✅ No DNS-related errors in logs
- ✅ Rollback generation documented

---

## Support

For issues specific to this migration:
```bash
# Check migration notes
cat ~/backups/migration-notes-$(date +%Y%m%d).md

# Check DNS documentation
cat platforms/nixos/system/dns.nix

# Check evaluation document
cat docs/architecture/TECHNITIUM-DNS-EVALUATION.md

# Run diagnostics
./scripts/dns-diagnostics.sh
```

For general Technitium DNS issues:
- Web Console Help: http://localhost:5380/help.html
- GitHub Issues: https://github.com/TechnitiumSoftware/DnsServer/issues
- Technitium Support: https://technitium.com/contact/

---

## Next Steps

After successful migration:

1. **Optional:** Configure MacBook Air to use Private Cloud DNS (when available)
2. **Optional:** Deploy on Private Cloud for network-wide DNS
3. **Advanced:** Configure split DNS for internal/external domains
4. **Advanced:** Set up clustering for multiple DNS servers
5. **Automation:** Use HTTP API for automated configuration

---

**Migration Complete!** 🎉

You've successfully migrated to Technitium DNS with ad blocking, caching, and privacy features.
