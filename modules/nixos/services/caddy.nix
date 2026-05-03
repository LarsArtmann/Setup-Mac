_: {
  flake.nixosModules.caddy = {
    config,
    lib,
    ...
  }: let
    inherit (config.networking) domain;
    serverCert = config.sops.secrets.dnsblockd_server_cert.path;
    serverKey = config.sops.secrets.dnsblockd_server_key.path;
    authPort = 9091;

    bindAddress =
      if config.services.dns-blocker.enable && config.services.dns-blocker.blockInterface != "lo"
      then let
        addrs = config.networking.interfaces.${config.services.dns-blocker.blockInterface}.ipv4.addresses;
      in
        if addrs != []
        then (builtins.head addrs).address
        else null
      else null;

    tlsConfig = ''
      tls ${serverCert} ${serverKey}
    '';

    forwardAuth = ''
      forward_auth localhost:${toString authPort} {
        uri /api/authz/forward-auth
        copy_headers Remote-User Remote-Groups Remote-Email Remote-Name
      }
    '';

    protectedVHost = _subdomain: port: {
      extraConfig = ''
        ${tlsConfig}
        @external not remote_ip 127.0.0.1/8 192.168.1.0/24
        handle @external {
          ${forwardAuth}
          reverse_proxy localhost:${toString port}
        }
        handle {
          reverse_proxy localhost:${toString port}
        }
      '';
    };
  in {
    config = lib.mkIf config.services.caddy.enable {
      services.caddy = {
        globalConfig = ''
          auto_https off
          ${lib.optionalString (bindAddress != null) "default_bind ${bindAddress}"}
          servers {
            metrics
          }
        '';

        virtualHosts = {
          "auth.${domain}" = {
            extraConfig = ''
              ${tlsConfig}
              reverse_proxy localhost:${toString authPort}
            '';
          };

          "immich.${domain}" = protectedVHost "immich" config.services.immich.port;
          "gitea.${domain}" = protectedVHost "gitea" 3000;
          "dash.${domain}" = protectedVHost "dash" 8082;
          "photomap.${domain}" = protectedVHost "photomap" 8050;
          "unsloth.${domain}" = protectedVHost "unsloth" 8888;
          "signoz.${domain}" = protectedVHost "signoz" 8080;
          "crm.${domain}" = protectedVHost "crm" 3200;
          "tasks.${domain}" = {
            extraConfig = ''
              ${tlsConfig}
              reverse_proxy localhost:10222
            '';
          };
          "comfyui.${domain}" = {
            extraConfig = ''
              ${tlsConfig}
              reverse_proxy localhost:8188
            '';
          };
        };
      };

      networking.firewall.allowedTCPPorts = [80 443];

      systemd.services.caddy = {
        after = ["authelia-main.service"];
        wants = ["authelia-main.service"];
        unitConfig = {
          StartLimitBurst = lib.mkForce 3;
          StartLimitIntervalSec = lib.mkForce 300;
        };
        serviceConfig = {
          Restart = lib.mkForce "always";
          RestartSec = lib.mkForce "5";
          OOMScoreAdjust = lib.mkForce (-500);
          PrivateTmp = lib.mkForce true;
          NoNewPrivileges = lib.mkForce false;
          ProtectClock = lib.mkForce true;
          ProtectHostname = lib.mkForce true;
          RestrictNamespaces = lib.mkForce true;
          LockPersonality = lib.mkForce true;
        };
      };
    };
  };
}
