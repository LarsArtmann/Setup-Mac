{
  lib,
  buildGoModule,
  writeText,
  src,
  go-output-src,
}:
buildGoModule {
  pname = "md-go-validator";
  version = "0.0.0";

  inherit src;

  vendorHash = "sha256-muAP0rqsR1+NWlTbnuLJlbDJHTgRusRXariVf6gcD+s=";

  proxyVendor = true;

  env = {
    GOPRIVATE = "github.com/LarsArtmann/*";
    GIT_CONFIG_GLOBAL = builtins.toFile "gitconfig" "\n[url \"git@github.com:\"]\n\tinsteadOf = https://github.com/\n";
  };

  postPatch = ''
    substituteInPlace go.mod \
      --replace '../go-output' '${go-output-src}'
  '';

  preBuild = "go mod tidy";

  meta = with lib; {
    description = "Validates code blocks in Markdown files (Go, TypeScript, Rust, Nix, HCL, Templ)";
    homepage = "https://github.com/larsartmann/md-go-validator";
    license = licenses.mit;
    platforms = platforms.linux ++ platforms.darwin;
    mainProgram = "md-go-validator";
  };
}
