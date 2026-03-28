{
  pkgs,
  lib,
  config,
  ...
}: let
  # Script to mirror all user repos from GitHub
  mirrorGithubScript = pkgs.writeShellScriptBin "gitea-mirror-github" ''
    # Mirror all repos from GitHub to Gitea
    # Requires: GITEA_TOKEN, GITHUB_TOKEN, GITHUB_USER in ~/.config/gitea-sync.env
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
      echo "Create a token at https://github.com/settings/tokens (needs repo scope)"
      exit 1
    fi

    if [[ -z "$GITHUB_USER" ]]; then
      echo "Error: Could not detect GitHub username"
      echo "Set GITHUB_USER in ~/.config/gitea-sync.env"
      exit 1
    fi

    echo "Fetching repositories for GitHub user: $GITHUB_USER"

    # Handle pagination for users with many repos
    page=1
    repos=""
    while true; do
      response=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
        "https://api.github.com/users/$GITHUB_USER/repos?per_page=100&page=$page&type=all")
      echo "$response" | jq -r '.[] | "\(.name)|\(.clone_url)|\(.private)|\(.description // "")"' >> /tmp/gitea-repos-$$.txt
      [[ $(echo "$response" | jq 'length') -lt 100 ]] && break
      page=$((page + 1))
    done

    while IFS='|' read -r name clone_url private description; do
      [[ -z "$name" ]] && continue

      existing=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: token $GITEA_TOKEN" \
        "$GITEA_URL/api/v1/repos/$GITHUB_USER/$name")

      if [[ "$existing" == "200" ]]; then
        echo "✓ Already mirrored: $name"
        continue
      fi

      echo "→ Mirroring: $name"

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
    done < /tmp/gitea-repos-$$
    rm -f /tmp/gitea-repos-$$

    echo "✓ Done! $(wc -l < /dev/stdin) repos processed"
  '';

  # Script to mirror all starred repos from GitHub
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

    # Create org if it doesn't exist
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

    # Handle pagination
    page=1
    while true; do
      response=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
        "https://api.github.com/users/$GITHUB_USER/starred?per_page=100&page=$page")
      echo "$response" | jq -r '.[] | "\(.full_name)|\(.clone_url)|\(.description // "")"' >> /tmp/gitea-starred-$$.txt
      [[ $(echo "$response" | jq 'length') -lt 100 ]] && break
      page=$((page + 1))
    done

    while IFS='|' read -r full_name clone_url description; do
      [[ -z "$full_name" ]] && continue
      name=$(echo "$full_name" | tr '/' '-')

      existing=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: token $GITEA_TOKEN" \
        "$GITEA_URL/api/v1/repos/$GITEA_ORG/$name")

      if [[ "$existing" == "200" ]]; then
        echo "✓ Already mirrored: $name"
        continue
      fi

      echo "→ Mirroring: $full_name"

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
    done < /tmp/gitea-starred-$$
    rm -f /tmp/gitea-starred-$$

    echo "✓ Done!"
  '';

  # Setup helper script
  setupScript = pkgs.writeShellScriptBin "gitea-setup" ''
    # Initial Gitea setup helper
    set -euo pipefail

    echo "=== Gitea Setup Helper ==="
    echo ""
    echo "1. Gitea is running at: http://localhost:3000"
    echo "2. Create your admin account in the web UI"
    echo ""
    echo "3. Create tokens:"
    echo "   - Gitea: http://localhost:3000/user/settings/applications"
    echo "   - GitHub: https://github.com/settings/tokens/new (select 'repo' scope)"
    echo ""
    echo "4. Create credentials file:"
    echo ""
    echo "   mkdir -p ~/.config"
    echo "   cat > ~/.config/gitea-sync.env << 'EOF'"
    echo "   GITEA_TOKEN=your-gitea-token"
    echo "   GITHUB_TOKEN=your-github-token"
    echo "   GITHUB_USER=your-github-username"
    echo "   EOF"
    echo ""
    echo "5. Run initial sync:"
    echo "   gitea-mirror-github      # Mirror your repos"
    echo "   gitea-mirror-starred     # Mirror starred repos"
    echo ""
    echo "After setup, mirrors sync automatically every 30 minutes."
    echo ""
    echo "Status:"
    systemctl is-active gitea && echo "✓ Gitea service: running" || echo "✗ Gitea service: stopped"
    systemctl is-active gitea-github-sync.timer && echo "✓ Sync timer: active" || echo "✗ Sync timer: inactive"
  '';
in {
  services.gitea = {
    enable = true;
    package = pkgs.gitea;

    # SQLite is fine for personal use (<50 repos)
    database.type = "sqlite3";

    # Enable Git LFS support
    lfs.enable = true;

    # Automatic weekly backups
    dump = {
      enable = true;
      interval = "weekly";
    };

    stateDir = "/var/lib/gitea";

    settings = {
      DEFAULT.APP_NAME = "Local Git Mirror";

      server = {
        HTTP_PORT = 3000;
        ROOT_URL = "http://localhost:3000/";
        DOMAIN = "localhost";
      };

      repository = {
        DEFAULT_BRANCH = "main";
        ENABLE_PUSH_CREATE_USER = true;
        DEFAULT_PUSH_CREATE_PRIVATE = true;
      };

      # Mirror configuration
      mirror = {
        ENABLED = true;
        DEFAULT_INTERVAL = "8h";
        MIN_INTERVAL = "10m";
      };

      # Automatic mirror sync (runs every 30 min)
      "cron.update_mirrors" = {
        ENABLED = true;
        SCHEDULE = "@every 30m";
        RUN_AT_START = false;
        PULL_LIMIT = 50;
        PUSH_LIMIT = 50;
      };

      # UI preferences
      ui = {
        DEFAULT_THEME = "gitea-auto";
        THEMES = "gitea-auto,gitea-light,gitea-dark,arc-green";
      };

      # Security (single-user instance)
      service = {
        DISABLE_REGISTRATION = true;
        REQUIRE_SIGNIN_VIEW = false;
      };

      session = {
        COOKIE_SECURE = false; # localhost doesn't use HTTPS
      };

      # Logging
      log = {
        LEVEL = "Info";
        ROOT_PATH = "/var/lib/gitea/log";
      };

      # Performance tuning
      "git.timeout" = {
        MIRROR = 600;
        CLONE = 600;
        PULL = 600;
      };

      # Cleaner footer
      other = {
        SHOW_FOOTER_VERSION = false;
        SHOW_FOOTER_TEMPLATE_LOAD_TIME = false;
      };
    };
  };

  # Systemd configuration
  systemd = {
    # Restart on failure
    services.gitea = {
      serviceConfig = {
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };

    # GitHub sync service
    services.gitea-github-sync = {
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

    # Schedule sync every 6 hours
    timers.gitea-github-sync = {
      description = "Sync GitHub repos to Gitea every 6 hours";
      wantedBy = ["timers.target"];
      timerConfig = {
        OnBootSec = "5m";
        OnUnitActiveSec = "6h";
        Unit = "gitea-github-sync.service";
        Persistent = true;
      };
    };
  };

  # CLI tools
  environment.systemPackages = [
    mirrorGithubScript
    mirrorStarredScript
    setupScript
  ];
}
