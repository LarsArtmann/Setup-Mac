{
  lib,
  buildGoModule,
  writeText,
  src,
  go-finding-src,
}:
buildGoModule {
  pname = "go-functional-fixer";
  version = "0.0.0";

  inherit src;

  vendorHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";

  proxyVendor = true;

  env = {
    GOPRIVATE = "github.com/LarsArtmann/*";
    GIT_CONFIG_GLOBAL = builtins.toFile "gitconfig" "\n[url \"git@github.com:\"]\n\tinsteadOf = https://github.com/\n";
  };

  postPatch = ''
    substituteInPlace go.mod \
      --replace '../go-finding' '${go-finding-src}'
  '';

  meta = with lib; {
    description = "Detects imperative Go code and transforms loops into functional code using samber/lo";
    homepage = "https://github.com/LarsArtmann/go-functional-fixer";
    license = licenses.mit;
    platforms = platforms.linux ++ platforms.darwin;
    mainProgram = "go-functional-fixer";
  };
}
