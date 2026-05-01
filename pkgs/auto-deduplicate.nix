{
  lib,
  buildGoModule,
  writeText,
  src,
  art-dupl-src,
  go-commit-src,
  go-filewatcher-src,
}:
buildGoModule {
  pname = "auto-deduplicate";
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
      --replace '/Users/larsartmann/projects/art-dupl' '${art-dupl-src}' \
      --replace '/home/lars/projects/art-dupl' '${art-dupl-src}' \
      --replace '/Users/larsartmann/projects/go-commit' '${go-commit-src}' \
      --replace '/home/lars/projects/go-commit' '${go-commit-src}'
    echo 'replace github.com/larsartmann/go-filewatcher => ${go-filewatcher-src}' >> go.mod
  '';

  meta = with lib; {
    description = "Automated file deduplication tool with content-addressable storage";
    homepage = "https://github.com/LarsArtmann/auto-deduplicate";
    license = licenses.mit;
    platforms = platforms.linux ++ platforms.darwin;
    mainProgram = "auto-deduplicate";
  };
}
