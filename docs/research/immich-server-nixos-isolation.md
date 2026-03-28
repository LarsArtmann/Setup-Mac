# Immich Server on NixOS: Isolation Strategy Research

**Date:** 2026-03-28
**Status:** Research Complete — Awaiting Decision
**Target Host:** evo-x2 (GMKtec AMD Ryzen AI Max+ 395, Strix Halo)
**Filesystem:** BTRFS (single NVMe, compress=zstd, noatime)

---

## Executive Summary

Immich is a self-hosted Google Photos alternative with native NixOS module support. Four isolation approaches were evaluated. **Incus/LXC is the recommended approach** if more isolated services are planned; otherwise, the **direct NixOS service module** is simplest.

---

## 1. Immich Requirements

### Dependencies (auto-managed by NixOS module)

| Component | Purpose | Notes |
|-----------|---------|-------|
| PostgreSQL | Metadata DB | Auto-configured by module |
| Redis | Caching/queues | Auto-configured by module |
| Typesense | Full-text search | Bundled with server |
| Machine Learning | Face detection, CLIP search, Smart Search | CPU or GPU |

### Hardware Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| RAM | 6 GB | 8 GB+ |
| CPU | 2 cores | 4 cores |
| Storage | Library size + 20% | SSD for DB |

### GPU Acceleration (AMD Strix Halo)

- ROCm backend supported but can be finicky with newer AMD GPUs
- Fallback to CPU inference available
- Each ML worker consumes ~1-2 GB RAM
- Configurable via `services.immich.accelerationDevices`

---

## 2. Isolation Approaches Compared

### Option A: Direct NixOS Service (Simplest)

```nix
services.immich = {
  enable = true;
  port = 2283;
  host = "0.0.0.0";
  openFirewall = true;
  mediaLocation = "/var/lib/immich";
  accelerationDevices = null;
};
```

| Aspect | Detail |
|--------|--------|
| Isolation | systemd service hardening (PrivateDevices, etc.) |
| Complexity | Minimal — one module toggle |
| GPU access | Needs `PrivateDevices = false` override |
| Declarative | Fully declarative |
| Management | `systemctl status immich-server` |

**Pros:** Simplest, fully declarative, no extra daemons
**Cons:** Not truly isolated, shares host PID/network/FS namespace

### Option B: NixOS Declarative Container (systemd-nspawn)

```nix
containers.immich = {
  autoStart = true;
  privateNetwork = true;
  hostAddress = "192.168.100.10";
  localAddress = "192.168.100.11";
  bindMounts."/var/lib/immich" = {
    hostPath = "/srv/immich";
    isReadOnly = false;
  };
  config = { config, pkgs, ... }: {
    services.immich = {
      enable = true;
      host = "0.0.0.0";
      port = 2283;
    };
    networking.firewall.allowedTCPPorts = [ 2283 ];
    system.stateVersion = "24.11";
  };
};
```

| Aspect | Detail |
|--------|--------|
| Isolation | Network + PID + mount namespace |
| Complexity | Moderate — NixOS native |
| GPU access | Manual systemd override per service |
| Declarative | Fully declarative |
| Management | `nixos-container start/stop/root-login immich` |

**Pros:** True isolation, fully declarative, no extra daemons
**Cons:** GPU passthrough requires manual systemd overrides, limited tooling

### Option C: Incus/LXC (Recommended for Multi-Service)

```nix
virtualisation.incus = {
  enable = true;
  ui.enable = true;
  preseed = {
    networks = [{
      name = "incusbr0";
      type = "bridge";
      config = {
        "ipv4.address" = "10.0.100.1/24";
        "ipv4.nat" = "true";
      };
    }];
    storage_pools = [{
      name = "default";
      driver = "btrfs";
      config.source = "/var/lib/incus/storage-pools/default";
    }];
  };
};

networking.nftables.enable = true;
users.users.lars.extraGroups = [ "incus-admin" ];
```

