{
  lib,
  buildGoModule,
  writeText,
  src,
  go-branded-id-src,
}:
buildGoModule {
  pname = "project-meta";
  version = "0.0.0";

  inherit src;

  vendorHash = "sha256-kon/uDx/Nx3IJjUCvegotGbpnIBVsB7/R8xEK2SjnC0=";

  proxyVendor = true;

  env = {
    GOPRIVATE = "github.com/LarsArtmann/*";
    GIT_CONFIG_GLOBAL = builtins.toFile "gitconfig" "\n[url \"git@github.com:\"]\n\tinsteadOf = https://github.com/\n";
  };

  postPatch = ''
    echo 'replace github.com/larsartmann/go-branded-id => ${go-branded-id-src}' >> go.mod
  '';

  meta = with lib; {
    description = "Per-project metadata management tool with tags and importance ratings";
    homepage = "https://github.com/LarsArtmann/project-meta";
    license = licenses.mit;
    platforms = platforms.linux ++ platforms.darwin;
    mainProgram = "meta";
  };
}
