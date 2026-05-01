{
  lib,
  buildGoModule,
  writeText,
  src,
  graphviz,
  cmdguard-src,
  go-composable-business-types-src,
}:
buildGoModule {
  pname = "terraform-diagrams-aggregator";
  version = "0.0.0";

  inherit src;

  vendorHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";

  proxyVendor = true;

  env = {
    GOPRIVATE = "github.com/LarsArtmann/*";
    GIT_CONFIG_GLOBAL = builtins.toFile "gitconfig" "\n[url \"git@github.com:\"]\n\tinsteadOf = https://github.com/\n";
  };

  buildInputs = [graphviz];

  postPatch = ''
    echo 'replace github.com/larsartmann/cmdguard => ${cmdguard-src}' >> go.mod
    echo 'replace github.com/larsartmann/go-composable-business-types => ${go-composable-business-types-src}' >> go.mod
  '';

  meta = with lib; {
    description = "Generate visual dependency diagrams from Terraform configurations";
    homepage = "https://github.com/LarsArtmann/terraform-diagrams-aggregator";
    license = licenses.mit;
    platforms = platforms.linux ++ platforms.darwin;
    mainProgram = "terraform-diagrams-aggregator";
  };
}
