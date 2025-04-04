{ ... }: {

  networking = {
    knownNetworkServices = [
      "AX88179A"
      "Pixel 6"
      "Wi-Fi"
      "Thunderbolt Bridge"
      "Lars' Private Cloud VPN"
      "Tailscale"
    ];

    dns = [
      "10.43.255.55"
      "9.9.9.9"
    ];
  };

}
