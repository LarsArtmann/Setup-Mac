{inputs, ...}: let
  harden = import ../../../lib/systemd.nix;
in {
  flake.nixosModules.hermes = {
    config,
    pkgs,
    lib,
    ...
  }: let
    cfg = config.services.hermes;
    hermesPkg = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default;
    sopsEnvPath = config.sops.templates."hermes-env".path;
    oldStateDir = "/home/${cfg.user}/.hermes";

    mergeEnvScript = pkgs.writeShellScript "hermes-merge-env" ''
      set -euo pipefail
      ENV_FILE="${cfg.stateDir}/.env"

      if [ ! -f "$ENV_FILE" ]; then
        touch "$ENV_FILE"
        chmod 600 "$ENV_FILE"
      fi

      # Write non-secret env vars only (secrets come from sops via EnvironmentFile)
      for pair in "OLLAMA_API_KEY=ollama" "TERMINAL_ENV=local"; do
        key="''${pair%%=*}"
        value="''${pair#*=}"
        [ -z "$key" ] && continue
        if grep -q "^''${key}=" "$ENV_FILE" 2>/dev/null; then
          ${pkgs.gnused}/bin/sed -i "/^''${key}=/d" "$ENV_FILE"
        fi
        echo "$key=$value" >> "$ENV_FILE"
      done
    '';

    migrateScript = pkgs.writeShellScript "hermes-migrate-state" ''
      set -euo pipefail
      OLD="${oldStateDir}"
      NEW="${cfg.stateDir}"

      if [ ! -d "$OLD" ]; then
        echo "hermes-migrate: no old state at $OLD, skipping migration"
        exit 0
      fi

      if [ -d "$NEW" ] && [ "$(ls -A "$NEW" 2>/dev/null)" ]; then
        echo "hermes-migrate: $NEW already populated, skipping migration"
        exit 0
      fi

      echo "hermes-migrate: migrating state from $OLD to $NEW"
      ${pkgs.rsync}/bin/rsync -a --chown=${cfg.user}:${cfg.group} "$OLD/" "$NEW/"
      echo "hermes-migrate: migration complete"
    '';
  in {
    options.services.hermes = {
      enable = lib.mkEnableOption "Hermes AI Agent Gateway";

      user = lib.mkOption {
        type = lib.types.str;
        default = "hermes";
        description = "System user for the gateway service";
      };

      group = lib.mkOption {
        type = lib.types.str;
        default = "hermes";
        description = "System group for the gateway service";
      };

      stateDir = lib.mkOption {
        type = lib.types.str;
        default = "/var/lib/hermes";
        description = "State directory for Hermes (config, sessions, skills, memories)";
      };

      restartSec = lib.mkOption {
        type = lib.types.str;
        default = "5";
        description = "Seconds to wait before restarting after failure";
      };

      timeoutStopSec = lib.mkOption {
        type = lib.types.str;
        default = "120";
        description = "Seconds to wait for graceful shutdown before SIGKILL";
      };
    };

    config = lib.mkIf cfg.enable {
      users.groups.${cfg.group} = {};

      users.users.${cfg.user} = {
        isSystemUser = true;
        inherit (cfg) group;
        home = cfg.stateDir;
        createHome = false;
        description = "Hermes AI Agent Gateway service user";
      };

      environment.systemPackages = [hermesPkg];

      systemd.tmpfiles.rules = [
        "d ${cfg.stateDir}           2770 ${cfg.user} ${cfg.group} -"
        "d ${cfg.stateDir}/sessions  2770 ${cfg.user} ${cfg.group} -"
        "d ${cfg.stateDir}/skills    2770 ${cfg.user} ${cfg.group} -"
        "d ${cfg.stateDir}/memories  2770 ${cfg.user} ${cfg.group} -"
        "d ${cfg.stateDir}/cron      2770 ${cfg.user} ${cfg.group} -"
        "d ${cfg.stateDir}/cache     2770 ${cfg.user} ${cfg.group} -"
        "d ${cfg.stateDir}/logs      2770 ${cfg.user} ${cfg.group} -"
        "d ${cfg.stateDir}/workspace 2770 ${cfg.user} ${cfg.group} -"
      ];

      system.activationScripts."hermes-setup" = lib.stringAfter (["users"] ++ lib.optional (config.system.activationScripts ? setupSecrets) "setupSecrets") ''
        mkdir -p ${cfg.stateDir}/{sessions,skills,memories,cron,cache,logs,workspace}
        chown -R ${cfg.user}:${cfg.group} ${cfg.stateDir}
        chmod 2770 ${cfg.stateDir} ${cfg.stateDir}/{sessions,skills,memories,cron,cache,logs,workspace}

        find ${cfg.stateDir} -maxdepth 1 \( -name "*.db" -o -name "*.db-wal" -o -name "*.db-shm" -o -name "SOUL.md" \) \
          -exec chmod g+rw {} + 2>/dev/null || true
        for _subdir in sessions skills memories cron cache logs; do
          find "${cfg.stateDir}/$_subdir" -type f -exec chmod g+rw {} + 2>/dev/null || true
        done

        touch ${cfg.stateDir}/.managed
        chown ${cfg.user}:${cfg.group} ${cfg.stateDir}/.managed
        chmod 0644 ${cfg.stateDir}/.managed
      '';

      systemd.services.hermes = {
        description = "Hermes Agent Gateway - Messaging Platform Integration";
        wantedBy = ["multi-user.target"];
        after = ["network-online.target"];
        wants = ["network-online.target"];
        startLimitIntervalSec = 600;
        startLimitBurst = 5;

        path = [
          hermesPkg
          pkgs.bash
          pkgs.coreutils
          pkgs.git
        ];

        serviceConfig =
          {
            Type = "simple";
            User = cfg.user;
            Group = cfg.group;
            ExecStartPre = ["+${migrateScript}" mergeEnvScript];
            ExecStart = "${hermesPkg}/bin/hermes gateway run --replace";
            WorkingDirectory = cfg.stateDir;
            Environment = [
              "HOME=${cfg.stateDir}"
              "HERMES_HOME=${cfg.stateDir}"
              "HERMES_MANAGED=true"
              "MESSAGING_CWD=${cfg.stateDir}/workspace"
            ];
            EnvironmentFile = [sopsEnvPath];
            Restart = lib.mkForce "always";
            RestartSec = lib.mkForce cfg.restartSec;
            RestartForceExitStatus = 75;
            KillMode = "mixed";
            KillSignal = "SIGTERM";
            TimeoutStopSec = cfg.timeoutStopSec;
            ExecReload = "/bin/kill -USR1 $MAINPID";
            StandardOutput = "journal";
            StandardError = "journal";
            WatchdogSec = "30";
            UMask = "0007";
          }
          // harden {
            MemoryMax = "4G";
            ReadWritePaths = [cfg.stateDir oldStateDir];
          };
      };
    };
  };
}
