{inputs, ...}: {
  flake.nixosModules.hermes = {
    config,
    pkgs,
    lib,
    ...
  }: let
    cfg = config.services.hermes;
    hermesPkg = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default;
    sopsEnvPath = config.sops.templates."hermes-env".path;
    oldStateDir = "/home/lars/.hermes";

    mergeEnvScript = pkgs.writeShellScript "hermes-merge-env" ''
      set -euo pipefail
      ENV_FILE="${cfg.stateDir}/.env"
      SOPS_FILE="${sopsEnvPath}"

      if [ ! -f "$SOPS_FILE" ]; then
        echo "hermes-merge-env: sops template not found at $SOPS_FILE, waiting..." >&2
        for i in $(seq 1 30); do
          [ -f "$SOPS_FILE" ] && break
          sleep 1
        done
        if [ ! -f "$SOPS_FILE" ]; then
          echo "hermes-merge-env: sops template still missing after 30s, aborting" >&2
          exit 1
        fi
      fi

      if [ ! -f "$ENV_FILE" ]; then
        touch "$ENV_FILE"
        chmod 600 "$ENV_FILE"
      fi

      while IFS= read -r line || [ -n "$line" ]; do
        key="''${line%%=*}"
        value="''${line#*=}"
        [ -z "$key" ] && continue
        if grep -q "^''${key}=" "$ENV_FILE" 2>/dev/null; then
          ${pkgs.gnused}/bin/sed -i "/^''${key}=/d" "$ENV_FILE"
        fi
        echo "$key=$value" >> "$ENV_FILE"
      done < "$SOPS_FILE"
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
        group = cfg.group;
        home = cfg.stateDir;
        createHome = false;
        description = "Hermes AI Agent Gateway service user";
      };

      environment.systemPackages = [hermesPkg];

      systemd.tmpfiles.rules = [
        "d ${cfg.stateDir} 0750 ${cfg.user} ${cfg.group} -"
        "d ${cfg.stateDir}/sessions 0750 ${cfg.user} ${cfg.group} -"
        "d ${cfg.stateDir}/skills 0750 ${cfg.user} ${cfg.group} -"
        "d ${cfg.stateDir}/memories 0750 ${cfg.user} ${cfg.group} -"
        "d ${cfg.stateDir}/cron 0750 ${cfg.user} ${cfg.group} -"
        "d ${cfg.stateDir}/cache 0750 ${cfg.user} ${cfg.group} -"
        "d ${cfg.stateDir}/logs 0750 ${cfg.user} ${cfg.group} -"
        "d ${cfg.stateDir}/workspace 0750 ${cfg.user} ${cfg.group} -"
      ];

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

        serviceConfig = {
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
          EnvironmentFile = sopsEnvPath;
          Restart = "always";
          RestartSec = cfg.restartSec;
          RestartForceExitStatus = 75;
          KillMode = "mixed";
          KillSignal = "SIGTERM";
          TimeoutStopSec = cfg.timeoutStopSec;
          ExecReload = "/bin/kill -USR1 $MAINPID";
          StandardOutput = "journal";
          StandardError = "journal";
          UMask = "0007";
          WatchdogSec = "60";

          MemoryMax = "4G";
          PrivateTmp = true;
          NoNewPrivileges = true;
          CapabilityBoundingSet = "";
          ProtectClock = true;
          ProtectHostname = true;
          ProtectKernelLogs = true;
          RestrictNamespaces = true;
          RestrictSUIDSGID = true;
          LockPersonality = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          ReadWritePaths = [cfg.stateDir oldStateDir];
        };
      };
    };
  };
}
