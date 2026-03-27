{lib, buildGoModule, src}:
buildGoModule rec {
  pname = "dnsblockd";
  version = "0.1.0";

  inherit src;

  vendorHash = lib.fakeHash;

  ldflags = ["-s" "-w" "-X main.version=${version}"];

  meta = {
    description = "Lightweight HTTP server that serves block pages for DNS-filtered domains";
    homepage = "https://github.com/larsartmann/dnsblockd";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "dnsblockd";
  };
}
