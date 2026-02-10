# ADR-003: Ban OpenZFS on macOS Due to Kernel Stability Issues

## Status
**Accepted** - Effective Immediately

## Date
2026-02-09

## Context

### Problem Statement

OpenZFS on macOS (`org.openzfsonosx.zfs`) caused **4+ kernel panics in 24 hours**, rendering the system unusable. The kernel extension triggered watchdog timeouts, causing complete system freezes requiring hard reboots.

**Evidence:**
- Panic type: `watchdog timeout: no checkins from watchdogd in 92 seconds`
- Culprit: `org.openzfsonosx.zfs 2.3.0` (OpenZFS macOS port)
- Last stopped kext in panic log: ZFS
- ZFS kext unload took 10+ seconds (abnormal - indicates instability)
- LaunchDaemon unload failed with I/O error (kext in bad state)

### Why ZFS Was Problematic on macOS

| Factor | Linux ZFS | macOS OpenZFS |
|--------|-----------|---------------|
| **Codebase** | ZFS on Linux (production) | OpenZFS OSX port (separate) |
| **Maintenance** | Active, enterprise-grade | Sporadic, Apple Silicon issues |
| **Stability** | Production-stable | Known kernel panic issues |
| **Maturity** | 10+ years production | Less mature, platform-specific bugs |
| **Apple Silicon** | N/A | Known compatibility issues |

**Root Cause:** The macOS OpenZFS port is a separate implementation from Linux ZFS. While Linux ZFS is battle-tested in enterprise environments (Proxmox, TrueNAS, cloud providers), the macOS port has known stability issues, particularly on Apple Silicon.

### What Worked on Linux

ZFS on NixOS (`evo-x2`) remains **unaffected** by this decision:
- Uses mature ZFS on Linux codebase
- Production-stable and widely deployed
- Properly integrated with NixOS kernel

## Decision

### Ban OpenZFS on macOS

**Effective immediately, OpenZFS is banned from all macOS (Darwin) configurations.**

#### Scope

| Platform | ZFS Status | Reason |
|----------|------------|--------|
| **macOS (Darwin)** | ❌ **BANNED** | Kernel panic risk, unstable kext |
| **NixOS (Linux)** | ✅ **Allowed** | Production-stable, mature codebase |

#### Rationale

1. **System Stability**: Kernel panics cause data loss and downtime
2. **No Benefit**: ZFS was installed but unused (no pools configured)
3. **Better Alternatives**: APFS (native), external storage, or NixOS for ZFS
4. **Risk/Reward**: High risk (kernel crashes) vs zero reward (unused)

## Consequences

### Positive

- ✅ Eliminates kernel panic risk on macOS
- ✅ Simplifies macOS configuration
- ✅ Removes third-party kext maintenance burden
- ✅ Faster boot times (no kext loading)
- ✅ Reduced attack surface

### Negative

- ❌ No ZFS features on macOS (snapshots, compression, RAID-Z)
- ❌ Must use alternative filesystems (APFS, external storage)

### Migration Path

For users needing ZFS features:

1. **Use NixOS** (`evo-x2`) for ZFS workloads
2. **External storage** with ZFS on Linux
3. **APFS** for native macOS (snapshots via Time Machine)

## Implementation

### Immediate Actions

```bash
# 1. Unload ZFS kext
sudo kextunload -b org.openzfsonosx.zfs

# 2. Remove LaunchDaemons
sudo rm -f /Library/LaunchDaemons/org.openzfsonosx.*

# 3. Clear kernel cache
sudo touch /System/Library/Extensions
sudo kextcache -u /

# 4. Reboot
sudo reboot
```

### Verification

```bash
# Verify ZFS is completely removed
kextstat | grep -i zfs        # Should be empty
ls /Library/LaunchDaemons/ | grep zfs  # Should be empty
ls /usr/local/zfs             # Should not exist
```

### Nix Configuration

**No action required** - Nix configs were already clean (no ZFS references found).

## References

- [Kernel Panic Investigation Report](/docs/status/2026-02-09_01-38_KERNEL-PANIC-INVESTIGATION-AND-ZFS-REMOVAL.md)
- [OpenZFS macOS Issues](https://github.com/openzfsonosx/openzfs/issues)
- [ZFS on Linux](https://zfsonlinux.org/) (stable, production-ready)

## Related Decisions

- ADR-001: Home Manager for Cross-Platform Configuration
- ADR-002: Cross-Shell Alias Architecture

---

**Decision Record Owner:** SystemNix Architecture Team
**Last Updated:** 2026-02-09
**Next Review:** N/A (Permanent Ban)
