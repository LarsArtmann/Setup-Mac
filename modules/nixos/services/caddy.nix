{inputs, ...}: {
  flake.nixosModules.caddy = {
    config,
    pkgs,
    ...
  }: {
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
            reverse_proxy localhost:${toString config.services.immich.port}
          '';
        };

        "gitea.lan" = {
          extraConfig = ''
            reverse_proxy localhost:3000
          '';
        };

        "grafana.lan" = {
          extraConfig = ''
            reverse_proxy localhost:3001
          '';
        };

        "home.lan" = {
          extraConfig = ''
            reverse_proxy localhost:8082
          '';
        };
      };
    };

    networking.firewall.allowedTCPPorts = [80 443];
  };
}
