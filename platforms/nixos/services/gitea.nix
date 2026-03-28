{
  pkgs,
  lib,
  config,
  ...
}: let
  mirrorGithubScript = pkgs.writeShellScriptBin "gitea-mirror-github" ''
    # Mirror all repos from GitHub to Gitea
    set -euo pipefail

    GITEA_URL="http://localhost:3000"
    GITEA_TOKEN="''${GITEA_TOKEN:-}"
    GITHUB_TOKEN="''${GITHUB_TOKEN:-}"
    GITHUB_USER="''${GITHUB_USER:-$(gh api user -q .login 2>/dev/null || echo "")}"

    if [[ -z "$GITEA_TOKEN" ]]; then
      echo "Error: GITEA_TOKEN not set"
      echo "Create a token at http://localhost:3000/user/settings/applications"
      exit 1
    fi

    if [[ -z "$GITHUB_TOKEN" ]]; then
      echo "Error: GITHUB_TOKEN not set"
      echo "Create a token at https://github.com/settings/tokens"
      exit 1
    fi

    if [[ -z "$GITHUB_USER" ]]; then
      echo "Error: Could not detect GitHub username"
      echo "Set GITHUB_USER environment variable"
      exit 1
    fi

    echo "Fetching repositories for GitHub user: $GITHUB_USER"

    repos=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
      "https://api.github.com/users/$GITHUB_USER/repos?per_page=100&type=all" | \
      jq -r '.[] | "\(.name)|\(.clone_url)|\(.private)|\(.description // "")"')

    while IFS='|' read -r name clone_url private description; do
      [[ -z "$name" ]] && continue

      existing=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: token $GITEA_TOKEN" \
        "$GITEA_URL/api/v1/repos/$GITHUB_USER/$name")

      if [[ "$existing" == "200" ]]; then
        echo "Already mirrored: $name"
        continue
      fi

      echo "Mirroring: $name"

      curl -s -X POST \
        -H "Authorization: token $GITEA_TOKEN" \
        -H "Content-Type: application/json" \
        "$GITEA_URL/api/v1/repos/migrate" \
        -d "$(jq -n \
          --arg name "$name" \
          --arg clone_url "$clone_url" \
          --argjson private "$private" \
          --arg description "$description" \
          --arg uid "1" \
          '{
            clone_addr: $clone_url,
            repo_name: $name,
            uid: ($uid | tonumber),
            private: $private,
            description: $description,
            mirror: true,
            wiki: true,
            labels: true,
            issues: true,
            pull_requests: true,
            releases: true,
            milestones: true,
            service: "git"
          }')"
    done <<< "$repos"

    echo "Done!"
  '';

  mirrorStarredScript = pkgs.writeShellScriptBin "gitea-mirror-starred" ''
    # Mirror all starred repos from GitHub to Gitea
    set -euo pipefail

    GITEA_URL="http://localhost:3000"
    GITEA_TOKEN="''${GITEA_TOKEN:-}"
    GITHUB_TOKEN="''${GITHUB_TOKEN:-}"
    GITHUB_USER="''${GITHUB_USER:-$(gh api user -q .login 2>/dev/null || echo "")}"
    GITEA_ORG="starred"

    if [[ -z "$GITEA_TOKEN" ]]; then
      echo "Error: GITEA_TOKEN not set"
      exit 1
    fi

    if [[ -z "$GITHUB_TOKEN" ]]; then
      echo "Error: GITHUB_TOKEN not set"
      exit 1
    fi

    curl -s -o /dev/null -w "%{http_code}" \
      -H "Authorization: token $GITEA_TOKEN" \
      "$GITEA_URL/api/v1/orgs/$GITEA_ORG" | grep -q "200" || {
      echo "Creating organization: $GITEA_ORG"
      curl -s -X POST \
        -H "Authorization: token $GITEA_TOKEN" \
        -H "Content-Type: application/json" \
        "$GITEA_URL/api/v1/orgs" \
        -d "{\"username\":\"$GITEA_ORG\",\"full_name\":\"Starred Repositories\"}"
    }

    echo "Fetching starred repositories..."

    repos=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
      "https://api.github.com/users/$GITHUB_USER/starred?per_page=100" | \
      jq -r '.[] | "\(.full_name)|\(.clone_url)|\(.description // "")"')

    while IFS='|' read -r full_name clone_url description; do
      [[ -z "$full_name" ]] && continue
      name=$(echo "$full_name" | tr '/' '-')

      existing=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: token $GITEA_TOKEN" \
        "$GITEA_URL/api/v1/repos/$GITEA_ORG/$name")

      if [[ "$existing" == "200" ]]; then
        echo "Already mirrored: $name"
        continue
      fi

      echo "Mirroring: $full_name -> $name"

      curl -s -X POST \
        -H "Authorization: token $GITEA_TOKEN" \
        -H "Content-Type: application/json" \
        "$GITEA_URL/api/v1/repos/migrate" \
        -d "$(jq -n \
          --arg name "$name" \
          --arg clone_url "$clone_url" \
          --arg description "$description" \
          --arg org "$GITEA_ORG" \
          '{
            clone_addr: $clone_url,
            repo_name: $name,
            org: $org,
            private: false,
            description: $description,
            mirror: true,
            wiki: true,
            labels: true,
            issues: true,
            pull_requests: true,
            releases: true,
            milestones: true,
            service: "git"
          }')"
    done <<< "$repos"

    echo "Done!"
  '';
in {
  services.gitea = {
    enable = true;
    package = pkgs.gitea;

    settings = {
      server = {
        HTTP_PORT = 3000;
        ROOT_URL = "http://localhost:3000/";
        DOMAIN = "localhost";
      };

      repository = {
        DEFAULT_BRANCH = "main";
        ENABLE_PUSH_CREATE_USER = true;
      };

      mirror = {
        ENABLED = true;
        DEFAULT_INTERVAL = "8h";
        MIN_INTERVAL = "10m";
      };

      cron.update_mirrors = {
        ENABLED = true;
        SCHEDULE = "@every 30m";
        RUN_AT_START = false;
        PULL_LIMIT = 50;
        PUSH_LIMIT = 50;
      };

      ui = {
        DEFAULT_THEME = "gitea-auto";
        THEMES = "gitea-auto,gitea-light,gitea-dark,arc-green";
      };

      service = {
        DISABLE_REGISTRATION = true;
        REQUIRE_SIGNIN_VIEW = false;
      };

      session = {
        COOKIE_SECURE = false;
      };

      log = {
        LEVEL = "Info";
        ROOT_PATH = "/var/lib/gitea/log";
      };
    };

    database = {
      type = "sqlite3";
    };

    stateDir = "/var/lib/gitea";
  };

  systemd.services.gitea = {
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };

  systemd.services.gitea-github-sync = {
    description = "Sync all GitHub repos to Gitea";
    after = ["gitea.service" "network-online.target"];
    wants = ["network-online.target"];
    requires = ["gitea.service"];
    path = [pkgs.curl pkgs.jq pkgs.gh];
    serviceConfig = {
      Type = "oneshot";
      User = "lars";
      EnvironmentFile = "-/home/lars/.config/gitea-sync.env";
      ExecStart = "${mirrorGithubScript}/bin/gitea-mirror-github";
    };
  };

  systemd.timers.gitea-github-sync = {
    description = "Sync GitHub repos to Gitea every 6 hours";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnBootSec = "5m";
      OnUnitActiveSec = "6h";
      Unit = "gitea-github-sync.service";
    };
  };

  environment.systemPackages = [
    mirrorGithubScript
    mirrorStarredScript
  ];
}
