{lib}: {
  systemd = {
    harden = import ./systemd.nix;
    serviceDefaults = import ./systemd/service-defaults.nix;
  };
  types = import ./types.nix lib;
  rocm = import ./rocm.nix;
}
