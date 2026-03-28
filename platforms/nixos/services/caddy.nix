{
  config,
  pkgs,
  ...
}: {
  services.caddy = {
    enable = true;

    virtualHosts."immich.lan" = {
      extraConfig = ''
        reverse_proxy localhost:${toString config.services.immich.port}
      '';
    };
  };

  networking.firewall.allowedTCPPorts = [80 443];
}
