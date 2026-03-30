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
        servers {
          metrics
        }
      '';

      virtualHosts = {
        "immich.lan" = {
          extraConfig = ''
            bind 192.168.1.162
            tls ${dnsblockdCert}/dnsblockd-server.crt ${dnsblockdCert}/dnsblockd-server.key
            reverse_proxy localhost:${toString config.services.immich.port}
          '';
        };

        "gitea.lan" = {
          extraConfig = ''
            bind 192.168.1.162
            tls ${dnsblockdCert}/dnsblockd-server.crt ${dnsblockdCert}/dnsblockd-server.key
            reverse_proxy localhost:3000
          '';
        };

        "grafana.lan" = {
          extraConfig = ''
            bind 192.168.1.162
            tls ${dnsblockdCert}/dnsblockd-server.crt ${dnsblockdCert}/dnsblockd-server.key
            reverse_proxy localhost:3001
          '';
        };

        "home.lan" = {
          extraConfig = ''
            bind 192.168.1.162
            tls ${dnsblockdCert}/dnsblockd-server.crt ${dnsblockdCert}/dnsblockd-server.key
            reverse_proxy localhost:8082
          '';
        };
      };
    };

    networking.firewall.allowedTCPPorts = [80 443];
  };
}
