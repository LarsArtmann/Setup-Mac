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
          root_url = "https://grafana.lan";
        };

        security = {
          admin_user = "admin";
          admin_password = "$__file{${config.sops.secrets.grafana_admin_password.path}}";
          secret_key = "$__file{${config.sops.secrets.grafana_secret_key.path}}";
        };

        analytics.reporting_enabled = false;

        "auth.generic_oauth" = {
          enabled = true;
          name = "Authelia";
          icon = "signin";
          client_id = "grafana";
          client_secret = "$__file{${config.sops.secrets.grafana_oauth_client_secret.path}}";
          scopes = "openid profile email groups";
          empty_scopes = false;
          auth_url = "https://auth.lan/api/oidc/authorization";
          token_url = "https://auth.lan/api/oidc/token";
          api_url = "https://auth.lan/api/oidc/userinfo";
          login_attribute_path = "preferred_username";
          groups_attribute_path = "groups";
          name_attribute_path = "name";
          use_pkce = true;
          allow_sign_up = true;
          auto_login = false;
          auth_style = "InHeader";
        };

        "auth" = {
          oauth_auto_login = false;
          disable_login_form = false;
        };
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
