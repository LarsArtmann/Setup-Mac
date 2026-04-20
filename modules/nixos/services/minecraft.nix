{...}: {
  flake.nixosModules.minecraft = {
    config,
    pkgs,
    lib,
    ...
  }: {
    options.services.minecraft = lib.mkEnableOption "Minecraft server";

    config = lib.mkIf config.services.minecraft {
      services.minecraft-server = {
        enable = true;
        eula = true;
        declarative = true;
        openFirewall = false;

        jvmOpts = "-Xms2G -Xmx4G -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200";

        serverProperties = {
          server-port = 25565;
          difficulty = "normal";
          gamemode = "survival";
          max-players = 20;
          motd = "§bHome §rMinecraft";
          white-list = true;
          enforce-whitelist = true;
          view-distance = 16;
          simulation-distance = 12;
          sync-chunk-writes = true;
          enable-status = true;
        };

        whitelist = {
          LartyHD = "8c9ec1ab-f64f-4003-9110-f98a1f0d7f47";
        };
      };

      networking.firewall.extraCommands = ''
        # Minecraft: only allow connections from local network
        iptables -A nixos-fw -p tcp --dport 25565 -s 192.168.1.0/24 -j nixos-fw-accept
        iptables -A nixos-fw -p tcp --dport 25565 -s 127.0.0.1 -j nixos-fw-accept
      '';
    };
  };
}
