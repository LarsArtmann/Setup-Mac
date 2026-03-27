# DNS Blocker - Declarative DNS with ad blocking and block pages
# Uses unbound + dnsblockd (Go HTTP server for block pages)
{lib, ...}: {
  imports = [
    ../modules/dns-blocker.nix
  ];

  services.dns-blocker = {
    enable = true;

    # Block page configuration
    blockIP = "127.0.0.2";
    blockPort = 80;
    statsPort = 9090;

    # Blocklists (hosts format, fetched at build time)
    # Note: Update hashes after first build attempt shows the correct hash
    blocklists = [
      {
        name = "StevenBlack-ads";
        url = "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts";
        # Run `nix build` once, it will fail with hash mismatch showing the correct hash
        # Then update this hash with the one from the error message
        hash = "sha256-Lhkn7vQHJc7RQKddUbafgwfR0koiUSr0Xoj27HLGWK0=";
      }
    ];

    # Whitelist - domains that should never be blocked
    whitelist = [
      # Add domains here that you want to allow despite being in blocklists
    ];

    # Upstream DNS-over-TLS servers
    upstreamDNS = [
      "9.9.9.9@853#dns.quad9.net"
      "1.1.1.1@853#cloudflare-dns.com"
    ];

    # DNSSEC validation
    enableDNSSEC = true;

    # Category mapping for block page display
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
}
