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
  fetchBlocklist = { name, url, hash }:
    let
      raw = pkgs.fetchurl { inherit url hash; name = "${name}-raw"; };
      text = builtins.readFile raw;
      lines = lib.splitString "\n" text;
      parseLine = line:
        let
          trimmed = lib.trim line;
          isComment = trimmed == "" || lib.hasPrefix "#" trimmed;
          parts = lib.filter (p: p != "") (lib.splitString " " (lib.replaceStrings ["\t"] [" "] trimmed));
          domain = if builtins.length parts >= 2 then lib.elemAt parts 1 else null;
        in
          if isComment || domain == null then null
          else if domain == "localhost" || domain == "localhost.localdomain" then null
          else domain;
      domains = lib.filter (d: d != null) (map parseLine lines);
      entries = map (d: ''local-data: "${d} A ${cfg.blockIP}"'') domains;
    in {
      inherit name url;
      content = ''
        # Blocklist: ${name}
        # Source: ${url}
        # Domains: ${toString (builtins.length domains)}

        ${lib.concatStringsSep "\n" entries}
      '';
    };

  # Combine all blocklists + extra domains
  extraDomainsEntries = map (d: ''local-data: "${d} A ${cfg.blockIP}"'') cfg.extraDomains;
  combinedBlocklist = pkgs.writeText "dns-blocker-combined.conf" ''
    # Combined DNS Blocklist
    # Blocklists: ${toString (builtins.length cfg.blocklists)}
    # Extra domains: ${toString (builtins.length cfg.extraDomains)}

    ${lib.concatStringsSep "\n\n" (map (bl: bl.content) (map fetchBlocklist cfg.blocklists))}

    # Extra manually blocked domains
    ${lib.concatStringsSep "\n" extraDomainsEntries}
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
          name = mkOption { type = types.str; description = "Blocklist name"; };
          url = mkOption { type = types.str; description = "URL to fetch hosts file"; };
          hash = mkOption { type = types.str; description = "SHA256 hash of fetched file"; };
        };
      });
      default = [
        {
          name = "StevenBlack-basic";
          url = "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts";
          # Update this hash after first build fails with the correct one
          hash = "sha256-47DeQd0L68Tv4f7eZf0W6hDkZCVsSjL2W5Y2Ty6bFJk=";
        }
      ];
      description = "Blocklists to fetch (hosts format)";
    };

    whitelist = mkOption {
      type = types.listOf types.str;
      default = [];
      example = [ "ads.example.com" ];
      description = "Domains to never block (whitelist)";
    };

    extraDomains = mkOption {
      type = types.listOf types.str;
      default = [];
      example = [ "360.cn" "baidu.com" ];
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
    # Disable conflicting resolvers
    services.resolved.enable = lib.mkForce false;
    networking.resolvconf.enable = lib.mkForce false;

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

          # Include blocklist
          include = toString combinedBlocklist;

          # Whitelist: return real IP (forward these normally)
          local-zone = map (d: ''"${d}" transparent'') cfg.whitelist;
        };

        forward-zone = [{
          name = ".";
          forward-addr = cfg.upstreamDNS;
          forward-tls-upstream = true;
        }];
      };
    };

    # Add blockIP to loopback at boot
    networking.localCommands = ''
      ${pkgs.iproute2}/bin/ip addr add ${cfg.blockIP}/8 dev lo 2>/dev/null || true
    '';

    # Add dnsblockd cert to system trust store
    security.pki.certificateFiles = [ "${dnsblockdCert}/dnsblockd.crt" ];

    # dnsblockd service
    systemd.services.dnsblockd = {
      description = "DNS Block Page Server";
      after = ["network.target"];
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.dnsblockd}/bin/dnsblockd"
          + " -addr ${cfg.blockIP}"
          + " -port ${toString cfg.blockPort}"
          + " -tls-port ${toString cfg.blockTLSPort}"
          + " -cert ${dnsblockdCert}/dnsblockd.crt"
          + " -key ${dnsblockdCert}/dnsblockd.key"
          + " -stats-addr 127.0.0.1"
          + " -stats-port ${toString cfg.statsPort}"
          + (if cfg.categories != {} then " -categories ${categoriesJSON}" else "");
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

    # System uses unbound
    networking.nameservers = ["127.0.0.1"];

    # Disable Firefox DNS-over-HTTPS so it uses local DNS blocker
    programs.firefox.policies = {
      DNSOverHTTPS = {
        Enabled = false;
        Locked = true;
      };
      # Disable "set as default browser" popup
      Preferences = {
        "browser.shell.checkDefaultBrowser" = {
          Value = false;
          Status = "locked";
        };
      };
    };
  };
}
