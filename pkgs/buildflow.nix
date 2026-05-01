{
  lib,
  buildGoModule,
  writeText,
  src,
  cmdguard-src,
  go-output-src,
  go-branded-id-src,
}:
buildGoModule {
  pname = "buildflow";
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
      --replace '../cmdguard' '${cmdguard-src}' \
      --replace '../go-output' '${go-output-src}'
    echo 'replace github.com/larsartmann/go-branded-id => ${go-branded-id-src}' >> go.mod
  '';

  meta = with lib; {
    description = "Zero-configuration build automation tool for Go projects with 40 type-safe steps";
    homepage = "https://github.com/LarsArtmann/BuildFlow";
    license = licenses.mit;
    platforms = platforms.linux ++ platforms.darwin;
    mainProgram = "buildflow";
  };
}
