{lib}: {
  systemd = {
    harden = import ./systemd.nix {inherit lib;};
    serviceDefaults = import ./systemd/service-defaults.nix;
  };
  types = import ./types.nix lib;
  rocm = import ./rocm.nix;
}
