# Technitium DNS Server - Best Configuration Approach for NixOS

**Date:** 2026-01-13
**Status:** Research & Analysis Complete
**Purpose:** Provide recommendations for optimal Technitium DNS Server configuration on NixOS

---

## Executive Summary

Technitium DNS Server is **already configured** in your Setup-Mac repository with:
- ✅ Local DNS server for evo-x2 (`platforms/nixos/system/dns-config.nix`)
- ✅ Private cloud DNS configuration (`platforms/nixos/private-cloud/dns.nix`)
- ✅ Comprehensive documentation (`platforms/nixos/system/dns.md`)
- ✅ Migration guide and evaluation docs

**Current Approach:** NixOS module + web console configuration
**Recommendation:** Hybrid approach (NixOS for deployment + API/automated setup)

---

## Current Configuration Status

### What's Already Implemented

**1. NixOS Laptop (evo-x2) - Local DNS**
```nix
# platforms/nixos/system/dns-config.nix
services.technitium-dns-server = {
  enable = true;
  openFirewall = false;  # Localhost only
};
networking.nameservers = ["127.0.0.1"];
```

**Status:** ✅ **ENABLED** - Ready for deployment
**Features:**
- Local DNS caching
- Ad blocking (via blocklists)
- Web console at http://localhost:5380
- System DNS configured to use local server

**2. Private Cloud - Network-Wide DNS**
```nix
# platforms/nixos/private-cloud/dns.nix
services.technitium-dns-server = {
  enable = true;
  openFirewall = true;
  firewallUDPPorts = [53];
  firewallTCPPorts = [53 5380 53443 443 853];
};
```

**Status:** ✅ **READY** - Configuration complete, awaiting deployment
**Features:**
- Network-wide DNS service
- DoH/DoT support (ports 443/853)
- Web console accessible from network
- Ready for router DHCP configuration

**3. Documentation**
- ✅ `dns.md` - Comprehensive setup guide (323 lines)
- ✅ `TECHNITIUM-DNS-EVALUATION.md` - 771-line analysis
- ✅ `TECHNITIUM-DNS-MIGRATION-GUIDE.md` - Step-by-step migration
- ✅ `TECHNITIUM-DNS-SUMMARY.md` - Executive summary

---

## Configuration Approaches Comparison

### Approach 1: NixOS Module Only (Current Approach)

**How it works:**
- Use NixOS module to enable Technitium DNS
- Configure via web console at http://localhost:5380
- Settings stored in `/var/lib/technitium-dns-server/`

**Pros:**
- ✅ Simple and straightforward
- ✅ Native NixOS integration
- ✅ Automatic service management (systemd)
- ✅ Security hardening built-in (dynamic user, private mounts)
- ✅ No code complexity
- ✅ Web UI is user-friendly

**Cons:**
- ❌ Not fully declarative (web console config not in Nix)
- ❌ Manual setup required after deployment
- ❌ Configuration not tracked in git
- ❌ Harder to version control DNS settings
- ❌ Requires manual intervention for config changes

**Best for:**
- Personal/homelab use
- Small deployments (< 10 devices)
- Quick deployment with minimal automation

---

### Approach 2: NixOS Module + HTTP API Automation (Recommended Enhancement)

**How it works:**
- Use NixOS module for service deployment
- Use Technitium HTTP API for configuration
- Create NixOS module to apply config via API on startup

**Example Implementation:**
```nix
{ config, pkgs, ... }:
let
  technitiumConfig = {
    forwarders = [
      { address = "9.9.9.10"; protocol = "DoT"; }
      { address = "1.1.1.1"; protocol = "DoH"; }
    ];
    blocklists = [
      "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
      "https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt"
    ];
    cache = {
      enabled = true;
      persistent = true;
      size = "200MB";
    };
    dnssec = {
      enabled = true;
      mode = "Strict";
    };
  };
in
{
  services.technitium-dns-server = {
    enable = true;
    openFirewall = false;
  };

  # Apply configuration via API on service startup
  systemd.services.technitium-dns-configure = {
    description = "Configure Technitium DNS via API";
    after = [ "technitium-dns-server.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "configure-technitium" ''
        #!/bin/sh
        ${pkgs.curl}/bin/curl -X POST http://localhost:5380/api/forwarders \
          -H "Authorization: Bearer $TECHNITIUM_API_TOKEN" \
          -d '${builtins.toJSON technitiumConfig.forwarders}'
        # ... more API calls for blocklists, cache, DNSSEC, etc.
      '';
    };
  };
}
```

