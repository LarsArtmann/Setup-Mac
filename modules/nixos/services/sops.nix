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
          sopsFile = ./../../../platforms/nixos/secrets/authelia-secrets.yaml;
          owner = "authelia-main";
          group = "authelia-main";
          restartUnits = ["authelia-main.service"];
        };
        authelia_storage_encryption_key = {
          sopsFile = ./../../../platforms/nixos/secrets/authelia-secrets.yaml;
          owner = "authelia-main";
          group = "authelia-main";
          restartUnits = ["authelia-main.service"];
        };
        authelia_oidc_hmac_secret = {
          sopsFile = ./../../../platforms/nixos/secrets/authelia-secrets.yaml;
          owner = "authelia-main";
          group = "authelia-main";
          restartUnits = ["authelia-main.service"];
        };
        authelia_oidc_issuer_private_key = {
          sopsFile = ./../../../platforms/nixos/secrets/authelia-secrets.yaml;
          owner = "authelia-main";
          group = "authelia-main";
          mode = "0400";
          restartUnits = ["authelia-main.service"];
        };

        immich_oauth_client_secret = {
          sopsFile = ./../../../platforms/nixos/secrets/authelia-secrets.yaml;
          owner = "immich";
          group = "immich";
          restartUnits = ["immich-server.service"];
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

        livekit_keys = {
          sopsFile = ./../../../platforms/nixos/secrets/voice-agents.yaml;
          restartUnits = ["livekit.service"];
        };

        hermes_discord_bot_token = {
          sopsFile = ./../../../platforms/nixos/secrets/hermes.yaml;
          owner = "lars";
          group = "users";
          restartUnits = ["hermes-gateway.service"];
        };
        hermes_glm_api_key = {
          sopsFile = ./../../../platforms/nixos/secrets/hermes.yaml;
          owner = "lars";
          group = "users";
          restartUnits = ["hermes-gateway.service"];
        };
        hermes_minimax_api_key = {
          sopsFile = ./../../../platforms/nixos/secrets/hermes.yaml;
          owner = "lars";
          group = "users";
          restartUnits = ["hermes-gateway.service"];
        };
        hermes_fal_key = {
          sopsFile = ./../../../platforms/nixos/secrets/hermes.yaml;
          owner = "lars";
          group = "users";
          restartUnits = ["hermes-gateway.service"];
        };
        hermes_firecrawl_api_key = {
          sopsFile = ./../../../platforms/nixos/secrets/hermes.yaml;
          owner = "lars";
          group = "users";
          restartUnits = ["hermes-gateway.service"];
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

      templates."hermes-env" = {
        owner = "lars";
        group = "users";
        content = ''
          DISCORD_BOT_TOKEN=${config.sops.placeholder.hermes_discord_bot_token}
          GLM_API_KEY=${config.sops.placeholder.hermes_glm_api_key}
          MINIMAX_API_KEY=${config.sops.placeholder.hermes_minimax_api_key}
          FAL_KEY=${config.sops.placeholder.hermes_fal_key}
          FIRECRAWL_API_KEY=${config.sops.placeholder.hermes_firecrawl_api_key}
          OLLAMA_API_KEY=ollama
          TERMINAL_ENV=local
        '';
      };
    };
  };
}
