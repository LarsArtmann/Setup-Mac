_: {
  flake.nixosModules.homepage = {
    config,
    pkgs,
    lib,
    ...
  }: let
    cfg = config.services.homepage;
    inherit (config.networking) domain;
    port = 8082;
    stateDir = "/var/lib/homepage-dashboard";

    svcUrl = subdomain: "https://${subdomain}.${domain}";
    harden = import ../../../lib/systemd.nix;
  in {
    options.services.homepage = {
      enable = lib.mkEnableOption "Homepage Dashboard service";
    };

    config = lib.mkIf cfg.enable {
      systemd.services.homepage-dashboard = {
        description = "Homepage Dashboard";
        wantedBy = ["multi-user.target"];
        after = ["network.target"];
        serviceConfig =
          {
            ExecStart = "${pkgs.homepage-dashboard}/bin/homepage";
            WorkingDirectory = stateDir;
            Environment = [
              "PORT=${toString port}"
              "HOMEPAGE_CONFIG_DIR=${stateDir}"
            ];
            User = "homepage";
            Group = "homepage";
            StateDirectory = "homepage-dashboard";
          }
          // harden {}
          // {
            Restart = lib.mkForce "on-failure";
            RestartSec = lib.mkForce "5s";
            StartLimitBurst = lib.mkForce 3;
            StartLimitIntervalSec = lib.mkForce 300;
            WatchdogSec = lib.mkForce "30";
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
          Productivity:
            style: row
            columns: 4
          Monitoring:
            style: row
            columns: 4
      '';

      environment.etc."homepage/services.yaml".source = pkgs.writeText "homepage-services.yaml" ''
        - Infrastructure:
            - Authelia:
                href: ${svcUrl "auth"}
                description: SSO & Identity Provider
                icon: authelia.png
                statusStyle: dot
                siteMonitor: ${svcUrl "auth"}/api/health
            - Caddy:
                href: ${svcUrl "dash"}
                description: Reverse Proxy
                icon: caddy.png
                statusStyle: dot
                siteMonitor: ${svcUrl "dash"}
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
                href: ${svcUrl "immich"}
                description: Photo & Video Management
                icon: immich.png
                statusStyle: dot
                siteMonitor: ${svcUrl "immich"}/api/server-info/ping
            - PhotoMapAI:
                href: ${svcUrl "photomap"}
                description: CLIP Embedding Vector Map
                icon: network-map.png
                statusStyle: dot
                siteMonitor: ${svcUrl "photomap"}
            - DNS Blocker:
                href: http://localhost:9090/stats
                description: DNS Block Stats
                icon: shield.png
                statusStyle: dot
                siteMonitor: http://localhost:9090/health

        - Development:
            - Gitea:
                href: ${svcUrl "gitea"}
                description: Git Mirror (GitHub Sync)
                icon: gitea.png
                statusStyle: dot
                siteMonitor: ${svcUrl "gitea"}/api/v1/nodeinfo
            - Ollama:
                description: Local AI Inference
                icon: ollama.png
                statusStyle: dot
                siteMonitor: http://localhost:11434/api/tags
            - Unsloth Studio:
                href: ${svcUrl "unsloth"}
                description: AI Model Training & Inference UI
                icon: jupyter.png
                statusStyle: dot
                siteMonitor: ${svcUrl "unsloth"}

        - Monitoring:
            - SigNoz:
                href: ${svcUrl "signoz"}
                description: Observability Platform (Traces, Metrics, Logs)
                icon: signoz.png
                statusStyle: dot
                siteMonitor: ${svcUrl "signoz"}
            - Node Exporter:
                description: System Metrics (CPU, RAM, Disk, Network)
                icon: prometheus.png
                statusStyle: dot
                siteMonitor: http://localhost:9100/metrics
            - cAdvisor:
                description: Container Metrics
                icon: docker.png
                statusStyle: dot
                siteMonitor: http://localhost:9110/metrics
            - dnsblockd:
                description: DNS Block Page Server
                icon: shield.png
                statusStyle: dot
                siteMonitor: http://localhost:9090/metrics
            - EMEET PIXY:
                description: Webcam Auto-Management Daemon
                icon: camera.png
                statusStyle: dot
                siteMonitor: http://localhost:8090/metrics

        - Productivity:
            - Twenty CRM:
                href: ${svcUrl "crm"}
                description: Customer Relationship Management
                icon: twenty.png
                statusStyle: dot
                siteMonitor: ${svcUrl "crm"}/healthz
            - Taskwarrior:
                href: ${svcUrl "tasks"}
                description: Task Sync Server (TaskChampion)
                icon: taskwarrior.png
                statusStyle: dot
                siteMonitor: ${svcUrl "tasks"}

            - Homepage:
                description: This Page
                icon: homepage.png
                statusStyle: dot
                siteMonitor: ${svcUrl "dash"}
      '';

      systemd.tmpfiles.rules = [
        "d ${stateDir} 0755 homepage homepage -"
        "L+ ${stateDir}/services.yaml - - - - /etc/homepage/services.yaml"
        "L+ ${stateDir}/settings.yaml - - - - /etc/homepage/settings.yaml"
        "L+ ${stateDir}/bookmarks.yaml - - - - ${pkgs.writeText "bookmarks.yaml" ""}"
        "L+ ${stateDir}/widgets.yaml - - - - ${pkgs.writeText "widgets.yaml" ''
          - greeting:
              text: evo-x2 Dashboard
          - resources:
              cpu: true
              memory: true
              disk: /
              uptime: true
        ''}"
        "L+ ${stateDir}/docker.yaml - - - - ${pkgs.writeText "docker.yaml" ""}"
      ];
    };
  };
}
