_: {
  flake.nixosModules.monitor365 = {
    config,
    pkgs,
    lib,
    ...
  }: let
    cfg = config.services.monitor365;

    # Generate TOML config matching Monitor365's exact expected format.
    # All required fields must be present — the binary validates strictly.
    monitor365Config = pkgs.writeText "monitor365-config.toml" ''
      [device]
      id = "${config.networking.hostName}"
      name = "${config.networking.hostName}"
      type = "desktop"
      os_family = "linux"

      [collectors]

      [collectors.location]
      enabled = ${lib.boolToString cfg.collectors.location}
      interval_seconds = 60

      [collectors.screenshots]
      enabled = ${lib.boolToString cfg.collectors.screenshot}
      interval_seconds = 300
      quality = 80

      [collectors.camera]
      enabled = ${lib.boolToString cfg.collectors.camera}
      interval_seconds = 300
      camera = "auto"

      [collectors.app_usage]
      enabled = ${lib.boolToString cfg.collectors.window}

      [collectors.keystrokes]
      enabled = ${lib.boolToString cfg.collectors.keystroke}

      [collectors.mouse]
      enabled = ${lib.boolToString cfg.collectors.mouse}

      [collectors.network]
      enabled = ${lib.boolToString cfg.collectors.network}

      [collectors.battery]
      enabled = ${lib.boolToString cfg.collectors.battery}

      [collectors.notifications]
      enabled = false

      [collectors.afk_status]
      enabled = ${lib.boolToString cfg.collectors.afk}
      idle_threshold_seconds = 180

      [collectors.bluetooth]
      enabled = ${lib.boolToString cfg.collectors.bluetooth}
      interval_seconds = 10

      [collectors.sensor]
      enabled = ${lib.boolToString cfg.collectors.sensor}
      interval_seconds = 30

      [collectors.wifi_scan]
      enabled = ${lib.boolToString cfg.collectors.wifi}
      interval_seconds = 60

      [collectors.process]
      enabled = ${lib.boolToString cfg.collectors.process}
      interval_seconds = 10

      [collectors.clipboard]
      enabled = ${lib.boolToString cfg.collectors.clipboard}

      [storage]
      path = "${cfg.home}"
      retention_days = ${toString cfg.retentionDays}
      encryption = false
      compression_level = 3

      ${lib.optionalString cfg.activityWatch.enable ''
        [activitywatch]
        enabled = true
        host = "${cfg.activityWatch.host}"
        port = ${toString cfg.activityWatch.port}
      ''}

      [logging]
      level = "info"
      format = "pretty"

      [metrics]
      enabled = false
      bind_address = "127.0.0.1:9090"
    '';
  in {
    options.services.monitor365 = {
      enable = lib.mkEnableOption "Monitor365 device monitoring agent";

      user = lib.mkOption {
        type = lib.types.str;
        default = "lars";
        description = "User account for the monitoring agent";
      };

      home = lib.mkOption {
        type = lib.types.str;
        default = "/home/lars/.local/share/monitor365";
        description = "Data directory for event storage";
      };

      configPath = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Path to custom config.toml. Overrides generated config.";
      };

      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.monitor365;
        description = "Monitor365 package to use";
      };

      collectors = lib.mkOption {
        type = lib.types.submodule {
          freeformType = with lib.types; attrsOf anything;
          options = {
            battery = lib.mkEnableOption "battery monitoring" // {default = true;};
            network = lib.mkEnableOption "network monitoring" // {default = true;};
            wifi = lib.mkEnableOption "WiFi scanning" // {default = true;};
            bluetooth = lib.mkEnableOption "Bluetooth monitoring" // {default = true;};
            window = lib.mkEnableOption "window/app usage tracking" // {default = true;};
            process = lib.mkEnableOption "process monitoring" // {default = true;};
            afk = lib.mkEnableOption "AFK/idle detection" // {default = true;};
            sensor = lib.mkEnableOption "hardware sensor monitoring" // {default = true;};
            location = lib.mkEnableOption "location tracking" // {default = false;};
            screenshot = lib.mkEnableOption "screenshot capture" // {default = false;};
            keystroke = lib.mkEnableOption "keystroke logging" // {default = false;};
            mouse = lib.mkEnableOption "mouse activity tracking" // {default = false;};
            camera = lib.mkEnableOption "camera capture" // {default = false;};
            clipboard = lib.mkEnableOption "clipboard monitoring" // {default = false;};
          };
        };
        default = {};
        description = "Collector enablement flags";
      };

      activityWatch = lib.mkOption {
        type = lib.types.submodule {
          options = {
            enable = lib.mkEnableOption "ActivityWatch integration" // {default = true;};
            host = lib.mkOption {
              type = lib.types.str;
              default = "localhost";
            };
            port = lib.mkOption {
              type = lib.types.int;
              default = 5600;
            };
          };
        };
        default = {};
        description = "ActivityWatch integration settings";
      };

      retentionDays = lib.mkOption {
        type = lib.types.int;
        default = 90;
        description = "Days to retain events before cleanup";
      };
    };

    config = lib.mkIf cfg.enable {
      # Install the binary system-wide
      environment.systemPackages = [cfg.package];

      # Data directory
      systemd.tmpfiles.rules = [
        "d ${cfg.home} 0750 ${cfg.user} users -"
      ];

      # Generated config (or custom path)
      environment.etc."monitor365/config.toml".source =
        if cfg.configPath != null
        then cfg.configPath
        else monitor365Config;

      # Systemd user service — needs display/input access
      home-manager.users.${cfg.user}.systemd.user.services.monitor365 = {
        Unit = {
          Description = "Monitor365 Device Monitoring Agent";
          After = ["network.target" "graphical-session.target"];
          Wants = ["network.target"];
          PartOf = ["graphical-session.target"];
          StartLimitIntervalSec = 600;
          StartLimitBurst = 5;
        };

        Service = {
          Type = "simple";
          ExecStart = "${cfg.package}/bin/monitor365 --config /etc/monitor365/config.toml run";
          WorkingDirectory = cfg.home;
          Restart = "on-failure";
          RestartSec = "10";
          KillMode = "mixed";
          TimeoutStopSec = "30";
          StandardOutput = "journal";
          StandardError = "journal";

          MemoryMax = "1G";
          PrivateTmp = true;
          NoNewPrivileges = true;
          ProtectClock = true;
          ProtectHostname = true;
          RestrictNamespaces = true;
          LockPersonality = true;
        };

        Install = {
          WantedBy = ["graphical-session.target"];
        };
      };
    };
  };
}
