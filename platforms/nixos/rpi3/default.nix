{
  config,
  pkgs,
  lib,
  ...
}: let
  blocklists = import ../../shared/dns-blocklists.nix;

  serverIP = "192.168.1.150";
  piIP = "192.168.1.151";
  virtualIP = "192.168.1.53";
  interface = "eth0";
  domain = "home.lan";

  fetchedBlocklists =
    map (bl: {
      inherit (bl) name;
      file = pkgs.fetchurl {
        inherit (bl) url;
        inherit (bl) hash;
        name = "${bl.name}-raw";
      };
    })
    blocklists.blocklists;

  whitelistFile = pkgs.writeText "dns-blocker-whitelist.txt" (
    lib.concatStringsSep "\n" blocklists.whitelist
  );

  processorArgs = lib.concatStringsSep " " (
    lib.concatMap (bl: [
      (toString bl.file)
      bl.name
    ])
    fetchedBlocklists
  );

  processedBlocklist =
    pkgs.runCommand "dns-blocker-processed" {
      nativeBuildInputs = [pkgs.dnsblockd-processor];
    } ''
      mkdir -p $out
      dnsblockd-processor \
        "0.0.0.0" \
        ${whitelistFile} \
        $out/unbound.conf \
        $out/mapping.json \
        ${processorArgs}
    '';

  unboundIncludeFile = pkgs.writeText "dns-blocker-unbound.conf" ''
    include: ${processedBlocklist}/unbound.conf
  '';
in {
  imports = [
    ../../common/core/nix-settings.nix
  ];

  system.stateVersion = "25.11";

  boot = {
    tmp.cleanOnBoot = true;
    initrd.availableKernelModules = ["usbhid" "usb_storage" "vc4"];
  };

  image.baseName = "nixos-rpi3-dns";
  sdImage.compressImage = false;

  networking = {
    hostName = "rpi3-dns";
    inherit domain;
    useDHCP = false;
    enableIPv6 = true;
    interfaces.eth0 = {
      useDHCP = false;
      ipv4.addresses = [
        {
          address = piIP;
          prefixLength = 24;
        }
      ];
    };
    defaultGateway = "192.168.1.1";
    nameservers = ["127.0.0.1" "9.9.9.9"];
    firewall = {
      enable = true;
      allowedTCPPorts = [22 53];
      allowedUDPPorts = [53];
    };
  };

  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "en_US.UTF-8";
  services = {
    resolved.enable = false;

    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "prohibit-password";
        PasswordAuthentication = false;
      };
    };

    unbound = {
      enable = true;
      resolveLocalQueries = true;
      enableRootTrustAnchor = true;

      settings = {
        server = {
          interface = ["0.0.0.0" "::0"];
          access-control = [
            "127.0.0.0/8 allow"
            "::1/128 allow"
            "192.168.1.0/24 allow"
          ];

          num-threads = 2;
          msg-cache-size = "32m";
          rrset-cache-size = "64m";
          prefetch = true;
          prefetch-key = true;

          qname-minimisation = true;
          hide-identity = true;
          hide-version = true;

          harden-glue = true;
          harden-dnssec-stripped = true;
          harden-below-nxdomain = true;
          harden-referral-path = true;

          include = toString unboundIncludeFile;

          local-zone =
            map (d: ''"${d}" transparent'') blocklists.whitelist
            ++ map (d: ''"${d}" always_nxdomain'') blocklists.extraDomains
            ++ [''"${domain}." static''];
          local-data =
            map
            (subdomain: ''"${subdomain}.${domain}. IN A ${serverIP}"'')
            ["auth" "immich" "gitea" "dash" "photomap" "unsloth" "signoz" "tasks" "crm"];
        };

        remote-control = {
          control-enable = true;
          control-interface = "/run/unbound/unbound.ctl";
        };

        forward-zone = [
          {
            name = ".";
            forward-addr = blocklists.upstreamDNS;
            forward-tls-upstream = true;
          }
        ];
      };
    };

    dns-failover = {
      enable = true;
      inherit virtualIP interface;
      priority = 50;
      routerID = 53;
      subnetPrefix = 24;
    };
  };

  users = {
    mutableUsers = false;
    users.root = {
      hashedPassword = "!";
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKm9qk4syNtsGJgWTMNRLdGyP3UtAfAKx7XnJxZxq7dF lars@evo-x2"
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    dig
    unbound
    pkgs.nur.repos.charmbracelet.crush
  ];

  systemd = {
    timers.crush-update-providers = {
      description = "Daily Crush AI provider update";
      timerConfig = {
        OnCalendar = "00:00";
        Persistent = true;
      };
      wantedBy = ["timers.target"];
    };
    services = {
      unbound.reloadIfChanged = true;
      crush-update-providers = {
        description = "Update Crush AI providers";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.nur.repos.charmbracelet.crush}/bin/crush update-providers";
          StandardOutput = "journal";
          StandardError = "journal";
        };
      };
    };
  };

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
    settings.auto-optimise-store = true;
  };
}
