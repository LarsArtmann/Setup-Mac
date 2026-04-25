_: {
  flake.nixosModules.minecraft = {
    config,
    pkgs,
    lib,
    ...
  }: let
    mcVersion = "26.1.2";
    mcJarSha1 = "97ccd4c0ed3f81bbb7bfacddd1090b0c56f9bc51";
    mcJarUrl = "https://piston-data.mojang.com/v1/objects/${mcJarSha1}/server.jar";
    inherit (import ../../../lib/systemd.nix {inherit lib;}) mkHardenedServiceConfig mkServiceRestartConfig;

    minecraft-server-26 = pkgs.stdenv.mkDerivation {
      pname = "minecraft-server";
      version = mcVersion;

      src = pkgs.fetchurl {
        url = mcJarUrl;
        sha1 = mcJarSha1;
      };

      nativeBuildInputs = [pkgs.makeWrapper];

      installPhase = ''
        runHook preInstall

        install -Dm644 $src $out/lib/minecraft/server.jar

        makeWrapper ${lib.getExe pkgs.jdk25.headless} $out/bin/minecraft-server \
          --append-flags "-jar $out/lib/minecraft/server.jar nogui" \
          ${lib.optionalString pkgs.stdenv.hostPlatform.isLinux "--prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [pkgs.udev]}"}

        runHook postInstall
      '';

      dontUnpack = true;

      passthru.updateScript = [];

      meta = {
        description = "Minecraft Server";
        homepage = "https://minecraft.net";
        sourceProvenance = with lib.sourceTypes; [binaryBytecode];
        license = lib.licenses.unfreeRedistributable;
        platforms = lib.platforms.unix;
        mainProgram = "minecraft-server";
      };
    };
    cfg = config.services.minecraft;
  in {
    options.services.minecraft = {
      enable = lib.mkEnableOption "Minecraft server";

      port = lib.mkOption {
        type = lib.types.port;
        default = 25565;
        description = "Server port";
      };

      jvmOpts = lib.mkOption {
        type = lib.types.str;
        default = "-Xms2G -Xmx4G -XX:+UseCompactObjectHeaders -XX:+AlwaysPreTouch -XX:+UseStringDeduplication -XX:+UseZGC";
        description = "JVM arguments for the server";
      };

      difficulty = lib.mkOption {
        type = lib.types.enum ["peaceful" "easy" "normal" "hard"];
        default = "normal";
        description = "Game difficulty";
      };

      maxPlayers = lib.mkOption {
        type = lib.types.ints.positive;
        default = 20;
        description = "Maximum number of players";
      };

      motd = lib.mkOption {
        type = lib.types.str;
        default = "§bHome §rMinecraft";
        description = "Message of the day shown in the server list";
      };

      viewDistance = lib.mkOption {
        type = lib.types.ints.positive;
        default = 16;
        description = "View distance in chunks";
      };

      simulationDistance = lib.mkOption {
        type = lib.types.ints.positive;
        default = 12;
        description = "Simulation distance in chunks";
      };

      whitelist = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = {};
        description = "Whitelist entries (username → UUID)";
        example = {"Player" = "uuid-here";};
      };
    };

    config = lib.mkIf cfg.enable {
      services.minecraft-server = {
        enable = true;
        eula = true;
        declarative = true;
        openFirewall = false;

        package = minecraft-server-26;

        inherit (cfg) jvmOpts;

        serverProperties =
          {
            server-port = cfg.port;
            gamemode = "survival";
            max-players = cfg.maxPlayers;
            white-list = cfg.whitelist != {};
            enforce-whitelist = cfg.whitelist != {};
            view-distance = cfg.viewDistance;
            simulation-distance = cfg.simulationDistance;
            sync-chunk-writes = true;
            enable-status = true;
          }
          // lib.getAttrs ["difficulty" "motd"] cfg;

        inherit (cfg) whitelist;
      };

      systemd.services.minecraft-server.serviceConfig =
        mkHardenedServiceConfig {
          protectHome = false;
          protectSystem = false;
          memoryMax = "4G";
        }
        // mkServiceRestartConfig {watchdogSec = "60";};

      networking.firewall.extraCommands = ''
        iptables -A nixos-fw -p tcp --dport ${toString cfg.port} -s ${config.networking.local.subnet} -j nixos-fw-accept
        iptables -A nixos-fw -p tcp --dport ${toString cfg.port} -s 127.0.0.1 -j nixos-fw-accept
      '';
    };
  };
}
