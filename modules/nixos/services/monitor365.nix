{inputs, ...}: {
  flake.nixosModules.monitor365 = {
    config,
    pkgs,
    lib,
    ...
  }: let
    cfg = config.services.monitor365;
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
        description = "Path to custom config.toml. If null, a minimal config is generated.";
      };

      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.monitor365;
        description = "Monitor365 package to use";
      };

      collectors = lib.mkOption {
        type = lib.types.submodule {
          options = {
            battery = lib.mkEnableOption "battery monitoring" // {default = true;};
            network = lib.mkEnableOption "network monitoring" // {default = true;};
            wifi = lib.mkEnableOption "WiFi monitoring" // {default = true;};
            bluetooth = lib.mkEnableOption "Bluetooth monitoring" // {default = true;};
            window = lib.mkEnableOption "window/app usage tracking" // {default = true;};
            process = lib.mkEnableOption "process monitoring" // {default = true;};
            systemInfo = lib.mkEnableOption "system info collection" // {default = true;};
            afk = lib.mkEnableOption "AFK/idle detection" // {default = true;};
            display = lib.mkEnableOption "display state monitoring" // {default = true;};
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
        description = "Collector configuration";
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

      collectionIntervalSec = lib.mkOption {
        type = lib.types.int;
        default = 60;
        description = "Default collection interval in seconds";
      };
    };

    config = lib.mkIf cfg.enable {
      # Generated minimal config if none provided
      environment.etc."monitor365/config.toml" = lib.mkIf (cfg.configPath == null) {
        source = pkgs.writeText "monitor365-config.toml" (lib.generators.toINI {} {
          device = {
            id = config.networking.hostName;
            name = config.networking.hostName;
            type = "desktop";
          };
          storage = {
            path = cfg.home;
            retention_days = cfg.retentionDays;
            compression_level = 3;
          };
          collectors = {
            battery_enabled = cfg.collectors.battery;
            network_enabled = cfg.collectors.network;
            wifi_enabled = cfg.collectors.wifi;
            bluetooth_enabled = cfg.collectors.bluetooth;
            window_enabled = cfg.collectors.window;
            process_enabled = cfg.collectors.process;
            system_info_enabled = cfg.collectors.systemInfo;
            afk_enabled = cfg.collectors.afk;
            display_enabled = cfg.collectors.display;
            sensor_enabled = cfg.collectors.sensor;
            location_enabled = cfg.collectors.location;
            screenshot_enabled = cfg.collectors.screenshot;
            keystroke_enabled = cfg.collectors.keystroke;
            mouse_enabled = cfg.collectors.mouse;
            camera_enabled = cfg.collectors.camera;
            clipboard_enabled = cfg.collectors.clipboard;
            default_interval_secs = cfg.collectionIntervalSec;
          };
          cloud = {
            enabled = false;
          };
          activitywatch = {
            enabled = cfg.activityWatch.enable;
            host = cfg.activityWatch.host;
            port = cfg.activityWatch.port;
          };
        });
      };

      # Data directories
      systemd.tmpfiles.rules = [
        "d ${cfg.home} 0750 ${cfg.user} users -"
        "d ${cfg.home}/events 0750 ${cfg.user} users -"
        "d ${cfg.home}/snapshots 0750 ${cfg.user} users -"
      ];

      # Systemd user service — runs under lars, has access to display/input
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
          ExecStart = "${cfg.package}/bin/monitor365 --config ${
            if cfg.configPath != null
            then toString cfg.configPath
            else "/etc/monitor365/config.toml"
          } run";
          WorkingDirectory = cfg.home;
          Restart = "on-failure";
          RestartSec = "10";
          KillMode = "mixed";
          TimeoutStopSec = "30";
          StandardOutput = "journal";
          StandardError = "journal";

          # Security sandboxing
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
