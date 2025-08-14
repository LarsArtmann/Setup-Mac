{ ... }: {

  networking = {
    knownNetworkServices = [
      "Wi-Fi"
      "Thunderbolt Bridge"
      "Tailscale"
    ];

    dns = [
      "10.43.255.55" # Pihole DNS over Tailscale
      # "10.43.255.53" consider adding unbound DNS as secondary
      "9.9.9.9" # Quad9
    ];
  };

}