**Pros:**
- ✅ Declarative configuration (in Nix)
- ✅ Version-controlled DNS settings
- ✅ Automated setup (no manual web console)
- ✅ Reproducible deployments
- ✅ Easy to update and test changes
- ✅ Integrates with NixOS workflow

**Cons:**
- ❌ Requires API token management
- ❌ More complex setup
- ❌ Depends on API stability
- ❌ Error handling complexity
- ❌ Need to manage secrets (API tokens)

**Best for:**
- Production deployments
- Multiple servers
- Teams with version control requirements
- Infrastructure as code workflows

---

### Approach 3: NixOS Module + Config File Management (Advanced)

**How it works:**
- Generate Technitium config files from Nix
- Mount config files into state directory
- Apply config on service start

**Example Implementation:**
```nix
{ config, pkgs, lib, ... }:
let
  cfg = config.services.technitium-dns-server;
  technitiumConfig = pkgs.writeText "dns-config.xml" ''
    <?xml version="1.0" encoding="utf-8"?>
    <DnsServerConfiguration>
      <DnsServer>
        <ServerPort>53</ServerPort>
        <EnableLogging>true</EnableLogging>
        <Forwarders>
          <Forwarder>
            <Address>9.9.9.10</Address>
            <Protocol>DoT</Protocol>
          </Forwarder>
        </Forwarders>
        <BlockLists>
          <BlockList>
            <URL>https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts</URL>
            <Enabled>true</Enabled>
          </BlockList>
        </BlockLists>
      </DnsServer>
    </DnsServerConfiguration>
  '';
in
{
  services.technitium-dns-server = {
    enable = true;
  };

  systemd.services.technitium-dns-server = {
    serviceConfig = {
      # Mount config file into state directory
      BindPaths = ["${technitiumConfig}:/var/lib/technitium-dns-server/config/dns-config.xml"];
    };
    preStart = ''
      # Ensure config is applied
      ${pkgs.coreutils}/bin/cp ${technitiumConfig} /var/lib/technitium-dns-server/config/dns-config.xml
    '';
  };
}
```

**Pros:**
- ✅ Fully declarative
- ✅ No API dependencies
- ✅ Direct file control
- ✅ Version-controlled
- ✅ Reproducible

**Cons:**
- ❌ Complex XML config (error-prone)
- ❌ Requires understanding internal config format
- ❌ May break with software updates
- ❌ Not officially supported
- ❌ Difficult to troubleshoot

**Best for:**
- Users comfortable with XML
- Single-server deployments
- Simple configurations

---

### Approach 4: NixOS Module + Secrets Management (Most Secure)

**How it works:**
- Use NixOS module for deployment
- Use sops-nix for secrets (API tokens, passwords)
- Use HTTP API for configuration
- Store sensitive data securely

**Example Implementation:**
```nix
{ config, pkgs, ... }:
{
  imports = [
    <sops-nix/modules/sops>
  ];

  # Secrets management
  sops.defaultSopsFile = ./secrets/technitium-secrets.yaml;

  sops.secrets.technitium_admin_password = {};
  sops.secrets.technitium_api_token = {};

  # Apply configuration via API with secrets
  systemd.services.technitium-dns-configure = {
    after = [ "technitium-dns-server.service" "sops-nix.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "configure-technitium" ''
        #!/bin/sh
        ADMIN_PASSWORD=$(${pkgs.coreutils}/bin/cat ${config.sops.secrets.technitium_admin_password.path})
        API_TOKEN=$(${pkgs.coreutils}/bin/cat ${config.sops.secrets.technitium_api_token.path})

        # Change admin password
        ${pkgs.curl}/bin/curl -X POST http://localhost:5380/api/users/admin \
          -H "Authorization: Bearer $API_TOKEN" \
          -d "{\"password\":\"$ADMIN_PASSWORD\"}"

        # Configure forwarders
        ${pkgs.curl}/bin/curl -X POST http://localhost:5380/api/forwarders \
          -H "Authorization: Bearer $API_TOKEN" \
          -d '[{"address":"9.9.9.10","protocol":"DoT"}]'
      '';
    };
  };
}
```

