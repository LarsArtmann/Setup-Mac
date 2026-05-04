{
  lib,
  buildGoModule,
  golangci-lint-auto-configure-src,
  go-finding-src,
}:
buildGoModule rec {
  pname = "golangci-lint-auto-configure";
  version = "0.1.0";

  src = lib.cleanSourceWith {
    filter = path: _type: let
      b = baseNameOf path;
    in
      !(
        b
        == "vendor"
        || b == ".git"
        || b == "docs"
        || b == ".crush"
        || b == "reports"
        || b == "examples"
        || b == "scripts"
        || b == ".envrc"
        || b == ".github"
        || b == "bin"
        || b == "justfile"
        || b == "Dockerfile"
        || b == ".dockerignore"
        || b == ".gitattributes"
        || b == ".pre-commit-config.yaml"
        || b == ".pre-commit-hooks.yaml"
        || b == ".config"
        || lib.hasSuffix ".md" b
        || lib.hasSuffix ".lock" b
        || lib.hasSuffix ".yml" b
        || lib.hasSuffix ".yaml" b
      );
    src = golangci-lint-auto-configure-src;
  };

  vendorHash = "sha256-Z6bu9RmRRVQT7gRO2YuAAi9am/lSW+3fQ9QdEWXlOiU=";

  proxyVendor = true;

  subPackages = ["cmd/golangci-lint-auto-configure"];

  doCheck = false;

  postPatch = ''
    echo "replace github.com/larsartmann/go-finding => ${go-finding-src}" >> go.mod
    if [ "''${dontFixup:-}" != "1" ]; then
      export GOPROXY="file://$goModules"
      export GONOSUMCHECK='*'
      export GONOSUMDB='*'
    fi
    HOME=$(mktemp -d) go mod tidy
  '';

  modPostBuild = ''
    HOME=$(mktemp -d) go mod download all
  '';

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}"
  ];

  env = {
    CGO_ENABLED = 0;
    GOWORK = "off";
  };

  meta = with lib; {
    description = "Automatically configure and optimize golangci-lint configurations";
    homepage = "https://github.com/LarsArtmann/golangci-lint-auto-configure";
    license = licenses.mit;
    mainProgram = "golangci-lint-auto-configure";
    platforms = platforms.unix;
  };
}
