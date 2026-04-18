{_, ...}: let
  version = "latest";
in {
  flake.nixosModules.twenty = {
    config,
    pkgs,
    lib,
    ...
  }: let
    cfg = config.services.twenty;
    inherit (config.networking) domain;

    stateDir = "/var/lib/twenty";
    serverPort = 3200;

    pgUser = "postgres";
    pgDb = "twenty";

    appSecretFile = config.sops.secrets.twenty_app_secret.path;
    pgPasswordFile = config.sops.secrets.twenty_db_password.path;

    serverUrl = "https://crm.${domain}";

    composeFile =
      pkgs.writeText "twenty-docker-compose.yml"
      ''
        name: twenty

        services:
          server:
            image: twentycrm/twenty:${version}
            ports:
              - "127.0.0.1:${toString serverPort}:3000"
            environment:
              NODE_PORT: 3000
              PG_DATABASE_URL: postgres://${pgUser}:''${PG_DATABASE_PASSWORD}@db:5432/${pgDb}
              SERVER_URL: ${serverUrl}
              REDIS_URL: redis://redis:6379
              STORAGE_TYPE: local
              APP_SECRET: ''${APP_SECRET}
            volumes:
              - server-local-data:/app/packages/twenty-server/.local-storage
            depends_on:
              db:
                condition: service_healthy
              redis:
                condition: service_healthy
            healthcheck:
              test: curl --fail http://localhost:3000/healthz
              interval: 5s
              timeout: 5s
              retries: 30
            restart: always

          worker:
            image: twentycrm/twenty:${version}
            command: ["yarn", "worker:prod"]
            environment:
              PG_DATABASE_URL: postgres://${pgUser}:''${PG_DATABASE_PASSWORD}@db:5432/${pgDb}
              SERVER_URL: ${serverUrl}
              REDIS_URL: redis://redis:6379
              STORAGE_TYPE: local
              APP_SECRET: ''${APP_SECRET}
              DISABLE_DB_MIGRATIONS: "true"
              DISABLE_CRON_JOBS_REGISTRATION: "true"
            volumes:
              - server-local-data:/app/packages/twenty-server/.local-storage
            depends_on:
              db:
                condition: service_healthy
              server:
                condition: service_healthy
            restart: always

          db:
            image: postgres:16
            environment:
              POSTGRES_DB: ${pgDb}
              POSTGRES_PASSWORD: ''${PG_DATABASE_PASSWORD}
              POSTGRES_USER: ${pgUser}
            volumes:
              - db-data:/var/lib/postgresql/data
            healthcheck:
              test: pg_isready -U ${pgUser} -h localhost -d postgres
              interval: 5s
              timeout: 5s
              retries: 10
            restart: always

          redis:
            image: redis
            command: ["--maxmemory-policy", "noeviction"]
            healthcheck:
              test: ["CMD", "redis-cli", "ping"]
              interval: 5s
              timeout: 5s
              retries: 10
            restart: always

        volumes:
          db-data:
          server-local-data:
      '';
  in {
    options.services.twenty = {
      enable = lib.mkEnableOption "Twenty CRM";
    };

    config = lib.mkIf cfg.enable {
      sops.secrets.twenty_app_secret = {
        owner = "root";
        group = "root";
        restartUnits = ["twenty.service"];
      };
      sops.secrets.twenty_db_password = {
        owner = "root";
        group = "root";
        restartUnits = ["twenty.service"];
      };

      systemd.tmpfiles.rules = [
        "d ${stateDir} 0755 root root -"
        "d ${stateDir}/backup 0755 root root -"
      ];

      systemd = {
        services = {
          twenty = {
            description = "Twenty CRM";
            after = ["docker.service" "sops-nix.service"];
            requires = ["docker.service"];
            wants = ["sops-nix.service"];
            wantedBy = ["multi-user.target"];
            path = [pkgs.docker pkgs.docker-compose];

            preStart = ''
              mkdir -p ${stateDir}
              printf 'PG_DATABASE_PASSWORD=%s\n' "$(cat ${pgPasswordFile} | tr -d '\n')" > ${stateDir}/.env
              printf 'APP_SECRET=%s\n' "$(cat ${appSecretFile} | tr -d '\n')" >> ${stateDir}/.env
              chmod 600 ${stateDir}/.env
            '';

            serviceConfig = {
              ExecStart = "${pkgs.docker-compose}/bin/docker-compose --env-file ${stateDir}/.env -f ${composeFile} up --remove-orphans";
              ExecStop = "${pkgs.docker-compose}/bin/docker-compose --env-file ${stateDir}/.env -f ${composeFile} down";
              WorkingDirectory = stateDir;
              Restart = "on-failure";
              RestartSec = "10s";
            };
          };

          twenty-db-backup = {
            description = "Twenty CRM Database Backup";
            after = ["twenty.service"];
            requires = ["docker.service"];
            serviceConfig = {
              Type = "oneshot";
              ExecStart = "${pkgs.docker}/bin/docker exec twenty-db-1 pg_dump -U ${pgUser} ${pgDb} > ${stateDir}/backup/$(date +%Y%m%d_%H%M%S).sql";
              WorkingDirectory = stateDir;
            };
            preStart = "mkdir -p ${stateDir}/backup";
          };
        };

        timers.twenty-db-backup = {
          wantedBy = ["timers.target"];
          timerConfig = {
            OnCalendar = "daily";
            Persistent = true;
          };
        };
      };
    };
  };
}
