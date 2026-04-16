{
  lib,
  buildGoModule,
  src,
}:
buildGoModule rec {
  pname = "emeet-pixyd";
  version = "0.2.0";

  inherit src;

  vendorHash = "sha256-ecs48LYOFifUXtEPa+bgwhKyrrAkkSCzQEeyOZkDuIQ=";

  ldflags = ["-s" "-w"];

  postInstall = ''
    ln -s $out/bin/emeet-pixyd $out/bin/emeet-pixy
  '';

  meta = {
    description = "Auto-activation daemon for EMEET PIXY webcam — face tracking, privacy, noise cancellation";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "emeet-pixyd";
  };
}