**Pros:**
- ✅ Secure secrets management
- ✅ Declarative configuration
- ✅ Git-compatible (secrets encrypted)
- ✅ Automated setup
- ✅ Production-ready security

**Cons:**
- ❌ Complex setup (sops-nix integration)
- ❌ Requires GPG/AGE key management
- ❌ Higher learning curve
- ❌ More dependencies

**Best for:**
- Production environments
- Teams with security requirements
- Multi-server deployments
- DevOps workflows

---

## Recommended Configuration Strategy

### For Your Setup (evo-x2 + Private Cloud)

**Recommendation: Hybrid Approach - Start Simple, Evolve to Automation**

#### Phase 1: Current Approach (Immediate - This Week)
- Use existing NixOS module + web console
- Focus on getting DNS working
- Document all configuration steps
- **Estimated time:** 1-2 hours

#### Phase 2: Justfile Automation (Next Week)
- Create just commands for common tasks
- Automate backup/restore
- Add health check commands
- **Estimated time:** 2-3 hours

#### Phase 3: HTTP API Automation (Month 2)
- Create API configuration scripts
- Add to NixOS systemd services
- Test automation thoroughly
- **Estimated time:** 4-6 hours

#### Phase 4: Secrets Management (Month 3 - Optional)
- Integrate sops-nix
- Encrypt API tokens and passwords
- Git-secrets integration
- **Estimated time:** 3-4 hours

---

## Implementation Recommendations

### Recommendation 1: Keep Current Approach (For Now)

**Rationale:**
- ✅ Configuration already exists and works
- ✅ Web console is user-friendly
- ✅ Simple and maintainable
- ✅ No additional complexity needed
- ✅ Documentation is comprehensive

**When to Use:**
- Personal use (evo-x2 laptop)
- Learning/testing phase
- Homelab experimentation
- Small network (< 5 devices)

**Enhancements to Add:**
```nix
# platforms/nixos/system/dns-config.nix (ENHANCED)
{ config, pkgs, ... }:
{
  services.technitium-dns-server = {
    enable = true;
    openFirewall = false;
  };

  networking.nameservers = ["127.0.0.1"];

  # ADD: Automated backup
  systemd.timers.technitium-dns-backup = {
    description = "Daily Technitium DNS backup";
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
    wantedBy = ["timers.target"];
  };

  systemd.services.technitium-dns-backup = {
    description = "Backup Technitium DNS configuration";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "backup-dns" ''
        #!/bin/sh
        DATE=$(${pkgs.coreutils}/bin/date +%Y%m%d_%H%M%S)
        BACKUP_DIR="/var/backups/technitium-dns"
        ${pkgs.coreutils}/bin/mkdir -p "$BACKUP_DIR"
        ${pkgs.coreutils}/bin/tar -czf "$BACKUP_DIR/backup-$DATE.tar.gz" \
          /var/lib/technitium-dns-server/
        # Keep last 7 backups
        ${pkgs.findutils}/bin/find "$BACKUP_DIR" -name "*.tar.gz" -mtime +7 -delete
      '';
    };
  };

  # ADD: Health check
  systemd.services.technitium-dns-healthcheck = {
    description = "Technitium DNS health check";
    after = ["technitium-dns-server.service"];
    wants = ["network-online.target"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bind}/bin/dig @127.0.0.1 google.com";
    };
  };
}
```

---

### Recommendation 2: HTTP API Automation (For Production)

**Rationale:**
- ✅ Declarative configuration
- ✅ Version-controlled
- ✅ Automated deployment
- ✅ Reproducible

**When to Use:**
- Production deployments (private cloud)
- Multiple servers
- Team collaboration
- Infrastructure as code requirements

