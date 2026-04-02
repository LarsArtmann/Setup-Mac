{inputs, ...}: {
  flake.nixosModules.caddy = {
    config,
    pkgs,
    ...
  }: let
    serverCert = config.sops.secrets.dnsblockd_server_cert.path;
    serverKey = config.sops.secrets.dnsblockd_server_key.path;
  in {
    services.caddy = {
      enable = true;

      globalConfig = ''
        auto_https off
        servers {
          metrics
        }
      '';

      virtualHosts = {
        "immich.lan" = {
          extraConfig = ''
            tls ${serverCert} ${serverKey}
            reverse_proxy localhost:${toString config.services.immich.port}
          '';
        };

        "gitea.lan" = {
          extraConfig = ''
            tls ${serverCert} ${serverKey}
            reverse_proxy localhost:3000
          '';
        };

        "grafana.lan" = {
          extraConfig = ''
            tls ${serverCert} ${serverKey}
            reverse_proxy localhost:3001
          '';
        };

        "home.lan" = {
          extraConfig = ''
            tls ${serverCert} ${serverKey}
            reverse_proxy localhost:8082
          '';
        };

        "photomap.lan" = {
          extraConfig = ''
            tls ${serverCert} ${serverKey}
            reverse_proxy localhost:8050
          '';
        };

        "unsloth.lan" = {
          extraConfig = ''
            tls ${serverCert} ${serverKey}
            reverse_proxy localhost:8888
          '';
        };
      };
    };

    networking.firewall.allowedTCPPorts = [80 443];
  };
}
