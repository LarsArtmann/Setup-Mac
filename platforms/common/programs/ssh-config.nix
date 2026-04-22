{lib, ...}: {
  ssh-config = {
    enable = true;
    user = "lars";
    hosts = {
      onprem = {
        hostname = "192.168.1.100";
        user = "root";
      };
      "evo-x2" = {
        hostname = "192.168.1.150";
        user = "lars";
        serverAliveInterval = 60;
        serverAliveCountMax = 3;
        extraOptions = {
          TCPKeepAlive = "yes";
        };
      };
      "private-cloud-hetzner-0" = {
        hostname = "37.27.217.205";
        user = "root";
      };
      "private-cloud-hetzner-1" = {
        hostname = "37.27.195.171";
        user = "root";
      };
      "private-cloud-hetzner-2" = {
        hostname = "37.27.24.111";
        user = "root";
      };
      "private-cloud-hetzner-3" = {
        hostname = "138.201.155.93";
        user = "root";
      };
    };
  };
}
