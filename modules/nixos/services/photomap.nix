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
        "${immichUploadDir}:/Pictures/upload"
        "${photomapDataDir}/photomap-index:/Pictures/upload/photomap_index"
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
      "d ${photomapDataDir}/photomap-index 0755 root root -"
    ];
  };
}
