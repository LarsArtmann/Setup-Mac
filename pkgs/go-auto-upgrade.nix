{
  lib,
  buildGoModule,
  writeText,
  src,
  cmdguard-src,
  go-finding-src,
  go-output-src,
}:
buildGoModule {
  pname = "go-auto-upgrade";
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
      --replace '/home/lars/projects/cmdguard' '${cmdguard-src}' \
      --replace '/home/lars/projects/go-finding' '${go-finding-src}' \
      --replace '/home/lars/projects/go-output' '${go-output-src}'
  '';

  meta = with lib; {
    description = "Automate Go library upgrades with import rewrites and breaking change detection";
    homepage = "https://github.com/larsartmann/go-auto-upgrade";
    license = licenses.mit;
    platforms = platforms.linux ++ platforms.darwin;
    mainProgram = "go-auto-upgrade";
  };
}
