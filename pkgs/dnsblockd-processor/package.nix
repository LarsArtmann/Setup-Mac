{
  lib,
  buildGoModule,
  src,
}:
buildGoModule {
  pname = "dnsblockd-processor";
  version = "0.1.0";

  inherit src;

  vendorHash = null;

  ldflags = ["-s" "-w"];

  meta = with lib; {
    description = "Blocklist processor for dnsblockd";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "dnsblockd-processor";
  };
}
