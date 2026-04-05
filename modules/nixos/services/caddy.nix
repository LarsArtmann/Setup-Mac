{inputs, ...}: {
  flake.nixosModules.caddy = {
    config,
    pkgs,
    ...
  }: let
    serverCert = config.sops.secrets.dnsblockd_server_cert.path;
    serverKey = config.sops.secrets.dnsblockd_server_key.path;
    autheliaPort = 9091;

    tlsConfig = ''
      tls ${serverCert} ${serverKey}
    '';

    forwardAuth = ''
      forward_auth localhost:${toString autheliaPort} {
        uri /api/authz/forward-auth
        copy_headers Remote-User Remote-Groups Remote-Email Remote-Name
      }
    '';
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
        # "auth.lan" = {
        #   extraConfig = ''
        #     ${tlsConfig}
        #     reverse_proxy localhost:${toString autheliaPort}
        #   '';
        # };
        #
        # "immich.lan" = {
        #   extraConfig = ''
        #     ${tlsConfig}
        #     ${forwardAuth}
        #     reverse_proxy localhost:${toString config.services.immich.port}
        #   '';
        # };

        "gitea.lan" = {
          extraConfig = ''
            ${tlsConfig}
            ${forwardAuth}
            reverse_proxy localhost:3000
          '';
        };

        "home.lan" = {
          extraConfig = ''
            ${tlsConfig}
            ${forwardAuth}
            reverse_proxy localhost:8082
          '';
        };

        "photomap.lan" = {
          extraConfig = ''
            ${tlsConfig}
            ${forwardAuth}
            reverse_proxy localhost:8050
          '';
        };

        "unsloth.lan" = {
          extraConfig = ''
            ${tlsConfig}
            ${forwardAuth}
            reverse_proxy localhost:8888
          '';
        };

        "signoz.lan" = {
          extraConfig = ''
            ${tlsConfig}
            ${forwardAuth}
            reverse_proxy localhost:8080
          '';
        };
      };
    };

    networking.firewall.allowedTCPPorts = [80 443];
  };
}
