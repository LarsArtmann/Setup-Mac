{
  lib,
  buildGoModule,
  writeText,
  src,
  go-output-src,
}:
buildGoModule {
  pname = "go-structure-linter";
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
      --replace '/home/lars/projects/go-output' '${go-output-src}'
  '';

  meta = with lib; {
    description = "Validates Go project structure against community best practices";
    homepage = "https://github.com/LarsArtmann/go-structure-linter";
    license = licenses.mit;
    platforms = platforms.linux ++ platforms.darwin;
    mainProgram = "go-structure-linter";
  };
}
