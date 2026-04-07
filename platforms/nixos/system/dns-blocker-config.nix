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
  domain = config.networking.domain;
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
        hash = "sha256-su61LEXtsIziTZobmqivh1DA377MoP4blB1Lp/+ax4o=";
      }
      # HaGeZi Ultimate: comprehensive ad/tracker/scam/clickbait blocking (~541K)
      {
        name = "HaGeZi-ultimate";
        url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/ultimate.txt";
        hash = "sha256-UyP3HnFPaRx9W/CNSD/03wGH5LXOXYdyCvMuaO9TGhM=";
      }
      # HaGeZi Tracker Interference: blocks anti-DNS tracking countermeasures (~1M)
      {
        name = "HaGeZi-tif";
        url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/tif.txt";
        hash = "sha256-5L3iet6uYsnhBR4wQlKR0wdAwUDkcee3+22Rq+aT2Ro=";
      }
      # HaGeZi DNS-over-HTTPS: prevent bypassing DNS via DoH (~4K)
      {
        name = "HaGeZi-doh";
        url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/doh.txt";
        hash = "sha256-tCLYLpYeJ2aYsFq2a4GGrRU2XpejUQouF4xDQ7QLpco=";
      }
      # HaGeZi DoH/VPN/TOR/Proxy full bypass prevention (~17K)
      {
        name = "HaGeZi-bypass-full";
        url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/dnsmasq/doh-vpn-proxy-bypass.txt";
        hash = "sha256-rk+2O0xK72RS1456/ab4B8VHMAEWWoUoH2DuHYJBVgg=";
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
        hash = "sha256-BrDHb/iJk5P5bwNbMqkUDFUemNZ5BQXjsTkiTIsmHR8=";
      }
      # HaGeZi Native telemetry - Samsung
      {
        name = "HaGeZi-native-samsung";
        url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/native.samsung.txt";
        hash = "sha256-IS58exeIQsXXf1sdBFBx2qeL3MaWVAnEhheDtvOZdOM=";
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
        hash = "sha256-QCOFH55djcTqQNsf7un7rXHAQ8D3cAAJ3XbGPKP2/EI=";
      }
      # HaGeZi Native telemetry - Oppo/Realme
      {
        name = "HaGeZi-native-oppo-realme";
        url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/native.oppo-realme.txt";
        hash = "sha256-yOkcgPJODSiF/r3JbmgA8szDuQOujX9uF0PDuwlP4Fw=";
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
        hash = "sha256-NcIO4nk6tW8v8cNmK+zjPn6+6WNgbTzF/HP7tSSG6Vw=";
      }
      # HaGeZi Native telemetry - Windows/Office
      {
        name = "HaGeZi-native-winoffice";
        url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/native.winoffice.txt";
        hash = "sha256-3+EnpSPeHhFwk2wqT5hWb6Iqp5cDVeUjoV0BzVVDmvs=";
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
        hash = "sha256-UUxkjn3izKVeMMJ84byU4SHfocn4CehX/1Q/rm4Qs3E=";
      }
      # HaGeZi NSFW: blocks adult content (~76K)
      {
        name = "HaGeZi-nsfw";
        url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/dnsmasq/nsfw.txt";
        hash = "sha256-RYl9KchX+Vjkv+bwrDv6pXux+/vNZLJm357ufOXqBIU=";
      }
      # HaGeZi Social Networks: blocks social media (~900)
      {
        name = "HaGeZi-social";
        url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/dnsmasq/social.txt";
        hash = "sha256-ps97h0PrTn2KBGjAEykgLgNW9cHVKN/Lr24x3/kIQco=";
      }
      # HaGeZi Anti Piracy: blocks piracy sites (~12K)
      {
        name = "HaGeZi-anti-piracy";
        url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/dnsmasq/anti.piracy.txt";
        hash = "sha256-aKI3ND4b+eX167l0sr2OicFyusypHoHkVux1v0wRAuQ=";
      }
      # HaGeZi Dynamic DNS: blocks malicious DynDNS services (~1.5K)
      {
        name = "HaGeZi-dyndns";
        url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/dnsmasq/dyndns.txt";
        hash = "sha256-c4XRe2ewuoWtxBLCoX4DUqUjQnXCh2IXgBANcQyd0b8=";
      }
      # HaGeZi Badware Hoster: blocks malicious hosting providers (~1.2K)
      {
        name = "HaGeZi-hoster";
        url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/dnsmasq/hoster.txt";
        hash = "sha256-wtZu0Xm8sAL9YdCgVQDn8IWpw4qkN3FYJ3zRUByuE+I=";
      }
      # HaGeZi URL Shortener: blocks link shorteners (~10K)
      {
        name = "HaGeZi-urlshortener";
        url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/dnsmasq/urlshortener.txt";
        hash = "sha256-h+mNpF2lRzYZlAqAl7ePExtc2J/nqxpJlzIfowYfUmU=";
      }
      # HaGeZi Safesearch: blocks engines without safesearch (~200)
      {
        name = "HaGeZi-nosafesearch";
        url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/dnsmasq/nosafesearch.txt";
        hash = "sha256-Cv+YjCRH+PsN+BQDDyyLF1KtSf/qfHYCpAO9UaUpJGE=";
      }
      # HaGeZi DGA 7-day: algorithmically generated malware domains (~511K)
      {
        name = "HaGeZi-dga7";
        url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/domains/dga7.txt";
        hash = "sha256-YujJHiSjG7sY+kj9vgy0rlxjLyM/CiCB9+p+quolES8=";
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
      "cdn-lfs.huggingface.co"
      "cdn-lfs-us-1.huggingface.co"
      "discord.gg"
      "us.i.posthog.com"
      "movieffm.net"
      "www.movieffm.net"
      "deref-mail.com"
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
      ["auth" "immich" "gitea" "dash" "photomap" "unsloth" "signoz"];
  };
}
