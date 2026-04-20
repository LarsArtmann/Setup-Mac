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
{config, ...}: let
  inherit (config.networking) domain;
  lanIP =
    builtins.head
    config.networking.interfaces.eno1.ipv4.addresses;
  serverIP = lanIP.address;
in {
  imports = [
    ../modules/dns-blocker.nix
  ];

  services.dns-blocker = {
    enable = true;

    blockIP = serverIP;
    blockPort = 80;
    blockTLSPort = 8443;
    blockInterface = "eno1";
    blockIPPrefix = 24;
    statsPort = 9090;

    blocklists = [
      # StevenBlack unified: ads + malware + fakenews + gambling + porn + social (~183K)
      {
        name = "StevenBlack-everything";
        url = "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling-porn-social/hosts";
        hash = "sha256-jba4GaVjtS0CvxeYnkh1MqQeneY8Cm2Af16RhRgazAE=";
      }
      # HaGeZi Ultimate: comprehensive ad/tracker/scam/clickbait blocking (~541K)
      {
        name = "HaGeZi-ultimate";
        url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/ultimate.txt";
        hash = "sha256-zAauuodO1b5RxQFd9e4A1PFl7Xye6Rt8CwgWTjWkX14=";
      }
      # HaGeZi Tracker Interference: blocks anti-DNS tracking countermeasures (~1M)
      {
        name = "HaGeZi-tif";
        url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/tif.txt";
        hash = "sha256-bgeO8BnncIPm0McrAwtT+oraQNieRYdobn5lMpVk49s=";
      }
      # HaGeZi DNS-over-HTTPS: prevent bypassing DNS via DoH (~4K)
      {
        name = "HaGeZi-doh";
        url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/doh.txt";
        hash = "sha256-dGGMNLQ6cZvrYZh6g//Tnka00DeanZIdNX1qIRxi8Xw=";
      }
      # HaGeZi DoH/VPN/TOR/Proxy full bypass prevention (~17K)
      {
        name = "HaGeZi-bypass-full";
        url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/dnsmasq/doh-vpn-proxy-bypass.txt";
        hash = "sha256-XSp/2gy03SlUtuXcGM3hHtmfb5AZLxilz/7Nt0KpHxE=";
      }
      # HaGeZi Native telemetry - Apple
      {
        name = "HaGeZi-native-apple";
        url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/native.apple.txt";
        hash = "sha256-Jp02CpVwePxyk9x9WrvjphpJdLg3qCd7YoBF+IX3j5U=";
      }
      # HaGeZi Native telemetry - Amazon
      {
        name = "HaGeZi-native-amazon";
        url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/native.amazon.txt";
        hash = "sha256-k9axYYx/c3sGdK7kQ0C6PFHNu1mm+F4smKTpB/rWtNs=";
      }
      # HaGeZi Native telemetry - Samsung
      {
        name = "HaGeZi-native-samsung";
        url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/native.samsung.txt";
        hash = "sha256-pdDNtYaHTjcx71MZ2Wkz/trz+cItUnW+ofwElS/Z50k=";
      }
      # HaGeZi Native telemetry - Xiaomi
      {
        name = "HaGeZi-native-xiaomi";
        url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/native.xiaomi.txt";
        hash = "sha256-Y9P9vA7baXSn9BHRaXd2XUxxaz3tZss0G9x4zMPbWJ4=";
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
        hash = "sha256-54kcIlAZfYAlNhOsGmrIWa6WPcDLzSTh68hx0rSw0jU=";
      }
      # HaGeZi Native telemetry - Oppo/Realme
      {
        name = "HaGeZi-native-oppo-realme";
        url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/native.oppo-realme.txt";
        hash = "sha256-m6LOj+w54poaFqCHaX1bY1X9hciY2PbGmRxOajQOflc=";
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
        hash = "sha256-GoR8kiDNwQ/iYRF655tbSXz7Anen7v2kvihBQs3I9oQ=";
      }
      # HaGeZi Native telemetry - Windows/Office
      {
        name = "HaGeZi-native-winoffice";
        url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/native.winoffice.txt";
        hash = "sha256-f2k+OFwPePuT3WYGVB5doU/HR92mO1cDjbuO6RByelE=";
      }
      # HaGeZi Native - TikTok extended blocking
      {
        name = "HaGeZi-native-tiktok-extended";
        url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/native.tiktok.extended.txt";
        hash = "sha256-j72mjZ4pRTycOaAFusE5EEZgxrgp48yWnoeEXqRe94U=";
      }
      # HaGeZi Gambling: blocks gambling content (~209K)
      {
        name = "HaGeZi-gambling";
        url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/dnsmasq/gambling.txt";
        hash = "sha256-yZnK68pBg4a9WNOgJEfn7gSa+h3ZpT67NwWaULZeHKM=";
      }
      # HaGeZi NSFW: blocks adult content (~76K)
      {
        name = "HaGeZi-nsfw";
        url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/dnsmasq/nsfw.txt";
        hash = "sha256-ijPvdz6nPBBB6i9dyWIsKx03oFhaEJPEKRLRjh43uR0=";
      }
      # HaGeZi Social Networks: blocks social media (~900)
      {
        name = "HaGeZi-social";
        url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/dnsmasq/social.txt";
        hash = "sha256-CkOW5tcKOH4dIksLueOLCOag21anCSQFYziK7WHZX8M=";
      }
      # HaGeZi Anti Piracy: blocks piracy sites (~12K)
      {
        name = "HaGeZi-anti-piracy";
        url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/dnsmasq/anti.piracy.txt";
        hash = "sha256-rXZ/fqbq+3PHbXp9IQqV7Ss52Biw5X4o8P44RpaHvlA=";
      }
      # HaGeZi Dynamic DNS: blocks malicious DynDNS services (~1.5K)
      {
        name = "HaGeZi-dyndns";
        url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/dnsmasq/dyndns.txt";
        hash = "sha256-qDnK3SZl5wdjjNd3Z+N2XeiYu7gAflWz2LG6+EeU8FY=";
      }
      # HaGeZi Badware Hoster: blocks malicious hosting providers (~1.2K)
      {
        name = "HaGeZi-hoster";
        url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/dnsmasq/hoster.txt";
        hash = "sha256-sa8r3hA0WgulS84aIS3T34+Kjv4rqB1ufFTeRA1vnMU=";
      }
      # HaGeZi URL Shortener: blocks link shorteners (~10K)
      {
        name = "HaGeZi-urlshortener";
        url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/dnsmasq/urlshortener.txt";
        hash = "sha256-MU3Cb+lucbXO/afj3fQ/qM63IUMMxIqx4RFaUjr8DnU=";
      }
      # HaGeZi Safesearch: blocks engines without safesearch (~200)
      {
        name = "HaGeZi-nosafesearch";
        url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/dnsmasq/nosafesearch.txt";
        hash = "sha256-EhDwK5Gz6fY7pkXLvtzqlwuEYPcbbHms011E3BFAszU=";
      }
      # HaGeZi DGA 7-day: algorithmically generated malware domains (~511K)
      {
        name = "HaGeZi-dga7";
        url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/domains/dga7.txt";
        hash = "sha256-6J6naaqyyaOf8gqQKYkgiHD3Zp9jUcuBNP2J3SDiy3g=";
      }
    ];

    whitelist = [
      "api.immich.app"
      "immich.app"
      "github.com"
      "github-releases.githubusercontent.com"
      "objects.githubusercontent.com"
      "linkedin.com"
      "linktr.ee"
      "nominatim.openstreetmap.org"
      "tile.openstreetmap.org"
      "huggingface.co"
      "hf.co"
      "cdn-lfs.huggingface.co"
      "cdn-lfs-us-1.huggingface.co"
      "discord.gg"
      "discord.com"
      "gateway.discord.gg"
      "us.i.posthog.com"
      "movieffm.net"
      "www.movieffm.net"
      "deref-mail.com"
      "wbby.co"
    ];

    extraDomains = [
      "reddit.com"
      "redd.it"
      "redditmedia.com"
      "redditstatic.com"
    ];

    upstreamDNS = [
      "9.9.9.9@853#dns.quad9.net"
      "1.1.1.1@853#cloudflare-dns.com"
    ];

    enableDNSSEC = true;

    # Temporarily allow all DNS queries (disable blocking)
    # Set to true to bypass all DNS blocking
    tempAllowAll = false;

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
      ".reddit.com" = "Social Media";
      ".redd.it" = "Social Media";
      ".redditmedia.com" = "Social Media";
      ".redditstatic.com" = "Social Media";
    };
  };

  services.unbound.settings.server = {
    local-zone = [''"${domain}." static''];
    local-data =
      map
      (subdomain: ''"${subdomain}.${domain}. IN A ${serverIP}"'')
      ["auth" "immich" "gitea" "dash" "photomap" "unsloth" "signoz" "tasks" "crm"];
  };
}
