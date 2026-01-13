# Nix Cache DNS Timeout Fix - Deep Research Report

## Problem Analysis

### Symptoms
- `nixos-rebuild switch` hangs with DNS resolution timeouts
- Error: "unable to download 'https://cache.nixos.org/...': Timeout was reached (28)"
- DNS queries timing out after 5 seconds (default timeout)

### Root Causes Identified

#### 1. IPv6 DNS Server in resolv.conf
**Issue:** `/etc/resolv.conf` contains IPv6 DNS server: `fe80::9ee5:49ff:fe61:9178%eno1`

**Why it's a problem:**
- IPv6 DNS resolution times out (network doesn't support IPv6 properly)
- Each DNS query tries IPv6 first, waits for timeout, then falls back to IPv4
- This multiplies the time for every DNS lookup

**How it got there:**
- NetworkManager pulls DNS configuration from the router (192.168.1.254)
- Router advertises IPv6 DNS server via RDNSS (Router Advertisement DNS)
- NetworkManager adds it to `/etc/resolv.conf` despite `enableIPv6 = false` in NixOS config

**Why `enableIPv6 = false` didn't help:**
- This disables IPv6 *routing* and *addresses*, not DNS resolution
- NetworkManager still receives IPv6 DNS server advertisements
- It adds them to `/etc/resolv.conf` regardless of IPv6 being enabled

#### 2. NetworkManager and dhcpcd Conflict
**Issue:** Both NetworkManager and dhcpcd were configured to manage DNS

**Configuration:**
```nix
networking.networkmanager.enable = true;
networking.networkmanager.dns = "none";  # Didn't work!
networking.dhcpcd.extraConfig = ''
  nohook resolv.conf
  static domain_name_servers=9.9.9.10 9.9.9.11
'';
```

**Why it failed:**
- `networking.networkmanager.dns = "none"` doesn't fully disable NetworkManager's DNS
- NetworkManager still gets DNS from router via DHCP
- NetworkManager writes to `/etc/resolv.conf` despite the setting
- dhcpcd's `nohook resolv.conf` only prevents dhcpcd from updating it
- NetworkManager overrides dhcpcd's DNS configuration

#### 3. Manual Editing of /etc/resolv.conf
**Issue:** Fix scripts manually edited `/etc/resolv.conf`

**Consequences:**
- resolvconf (the tool managing `/etc/resolv.conf`) detects "signature mismatch"
- `network-setup.service` fails when trying to update DNS
- System rebuilds partially fail due to network-setup.service errors

**Error messages:**
```
.resolvconf-wrapped: signature mismatch: /etc/resolv.conf
.resolvconf-wrapped: run `resolvconf -u` to update
network-setup.service: Main process exited, code=exited, status=1/FAILURE
```

#### 4. Short Nix DNS Timeout
**Issue:** Default `connect-timeout = 5` in `/etc/nix/nix.conf`

**Problem:**
- 5 seconds is not enough for DNS resolution with IPv6 timeout
- Each cache download requires DNS lookup
- With IPv6 timeout, actual DNS time is ~10+ seconds
- Nix gives up before DNS completes

## Solution Architecture

### Phase 1: Disable NetworkManager
**Rationale:** NetworkManager is over-engineered for simple wired connections and adds complexity to DNS management

**Configuration:**
```nix
# networking.networkmanager.enable = false;  # DISABLED
networking.useDHCP = true;  # Use dhcpcd for DHCP
services.dhcpcd = {
  enable = true;
  persistent = true;  # Keep DHCP lease across reboots
};
```

### Phase 2: Configure dhcpcd for Quad9-Only DNS
**Rationale:** dhcpcd is simpler, more predictable, and allows fine-grained DNS control

**Configuration:**
```nix
networking.dhcpcd.extraConfig = ''
  # Ignore router DNS (prevent IPv6 DNS injection)
  nooption routers
  nooption domain_name_servers

  # Use static Quad9 DNS only
  static domain_name_servers=9.9.9.10 9.9.9.11

  # Don't manage resolv.conf (let network-setup.service do it)
  nohook resolv.conf

  # Disable IPv6 completely in dhcpcd
  noipv6
  noipv6rs
'';
```

**Why this works:**
- `nooption domain_name_servers` prevents dhcpcd from using router DNS
- `static domain_name_servers` forces only Quad9 DNS
- `noipv6` disables IPv6 in dhcpcd (prevents IPv6 DNS server discovery)
- `nohook resolv.conf` lets `network-setup.service` manage `/etc/resolv.conf` via resolvconf

### Phase 3: Increase Nix DNS Timeout
**Rationale:** Longer timeout accommodates network delays without failing

**Configuration:**
```nix
# In platforms/common/core/nix-settings.nix
nix.settings.connect-timeout = 120;  # 120 seconds (was 5)
```

**Why 120 seconds:**
- Accommodates slow DNS resolution
- Prevents premature failures
- Doesn't slow down normal operations (DNS usually completes in <100ms)
- Provides buffer for network hiccups

### Phase 4: Manual Reset and Rebuild
**Rationale:** Clean slate to ensure no lingering configuration conflicts

**Steps:**
1. Reset `/etc/resolv.conf` to resolvconf management (remove manual edits)
2. Stop and disable NetworkManager service
3. Enable dhcpcd service
4. Rebuild NixOS with new networking configuration
5. Verify DNS configuration and resolution

## Verification

### Expected /etc/resolv.conf After Fix
```
nameserver 9.9.9.10
nameserver 9.9.9.11
search lan
options edns0
```

### Expected nmcli Output (NetworkManager Disabled)
```
# NetworkManager should be stopped
# dhcpcd should be managing the interface
```

### Expected Systemd Services
```
dhcpcd.service: active
network-setup.service: active (no more signature mismatch)
NetworkManager.service: inactive/dead
```

### Expected DNS Resolution
```bash
$ host cache.nixos.org
cache.nixos.org has address 151.101.193.91
cache.nixos.org has address 151.101.1.91
cache.nixos.org has address 151.101.65.91
cache.nixos.org has address 151.101.129.91
cache.nixos.org has address 151.101.193.91
cache.nixos.org has address 151.101.1.91
cache.nixos.org has address 151.101.65.91
cache.nixos.org has address 151.101.193.91
```

### Expected Nix Rebuild
```bash
$ sudo nixos-rebuild switch --flake .#evo-x2
building the system configuration...
activating the configuration...
setting up /etc...
# No DNS timeout errors!
# No network-setup.service failures!
✅ Rebuild successful
```

## Alternative Approaches Considered

### Alternative 1: Configure NetworkManager Properly
**Approach:** Configure NetworkManager to use only Quad9 DNS via connection profiles

**Why rejected:**
- Complex configuration (requires creating NetworkManager connection profiles)
- NetworkManager still tries IPv6 DNS despite configuration
- Requires understanding NetworkManager's DNS plugin system
- More moving parts, harder to debug

### Alternative 2: Use systemd-networkd
**Approach:** Replace both NetworkManager and dhcpcd with systemd-networkd

**Why rejected:**
- Steep learning curve (systemd-networkd is complex)
- Overkill for simple wired connection
- NetworkManager is already well-integrated with NixOS desktop environment
- Would require complete networking reconfiguration

### Alternative 3: Keep NetworkManager + Use resolvconf Override
**Approach:** Use `resolvconf -a` to override NetworkManager's DNS

**Why rejected:**
- Doesn't fix root cause (NetworkManager still tries IPv6 DNS)
- Still have conflict between NetworkManager and dhcpcd
- More complex state management
- Not a clean solution

## Files Modified

1. `platforms/nixos/system/networking.nix`
   - Disabled NetworkManager
   - Enabled dhcpcd
   - Configured dhcpcd for Quad9-only DNS
   - Disabled IPv6 in dhcpcd

2. `platforms/common/core/nix-settings.nix`
   - Increased `connect-timeout` to 120s

3. `fix-network-deep.sh`
   - Comprehensive fix script that:
     - Resets `/etc/resolv.conf`
     - Stops NetworkManager
     - Enables dhcpcd
     - Rebuilds system
     - Verifies configuration

## Testing Checklist

- [ ] `/etc/resolv.conf` contains only Quad9 DNS (no IPv6)
- [ ] NetworkManager is stopped and disabled
- [ ] dhcpcd is running and active
- [ ] network-setup.service is active (no signature mismatch errors)
- [ ] `host cache.nixos.org` resolves quickly (<1 second)
- [ ] `nixos-rebuild switch` completes without DNS timeout errors
- [ ] `nix-store ping --store https://cache.nixos.org` succeeds
- [ ] General internet browsing works
- [ ] DNS lookups are fast (Quad9 is fast and reliable)

## Rollback Plan

If the fix causes issues:

```bash
# Re-enable NetworkManager
sudo systemctl enable NetworkManager
sudo systemctl start NetworkManager

# Disable dhcpcd
sudo systemctl disable dhcpcd

# Restore old networking configuration
git checkout HEAD -- platforms/nixos/system/networking.nix

# Rebuild with old config
sudo nixos-rebuild switch --flake .#evo-x2
```

## Summary

**Root Cause:** NetworkManager was pulling IPv6 DNS from router, causing DNS resolution timeouts for Nix cache lookups.

**Solution:** Migrate from NetworkManager to dhcpcd for simpler, more predictable network and DNS management with strict Quad9-only DNS configuration.

**Result:** Fast, reliable DNS resolution using Quad9 only, no IPv6 DNS timeouts, successful Nix cache downloads.

**Files Changed:**
- `platforms/nixos/system/networking.nix` (NetworkManager → dhcpcd)
- `platforms/common/core/nix-settings.nix` (timeout: 5s → 120s)

**Time to Fix:** ~20-30 minutes (mostly for rebuild)

**Complexity:** Medium (requires service migration, but well-documented)
