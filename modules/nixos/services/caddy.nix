{inputs, ...}: {
  flake.nixosModules.caddy = {
    config,
    pkgs,
    ...
  }: let
    domain = config.networking.domain;
    serverCert = config.sops.secrets.dnsblockd_server_cert.path;
    serverKey = config.sops.secrets.dnsblockd_server_key.path;
    authPort = 9091;

    tlsConfig = ''
      tls ${serverCert} ${serverKey}
    '';

    forwardAuth = ''
      forward_auth localhost:${toString authPort} {
        uri /api/authz/forward-auth
        copy_headers Remote-User Remote-Groups Remote-Email Remote-Name
      }
    '';

    protectedVHost = subdomain: port: {
      extraConfig = ''
        ${tlsConfig}
        ${forwardAuth}
        reverse_proxy localhost:${toString port}
      '';
    };
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
      };
    };

    networking.firewall.allowedTCPPorts = [80 443];
  };
}
