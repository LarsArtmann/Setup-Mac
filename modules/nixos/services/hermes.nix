{inputs, ...}: {
  flake.nixosModules.hermes = {
    config,
    pkgs,
    lib,
    ...
  }: let
    cfg = config.services.hermes;
    hermesPkg = inputs.hermes-agent.packages.${pkgs.system}.default;
    sopsEnvPath = config.sops.templates."hermes-env".path;

    mergeEnvScript = pkgs.writeShellScript "hermes-merge-env" ''
      set -euo pipefail
      ENV_FILE="${cfg.home}/.env"
      SOPS_FILE="${sopsEnvPath}"

      if [ ! -f "$ENV_FILE" ]; then
        touch "$ENV_FILE"
        chmod 600 "$ENV_FILE"
      fi

      while IFS='=' read -r key value; do
        [ -z "$key" ] && continue
        if grep -q "^''${key}=" "$ENV_FILE" 2>/dev/null; then
          ${pkgs.gnused}/bin/sed -i "/^''${key}=/d" "$ENV_FILE"
        fi
        echo "$key=$value" >> "$ENV_FILE"
      done < "$SOPS_FILE"
    '';
  in {
    options.services.hermes = {
      enable = lib.mkEnableOption "Hermes AI Agent Gateway";

      user = lib.mkOption {
        type = lib.types.str;
        default = "lars";
        description = "User account for the gateway service";
      };

      home = lib.mkOption {
        type = lib.types.str;
        default = "/home/lars/.hermes";
        description = "Hermes home directory (config, sessions, skills)";
      };

      restartSec = lib.mkOption {
        type = lib.types.str;
        default = "30";
        description = "Seconds to wait before restarting after failure";
      };

      timeoutStopSec = lib.mkOption {
        type = lib.types.str;
        default = "120";
        description = "Seconds to wait for graceful shutdown before SIGKILL";
      };
    };

    config = lib.mkIf cfg.enable {
      environment.systemPackages = [
        hermesPkg
        pkgs.libopus
      ];

      systemd.tmpfiles.rules = [
        "d ${cfg.home} 0750 ${cfg.user} users -"
        "d ${cfg.home}/sessions 0750 ${cfg.user} users -"
        "d ${cfg.home}/skills 0750 ${cfg.user} users -"
        "d ${cfg.home}/memories 0750 ${cfg.user} users -"
        "d ${cfg.home}/cron 0750 ${cfg.user} users -"
        "d ${cfg.home}/cache 0750 ${cfg.user} users -"
        "d ${cfg.home}/logs 0750 ${cfg.user} users -"
      ];

      home-manager.users.${cfg.user}.systemd.user.services.hermes-gateway = {
        Unit = {
          Description = "Hermes Agent Gateway - Messaging Platform Integration";
          After = ["network.target" "network-online.target"];
          Wants = ["network-online.target"];
          StartLimitIntervalSec = 600;
          StartLimitBurst = 5;
        };

        Service = {
          Type = "simple";
          ExecStartPre = mergeEnvScript;
          ExecStart = "${hermesPkg}/bin/hermes gateway run --replace";
          WorkingDirectory = cfg.home;
          Environment = [
            "HERMES_HOME=${cfg.home}"
            "LD_LIBRARY_PATH=/run/current-system/sw/lib"
          ];
          Restart = "on-failure";
          RestartSec = cfg.restartSec;
          RestartForceExitStatus = 75;
          KillMode = "mixed";
          KillSignal = "SIGTERM";
          TimeoutStopSec = cfg.timeoutStopSec;
          ExecReload = "/bin/kill -USR1 $MAINPID";
          StandardOutput = "journal";
          StandardError = "journal";
          WatchdogSec = 60;
          MemoryMax = "4G";
          PrivateTmp = true;
          NoNewPrivileges = true;
          ProtectClock = true;
          ProtectHostname = true;
          ProtectKernelLogs = true;
          RestrictNamespaces = true;
          LockPersonality = true;
        };

        Install = {
          WantedBy = ["default.target"];
        };
      };
    };
  };
}
