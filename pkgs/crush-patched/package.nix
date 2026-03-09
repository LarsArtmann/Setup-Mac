{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "crush-patched";
  version = "0.47.2";

  src = fetchFromGitHub {
    owner = "charmbracelet";
    repo = "crush";
    rev = "v${version}";
    hash = "sha256-Lmp2DYrlzxVnll9x1jcnw/QgYjhA9RHpciQZ7mAUK5Y=";
  };

  vendorHash = "sha256-pBZdmQRnPfvhz66+DGQx/ZMMiYeKBfWThybw4RXsjno=";

  postUnpack = ''
    rm -rf $sourceRoot/vendor
  '';

  env = {
    GOEXPERIMENT = "greenteagc";
    CGO_ENABLED = "0";
  };

  ldflags = [
    "-s"
    "-w"
    "-X=github.com/charmbracelet/crush/internal/version.Version=v${version}"
  ];

  postBuild = ''
    strip --strip-all --remove-section=.comment --remove-section=.note --strip-debug --discard-all $out/bin/crush 2>/dev/null || true
  '';

  doCheck = false;

  meta = with lib; {
    description = "Crush CLI - AI-powered coding assistant";
    homepage = "https://github.com/charmbracelet/crush";
    license = licenses.mit;
    platforms = platforms.all;
    maintainers = ["Lars Artmann"];
  };
}
