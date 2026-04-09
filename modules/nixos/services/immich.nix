{inputs, ...}: {
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

      environment.NODE_TLS_REJECT_UNAUTHORIZED = "0";

      settings = {
        oauth = {
          enabled = true;
          issuerUrl = "https://auth.${config.networking.domain}";
          clientId = "immich";
          clientSecret._secret = config.sops.secrets.immich_oauth_client_secret.path;
          scope = "openid profile email";
          autoLaunch = false;
          autoRegister = true;
          buttonText = "Login with Authelia";
        };
      };
    };

    users.users.immich.extraGroups = ["video" "render"];

    # PostgreSQL tuning for Immich workload
    services.postgresql.settings = {
      shared_buffers = "512MB";
      effective_cache_size = "2GB";
      work_mem = "16MB";
      maintenance_work_mem = "256MB";
      max_connections = 100;
      checkpoint_completion_target = "0.9";
      random_page_cost = "1.1";
    };

    systemd = {
      services = {
        immich-server.serviceConfig = {
          Restart = lib.mkForce "on-failure";
          RestartSec = lib.mkForce "5s";
        };
        immich-machine-learning.serviceConfig = {
          Restart = lib.mkForce "on-failure";
          RestartSec = lib.mkForce "10s";
        };
        immich-db-backup = {
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
      };
      timers.immich-db-backup = {
        description = "Daily Immich database backup";
        wantedBy = ["timers.target"];
        timerConfig = {
          OnCalendar = "daily";
          Persistent = true;
        };
      };
    };
  };
}
