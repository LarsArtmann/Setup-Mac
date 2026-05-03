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
    oldStateDirs = ["/home/lars/.hermes" "/var/lib/hermes"];

    mergeEnvScript = pkgs.writeShellScript "hermes-merge-env" ''
      set -euo pipefail
      ENV_FILE="${cfg.stateDir}/.env"

      if [ ! -f "$ENV_FILE" ]; then
        touch "$ENV_FILE"
        chmod 600 "$ENV_FILE"
      fi

      # Clean up deprecated keys
      for dep_key in MESSAGING_CWD; do
        if grep -q "^''${dep_key}=" "$ENV_FILE" 2>/dev/null; then
          ${pkgs.gnused}/bin/sed -i "/^''${dep_key}=/d" "$ENV_FILE"
          echo "hermes-merge: removed deprecated key $dep_key from .env"
        fi
      done

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
      NEW="${cfg.stateDir}"

      if [ -f "$NEW/state.db" ] && [ "$(stat -c%s "$NEW/state.db" 2>/dev/null)" -gt 1048576 ]; then
        echo "hermes-migrate: $NEW has existing state ($(stat -c%s "$NEW/state.db") bytes), skipping migration"
        exit 0
      fi

      for OLD in ${lib.concatStringsSep " " (map (p: "\"${p}\"") oldStateDirs)}; do
        if [ -d "$OLD" ] && [ "$(ls -A "$OLD" 2>/dev/null)" ]; then
          echo "hermes-migrate: migrating state from $OLD to $NEW"
          mkdir -p "$NEW"
          ${pkgs.rsync}/bin/rsync -a --chown=${cfg.user}:${cfg.group} "$OLD/" "$NEW/"
          echo "hermes-migrate: migration complete (from $OLD)"
          exit 0
        fi
      done

      echo "hermes-migrate: no old state found, skipping migration"
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
        default = "/home/hermes";
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
        createHome = true;
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
          pkgs.binutils
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
              "GATEWAY_ALLOW_ALL_USERS=true"
              "LD_LIBRARY_PATH=${pkgs.libopus}/lib"
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
            UMask = "0007";
          }
          // harden {
            MemoryMax = "4G";
            ProtectHome = false;
            ReadWritePaths = [cfg.stateDir];
          };
      };
    };
  };
}
