{inputs, ...}: {
  flake.nixosModules.homepage = {
    config,
    pkgs,
    ...
  }: let
    port = 8082;
    stateDir = "/var/lib/homepage-dashboard";
  in {
    systemd.services.homepage-dashboard = {
      description = "Homepage Dashboard";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];
      serviceConfig = {
        ExecStart = "${pkgs.homepage-dashboard}/bin/homepage";
        WorkingDirectory = stateDir;
        Environment = [
          "PORT=${toString port}"
          "HOMEPAGE_CONFIG_DIR=${stateDir}"
        ];
        User = "homepage";
        Group = "homepage";
        StateDirectory = "homepage-dashboard";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };

    users.users.homepage = {
      isSystemUser = true;
      group = "homepage";
      home = stateDir;
    };
    users.groups.homepage = {};

    environment.etc."homepage/settings.yaml".source = pkgs.writeText "homepage-settings.yaml" ''
      title: evo-x2
      favicon: https://raw.githubusercontent.com/walkxcode/dashboard-icons/main/png/nixos.png
      theme: dark
      color: slate
      headerStyle: boxed
      layout:
        Infrastructure:
          style: row
          columns: 4
        Media:
          style: row
          columns: 4
        Development:
          style: row
          columns: 4
        Monitoring:
          style: row
          columns: 4
    '';

    environment.etc."homepage/services.yaml".source = pkgs.writeText "homepage-services.yaml" ''
      - Infrastructure:
          - Authelia:
              href: https://auth.home.lan
              description: SSO & Identity Provider
              icon: authelia.png
              statusStyle: dot
              siteMonitor: https://auth.home.lan/api/health
          - Caddy:
              href: https://dash.home.lan
              description: Reverse Proxy
              icon: caddy.png
              statusStyle: dot
              siteMonitor: https://dash.home.lan
          - Unbound DNS:
              description: DNS Resolver + Blocker
              icon: unbound.png
              statusStyle: dot
              # DNS runs on UDP/TCP 53 - no HTTP health check available
          - PostgreSQL:
              description: Database Server
              icon: postgres.png
          - Redis:
              description: Cache (Immich)
              icon: redis.png

      - Media:
          - Immich:
              href: https://immich.home.lan
              description: Photo & Video Management
              icon: immich.png
              statusStyle: dot
              siteMonitor: https://immich.home.lan/api/server-info/ping
          - PhotoMapAI:
              href: https://photomap.home.lan
              description: CLIP Embedding Vector Map
              icon: network-map.png
              statusStyle: dot
              siteMonitor: https://photomap.home.lan
          - DNS Blocker:
              href: https://localhost:8443/stats
              description: DNS Block Stats
              icon: shield.png
              statusStyle: dot
              siteMonitor: https://localhost:8443

      - Development:
          - Gitea:
              href: https://gitea.home.lan
              description: Git Mirror (GitHub Sync)
              icon: gitea.png
              statusStyle: dot
              siteMonitor: https://gitea.home.lan/api/v1/nodeinfo
          - Ollama:
              description: Local AI Inference
              icon: ollama.png
              statusStyle: dot
              siteMonitor: http://localhost:11434/api/tags
          - Unsloth Studio:
              href: https://unsloth.home.lan
              description: AI Model Training & Inference UI
              icon: jupyter.png
              statusStyle: dot
              siteMonitor: https://unsloth.home.lan

      - Monitoring:
          - SigNoz:
              href: https://signoz.home.lan
              description: Observability Platform
              icon: signoz.png
              statusStyle: dot
              siteMonitor: https://signoz.home.lan
          - Homepage:
              description: This Page
              icon: homepage.png
              statusStyle: dot
              siteMonitor: https://dash.home.lan
    '';

    systemd.tmpfiles.rules = [
      "d ${stateDir} 0755 homepage homepage -"
      "L+ ${stateDir}/services.yaml - - - - /etc/homepage/services.yaml"
      "L+ ${stateDir}/settings.yaml - - - - /etc/homepage/settings.yaml"
      "L+ ${stateDir}/bookmarks.yaml - - - - ${pkgs.writeText "bookmarks.yaml" ""}"
      "L+ ${stateDir}/widgets.yaml - - - - ${pkgs.writeText "widgets.yaml" ""}"
      "L+ ${stateDir}/docker.yaml - - - - ${pkgs.writeText "docker.yaml" ""}"
    ];
  };
}
