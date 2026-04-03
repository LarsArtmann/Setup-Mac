flake: {
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.signoz;

  # Get packages from flake's legacyPackages (internal components)
  signozPackage = flake.packages.${pkgs.system}.signoz;
  otelCollectorPackage = flake.legacyPackages.${pkgs.system}.otelCollector;
  schemaMigratorPackage = flake.legacyPackages.${pkgs.system}.schemaMigrator;
in {
  options.services.signoz = {
    enable = lib.mkEnableOption "SigNoz observability platform";

    settings = lib.mkOption {
      type = lib.types.submodule {
        options = {
          clickhouse = {
            url = lib.mkOption {
              type = lib.types.str;
              default = "tcp://127.0.0.1:9000";
            };
            database = lib.mkOption {
              type = lib.types.str;
              default = "signoz_metrics";
            };
            tracesDatabase = lib.mkOption {
              type = lib.types.str;
              default = "signoz_traces";
            };
            logsDatabase = lib.mkOption {
              type = lib.types.str;
              default = "signoz_logs";
            };
          };
          queryService = {
            port = lib.mkOption {
              type = lib.types.port;
              default = 8080;
            };
            host = lib.mkOption {
              type = lib.types.str;
              default = "0.0.0.0";
            };
            dataDir = lib.mkOption {
              type = lib.types.path;
              default = "/var/lib/signoz";
            };
          };
          collector = {
            port = lib.mkOption {
              type = lib.types.port;
              default = 4317;
            };
            httpPort = lib.mkOption {
              type = lib.types.port;
              default = 4318;
            };
          };
        };
      };
      default = {};
    };

    components = lib.mkOption {
      type = lib.types.submodule {
        options = {
          queryService = lib.mkEnableOption "SigNoz query service" // {default = true;};
          otelCollector = lib.mkEnableOption "SigNoz OTel collector" // {default = true;};
          clickhouse = lib.mkEnableOption "ClickHouse" // {default = true;};
        };
      };
      default = {};
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      users.users.signoz = {
        isSystemUser = true;
        group = "signoz";
        home = cfg.settings.queryService.dataDir;
        createHome = true;
      };
      users.groups.signoz = {};

      systemd.tmpfiles.rules = [
        "d ${cfg.settings.queryService.dataDir} 0755 signoz signoz -"
      ];
    }

    # ClickHouse
    (lib.mkIf cfg.components.clickhouse {
      services.clickhouse.enable = true;
      systemd.services.clickhouse-poststart = {
        after = ["clickhouse.service"];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = pkgs.writeShellScript "init-signoz-ch" ''
            sleep 2
            ${pkgs.clickhouse}/bin/clickhouse-client --query "CREATE DATABASE IF NOT EXISTS ${cfg.settings.clickhouse.database}"
            ${pkgs.clickhouse}/bin/clickhouse-client --query "CREATE DATABASE IF NOT EXISTS ${cfg.settings.clickhouse.tracesDatabase}"
            ${pkgs.clickhouse}/bin/clickhouse-client --query "CREATE DATABASE IF NOT EXISTS ${cfg.settings.clickhouse.logsDatabase}"
          '';
        };
      };
    })

    # Schema Migration
    (lib.mkIf (cfg.components.queryService && cfg.components.clickhouse) {
      systemd.services.signoz-schema-migration = {
        after = ["clickhouse.service"];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          User = "signoz";
          ExecStart = "${schemaMigratorPackage}/bin/signoz-schema-migrator --dsn \"${cfg.settings.clickhouse.url}\" --up";
        };
      };
    })

    # Query Service
    (lib.mkIf cfg.components.queryService {
      systemd.services.signoz = {
        description = "SigNoz Observability Platform";
        after = lib.optional cfg.components.clickhouse "signoz-schema-migration.service";
        wantedBy = ["multi-user.target"];
        environment = {
          ClickHouseUrl = cfg.settings.clickhouse.url;
          STORAGE = "clickhouse";
        };
        serviceConfig = {
          Type = "simple";
          User = "signoz";
          Group = "signoz";
          WorkingDirectory = cfg.settings.queryService.dataDir;
          ExecStart = "${signozPackage}/bin/signoz --port ${toString cfg.settings.queryService.port} --host ${cfg.settings.queryService.host}";
          Restart = "on-failure";
          RestartSec = 10;
        };
      };
    })

    # OTel Collector
    (lib.mkIf cfg.components.otelCollector {
      systemd.services.signoz-collector = {
        description = "SigNoz OTel Collector";
        after = ["signoz.service"];
        wantedBy = ["multi-user.target"];
        serviceConfig = {
          Type = "simple";
          User = "signoz";
          ExecStart = "${otelCollectorPackage}/bin/signoz-otel-collector --config /etc/signoz/collector.yaml";
          Restart = "on-failure";
        };
      };

      environment.etc."signoz/collector.yaml".text = ''
        receivers:
          otlp:
            protocols:
              grpc:
                endpoint: 0.0.0.0:${toString cfg.settings.collector.port}
              http:
                endpoint: 0.0.0.0:${toString cfg.settings.collector.httpPort}
        exporters:
          clickhousetraces:
            datasource: ${cfg.settings.clickhouse.url}/${cfg.settings.clickhouse.tracesDatabase}
          signozclickhousemetrics:
            dsn: ${cfg.settings.clickhouse.url}/${cfg.settings.clickhouse.database}
          clickhouselogsexporter:
            dsn: ${cfg.settings.clickhouse.url}/${cfg.settings.clickhouse.logsDatabase}
        service:
          pipelines:
            traces:
              receivers: [otlp]
              exporters: [clickhousetraces]
            metrics:
              receivers: [otlp]
              exporters: [signozclickhousemetrics]
            logs:
              receivers: [otlp]
              exporters: [clickhouselogsexporter]
      '';
    })

    {
      networking.firewall.allowedTCPPorts =
        lib.optionals cfg.components.queryService [cfg.settings.queryService.port]
        ++ lib.optionals cfg.components.otelCollector [cfg.settings.collector.port cfg.settings.collector.httpPort]
        ++ lib.optionals cfg.components.clickhouse [9000 8123];
    }
  ]);
}
