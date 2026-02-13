# Go 1.26 package - simple override of go_1_26
{pkgs}:
pkgs.go_1_26.overrideAttrs (oldAttrs: {
  version = "1.26.0";
  src = pkgs.fetchurl {
    url = "https://go.dev/dl/go1.26.0.src.tar.gz";
    hash = "sha256:c9132a8a1f6bd2aa4aad1d74b8231d95274950483a4950657ee6c56e6e817790";
  };
  passthru =
    oldAttrs.passthru
    // {
      tests = oldAttrs.passthru.tests or {};
    };
})
