{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.dns-blocker;
  inherit (lib) mkEnableOption mkOption types;

  dnsblockdCert = pkgs.dnsblockd-cert;

  categoriesJSON = pkgs.writeText "dnsblockd-categories.json" (builtins.toJSON cfg.categories);

  # Fetch each blocklist file at eval time (fast - just metadata lookup)
  fetchedBlocklists =
    map (bl: {
      inherit (bl) name;
      file = pkgs.fetchurl {
        inherit (bl) url;
        inherit (bl) hash;
        name = "${bl.name}-raw";
      };
    })
    cfg.blocklists;

  # Whitelist file
  whitelistFile = pkgs.writeText "dns-blocker-whitelist.txt" (
    lib.concatStringsSep "\n" cfg.whitelist
  );

  # Build processor arguments: blocklist-file name pairs
  processorArgs = lib.concatStringsSep " " (
    lib.concatMap (bl: [
      (toString bl.file)
      bl.name
    ])
    fetchedBlocklists
  );

  # Run Go processor at build time instead of Nix eval-time string processing
  processedBlocklist =
    pkgs.runCommand "dns-blocker-processed" {
      nativeBuildInputs = [pkgs.dnsblockd-processor];
    } ''
      mkdir -p $out
      dnsblockd-processor \
        ${cfg.blockIP} \
        ${whitelistFile} \
        $out/unbound.conf \
        $out/mapping.json \
        ${processorArgs}
    '';

  # Unbound include file: temp-allowlist BEFORE blocklist so transparent zones win
  unboundIncludeFile = pkgs.writeText "dns-blocker-unbound.conf" ''
    include: /var/lib/dnsblockd/temp-allowlist.conf
    include: ${processedBlocklist}/unbound.conf
  '';
in {
  options.services.dns-blocker = {
    enable = mkEnableOption "DNS blocker with unbound + block page";

    blockInterface = mkOption {
      type = types.str;
      default = "lo";
      description = "Network interface for block IP address";
    };

    blockIPPrefix = mkOption {
      type = types.int;
      default = 8;
      description = "Network prefix length for block IP";
    };

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
      default = [];
      description = "Blocklists to fetch (hosts format)";
    };

    whitelist = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Domains to never block (whitelist)";
    };

    extraDomains = mkOption {
      type = types.listOf types.str;
      default = [];
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
      default = {};
      description = "Domain suffix -> category for block page";
    };
  };

  config = lib.mkIf cfg.enable {
    services.unbound = {
      enable = true;
      resolveLocalQueries = true;
      enableRootTrustAnchor = cfg.enableDNSSEC;

      settings = {
        server = {
          interface = ["0.0.0.0" "::0"];
          access-control = [
            "127.0.0.0/8 allow"
            "::1/128 allow"
            "192.168.1.0/24 allow"
          ];

          num-threads = 2;
          msg-cache-size = "64m";
          rrset-cache-size = "128m";
          prefetch = true;
          prefetch-key = true;

          qname-minimisation = true;
          hide-identity = true;
          hide-version = true;

          harden-glue = true;
          harden-dnssec-stripped = cfg.enableDNSSEC;
          harden-below-nxdomain = true;
          harden-referral-path = true;

          include = toString unboundIncludeFile;

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

    networking.localCommands = lib.mkIf (cfg.blockInterface == "lo") ''
      ${pkgs.iproute2}/bin/ip addr add ${cfg.blockIP}/${toString cfg.blockIPPrefix} dev lo 2>/dev/null || true
    '';

    security.pki.certificateFiles = ["${dnsblockdCert}/dnsblockd-ca.crt"];

    programs.firefox.policies = {
      DNSOverHTTPS = {
        Enabled = false;
        Locked = true;
      };
      Certificates = {
        Install = ["${dnsblockdCert}/dnsblockd-ca.crt"];
      };
      Preferences = {
        "browser.shell.checkDefaultBrowser" = {
          Value = false;
          Status = "locked";
        };
      };
    };

    systemd = {
      tmpfiles.rules = [
        "d /var/lib/dnsblockd 0755 root root -"
      ];

      services.dnsblockd = {
        description = "DNS Block Page Server";
        after = ["network-online.target"];
        wants = ["network-online.target"];
        wantedBy = ["multi-user.target"];

        serviceConfig =
          {
            Type = "simple";
            ExecStartPre = "+${pkgs.writeShellScript "dnsblockd-init" ''
              install -d /var/lib/dnsblockd
              [ -f /var/lib/dnsblockd/temp-allowlist.conf ] || printf '# dnsblockd temp allowlist\n' > /var/lib/dnsblockd/temp-allowlist.conf
            ''}";
            ExecStart =
              "${pkgs.dnsblockd}/bin/dnsblockd"
              + " -addr ${cfg.blockIP}"
              + " -port ${toString cfg.blockPort}"
              + " -tls-port ${toString cfg.blockTLSPort}"
              + " -ca-cert ${dnsblockdCert}/dnsblockd-ca.crt"
              + " -ca-key ${dnsblockdCert}/dnsblockd-ca.key"
              + " -stats-addr 127.0.0.1"
              + " -stats-port ${toString cfg.statsPort}"
              + " -blocklist-mapping ${processedBlocklist}/mapping.json"
              + " -unbound-control ${pkgs.unbound}/bin/unbound-control"
              + " -allowlist-conf /var/lib/dnsblockd/temp-allowlist.conf"
              + (
                if cfg.categories != {}
                then " -categories ${categoriesJSON}"
                else ""
              );
            StateDirectory = "dnsblockd";
            Restart = "on-failure";
            RestartSec = "3s";

            ProtectSystem = "strict";
            ProtectHome = true;
            PrivateTmp = true;
            RestrictAddressFamilies = ["AF_INET" "AF_INET6" "AF_NETLINK"];
            AmbientCapabilities = ["CAP_NET_BIND_SERVICE"];
            CapabilityBoundingSet = ["CAP_NET_BIND_SERVICE"];
          }
          // lib.optionalAttrs (cfg.blockInterface != "lo") {
            ExecStartPre = let
              addIPScript = pkgs.writeShellScript "dnsblockd-add-ip" ''
                ${pkgs.iproute2}/bin/ip addr add ${cfg.blockIP}/${toString cfg.blockIPPrefix} dev ${cfg.blockInterface} 2>/dev/null || true
              '';
            in "+-${addIPScript}";
            ExecStopPost = let
              delIPScript = pkgs.writeShellScript "dnsblockd-del-ip" ''
                ${pkgs.iproute2}/bin/ip addr del ${cfg.blockIP}/${toString cfg.blockIPPrefix} dev ${cfg.blockInterface} 2>/dev/null || true
              '';
            in "+-${delIPScript}";
          };
      };

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
          mkdir -p $HOME/.pki/nssdb
          certutil -d sql:$HOME/.pki/nssdb -N --empty-password 2>/dev/null || true
          certutil -d sql:$HOME/.pki/nssdb -D -n dnsblockd-ca 2>/dev/null || true
          certutil -d sql:$HOME/.pki/nssdb -A -t "C,," -n dnsblockd-ca -i ${dnsblockdCert}/dnsblockd-ca.crt
        '';
      };
    };
  };
}
