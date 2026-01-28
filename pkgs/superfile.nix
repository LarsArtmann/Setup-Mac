{ pkgs }:
let
  lib = pkgs.lib;
in
pkgs.buildGoModule rec {
  pname = "superfile";
  version = "1.5.0";

  src = pkgs.fetchFromGitHub {
    owner = "yorukot";
    repo = "superfile";
    rev = "f804bf069bb079b7a6613b4640a3cc90a17b8c56";
    sha256 = "sha256-bnftcbi42KFxi6CSRcCE2e+Jo3u/yBWkS5KT/MTiJds=";
  };

  # Vendor hash computed with: nix-prefetch-url --type sha256 https://github.com/yorukot/superfile/archive/f804bf069bb079b7a6613b4640a3cc90a17b8c56.tar.gz
  vendorHash = "sha256-bnftcbi42KFxi6CSRcCE2e+Jo3u/yBWkS5KT/MTiJds=";

  # Disable tests due to flaky zoxide integration test
  doCheck = false;

  meta = with lib; {
    description = "A fancy, pretty terminal file manager (tests disabled)";
    homepage = "https://github.com/yorukot/superfile";
    license = licenses.mit;
    platforms = platforms.all;
  };
}