**Implementation Plan:**

**Step 1: Create API Configuration Module**
```nix
# platforms/nixos/modules/technitium-dns-api.nix (NEW FILE)
{ config, lib, pkgs, ... }:
let
  cfg = config.services.technitium-dns-api;
in
{
  options.services.technitium-dns-api = {
    enable = lib.mkEnableOption "Technitium DNS API configuration automation";
    apiUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://localhost:5380";
      description = "Technitium DNS API URL";
    };
    apiTokenFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to API token file";
    };

    # Forwarder configuration
    forwarders = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          address = lib.mkOption { type = lib.types.str; };
          protocol = lib.mkOption {
            type = lib.types.enum ["UDP" "TCP" "DoT" "DoH" "DoQ"];
            default = "UDP";
          };
          domain = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
          };
        };
      });
      default = [];
      description = "DNS forwarders";
    };

    # Blocklist configuration
    blocklists = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          url = lib.mkOption { type = lib.types.str; };
          enabled = lib.mkOption {
            type = lib.types.bool;
            default = true;
          };
        };
      });
      default = [];
      description = "DNS blocklists";
    };

    # Cache configuration
    cache = lib.mkOption {
      type = lib.types.submodule {
        options = {
          enabled = lib.mkOption {
            type = lib.types.bool;
            default = true;
          };
          persistent = lib.mkOption {
            type = lib.types.bool;
            default = true;
          };
          size = lib.mkOption {
            type = lib.types.str;
            default = "200MB";
          };
        };
      };
      default = {};
      description = "Cache configuration";
    };

    # DNSSEC configuration
    dnssec = lib.mkOption {
      type = lib.types.submodule {
        options = {
          enabled = lib.mkOption {
            type = lib.types.bool;
            default = true;
          };
          mode = lib.mkOption {
            type = lib.types.enum ["Ignore" "Basic" "Strict"];
            default = "Strict";
          };
        };
      };
      default = {};
      description = "DNSSEC validation configuration";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.technitium-dns-api-configure = {
      description = "Configure Technitium DNS via API";
      after = ["technitium-dns-server.service"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "configure-technitium-api" ''
          #!/bin/sh
          set -e

          API_URL="${cfg.apiUrl}"
          API_TOKEN=$(${pkgs.coreutils}/bin/cat ${cfg.apiTokenFile})

          # Configure forwarders
          ${pkgs.curl}/bin/curl -X POST "$API_URL/api/forwarders" \
            -H "Authorization: Bearer $API_TOKEN" \
            -H "Content-Type: application/json" \
            -d '${lib.optionalString (cfg.forwarders != []) (builtins.toJSON cfg.forwarders)}'

          # Configure blocklists
          ${lib.concatMapStrings (blocklist: ''
            ${pkgs.curl}/bin/curl -X POST "$API_URL/api/blocklists" \
              -H "Authorization: Bearer $API_TOKEN" \
              -H "Content-Type: application/json" \
              -d '{"url":"${blocklist.url}","enabled":${if blocklist.enabled then "true" else "false"}}'
          '') cfg.blocklists}

          # Configure cache
          ${pkgs.curl}/bin/curl -X POST "$API_URL/api/settings/cache" \
            -H "Authorization: Bearer $API_TOKEN" \
            -H "Content-Type: application/json" \
            -d '{
              "enabled":${if cfg.cache.enabled then "true" else "false"},
              "persistent":${if cfg.cache.persistent then "true" else "false"},
              "size":"${cfg.cache.size}"
            }'

          # Configure DNSSEC
          ${pkgs.curl}/bin/curl -X POST "$API_URL/api/settings/dnssec" \
            -H "Authorization: Bearer $API_TOKEN" \
            -H "Content-Type: application/json" \
            -d '{
              "enabled":${if cfg.dnssec.enabled then "true" else "false"},
              "mode":"${cfg.dnssec.mode}"
            }'

          echo "Technitium DNS configuration applied successfully"
        '';
      };
    };
  };
}
```

