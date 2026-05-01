{
  lib,
  buildGoModule,
  writeText,
  src,
}:
buildGoModule {
  pname = "template-readme";
  version = "0.0.0";

  inherit src;

  vendorHash = "sha256-VEdbG6QrAfGBTXCrH5crQ1gg8M0ewlPQjQ/UsDYMFEs=";

  proxyVendor = true;

  env = {
    GOPRIVATE = "github.com/LarsArtmann/*";
    GIT_CONFIG_GLOBAL = builtins.toFile "gitconfig" "\n[url \"git@github.com:\"]\n\tinsteadOf = https://github.com/\n";
  };

  meta = with lib; {
    description = "Enterprise-grade README generation workflow orchestration platform";
    homepage = "https://github.com/LarsArtmann/template-readme";
    license = licenses.mit;
    platforms = platforms.linux ++ platforms.darwin;
    mainProgram = "readme-generator";
  };
}