| Aspect | Detail |
|--------|--------|
| Isolation | Full container or VM |
| Complexity | Higher — additional daemon |
| GPU access | Clean: `incus config device add immich gpu ...` |
| Declarative | Infrastructure yes, instances no (nixpkgs #386841) |
| Management | Web UI + `incus` CLI |

**Pros:** Best isolation, GPU passthrough, snapshots, Web UI, BTRFS native driver, can run VMs too
**Cons:** Requires nftables migration, instance creation is imperative, additional daemon to maintain

### Option D: MicroVM (Overkill)

Uses `microvm.nix` for VM-level isolation via QEMU/KVM.

**Pros:** Strongest isolation (hardware-enforced)
**Cons:** Significant overhead, complex networking, unnecessary for a media server

---

## 3. Decision Matrix

| Factor | Direct Service | nspawn | Incus | MicroVM |
|--------|---------------|--------|-------|---------|
| Setup effort | Minimal | Low | Medium | High |
| Isolation strength | Weak | Medium | Strong | Strongest |
| GPU passthrough | Hacky | Manual | Clean | Complex |
| BTRFS snapshots | Host-level | Host-level | Native driver | N/A |
| Network isolation | None | Private network | Bridge/NAT | Full |
| Resource limits | systemd | Partial | cgroups v2 | Full |
| Web management | No | No | Yes | No |
| Multi-service future | No | Yes | Yes | Yes |
| Fully declarative | Yes | Yes | Partial | Yes |

---

## 4. Recommendation

### If Immich is the only isolated service → **Option A** (Direct)

Simplest path. Add a module at `platforms/nixos/services/immich.nix`:

```nix
{ config, pkgs, lib, ... }:
{
  services.immich = {
    enable = true;
    port = 2283;
    host = "0.0.0.0";
    openFirewall = true;
    accelerationDevices = null;
  };

  users.users.immich.extraGroups = [ "video" "render" ];
}
```

### If more isolated services are planned → **Option C** (Incus)

One management plane for Immich, future Nextcloud, Jellyfin, etc. Invest in the Incus setup once, reuse for all services.

**Migration path:** Start with Option A, move to Incus later if needed. Immich data is portable (mediaLocation + pg_dump).

---

## 5. Considerations for This Setup

### DNS Blocker Interaction

The existing `dns-blocker.nix` module could block Immich's external connections:
- ML model downloads
- Map tile sources (reverse geocoding)
- OAuth providers (if configured)
- `api.immich.app` (version checks)

Whitelist these domains in the blocker config.

### Reverse Proxy / Remote Access

Mobile app requires a reachable HTTPS URL. Options:

| Approach | Complexity | Security |
|----------|-----------|----------|
| Tailscale Serve/Funnel | Low | High (no open ports) |
| Caddy + Let's Encrypt | Medium | High |
| Nginx + ACME | Medium | High |
| Self-signed cert | Low | Mobile apps may reject |

Tailscale is the cleanest fit for LAN-only evo-x2.

### Storage Layout (BTRFS)

Consider a dedicated subvolume for Immich data:
- `@immich` — media, thumbnails, transcoded video
- Keeps Timeshift snapshots from bloating with media data
- BTRFS compression (`zstd`) helps with thumbnails
- Single NVMe means DB and media share the same physical device

### Backup Strategy

Photos are irreplaceable. Recommended approach:

1. **DB consistency**: `pg_dump` before backup (Immich DB + media must be in sync)
2. **Local backup**: Borg/Restic to external drive or NAS
3. **Off-site backup**: Borg to remote storage (e.g., rsync.net, S3)
4. **BTRFS snapshots**: Not sufficient alone (not off-site)

Example systemd timer for DB dump:
```nix
systemd.services.immich-db-backup = {
  serviceConfig.Type = "oneshot";
  path = [ config.services.postgresql.package ];
  script = ''
    pg_dump --clean --if-exists --dbname=immich > /var/lib/immich/database-backup/immich.sql
  '';
};
```

### Existing Service Conflicts

- **Docker**: Already enabled. Incus and Docker can coexist but Incus's nftables requirement may conflict with Docker's iptables manipulation.
- **PostgreSQL**: Immich module auto-provisions its own PG instance. If other services need PG, verify port/version conflicts.
- **Redis**: Same concern as PostgreSQL.

### nftables Migration (Incus prerequisite)

Incus requires `networking.nftables.enable = true`. Current setup likely uses iptables (NixOS default). Verify:
- `dns-blocker.nix` firewall rules work with nftables
- Docker compatibility with nftables (may need `virtualisation.docker.extraOptions` adjustments)
- Any custom `networking.firewall.extraCommands` need rewriting

### Update Cadence

Immich releases frequently with occasional breaking DB migrations:
- Pin to specific version in config
- Test updates in Incus snapshot before applying
- Read release notes before major version bumps

---

## 6. Implementation Plan (If Proceeding)

### Phase 1: Direct Service (1-2 hours)

1. Create `platforms/nixos/services/immich.nix`
2. Import in NixOS configuration
3. Configure storage (BTRFS subvolume)
4. Test build with `just test`
5. Apply with `just switch`
6. Access at `http://evo-x2:2283`

### Phase 2: Remote Access (optional)

1. Configure Tailscale Serve for Immich
2. Test mobile app connectivity
3. Set up HTTPS

### Phase 3: Backup (essential)

1. Add `pg_dump` timer
2. Configure Borg/Restic job
3. Test restore procedure

### Phase 4: Incus Migration (optional, future)

1. Enable `virtualisation.incus`
2. Migrate nftables
3. Create Immich container/VM
4. Migrate data from direct service

---

## Sources

- NixOS Immich module: `nixpkgs/nixos/modules/services/web-apps/immich.nix`
- NixOS Incus module: `nixpkgs/nixos/modules/virtualisation/incus.nix`
- NixOS Wiki: https://wiki.nixos.org/wiki/Immich
- Immich docs: https://immich.app/docs/overview
- Incus docs: https://linuxcontainers.org/incus/
- Declarative Incus issue: https://github.com/NixOS/nixpkgs/issues/386841
