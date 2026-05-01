{
  lib,
  buildGoModule,
  writeText,
  src,
}:
buildGoModule {
  pname = "library-policy";
  version = "0.0.0";

  inherit src;

  vendorHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";

  proxyVendor = true;

  env = {
    GOPRIVATE = "github.com/LarsArtmann/*";
    GIT_CONFIG_GLOBAL = builtins.toFile "gitconfig" "\n[url \"git@github.com:\"]\n\tinsteadOf = https://github.com/\n";
  };

  meta = with lib; {
    description = "Library governance system for detecting banned/vulnerable Go libraries";
    homepage = "https://github.com/LarsArtmann/library-policy";
    license = licenses.mit;
    platforms = platforms.linux ++ platforms.darwin;
    mainProgram = "library-policy";
  };
}
