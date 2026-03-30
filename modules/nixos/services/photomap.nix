{inputs, ...}: {
  flake.nixosModules.photomap = {
    config,
    pkgs,
    lib,
    ...
  }: let
    immichUploadDir = "${config.services.immich.mediaLocation}/upload";
    photomapDataDir = "/var/lib/photomap";
  in {
    virtualisation.oci-containers.containers.photomap = {
      autoStart = true;
      image = "lstein/photomapai:latest";
      ports = ["127.0.0.1:8050:8050"];
      volumes = [
        "${immichUploadDir}:/Pictures:ro"
        "${photomapDataDir}/config:/root/.config/photomap"
        "${photomapDataDir}/index:/root/.local/share/photomap"
      ];
      extraOptions = [
        "--health-cmd=curl -f http://localhost:8050/ || exit 1"
        "--health-interval=30s"
        "--health-timeout=10s"
        "--health-retries=3"
      ];
    };

    systemd.tmpfiles.rules = [
      "d ${photomapDataDir} 0755 root root -"
      "d ${photomapDataDir}/config 0755 root root -"
      "d ${photomapDataDir}/index 0755 root root -"
    ];
  };
}
