{inputs, ...}: {
  flake.nixosModules.sops = {
    config,
    pkgs,
    ...
  }: {
    sops = {
      defaultSopsFile = ./../../../platforms/nixos/secrets/secrets.yaml;
      age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];

      secrets = {
        grafana_admin_password = {
          owner = "grafana";
          group = "grafana";
          restartUnits = ["grafana.service"];
        };
        grafana_secret_key = {
          owner = "grafana";
          group = "grafana";
          restartUnits = ["grafana.service"];
        };
        grafana_oauth_client_secret = {
          owner = "grafana";
          group = "grafana";
          restartUnits = ["grafana.service"];
        };
        gitea_token = {
          owner = "lars";
          group = "users";
          restartUnits = ["gitea-github-sync.service" "gitea-ensure-repos.service"];
        };
        github_token = {
          owner = "lars";
          group = "users";
          restartUnits = ["gitea-github-sync.service" "gitea-ensure-repos.service"];
        };
        github_user = {
          owner = "lars";
          group = "users";
          restartUnits = ["gitea-github-sync.service" "gitea-ensure-repos.service"];
        };

        authelia_jwt_secret = {
          owner = "authelia-main";
          group = "authelia-main";
          restartUnits = ["authelia-main.service"];
        };
        authelia_storage_encryption_key = {
          owner = "authelia-main";
          group = "authelia-main";
          restartUnits = ["authelia-main.service"];
        };
        authelia_oidc_hmac_secret = {
          owner = "authelia-main";
          group = "authelia-main";
          restartUnits = ["authelia-main.service"];
        };
        authelia_oidc_issuer_private_key = {
          owner = "authelia-main";
          group = "authelia-main";
          mode = "0400";
          restartUnits = ["authelia-main.service"];
        };

        dnsblockd_ca_cert = {
          sopsFile = ./../../../platforms/nixos/secrets/dnsblockd-certs.yaml;
          restartUnits = ["dnsblockd.service"];
        };
        dnsblockd_ca_key = {
          sopsFile = ./../../../platforms/nixos/secrets/dnsblockd-certs.yaml;
          mode = "0400";
          restartUnits = ["dnsblockd.service"];
        };
        dnsblockd_server_cert = {
          sopsFile = ./../../../platforms/nixos/secrets/dnsblockd-certs.yaml;
          owner = "caddy";
          group = "caddy";
          restartUnits = ["caddy.service"];
        };
        dnsblockd_server_key = {
          sopsFile = ./../../../platforms/nixos/secrets/dnsblockd-certs.yaml;
          owner = "caddy";
          group = "caddy";
          mode = "0400";
          restartUnits = ["caddy.service"];
        };
      };

      templates."gitea-sync.env" = {
        owner = "lars";
        group = "users";
        content = ''
          GITHUB_TOKEN=${config.sops.placeholder.github_token}
          GITHUB_USER=${config.sops.placeholder.github_user}
        '';
      };
    };
  };
}
