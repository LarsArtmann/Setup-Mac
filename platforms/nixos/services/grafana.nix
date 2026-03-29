{
  config,
  pkgs,
  ...
}: let
  grafanaPort = 3001;
  prometheusPort = config.services.prometheus.port;
in {
  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "127.0.0.1";
        http_port = grafanaPort;
        domain = "grafana.lan";
        root_url = "http://grafana.lan";
      };

      security = {
        admin_user = "admin";
        admin_password = "admin";
        secret_key = "SW2YcwTIb9zpOOhoPsMm";
      };

      analytics.reporting_enabled = false;
    };

    provision = {
      enable = true;

      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          access = "proxy";
          url = "http://localhost:${toString prometheusPort}";
          isDefault = true;
        }
      ];

      dashboards.settings.providers = [
        {
          name = "evo-x2";
          orgId = 1;
          folder = "";
          type = "file";
          disableDeletion = false;
          editable = true;
          options = {
            path = ./dashboards;
            foldersFromFilesStructure = false;
          };
        }
      ];
    };
  };
}
