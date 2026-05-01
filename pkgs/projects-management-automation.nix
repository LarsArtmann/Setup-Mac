{
  lib,
  buildGoModule,
  writeText,
  src,
  project-meta-src,
  go-output-src,
  cmdguard-src,
  go-branded-id-src,
  go-commit-src,
  go-filewatcher-src,
  project-discovery-sdk-src,
}:
buildGoModule {
  pname = "projects-management-automation";
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
      --replace '/home/lars/projects/project-meta' '${project-meta-src}' \
      --replace '/home/lars/projects/go-output' '${go-output-src}' \
      --replace '/home/lars/projects/cmdguard' '${cmdguard-src}' \
      --replace '/home/lars/projects/go-branded-id' '${go-branded-id-src}' \
      --replace '/home/lars/projects/go-commit' '${go-commit-src}' \
      --replace '/home/lars/projects/go-filewatcher' '${go-filewatcher-src}' \
      --replace '/home/lars/projects/project-discovery-sdk' '${project-discovery-sdk-src}'
  '';

  meta = with lib; {
    description = "CLI tool for discovering and managing multiple projects with automated Git operations and AI-powered commits";
    homepage = "https://github.com/LarsArtmann/projects-management-automation";
    license = licenses.mit;
    platforms = platforms.linux ++ platforms.darwin;
    mainProgram = "projects-management-automation";
  };
}
