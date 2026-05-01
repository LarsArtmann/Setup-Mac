{
  lib,
  buildGoModule,
  writeText,
  src,
  go-composable-business-types-src,
}:
buildGoModule {
  pname = "terraform-to-d2";
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
      --replace '/Users/larsartmann/projects/go-composable-business-types' '${go-composable-business-types-src}' \
      --replace '/home/lars/projects/go-composable-business-types' '${go-composable-business-types-src}'
  '';

  meta = with lib; {
    description = "Visualize cloud infrastructure as D2 diagrams from Terraform HCL code";
    homepage = "https://github.com/larsartmann/terraform-to-d2";
    license = licenses.mit;
    platforms = platforms.linux ++ platforms.darwin;
    mainProgram = "terraform-to-d2";
  };
}
