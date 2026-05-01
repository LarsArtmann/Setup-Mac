{
  lib,
  buildGoModule,
  writeText,
  src,
  graphviz,
  cmdguard-src,
  go-composable-business-types-src,
  go-output-src,
  go-branded-id-src,
}:
buildGoModule {
  pname = "terraform-diagrams-aggregator";
  version = "0.0.0";

  inherit src;

  vendorHash = "";

  proxyVendor = true;

  env = {
    GOPRIVATE = "github.com/LarsArtmann/*";
    GIT_CONFIG_GLOBAL = builtins.toFile "gitconfig" "\n[url \"git@github.com:\"]\n\tinsteadOf = https://github.com/\n";
  };

  buildInputs = [graphviz];

  postPatch = ''
        cat >> go.mod <<EOF
    replace github.com/larsartmann/cmdguard => ${cmdguard-src}
    replace github.com/larsartmann/go-composable-business-types => ${go-composable-business-types-src}
    replace github.com/larsartmann/go-output => ${go-output-src}
    replace github.com/larsartmann/go-branded-id => ${go-branded-id-src}
    EOF
  '';

  preBuild = "go mod tidy";

  meta = with lib; {
    description = "Generate visual dependency diagrams from Terraform configurations";
    homepage = "https://github.com/LarsArtmann/terraform-diagrams-aggregator";
    license = licenses.mit;
    platforms = platforms.linux ++ platforms.darwin;
    mainProgram = "terraform-diagrams-aggregator";
  };
}
