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
        gitea_token = {
          owner = "lars";
          group = "users";
          restartUnits = ["gitea-github-sync.service"];
        };
        github_token = {
          owner = "lars";
          group = "users";
          restartUnits = ["gitea-github-sync.service"];
        };
        github_user = {
          owner = "lars";
          group = "users";
          restartUnits = ["gitea-github-sync.service"];
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
