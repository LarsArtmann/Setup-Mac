# Go 1.26.1 package - simple override of go_1_26
{pkgs}:
pkgs.go_1_26.overrideAttrs (oldAttrs: {
  version = "1.26.1";
  src = pkgs.fetchurl {
    url = "https://go.dev/dl/go1.26.1.src.tar.gz";
    hash = "sha256-MXIpPQSyCdwRRGmOe6E/BHf2uoxf/QvmbCD9vJeF37s=";
  };
  passthru =
    oldAttrs.passthru
    // {
      tests = oldAttrs.passthru.tests or {};
    };
})
