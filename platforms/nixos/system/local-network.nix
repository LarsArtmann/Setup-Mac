{lib, ...}: {
  options.networking.local = {
    lanIP = lib.mkOption {
      type = lib.types.str;
      default = "192.168.1.150";
      description = "Static LAN IP address of this machine";
    };
    subnet = lib.mkOption {
      type = lib.types.str;
      default = "192.168.1.0/24";
      description = "LAN subnet in CIDR notation";
    };
    gateway = lib.mkOption {
      type = lib.types.str;
      default = "192.168.1.1";
      description = "Default gateway IP address";
    };
  };
}
