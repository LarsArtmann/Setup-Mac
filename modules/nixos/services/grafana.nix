{inputs, ...}: {
  flake.nixosModules.grafana = {
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
          admin_password = "$__file{${config.sops.secrets.grafana_admin_password.path}}";
          secret_key = "$__file{${config.sops.secrets.grafana_secret_key.path}}";
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
  };
}
