{inputs, ...}: {
  flake.nixosModules.photomap = {
    config,
    pkgs,
    lib,
    ...
  }: let
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
    virtualisation.oci-containers.containers.photomap = {
      autoStart = true;
      image = "lstein/photomapai:latest";
      ports = ["127.0.0.1:8050:8050"];
      volumes = [
        "${immichUploadDir}:/Pictures/upload:ro"
        "${immichLibraryDir}:/Pictures/library:ro"
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

    systemd.services.docker-photomap = {
      after = ["immich-server.service"];
      wants = ["immich-server.service"];
    };

    systemd.tmpfiles.rules = [
      "d ${photomapDataDir} 0755 root root -"
      "d ${photomapDataDir}/config 0755 root root -"
      "d ${photomapDataDir}/data 0755 root root -"
      "d ${photomapDataDir}/index 0755 root root -"
      "L+ ${photomapDataDir}/config/config.yaml - - - - ${photomapConfig}"
    ];
  };
}
