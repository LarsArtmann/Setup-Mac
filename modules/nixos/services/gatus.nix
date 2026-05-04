_: {
  flake.nixosModules.gatus = {
    config,
    lib,
    ...
  }: let
    cfg = config.services.gatus-config;
    harden = import ../../../lib/systemd.nix;
    serviceDefaults = import ../../../lib/systemd/service-defaults.nix;
    inherit (config.networking) domain;
  in {
    options.services.gatus-config = {
      enable = lib.mkEnableOption "Gatus uptime monitor with SystemNix configuration";
    };

    config = lib.mkIf cfg.enable {
      services.gatus = {
        enable = true;
        openFirewall = true;

        settings = {
          web.port = 8100;

          alerting = {
            ntfy = {
              server-url = "https://ntfy.sh";
              topic = "gatus-systemnix";
            };
          };

          endpoints = [
            # ── Public Websites (Firebase Hosting) ────────────────
            {
              name = "artmann.tech";
              group = "Websites";
              url = "https://artmann.tech";
              interval = "2m";
              conditions = [
                "[STATUS] == 200"
                "[RESPONSE_TIME] < 2000"
                "[CERTIFICATE_EXPIRATION] > 14"
              ];
            }
            {
              name = "larsartmann.com";
              group = "Websites";
              url = "https://larsartmann.com";
              interval = "2m";
              conditions = [
                "[STATUS] == 200"
                "[RESPONSE_TIME] < 2000"
                "[CERTIFICATE_EXPIRATION] > 14"
              ];
            }
            {
              name = "lars.software";
              group = "Websites";
              url = "https://lars.software";
              interval = "2m";
              conditions = [
                "[STATUS] == 200"
                "[RESPONSE_TIME] < 2000"
                "[CERTIFICATE_EXPIRATION] > 14"
              ];
            }
            {
              name = "jetpackx.io";
              group = "Websites";
              url = "https://jetpackx.io";
              interval = "2m";
              conditions = [
                "[STATUS] == 200"
                "[RESPONSE_TIME] < 2000"
                "[CERTIFICATE_EXPIRATION] > 14"
              ];
            }
            {
              name = "issue-shield.com";
              group = "Websites";
              url = "https://issue-shield.com";
              interval = "2m";
              conditions = [
                "[STATUS] == 200"
                "[RESPONSE_TIME] < 2000"
                "[CERTIFICATE_EXPIRATION] > 14"
              ];
            }
            {
              name = "artmann-holding.com";
              group = "Websites";
              url = "https://artmann-holding.com";
              interval = "2m";
              conditions = [
                "[STATUS] == 200"
                "[RESPONSE_TIME] < 2000"
                "[CERTIFICATE_EXPIRATION] > 14"
              ];
            }
            {
              name = "extract-metadata.tech";
              group = "Websites";
              url = "https://extract-metadata.tech";
              interval = "2m";
              conditions = [
                "[STATUS] == 200"
                "[RESPONSE_TIME] < 2000"
                "[CERTIFICATE_EXPIRATION] > 14"
              ];
            }
            {
              name = "helpless.ai";
              group = "Websites";
              url = "https://helpless.ai";
              interval = "2m";
              conditions = [
                "[STATUS] == 200"
                "[RESPONSE_TIME] < 2000"
                "[CERTIFICATE_EXPIRATION] > 14"
              ];
            }

            # ── URL Redirects ──────────────────────────────────────
            {
              name = "artmann-technologies.com";
              group = "Redirects";
              url = "https://artmann-technologies.com";
              interval = "5m";
              conditions = [
                "[STATUS] == 301 || [STATUS] == 302 || [STATUS] == 200"
              ];
            }
            {
              name = "skylines.one";
              group = "Redirects";
              url = "https://skylines.one";
              interval = "5m";
              conditions = [
                "[STATUS] == 301 || [STATUS] == 302 || [STATUS] == 200"
              ];
            }

            # ── Custom Server ──────────────────────────────────────
            {
              name = "larsartmann.cloud";
              group = "Servers";
              url = "https://larsartmann.cloud";
              interval = "2m";
              conditions = [
                "[STATUS] == 200"
                "[RESPONSE_TIME] < 3000"
                "[CERTIFICATE_EXPIRATION] > 14"
              ];
            }

            # ── NixOS home.lan Services ────────────────────────────
            {
              name = "Authelia SSO";
              group = "NixOS Services";
              url = "https://auth.${domain}";
              interval = "1m";
              client = {insecure = true;};
              conditions = [
                "[STATUS] == 200 || [STATUS] == 401"
                "[RESPONSE_TIME] < 1000"
              ];
            }
            {
              name = "SigNoz";
              group = "NixOS Services";
              url = "https://signoz.${domain}";
              interval = "1m";
              client = {insecure = true;};
              conditions = [
                "[STATUS] == 200"
                "[RESPONSE_TIME] < 1000"
              ];
            }
            {
              name = "TaskChampion Sync";
              group = "NixOS Services";
              url = "https://tasks.${domain}";
              interval = "1m";
              client = {insecure = true;};
              conditions = [
                "[STATUS] == 200 || [STATUS] == 404"
                "[RESPONSE_TIME] < 1000"
              ];
            }
            {
              name = "Homepage Dashboard";
              group = "NixOS Services";
              url = "https://dash.${domain}";
              interval = "1m";
              client = {insecure = true;};
              conditions = [
                "[STATUS] == 200"
                "[RESPONSE_TIME] < 1000"
              ];
            }
            {
              name = "Immich";
              group = "NixOS Services";
              url = "https://immich.${domain}";
              interval = "1m";
              client = {insecure = true;};
              conditions = [
                "[STATUS] == 200"
                "[RESPONSE_TIME] < 2000"
              ];
            }
            {
              name = "Gitea";
              group = "NixOS Services";
              url = "https://gitea.${domain}";
              interval = "1m";
              client = {insecure = true;};
              conditions = [
                "[STATUS] == 200"
                "[RESPONSE_TIME] < 1000"
              ];
            }
            {
              name = "Photomap";
              group = "NixOS Services";
              url = "https://photomap.${domain}";
              interval = "2m";
              client = {insecure = true;};
              conditions = [
                "[STATUS] == 200"
                "[RESPONSE_TIME] < 2000"
              ];
            }
            {
              name = "Twenty CRM";
              group = "NixOS Services";
              url = "https://crm.${domain}";
              interval = "2m";
              client = {insecure = true;};
              conditions = [
                "[STATUS] == 200"
                "[RESPONSE_TIME] < 2000"
              ];
            }
            {
              name = "ComfyUI";
              group = "NixOS Services";
              url = "https://comfyui.${domain}";
              interval = "2m";
              client = {insecure = true;};
              conditions = [
                "[STATUS] == 200"
                "[RESPONSE_TIME] < 3000"
              ];
            }

            # ── DNS A-record checks ────────────────────────────────
            {
              name = "DNS: artmann.tech";
              group = "DNS";
              url = "udp://1.1.1.1:53";
              interval = "10m";
              dns = {
                query-name = "artmann.tech";
                query-type = "A";
              };
              conditions = ["[DNS_RCODE] == NOERROR"];
            }
            {
              name = "DNS: larsartmann.com";
              group = "DNS";
              url = "udp://1.1.1.1:53";
              interval = "10m";
              dns = {
                query-name = "larsartmann.com";
                query-type = "A";
              };
              conditions = ["[DNS_RCODE] == NOERROR"];
            }
            {
              name = "DNS: lars.software";
              group = "DNS";
              url = "udp://1.1.1.1:53";
              interval = "10m";
              dns = {
                query-name = "lars.software";
                query-type = "A";
              };
              conditions = ["[DNS_RCODE] == NOERROR"];
            }
            {
              name = "DNS: jetpackx.io";
              group = "DNS";
              url = "udp://1.1.1.1:53";
              interval = "10m";
              dns = {
                query-name = "jetpackx.io";
                query-type = "A";
              };
              conditions = ["[DNS_RCODE] == NOERROR"];
            }
            {
              name = "DNS: larsartmann.cloud";
              group = "DNS";
              url = "udp://1.1.1.1:53";
              interval = "10m";
              dns = {
                query-name = "larsartmann.cloud";
                query-type = "A";
              };
              conditions = ["[DNS_RCODE] == NOERROR"];
            }
            {
              name = "DNS: helpless.ai";
              group = "DNS";
              url = "udp://1.1.1.1:53";
              interval = "10m";
              dns = {
                query-name = "helpless.ai";
                query-type = "A";
              };
              conditions = ["[DNS_RCODE] == NOERROR"];
            }

            # ── Email MX-record checks ─────────────────────────────
            {
              name = "MX: artmann.tech";
              group = "Email DNS";
              url = "udp://1.1.1.1:53";
              interval = "1h";
              dns = {
                query-name = "artmann.tech";
                query-type = "MX";
              };
              conditions = ["[DNS_RCODE] == NOERROR"];
            }
            {
              name = "MX: larsartmann.com";
              group = "Email DNS";
              url = "udp://1.1.1.1:53";
              interval = "1h";
              dns = {
                query-name = "larsartmann.com";
                query-type = "MX";
              };
              conditions = ["[DNS_RCODE] == NOERROR"];
            }
            {
              name = "MX: lars.software";
              group = "Email DNS";
              url = "udp://1.1.1.1:53";
              interval = "1h";
              dns = {
                query-name = "lars.software";
                query-type = "MX";
              };
              conditions = ["[DNS_RCODE] == NOERROR"];
            }
            {
              name = "MX: issue-shield.com";
              group = "Email DNS";
              url = "udp://1.1.1.1:53";
              interval = "1h";
              dns = {
                query-name = "issue-shield.com";
                query-type = "MX";
              };
              conditions = ["[DNS_RCODE] == NOERROR"];
            }
            {
              name = "MX: artmann-holding.com";
              group = "Email DNS";
              url = "udp://1.1.1.1:53";
              interval = "1h";
              dns = {
                query-name = "artmann-holding.com";
                query-type = "MX";
              };
              conditions = ["[DNS_RCODE] == NOERROR"];
            }
            {
              name = "MX: helpless.ai";
              group = "Email DNS";
              url = "udp://1.1.1.1:53";
              interval = "1h";
              dns = {
                query-name = "helpless.ai";
                query-type = "MX";
              };
              conditions = ["[DNS_RCODE] == NOERROR"];
            }
          ];
        };
      };

      systemd.services.gatus = {
        startLimitBurst = 3;
        startLimitIntervalSec = 60;
        serviceConfig =
          harden {
            MemoryMax = "512M";
          }
          // serviceDefaults {};
      };
    };
  };
}
