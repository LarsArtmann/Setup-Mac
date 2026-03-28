{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.dns-blocker;
  inherit (lib) mkEnableOption mkOption types;

  # Self-signed cert for HTTPS block pages (added to system trust store)
  dnsblockdCert = pkgs.callPackage ../../../pkgs/dnsblockd-cert.nix {};

  # Categories JSON for dnsblockd
  categoriesJSON = pkgs.writeText "dnsblockd-categories.json" (builtins.toJSON cfg.categories);

  # Generate unbound local-data entries from a hosts file at build time
  # This is done at eval time from fetchurl results
  fetchBlocklist = {
    name,
    url,
    hash,
  }: let
    raw = pkgs.fetchurl {
      inherit url hash;
      name = "${name}-raw";
    };
    text = builtins.readFile raw;
    lines = lib.splitString "\n" text;
    parseLine = line: let
      trimmed = lib.trim line;
      isComment = trimmed == "" || lib.hasPrefix "#" trimmed;
      parts = lib.filter (p: p != "") (lib.splitString " " (lib.replaceStrings ["\t"] [" "] trimmed));
      domain =
        if builtins.length parts >= 2
        then lib.elemAt parts 1
        else null;
    in
      if isComment || domain == null
      then null
      else if domain == "localhost" || domain == "localhost.localdomain"
      then null
      else domain;
    domains = lib.filter (d: d != null) (map parseLine lines);
    entries = map (d: ''local-data: "${d} A ${cfg.blockIP}"'') domains;
  in {
    inherit name url domains;
    content = ''
      # Blocklist: ${name}
      # Source: ${url}
      # Domains: ${toString (builtins.length domains)}

      ${lib.concatStringsSep "\n" entries}
    '';
  };

  # Process all blocklists
  processedBlocklists = map fetchBlocklist cfg.blocklists;

  # Collect all domains from all blocklists + extra, then deduplicate
  allDomains = lib.unique (
    lib.concatMap (bl: bl.domains) processedBlocklists
    ++ cfg.extraDomains
  );

  # Filter out whitelisted domains
  blockedDomains = lib.filter (d: !builtins.elem d cfg.whitelist) allDomains;

  # Build domain -> source mapping for dnsblockd (deduplicated)
  blocklistDomainsMapping = builtins.listToAttrs (
    lib.concatMap (bl:
      map (d: {
        name = d;
        value = "${bl.name}";
      })
      bl.domains)
    processedBlocklists
    ++ map (d: {
      name = d;
      value = "Manual block";
    })
    cfg.extraDomains
  );

  blocklistMappingJSON = pkgs.writeText "dnsblockd-blocklist-mapping.json" (builtins.toJSON blocklistDomainsMapping);

  # Combined blocklist with deduplication
  combinedBlocklist = pkgs.writeText "dns-blocker-combined.conf" ''
    # Combined DNS Blocklist (deduplicated)
    # Blocklists: ${toString (builtins.length cfg.blocklists)}
    # Unique domains: ${toString (builtins.length blockedDomains)}

    ${lib.concatStringsSep "\n" (map (d: ''local-data: "${d} A ${cfg.blockIP}"'') blockedDomains)}
  '';

  # Unbound include file that pulls in blocklist
  # TODO: Add temp-allowlist include once tmpfiles issue is resolved
  unboundIncludeFile = pkgs.writeText "dns-blocker-unbound.conf" ''
    include: ${combinedBlocklist}
  '';
in {
  options.services.dns-blocker = {
    enable = mkEnableOption "DNS blocker with unbound + block page";

    blockIP = mkOption {
      type = types.str;
      default = "127.0.0.2";
      description = "IP address for blocked domains (dnsblockd listens here)";
    };

    blockPort = mkOption {
      type = types.port;
      default = 80;
      description = "Port for dnsblockd HTTP server";
    };

    blockTLSPort = mkOption {
      type = types.port;
      default = 443;
      description = "Port for dnsblockd HTTPS server (self-signed cert)";
    };

    statsPort = mkOption {
      type = types.port;
      default = 9090;
      description = "Port for dnsblockd stats API (localhost only)";
    };

    blocklists = mkOption {
      type = types.listOf (types.submodule {
        options = {
          name = mkOption {
            type = types.str;
            description = "Blocklist name";
          };
          url = mkOption {
            type = types.str;
            description = "URL to fetch hosts file";
          };
          hash = mkOption {
            type = types.str;
            description = "SHA256 hash of fetched file";
          };
        };
      });
      default = [
        {
          name = "StevenBlack-basic";
          url = "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts";
          hash = "sha256-47DeQd0L68Tv4f7eZf0W6hDkZCVsSjL2W5Y2Ty6bFJk=";
        }
      ];
      description = "Blocklists to fetch (hosts format)";
    };

    whitelist = mkOption {
      type = types.listOf types.str;
      default = [];
      example = ["ads.example.com"];
      description = "Domains to never block (whitelist)";
    };

    extraDomains = mkOption {
      type = types.listOf types.str;
      default = [];
      example = ["360.cn" "baidu.com"];
      description = "Additional domains to block (not in blocklists)";
    };

    upstreamDNS = mkOption {
      type = types.listOf types.str;
      default = [
        "9.9.9.9@853#dns.quad9.net"
        "1.1.1.1@853#cloudflare-dns.com"
      ];
      description = "Upstream DoT servers (IP@PORT#hostname)";
    };

    enableDNSSEC = mkOption {
      type = types.bool;
      default = true;
      description = "Enable DNSSEC validation";
    };

    categories = mkOption {
      type = types.attrsOf types.str;
      default = {
        ".doubleclick.net" = "Advertising";
        ".googlesyndication.com" = "Advertising";
        ".googleadservices.com" = "Advertising";
        ".adnxs.com" = "Advertising";
        ".adsrvr.org" = "Advertising";
        ".facebook.net" = "Tracking";
        ".analytics.google.com" = "Analytics";
        ".google-analytics.com" = "Analytics";
      };
      description = "Domain suffix -> category for block page";
    };
  };

  config = lib.mkIf cfg.enable {
    # Configure unbound
    services.unbound = {
      enable = true;
      resolveLocalQueries = true;
      enableRootTrustAnchor = cfg.enableDNSSEC;

      settings = {
        server = {
          interface = ["127.0.0.1" "::1"];
          access-control = ["127.0.0.0/8 allow" "::1/128 allow"];

          # Performance
          num-threads = 2;
          msg-cache-size = "64m";
          rrset-cache-size = "128m";
          prefetch = true;
          prefetch-key = true;

          # Privacy
          qname-minimisation = true;
          hide-identity = true;
          hide-version = true;

          # Hardening
          harden-glue = true;
          harden-dnssec-stripped = cfg.enableDNSSEC;
          harden-below-nxdomain = true;
          harden-referral-path = true;

          # Include blocklist (which also includes temp allowlist)
          include = toString unboundIncludeFile;

          # Whitelist: return real IP (forward these normally)
          local-zone = map (d: ''"${d}" transparent'') cfg.whitelist;
        };

        forward-zone = [
          {
            name = ".";
            forward-addr = cfg.upstreamDNS;
            forward-tls-upstream = true;
          }
        ];
      };
    };

    # Add blockIP to loopback at boot
    networking.localCommands = ''
      ${pkgs.iproute2}/bin/ip addr add ${cfg.blockIP}/8 dev lo 2>/dev/null || true
    '';

    # Add dnsblockd CA cert to system trust store (server cert is signed by this CA)
    security.pki.certificateFiles = ["${dnsblockdCert}/dnsblockd-ca.crt"];

    # Firefox policies: disable DoH, install dnsblockd cert, suppress default browser prompt
    programs.firefox.policies = {
      DNSOverHTTPS = {
        Enabled = false;
        Locked = true;
      };
      # Install dnsblockd CA cert into Firefox's own certificate store
      Certificates = {
        Install = ["${dnsblockdCert}/dnsblockd-ca.crt"];
      };
      # Disable "set as default browser" popup
      Preferences = {
        "browser.shell.checkDefaultBrowser" = {
          Value = false;
          Status = "locked";
        };
      };
    };

    systemd = {
      # Create state directory and empty temp-allowlist BEFORE unbound starts
      # Use 'w' (write) to overwrite any existing broken file from failed deploy
      tmpfiles.rules = [
        "d /var/lib/dnsblockd 0755 root root -"
        "w /var/lib/dnsblockd/temp-allowlist.json 0644 root root - []"
        "w /var/lib/dnsblockd/temp-allowlist.json.conf 0644 root root -"
      ];

      # dnsblockd service
      services.dnsblockd = {
        description = "DNS Block Page Server";
        after = ["network.target"];
        wantedBy = ["multi-user.target"];

        serviceConfig = {
          Type = "simple";
          ExecStart =
            "${pkgs.dnsblockd}/bin/dnsblockd"
            + " -addr ${cfg.blockIP}"
            + " -port ${toString cfg.blockPort}"
            + " -tls-port ${toString cfg.blockTLSPort}"
            + " -ca-cert ${dnsblockdCert}/dnsblockd-ca.crt"
            + " -ca-key ${dnsblockdCert}/dnsblockd-ca.key"
            + " -stats-addr 127.0.0.1"
            + " -stats-port ${toString cfg.statsPort}"
            + " -blocklist-mapping ${blocklistMappingJSON}"
            + " -temp-allowlist /var/lib/dnsblockd/temp-allowlist.json"
            + (
              if cfg.categories != {}
              then " -categories ${categoriesJSON}"
              else ""
            );
          StateDirectory = "dnsblockd";
          Restart = "on-failure";
          RestartSec = "3s";

          # Sandboxing
          ProtectSystem = "strict";
          ProtectHome = true;
          PrivateTmp = true;
          NoNewPrivileges = true;
          RestrictAddressFamilies = ["AF_INET" "AF_INET6"];
        };
      };

      # Import dnsblockd cert into NSS database for Chromium-based browsers (Helium, Chrome, etc.)
      # Chromium on Linux uses ~/.pki/nssdb, not the system trust store
      user.services.dnsblockd-cert-import = {
        description = "Import dnsblockd CA cert into NSS database";
        wantedBy = ["default.target"];
        after = ["nss-user-lookup.target"];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        path = [pkgs.nss];
        script = ''
          # Create NSS db if it doesn't exist
          mkdir -p $HOME/.pki/nssdb
          certutil -d sql:$HOME/.pki/nssdb -N --empty-password 2>/dev/null || true
          # Import the cert (remove old version first if exists)
          certutil -d sql:$HOME/.pki/nssdb -D -n dnsblockd-ca 2>/dev/null || true
          certutil -d sql:$HOME/.pki/nssdb -A -t "C,," -n dnsblockd-ca -i ${dnsblockdCert}/dnsblockd-ca.crt
        '';
      };
    };
  };
}
