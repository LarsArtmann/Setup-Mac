{...}: {
  flake.nixosModules.minecraft = {
    config,
    pkgs,
    lib,
    ...
  }: let
    mcVersion = "26.1.2";
    mcJarSha1 = "97ccd4c0ed3f81bbb7bfacddd1090b0c56f9bc51";
    mcJarUrl = "https://piston-data.mojang.com/v1/objects/${mcJarSha1}/server.jar";

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
  in {
    options.services.minecraft = lib.mkEnableOption "Minecraft server";

    config = lib.mkIf config.services.minecraft {
      services.minecraft-server = {
        enable = true;
        eula = true;
        declarative = true;
        openFirewall = false;

        package = minecraft-server-26;

        jvmOpts = "-Xms2G -Xmx4G -XX:+UseCompactObjectHeaders -XX:+AlwaysPreTouch -XX:+UseStringDeduplication -XX:+UseZGC";

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
        iptables -A nixos-fw -p tcp --dport 25565 -s 192.168.1.0/24 -j nixos-fw-accept
        iptables -A nixos-fw -p tcp --dport 25565 -s 127.0.0.1 -j nixos-fw-accept
      '';
    };
  };
}
