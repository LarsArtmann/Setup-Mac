# DNS Blocker - Declarative DNS with ad blocking and block pages
# Uses unbound + dnsblockd (Go HTTP server for block pages)
#
# Coverage: ~2.5M+ unique domains across 25 blocklists
# - Ads, malware, phishing, scams, fakenews, gambling, porn, social trackers
# - DNS-over-HTTPS/VPN/TOR/Proxy bypass prevention
# - Native telemetry: Apple, Amazon, Samsung, Xiaomi, Huawei, LG WebOS,
#   Oppo/Realme, Roku, Vivo, Windows/Office, TikTok
# - DGA/NRD blocking, anti-piracy, NSFW, social, gambling, URL shorteners
# - Dynamic DNS, badware hosters, safesearch enforcement
#
# Blocklists are shared with rpi3-dns via platforms/shared/dns-blocklists.nix
# DNS resolution: full recursive from root hints (no third-party resolver)
{config, ...}: let
  inherit (config.networking) domain;
  inherit (config.networking.local) blockIP virtualIP;
  blocklists = import ../../shared/dns-blocklists.nix;
  lanIP =
    builtins.head
    config.networking.interfaces.eno1.ipv4.addresses;
  serverIP = lanIP.address;
in {
  imports = [
    ../modules/dns-blocker.nix
  ];

  services = {
    dns-blocker = {
      enable = true;

      inherit blockIP;
      blockPort = 80;
      blockTLSPort = 443;
      blockInterface = "eno1";
      blockIPPrefix = 24;
      statsPort = 9090;

      inherit (blocklists) blocklists whitelist extraDomains categories;

      enableDNSSEC = true;

      # DoQ (DNS-over-QUIC) port — RFC 9250, uses QUIC transport encryption
      # No TLS certificates needed — QUIC handles encryption natively
      # DISABLED: the unboundDoQOverlay that patches unbound for DoQ support
      # kills binary cache hits (cascades to ffmpeg, linux, pipewire, etc.)
      # doqPort = 853;

      # Temporarily allow all DNS queries (disable blocking)
      # Set to true to bypass all DNS blocking
      tempAllowAll = false;
    };

    unbound.settings.server = {
      local-zone = [''"${domain}." static''];
      local-data =
        map
        (subdomain: ''"${subdomain}.${domain}. IN A ${serverIP}"'')
        ["auth" "immich" "gitea" "dash" "photomap" "signoz" "tasks" "crm" "manifest"];
    };

    dns-failover = {
      enable = true;
      inherit virtualIP;
      interface = "eno1";
      priority = 100;
      routerID = 53;
      subnetPrefix = 24;
      authPassword = "DNSClusterVRRP-evox2";
    };
  };
}
