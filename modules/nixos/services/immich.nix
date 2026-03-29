{
  inputs,
  ...
}: {
  flake.nixosModules.immich = {
    config,
    pkgs,
    lib,
    ...
  }: let
    cfg = config.services.immich;
  in {
    services.immich = {
      enable = true;
      port = 2283;
      host = "127.0.0.1";
      openFirewall = false;
      mediaLocation = "/var/lib/immich";

      accelerationDevices = null;

      database.enable = true;
      redis.enable = true;
      machine-learning.enable = true;
    };

    users.users.immich.extraGroups = ["video" "render"];

    systemd.services.immich-db-backup = {
      description = "Immich PostgreSQL database backup";
      path = [config.services.postgresql.package];
      after = ["postgresql.service" "immich-server.service"];
      requires = ["postgresql.service"];
      serviceConfig = {
        Type = "oneshot";
        User = "immich";
        Group = "immich";
      };
      script = ''
        set -euo pipefail
        backupDir="${cfg.mediaLocation}/database-backup"
        mkdir -p "$backupDir"
        stamp="$(date +%Y%m%d-%H%M%S)"
        pg_dump --host=/run/postgresql --clean --if-exists --dbname=${cfg.database.name} \
          > "$backupDir/immich-$stamp.sql"
        find "$backupDir" -name "immich-*.sql" -mtime +7 -delete
        echo "immich-db-backup: completed -> immich-$stamp.sql"
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
  };
}
