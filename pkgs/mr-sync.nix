{
  lib,
  buildGoModule,
  src,
}:
buildGoModule {
  pname = "mr-sync";
  version = "0.0.0";

  inherit src;

  vendorHash = "sha256-NBfpRc+el41FiogJ7iN3I853ilQ8JogiXPpslhsNNH0=";

  proxyVendor = true;

  meta = with lib; {
    description = "CLI tool to keep ~/.mrconfig in sync with your GitHub repos";
    homepage = "https://github.com/LarsArtmann/mr-sync";
    license = licenses.mit;
    platforms = platforms.linux ++ platforms.darwin;
    mainProgram = "mr-sync";
  };
}
