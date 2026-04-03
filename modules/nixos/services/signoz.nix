{
  inputs,
  config,
  lib,
  ...
}: let
  version = "0.117.1";
  collectorVersion = "0.144.2";

  mkPackages = pkgs: let
    src = inputs.signoz-src;
    collectorSrc = inputs.signoz-collector-src;

    buildGoModule = pkgs.buildGoModule.override {go = pkgs.go_1_25;};

    collectorVendorHash = "sha256-FEzjJTYItt6mMPUu2cFnfYP6oTjnWiqCVKO+dUIm1pg=";

    schemaMigrator = buildGoModule {
      pname = "signoz-schema-migrator";
      version = collectorVersion;
      src = collectorSrc;
      vendorHash = collectorVendorHash;
      subPackages = ["cmd/signozschemamigrator"];
      ldflags = ["-s" "-w"];
      postInstall = "mv $out/bin/signozschemamigrator $out/bin/signoz-schema-migrator";
    };

    otelCollector = buildGoModule {
      pname = "signoz-otel-collector";
      version = collectorVersion;
      src = collectorSrc;
      vendorHash = collectorVendorHash;
      subPackages = ["cmd/signozotelcollector"];
      ldflags = ["-s" "-w"];
      postInstall = "mv $out/bin/signozotelcollector $out/bin/signoz-otel-collector";
    };

    signoz = buildGoModule {
      pname = "signoz";
      inherit version;
      src = src;
      vendorHash = "sha256-z6WdVvDvFsbQ1apEr+jHFPB+mLLZj3jeUUX92atTuUk=";
      subPackages = ["cmd/community"];
      tags = ["timetzdata"];

      ldflags = [
        "-s"
        "-w"
        "-X github.com/SigNoz/signoz/pkg/version.version=${version}"
        "-X github.com/SigNoz/signoz/pkg/version.variant=community"
        "-X github.com/SigNoz/signoz/pkg/version.hash=nix"
        "-X github.com/SigNoz/signoz/pkg/version.time=1970-01-01T00:00:00Z"
        "-X github.com/SigNoz/signoz/pkg/version.branch=nix"
      ];

      postInstall = ''
        mv $out/bin/community $out/bin/signoz
        mkdir -p $out/share/signoz
        cp -r $src/conf $out/share/signoz/ 2>/dev/null || true
        cp -r $src/templates $out/share/signoz/ 2>/dev/null || true
      '';

      meta = with lib; {
        description = "SigNoz observability platform (community edition)";
        homepage = "https://signoz.io";
        license = licenses.asl20;
        platforms = platforms.linux;
      };
    };
  in {
    inherit signoz otelCollector schemaMigrator;
  };
in {
  perSystem = {
    pkgs,
    lib,
    ...
  }: let
    packages = mkPackages pkgs;
  in {
    packages =
      lib.optionalAttrs pkgs.stdenv.isLinux {
        signoz = packages.signoz;
        signoz-otel-collector = packages.otelCollector;
        signoz-schema-migrator = packages.schemaMigrator;
      };
  };

  flake.nixosModules.signoz = {
    config,
    pkgs,
    lib,
    ...
  }: let
    cfg = config.services.signoz;
    packages = mkPackages pkgs;
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
            queryService = lib.mkEnableOption "query service" // {default = true;};
            otelCollector = lib.mkEnableOption "OTel collector" // {default = true;};
            clickhouse = lib.mkEnableOption "managed ClickHouse" // {default = true;};
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

        environment.etc."signoz/signoz.yaml".text = lib.generators.toYAML {} {
          gateway = {
            url = "http://${cfg.settings.queryService.host}:${toString cfg.settings.queryService.port}";
          };
          telemetrystore = {
            provider = "clickhouse";
            clickhouse = {
              dsn = cfg.settings.clickhouse.url;
              cluster = "cluster";
            };
          };
          sqlstore = {
            provider = "sqlite";
            sqlite = {
              path = "${cfg.settings.queryService.dataDir}/signoz.db";
              mode = "wal";
              busy_timeout = "10s";
            };
          };
          web = {
            enabled = false;
          };
          instrumentation = {
            logs.level = "info";
            metrics.enabled = false;
          };
        };
      }

      (lib.mkIf cfg.components.clickhouse {
        services.clickhouse.enable = true;
      })

      (lib.mkIf cfg.components.queryService {
        systemd.services.signoz = {
          description = "SigNoz Observability Platform";
          after = lib.optional cfg.components.clickhouse "clickhouse.service";
          requires = lib.optional cfg.components.clickhouse "clickhouse.service";
          wantedBy = ["multi-user.target"];
          serviceConfig = {
            Type = "simple";
            User = "signoz";
            Group = "signoz";
            WorkingDirectory = cfg.settings.queryService.dataDir;
            ExecStart = "${packages.signoz}/bin/signoz server --config /etc/signoz/signoz.yaml";
            Restart = "on-failure";
            RestartSec = 10;
          };
        };
      })

      (lib.mkIf cfg.components.otelCollector {
        systemd.services.signoz-collector = {
          description = "SigNoz OTel Collector";
          after = ["signoz.service"];
          wants = ["signoz.service"];
          wantedBy = ["multi-user.target"];
          preStart = ''
            ${packages.otelCollector}/bin/signoz-otel-collector migrate sync up \
              --clickhouse-dsn "${cfg.settings.clickhouse.url}" \
              --clickhouse-cluster "cluster" || true
          '';
          serviceConfig = {
            Type = "simple";
            User = "signoz";
            Group = "signoz";
            WorkingDirectory = cfg.settings.queryService.dataDir;
            ExecStart = "${packages.otelCollector}/bin/signoz-otel-collector --config /etc/signoz/collector.yaml";
            Restart = "on-failure";
            RestartSec = 10;
          };
        };
        environment.etc."signoz/collector.yaml".text = lib.generators.toYAML {} {
          receivers = {
            otlp = {
              protocols = {
                grpc = {endpoint = "0.0.0.0:${toString cfg.settings.collector.port}";};
                http = {endpoint = "0.0.0.0:${toString cfg.settings.collector.httpPort}";};
              };
            };
          };
          exporters = {
            clickhousetraces = {
              datasource = "${cfg.settings.clickhouse.url}/${cfg.settings.clickhouse.tracesDatabase}";
              retry_on_failure = {
                enabled = true;
                initial_interval = "5s";
                max_interval = "30s";
                max_elapsed_time = "300s";
              };
            };
            signozclickhousemetrics = {
              dsn = "${cfg.settings.clickhouse.url}/${cfg.settings.clickhouse.database}";
            };
            clickhouselogsexporter = {
              dsn = "${cfg.settings.clickhouse.url}/${cfg.settings.clickhouse.logsDatabase}";
              timeout = "10s";
              use_new_schema = true;
            };
          };
          service = {
            pipelines = {
              traces = {
                receivers = ["otlp"];
                exporters = ["clickhousetraces"];
              };
              metrics = {
                receivers = ["otlp"];
                exporters = ["signozclickhousemetrics"];
              };
              logs = {
                receivers = ["otlp"];
                exporters = ["clickhouselogsexporter"];
              };
            };
          };
        };
      })

      {
        networking.firewall.allowedTCPPorts =
          lib.optionals cfg.components.queryService [cfg.settings.queryService.port]
          ++ lib.optionals cfg.components.otelCollector [cfg.settings.collector.port cfg.settings.collector.httpPort]
          ++ lib.optionals cfg.components.clickhouse [9000 8123];
      }
    ]);
  };
}
