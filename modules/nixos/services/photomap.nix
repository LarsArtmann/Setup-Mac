_: {
  flake.nixosModules.photomap = {
    config,
    pkgs,
    lib,
    ...
  }: let
    cfg = config.services.photomap;
    harden = import ../../../lib/systemd.nix;
    serviceDefaults = import ../../../lib/systemd/service-defaults.nix;
    immichMediaDir = config.services.immich.mediaLocation;
    immichUploadDir = "${immichMediaDir}/upload";
    immichLibraryDir = "${immichMediaDir}/library";
    photomapDataDir = "/var/lib/photomap";

    photomapConfig = pkgs.writeText "config.yaml" ''
      config_version: "1.0.0"
      albums:
        immich:
          name: "Immich Library"
          description: "All photos from local Immich server"
          image_paths:
            - /Pictures/upload
            - /Pictures/library
          index: /Pictures/index/immich-embeddings.npz
          umap_eps: 0.13
    '';
  in {
    options.services.photomap = {
      enable = lib.mkEnableOption "PhotoMap AI service";
    };

    config = lib.mkIf cfg.enable {
      virtualisation.oci-containers.containers.photomap = {
        autoStart = true;
        image = "lstein/photomapai@sha256:ca975ca6b2a00a7943fec1f578815dccfdbc212630547c70e750c724e981435d";
        ports = ["127.0.0.1:8050:8050"];
        volumes = [
          "${immichUploadDir}:/Pictures/upload:ro"
          "${immichLibraryDir}:/Pictures/library:ro"
          "${photomapDataDir}/index/upload:/Pictures/upload/photomap_index"
          "${photomapDataDir}/index/library:/Pictures/library/photomap_index"
          "${photomapDataDir}/index:/Pictures/index"
          "${photomapDataDir}/config:/root/.config/photomap"
          "${photomapDataDir}/data:/root/.local/share/photomap"
        ];
        extraOptions = [
          "--health-cmd=python3 -c \"import urllib.request;urllib.request.urlopen('http://localhost:8050/')\""
          "--health-interval=30s"
          "--health-timeout=10s"
          "--health-retries=3"
        ];
      };

      systemd.services.podman-photomap = {
        after = ["immich-server.service" "postgresql.service" "network-online.target"];
        wants = ["immich-server.service" "network-online.target"];
        requires = ["immich-server.service" "postgresql.service"];
        preStart = ''
          if [ ! -f ${photomapDataDir}/config/config.yaml ]; then
            cp ${photomapConfig} ${photomapDataDir}/config/config.yaml
            chmod 644 ${photomapDataDir}/config/config.yaml
          fi
        '';
        serviceConfig =
          serviceDefaults {RestartSec = "10s";}
          // {
            Restart = lib.mkForce "always";
            MemoryMax = "512M";
          };
      };

      systemd.tmpfiles.rules = [
        "d ${photomapDataDir} 0755 root root -"
        "d ${photomapDataDir}/config 0755 root root -"
        "d ${photomapDataDir}/data 0755 root root -"
        "d ${photomapDataDir}/index 0755 root root -"
        "d ${photomapDataDir}/index/upload 0755 root root -"
        "d ${photomapDataDir}/index/library 0755 root root -"
      ];
    };
  };
}
