{
  lib,
  buildGoModule,
  src,
}:
buildGoModule rec {
  pname = "emeet-pixyd";
  version = "0.1.0";

  inherit src;

  vendorHash = null;

  ldflags = ["-s" "-w"];

  meta = {
    description = "Auto-activation daemon for EMEET PIXY webcam — face tracking, privacy, noise cancellation";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "emeet-pixyd";
  };
}