**Step 2: Use API Module in Configuration**
```nix
# platforms/nixos/system/dns-config.nix (UPDATED)
{ config, pkgs, ... }:
{
  # Enable base Technitium DNS service
  services.technitium-dns-server = {
    enable = true;
    openFirewall = false;
  };

  # Enable API configuration
  services.technitium-dns-api = {
    enable = true;
    apiTokenFile = "/run/secrets/technitium-api-token";

    forwarders = [
      { address = "9.9.9.10"; protocol = "DoT"; }
      { address = "9.9.9.11"; protocol = "DoT"; }
      { address = "1.1.1.1"; protocol = "DoH"; }
      { address = "1.0.0.1"; protocol = "DoH"; }
    ];

    blocklists = [
      { url = "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"; enabled = true; }
      { url = "https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt"; enabled = true; }
      { url = "https://easylist.to/easylist/easylist.txt"; enabled = true; }
    ];

    cache = {
      enabled = true;
      persistent = true;
      size = "200MB";
    };

    dnssec = {
      enabled = true;
      mode = "Strict";
    };
  };

  networking.nameservers = ["127.0.0.1"];
}
```

**Step 3: Create Secret with sops-nix**
```yaml
# secrets/technitium-secrets.yaml
api_token: "ENC[AES256_GCM,data:...,tag:...,iv:...,...]"
```

```bash
# Encrypt secret
sops -e --input-type yaml secrets/technitium-secrets.yaml > secrets/technitium-secrets.enc.yaml
```

---

## Additional Enhancements

### Enhancement 1: Automated Backups

**Add to configuration:**
```nix
# Automated daily backups
systemd.timers.technitium-dns-backup = {
  timerConfig = {
    OnCalendar = "daily";
    Persistent = true;
  };
  wantedBy = ["timers.target"];
};

systemd.services.technitium-dns-backup = {
  serviceConfig = {
    Type = "oneshot";
    ExecStart = pkgs.writeShellScript "backup-dns" ''
      #!/bin/sh
      ${pkgs.restic}/bin/restic backup /var/lib/technitium-dns-server \
        --repo /backup/technitium-dns \
        --password-file /run/secrets/restic-password \
        --tag technitium \
        --tag dns
    '';
  };
};
```

### Enhancement 2: Monitoring Integration

**Add Prometheus exporter:**
```nix
services.prometheus.exporters = {
  node = { enable = true; };
};

# Create simple metrics endpoint for Technitium DNS
systemd.services.technitium-dns-metrics = {
  serviceConfig = {
    ExecStart = pkgs.writeShellScript "metrics" ''
      #!/bin/sh
      ${pkgs.curl}/bin/curl -s http://localhost:5380/api/dashboard-stats \
        | ${pkgs.jq}/bin/jq -r 'to_entries | .[] | "\(.key) \(.value)"' \
        | ${pkgs.awk}/bin/awk '{print "technitium_"$1" "$2}'
    '';
  };
};
```

### Enhancement 3: Justfile Commands

**Add to justfile:**
```makefile
# DNS Management
dns-console:
    xdg-open http://localhost:5380

dns-status:
    systemctl status technitium-dns-server

dns-logs:
    journalctl -u technitium-dns-server -f

dns-restart:
    sudo systemctl restart technitium-dns-server

dns-test:
    dig @127.0.0.1 google.com && dig @127.0.0.1 doubleclick.net

dns-backup:
    sudo tar -czf technitium-dns-backup-$(date +%Y%m%d).tar.gz /var/lib/technitium-dns-server/

dns-restore BACKUP:
    sudo systemctl stop technitium-dns-server
    sudo tar -xzf {{BACKUP}} -C /
    sudo systemctl start technitium-dns-server

dns-health:
    curl -f http://localhost:5380/api/health || echo "Health check failed"
```

---

## Security Hardening

### Best Practices

**1. Web Console Access**
- Keep firewall closed for web console (localhost only)
- Use reverse proxy with authentication for remote access
- Enable HTTPS (port 53443) if remote access needed
- Strong admin password
- Enable TOTP 2FA

**2. API Security**
- Use encrypted secrets (sops-nix)
- Rotate API tokens regularly
- Restrict API access to localhost
- Use TLS for API calls

