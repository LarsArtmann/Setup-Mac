{inputs, ...}: {
  flake.nixosModules.monitoring = {
    config,
    pkgs,
    ...
  }: let
    listenPort = 9090;
  in {
    services.prometheus = {
      enable = true;
      port = listenPort;
      retentionTime = "30d";

      scrapeConfigs = [
        {
          job_name = "node";
          static_configs = [{targets = ["localhost:${toString config.services.prometheus.exporters.node.port}"];}];
        }
        {
          job_name = "postgres";
          static_configs = [{targets = ["localhost:${toString config.services.prometheus.exporters.postgres.port}"];}];
        }
        {
          job_name = "caddy";
          static_configs = [{targets = ["localhost:2019"];}];
        }
        {
          job_name = "redis";
          static_configs = [{targets = ["localhost:${toString config.services.prometheus.exporters.redis.port}"];}];
        }
        {
          job_name = "authelia";
          static_configs = [{targets = ["localhost:9959"];}];
        }
      ];
    };

    services.prometheus.exporters = {
      node = {
        enable = true;
        port = 9100;
        enabledCollectors = [
          "cpu"
          "diskstats"
          "filesystem"
          "loadavg"
          "meminfo"
          "netdev"
          "stat"
          "time"
          "uname"
          "hwmon"
          "thermal_zone"
        ];
      };

      postgres = {
        enable = true;
        port = 9187;
        dataSourceName = "user=postgres host=/run/postgresql sslmode=disable";
      };

      redis = {
        enable = true;
        port = 9121;
      };
    };
  };
}
