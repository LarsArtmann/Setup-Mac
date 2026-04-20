{inputs, ...}: {
  flake.nixosModules.hermes = {
    config,
    pkgs,
    lib,
    ...
  }: let
    cfg = config.services.hermes;
    hermesPkg = inputs.hermes-agent.packages.${pkgs.system}.default;
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
      # Install hermes system-wide (provides hermes, hermes-agent, hermes-acp binaries)
      environment.systemPackages = [
        hermesPkg
        pkgs.libopus
      ];

      # Ensure hermes home directory structure exists + link sops-rendered .env
      systemd.tmpfiles.rules = [
        "d ${cfg.home} 0750 ${cfg.user} users -"
        "d ${cfg.home}/sessions 0750 ${cfg.user} users -"
        "d ${cfg.home}/skills 0750 ${cfg.user} users -"
        "d ${cfg.home}/memories 0750 ${cfg.user} users -"
        "d ${cfg.home}/cron 0750 ${cfg.user} users -"
        "d ${cfg.home}/cache 0750 ${cfg.user} users -"
        "d ${cfg.home}/logs 0750 ${cfg.user} users -"
        "L+ ${cfg.home}/.env 0600 ${cfg.user} users - ${config.sops.templates."hermes-env".path}"
      ];

      # Declarative systemd user service managed by Home Manager
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
        };

        Install = {
          WantedBy = ["default.target"];
        };
      };
    };
  };
}