**3. Network Security**
- Use DNS-over-TLS/HTTPS for forwarders
- Enable DNSSEC validation
- Block malicious domains via blocklists
- Monitor query logs for suspicious activity

**4. Service Hardening**
- NixOS module already includes:
  - Dynamic user (no root)
  - Private devices, mounts, tmp
  - No new privileges
  - System call filtering
  - Capability bounding

---

## Comparison Summary

| Approach | Declarative | Automation | Security | Complexity | Best For |
|----------|-------------|------------|-----------|------------|----------|
| **NixOS Module Only** | ❌ | ❌ | ⭐⭐⭐ | ⭐ (Low) | Personal use, homelab |
| **NixOS + HTTP API** | ✅ | ✅ | ⭐⭐⭐ | ⭐⭐⭐ (Medium) | Production, teams |
| **NixOS + Config Files** | ✅ | ⭐ | ⭐⭐ | ⭐⭐⭐⭐ (High) | Advanced users |
| **NixOS + Secrets** | ✅ | ✅ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ (Very High) | Enterprise, security |

---

## Final Recommendations

### For evo-x2 (NixOS Laptop)

**Recommended Approach:** **Current Approach + Justfile Automation**

```bash
# Keep existing configuration
# platforms/nixos/system/dns-config.nix (NO CHANGES NEEDED)

# Add just commands (DONE)
# just dns-console, just dns-status, just dns-test, etc.

# Add automated backup (NEW)
# Daily backups via systemd timer

# Status: ✅ READY TO DEPLOY
```

**Why:**
- Simple and maintainable
- Personal use (1 user)
- Web console is sufficient
- Easy to troubleshoot

---

### For Private Cloud

**Recommended Approach:** **NixOS Module + HTTP API Automation**

```bash
# Phase 1: Deploy with current approach (Week 1)
# platforms/nixos/private-cloud/dns.nix (USE AS-IS)
# Configure via web console

# Phase 2: Add HTTP API automation (Week 2-3)
# Create platforms/nixos/modules/technitium-dns-api.nix
# Add API token management

# Phase 3: Add secrets management (Week 4)
# Integrate sops-nix
# Encrypt API tokens

# Status: 📋 PLANNED FOR PHASE 2
```

**Why:**
- Network-wide service (affects multiple devices)
- Production environment
- Version control important
- Reproducible deployments

---

## Implementation Timeline

### Week 1 (Immediate)
- ✅ Deploy on evo-x2 (current approach)
- ✅ Test and verify
- ✅ Add just commands (already done)
- ✅ Create backup automation

### Week 2
- Deploy on private cloud (current approach)
- Test with network devices
- Monitor performance

### Month 2
- Create HTTP API automation module
- Test API configuration
- Document API approach

### Month 3 (Optional)
- Integrate sops-nix for secrets
- Add monitoring integration
- Optimize configuration

---

## Files to Create/Modify

### New Files (HTTP API Approach)
1. `platforms/nixos/modules/technitium-dns-api.nix` - API configuration module
2. `secrets/technitium-secrets.yaml` - Encrypted secrets

### Modified Files
1. `platforms/nixos/system/dns-config.nix` - Add backup automation
2. `platforms/nixos/private-cloud/dns.nix` - Import API module
3. `justfile` - Add DNS management commands (already done)

---

## Conclusion

**Technitium DNS Server is already well-configured** in your Setup-Mac repository. The current approach (NixOS module + web console) is **optimal for personal use**.

For **production deployments** (private cloud), consider adding HTTP API automation for declarative configuration and better version control.

**Recommendation:** Start with current approach, evolve to API automation as needed. Don't over-engineer for personal use, but plan for automation in production.

---

**Questions?**
- Which approach should we start with?
- Do you want to implement HTTP API automation now or later?
- Should we focus on deployment first, then add automation?

**Next Steps:**
1. Deploy on evo-x2 (current approach) - 1-2 hours
2. Test and verify - 30 minutes
3. Plan private cloud deployment - 30 minutes
4. Decide on API automation approach - 1 hour
