{inputs, ...}: {
  flake.nixosModules.caddy = {
    config,
    pkgs,
    ...
  }: let
    dnsblockdCert = pkgs.dnsblockd-cert;
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
            tls ${dnsblockdCert}/dnsblockd-server.crt ${dnsblockdCert}/dnsblockd-server.key
            reverse_proxy localhost:${toString config.services.immich.port}
          '';
        };

        "gitea.lan" = {
          extraConfig = ''
            tls ${dnsblockdCert}/dnsblockd-server.crt ${dnsblockdCert}/dnsblockd-server.key
            reverse_proxy localhost:3000
          '';
        };

        "grafana.lan" = {
          extraConfig = ''
            tls ${dnsblockdCert}/dnsblockd-server.crt ${dnsblockdCert}/dnsblockd-server.key
            reverse_proxy localhost:3001
          '';
        };

        "home.lan" = {
          extraConfig = ''
            tls ${dnsblockdCert}/dnsblockd-server.crt ${dnsblockdCert}/dnsblockd-server.key
            reverse_proxy localhost:8082
          '';
        };

        "photomap.lan" = {
          extraConfig = ''
            tls ${dnsblockdCert}/dnsblockd-server.crt ${dnsblockdCert}/dnsblockd-server.key
            reverse_proxy localhost:8050
          '';
        };
      };
    };

    networking.firewall.allowedTCPPorts = [80 443];
  };
}
