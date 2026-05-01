{
  lib,
  buildGoModule,
  writeText,
  src,
  art-dupl-src,
  cmdguard-src,
  go-output-src,
}:
buildGoModule {
  pname = "code-duplicate-analyzer";
  version = "0.0.0";

  inherit src;

  vendorHash = "sha256-1uEaax/lHNrWAWIt3XjJhWIwlnXs5xqiDMU4mWsVSEQ=";

  proxyVendor = true;

  env = {
    GOPRIVATE = "github.com/LarsArtmann/*";
    GIT_CONFIG_GLOBAL = builtins.toFile "gitconfig" "\n[url \"git@github.com:\"]\n\tinsteadOf = https://github.com/\n";
  };

  postPatch = ''
    substituteInPlace go.mod \
      --replace '../art-dupl' '${art-dupl-src}' \
      --replace '../cmdguard' '${cmdguard-src}' \
      --replace '../go-output' '${go-output-src}'
  '';

  meta = with lib; {
    description = "High-performance Go CLI for AST-based duplicate code detection across projects";
    homepage = "https://github.com/LarsArtmann/code-duplicate-analyzer";
    license = licenses.mit;
    platforms = platforms.linux ++ platforms.darwin;
    mainProgram = "code-duplicate-analyzer";
  };
}
