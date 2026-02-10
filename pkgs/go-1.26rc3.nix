# Go 1.26rc3 package - simple override of go_1_26
{pkgs}:
pkgs.go_1_26.overrideAttrs (oldAttrs: {
  version = "1.26rc3";
  src = pkgs.fetchurl {
    url = "https://go.dev/dl/go1.26rc3.src.tar.gz";
    hash = "sha256:16rfmn05vkrpyr817xz1lq1w1i26bi6kq0j7h7fnb19qw03sfzdp";
  };
  passthru =
    oldAttrs.passthru
    // {
      tests = oldAttrs.passthru.tests or {};
    };
})
