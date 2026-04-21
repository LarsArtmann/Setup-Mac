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

    waitOnlineScript = pkgs.writeShellScript "hermes-wait-online" ''
      timeout 60 bash -c 'until ${pkgs.iputils}/bin/ping -c 1 -W 2 9.9.9.9 >/dev/null 2>&1; do sleep 2; done'
    '';

    mergeEnvScript = pkgs.writeShellScript "hermes-merge-env" ''
      set -euo pipefail
      ENV_FILE="${cfg.home}/.env"
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
          After = ["network.target"];
          StartLimitIntervalSec = 600;
          StartLimitBurst = 5;
        };

        Service = {
          Type = "simple";
          ExecStartPre = [
            waitOnlineScript
            mergeEnvScript
          ];
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
