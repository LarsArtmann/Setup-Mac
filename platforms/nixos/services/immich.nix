{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.services.immich;
  dataDir = cfg.mediaLocation;
in {
  services.immich = {
    enable = true;
    port = 2283;
    host = "0.0.0.0";
    openFirewall = true;
    mediaLocation = "/var/lib/immich";
    accelerationDevices = null;
  };

  users.users.immich.extraGroups = ["video" "render"];

  systemd.tmpfiles.rules = [
    "d ${dataDir} 750 immich immich - -"
    "d ${dataDir}/library 750 immich immich - -"
    "d ${dataDir}/upload 750 immich immich - -"
    "d ${dataDir}/profile 750 immich immich - -"
    "d ${dataDir}/thumbs 750 immich immich - -"
    "d ${dataDir}/encoded-video 750 immich immich - -"
    "d ${dataDir}/database-backup 750 immich immich - -"
  ];

  systemd.services.immich-db-backup = {
    description = "Immich PostgreSQL database backup";
    path = [config.services.postgresql.package];
    serviceConfig = {
      Type = "oneshot";
      User = "immich";
      Group = "immich";
    };
    script = ''
      mkdir -p ${dataDir}/database-backup
      pg_dump --clean --if-exists --dbname=immich > ${dataDir}/database-backup/immich-$(date +%Y%m%d).sql
      find ${dataDir}/database-backup -name "immich-*.sql" -mtime +7 -delete
    '';
  };

  systemd.timers.immich-db-backup = {
    description = "Daily Immich database backup";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };
}
