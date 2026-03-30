# DNS Blocker - Declarative DNS with ad blocking and block pages
# Uses unbound + dnsblockd (Go HTTP server for block pages)
#
# Coverage: ~1.9M unique domains across 15 blocklists
# - Ads, malware, phishing, scams, fakenews, gambling, porn, social trackers
# - DNS-over-HTTPS bypass prevention
# - Native telemetry: Apple, Amazon, Samsung, Xiaomi, Huawei, LG WebOS,
#   Oppo/Realme, Roku, Vivo, Windows/Office, TikTok
{lib, ...}: {
  imports = [
    ../modules/dns-blocker.nix
  ];

  services.dns-blocker = {
    enable = true;

    blockIP = "192.168.1.163";
    blockPort = 80;
    blockTLSPort = 443;
    blockInterface = "enp1s0";
    blockIPPrefix = 24;
    statsPort = 9090;

    blocklists = [
      # StevenBlack unified: ads + malware + fakenews + gambling + porn + social (~183K)
      {
        name = "StevenBlack-everything";
        url = "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling-porn-social/hosts";
        hash = "sha256-3n8FyZl6oqbKJaMe/46bX1JHXdUfJVqz5hcemq5CkwI=";
      }
      # HaGeZi Ultimate: comprehensive ad/tracker/scam/clickbait blocking (~541K)
      {
        name = "HaGeZi-ultimate";
        url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/ultimate.txt";
        hash = "sha256-vfkr6+lekvhWMucKjM+PE4km9+ZkIv0cLxYjEYwGhM0=";
      }
      # HaGeZi Tracker Interference: blocks anti-DNS tracking countermeasures (~1M)
      {
        name = "HaGeZi-tif";
        url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/tif.txt";
        hash = "sha256-rA8vqgWaFQqOiszkTpwze6ooTBald+PLcyFwDLvD1D4=";
      }
      # HaGeZi DNS-over-HTTPS: prevent bypassing DNS via DoH (~4K)
      {
        name = "HaGeZi-doh";
        url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/doh.txt";
        hash = "sha256-FHHiqo/cT/6FoHl4NKk8l249xRAH0pvvlJm1A8nAnGM=";
      }
      # HaGeZi Native telemetry - Apple
      {
        name = "HaGeZi-native-apple";
        url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/native.apple.txt";
        hash = "sha256-iDNL4t9MUCCP0HfnbKi1TNu43luErKcJI/KZodzV5jA=";
      }
      # HaGeZi Native telemetry - Amazon
      {
        name = "HaGeZi-native-amazon";
        url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/native.amazon.txt";
        hash = "sha256-qmTShV7kjfZ+yDnxjxOJAjxuM3hKU5Qy6AZJEDDFaQ4=";
      }
      # HaGeZi Native telemetry - Samsung
      {
        name = "HaGeZi-native-samsung";
        url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/native.samsung.txt";
        hash = "sha256-L/ag8CukXGwqmP1Mxz3f5A5o5tRSOKQsqFaXB1mcikM=";
      }
      # HaGeZi Native telemetry - Xiaomi
      {
        name = "HaGeZi-native-xiaomi";
        url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/native.xiaomi.txt";
        hash = "sha256-ZcwN1KdvE9n5AuMzpJ6ESIlpAq+EkXlBz+F+YFFBF+g=";
      }
      # HaGeZi Native telemetry - Huawei
      {
        name = "HaGeZi-native-huawei";
        url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/native.huawei.txt";
        hash = "sha256-Q5Cxf6BZqW4uTTZxZpc/LNj6qFjXAv8GxGFyWIdw+Yw=";
      }
      # HaGeZi Native telemetry - LG WebOS
      {
        name = "HaGeZi-native-lgwebos";
        url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/native.lgwebos.txt";
        hash = "sha256-7oxVOVxGKvV3hEv8TsvjpqEDovzpFMOU8m3oJceZ9zw=";
      }
      # HaGeZi Native telemetry - Oppo/Realme
      {
        name = "HaGeZi-native-oppo-realme";
        url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/native.oppo-realme.txt";
        hash = "sha256-LqnphPEYyTyR9GalRhYWRHZXCrXR+gpviK+qHxvI37s=";
      }
      # HaGeZi Native telemetry - Roku
      {
        name = "HaGeZi-native-roku";
        url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/native.roku.txt";
        hash = "sha256-hAiQ5KVJDnsV/t+iuNhzDfjTbexdZsO3ab/Hcs49/Po=";
      }
      # HaGeZi Native telemetry - Vivo
      {
        name = "HaGeZi-native-vivo";
        url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/native.vivo.txt";
        hash = "sha256-q4F1xGp7E/AUNm5MI4ctXDk0HhxskjL2S9X9dnd7PDk=";
      }
      # HaGeZi Native telemetry - Windows/Office
      {
        name = "HaGeZi-native-winoffice";
        url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/native.winoffice.txt";
        hash = "sha256-oYxCzmggNG5biolQLwNNg3wrBIgqKZ3KUEykNUAm13w=";
      }
      # HaGeZi Native - TikTok extended blocking
      {
        name = "HaGeZi-native-tiktok-extended";
        url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/native.tiktok.extended.txt";
        hash = "sha256-+9dqc3cJD2FUPpDW4YgfFs++B7HbYBapRdwj+vOnWaI=";
      }
    ];

    whitelist = [
      "api.immich.app"
      "immich.app"
      "github.com"
      "github-releases.githubusercontent.com"
      "objects.githubusercontent.com"
      "nominatim.openstreetmap.org"
      "tile.openstreetmap.org"
      "huggingface.co"
      "cdn-lfs.huggingface.co"
      "cdn-lfs-us-1.huggingface.co"
    ];

    extraDomains = [
      "360.cn"
      "www.360.cn"
    ];

    upstreamDNS = [
      "9.9.9.9@853#dns.quad9.net"
      "1.1.1.1@853#cloudflare-dns.com"
    ];

    enableDNSSEC = true;

    categories = {
      ".doubleclick.net" = "Advertising";
      ".googlesyndication.com" = "Advertising";
      ".googleadservices.com" = "Advertising";
      ".adnxs.com" = "Advertising";
      ".adsrvr.org" = "Advertising";
      ".facebook.net" = "Tracking";
      ".analytics.google.com" = "Analytics";
      ".google-analytics.com" = "Analytics";
      ".pornhub.com" = "Adult Content";
      ".xvideos.com" = "Adult Content";
      ".xnxx.com" = "Adult Content";
      ".redtube.com" = "Adult Content";
      ".onlyfans.com" = "Adult Content";
      ".chaturbate.com" = "Adult Content";
      ".tiktok.com" = "Social Media";
      ".tiktokcdn.com" = "Social Media";
    };
  };

  services.unbound.settings.server = {
    local-zone = [''"lan." static''];
    local-data = [
      ''"immich.lan. IN A 192.168.1.162"''
      ''"gitea.lan. IN A 192.168.1.162"''
      ''"grafana.lan. IN A 192.168.1.162"''
      ''"home.lan. IN A 192.168.1.162"''
      ''"photomap.lan. IN A 192.168.1.162"''
    ];
  };
}
