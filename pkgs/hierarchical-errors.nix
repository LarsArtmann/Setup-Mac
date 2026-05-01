{
  lib,
  buildGoModule,
  writeText,
  src,
  go-finding-src,
  go-filewatcher-src,
}:
buildGoModule {
  pname = "hierarchical-errors";
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
      --replace '/home/lars/projects/go-finding' '${go-finding-src}'
    echo 'replace github.com/larsartmann/go-filewatcher => ${go-filewatcher-src}' >> go.mod
  '';

  meta = with lib; {
    description = "Static analysis tool for error handling patterns, hierarchies, and violations in Go";
    homepage = "https://github.com/larsartmann/hierarchical-errors";
    license = licenses.mit;
    platforms = platforms.linux ++ platforms.darwin;
    mainProgram = "hierarchical-errors";
  };
}
