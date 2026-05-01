{
  lib,
  buildGoModule,
  writeText,
  src,
  gogenfilter-src,
}:
buildGoModule {
  pname = "art-dupl";
  version = "0.0.0";

  inherit src;

  vendorHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";

  proxyVendor = true;

  env = {
    GOPRIVATE = "github.com/LarsArtmann/*";
    GIT_CONFIG_GLOBAL = builtins.toFile "gitconfig" "\n[url \"git@github.com:\"]\n\tinsteadOf = https://github.com/\n";
  };

  postPatch = ''
    echo 'replace github.com/LarsArtmann/gogenfilter => ${gogenfilter-src}' >> go.mod
  '';

  meta = with lib; {
    description = "Fast, type-safe code duplication detector for Go projects";
    homepage = "https://github.com/LarsArtmann/art-dupl";
    license = licenses.mit;
    platforms = platforms.linux ++ platforms.darwin;
    mainProgram = "art-dupl";
  };
}
