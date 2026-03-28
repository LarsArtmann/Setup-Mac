# DNS Blocker - Declarative DNS with ad blocking and block pages
# Uses unbound + dnsblockd (Go HTTP server for block pages)
{lib, ...}: {
  imports = [
    ../modules/dns-blocker.nix
  ];

  services.dns-blocker = {
    enable = true;

    blockIP = "127.0.0.2";
    blockPort = 80;
    statsPort = 9090;

    blocklists = [
      {
        name = "StevenBlack-ads";
        url = "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts";
        hash = "sha256-Lhkn7vQHJc7RQKddUbafgwfR0koiUSr0Xoj27HLGWK0=";
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
    };
  };

  services.unbound.settings.server = {
    local-zone = [''"lan." static''];
    local-data = [''"immich.lan. IN A 127.0.0.1"''];
  };
}
