{
  lib,
  appimageTools,
  fetchurl,
}:
appimageTools.wrapType2 rec {
  pname = "openaudible";
  version = "4.7.4";

  src = fetchurl {
    url = "https://openaudible.org/latest/linux_AppImage";
    hash = "sha256-uPDsFxAET5hZ4ntBvMuH5G9DogcZuP5kZaLNjLypF70=";
  };

  meta = {
    description = "Desktop application for managing Audible audiobooks";
    homepage = "https://openaudible.org";
    license = lib.licenses.unfree;
    platforms = lib.platforms.linux;
    mainProgram = "openaudible";
  };
}
