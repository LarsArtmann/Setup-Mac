{
  lib,
  buildGoModule,
  writeText,
  src,
  go-finding-src,
  go-output-src,
}:
buildGoModule {
  pname = "branching-flow";
  version = "0.0.0";

  inherit src;

  vendorHash = "sha256-eQALDafez+UVw51P/mtuJ3IV/vNpsB2tX4eZdDvAJ+o=";

  doCheck = false;

  proxyVendor = true;

  env = {
    GOPRIVATE = "github.com/LarsArtmann/*";
    GIT_CONFIG_GLOBAL = builtins.toFile "gitconfig" "\n[url \"git@github.com:\"]\n\tinsteadOf = https://github.com/\n";
  };

  postPatch = ''
    substituteInPlace go.mod \
      --replace '/home/lars/projects/go-finding' '${go-finding-src}' \
      --replace '/home/lars/projects/go-output' '${go-output-src}'
  '';

  meta = with lib; {
    description = "Go CLI analyzer for code quality issues: error context loss, type safety, structural patterns, duplication";
    homepage = "https://github.com/larsartmann/branching-flow";
    license = licenses.mit;
    platforms = platforms.linux ++ platforms.darwin;
    mainProgram = "branching-flow";
  };
}
