{
  lib,
  buildGoModule,
  fetchFromGitHub,
  fetchpatch,
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

  patches = [
    (fetchpatch {
      name = "grep-show-search-params.patch";
      url = "https://github.com/charmbracelet/crush/commit/e4aa1742699db27c2ccd5e9c2b9f4d0948870581.patch";
      hash = "sha256-3G73sqv4UdwNZHs6HKr9mCYO8WWplJAnLrurDpEiK20=";
    })
  ];

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
