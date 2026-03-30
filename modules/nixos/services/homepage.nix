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
          - Caddy:
              href: http://immich.lan
              description: Reverse Proxy
              icon: caddy.png
              ping: localhost:80
          - Unbound DNS:
              description: DNS Resolver + Blocker
              icon: unbound.png
              ping: localhost:53
          - PostgreSQL:
              description: Database Server
              icon: postgres.png
              ping: localhost:5432
          - Redis:
              description: Cache (Immich)
              icon: redis.png
              ping: localhost:6379

      - Media:
          - Immich:
              href: http://immich.lan
              description: Photo & Video Management
              icon: immich.png
              ping: localhost:2283
          - PhotoMapAI:
              href: http://photomap.lan
              description: CLIP Embedding Vector Map
              icon: network-map.png
              ping: localhost:8050
          - DNS Blocker:
              href: http://localhost:9090/stats
              description: DNS Block Stats
              icon: shield.png
              ping: localhost:9090

      - Development:
          - Gitea:
              href: http://gitea.lan
              description: Git Mirror (GitHub Sync)
              icon: gitea.png
              ping: localhost:3000
          - Ollama:
              description: Local AI Inference
              icon: ollama.png
              ping: localhost:11434

      - Monitoring:
          - Grafana:
              href: http://grafana.lan
              description: Metrics & Dashboards
              icon: grafana.png
              ping: localhost:3001
          - Prometheus:
              description: Metrics Collection
              icon: prometheus.png
              ping: localhost:9091
          - Node Exporter:
              description: System Metrics Agent
              icon: prometheus.png
              ping: localhost:9100
          - Homepage:
              description: This Page
              icon: homepage.png
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
