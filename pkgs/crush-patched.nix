{ pkgs }:
let
  lib = pkgs.lib;
in
pkgs.buildGoModule rec {
  pname = "crush-patched";
  version = "0.1.0";

  src = pkgs.fetchFromGitHub {
    owner = "charmbracelet";
    repo = "crush";
    rev = "main";
    sha256 = "sha256:xitCvejiVts9kkvtcVwh/zaeWIzDj0jx9xQMh2h+9Ns=";
    fetchSubmodules = true;
  };

  patches = [];
  doCheck = false; # Tests require network access to fetch providers

  # Verified: sha256-8Tw+O57E5aKFO2bKimiXRK9tGnAAQr3qsuP6P9LgBjw=
  vendorHash = "sha256:8Tw+O57E5aKFO2bKimiXRK9tGnAAQr3qsuP6P9LgBjw=";
  
  meta = with lib; {
    description = "Crush with Lars' PR patches applied";
    homepage = "https://github.com/charmbracelet/crush";
    license = licenses.mit;
    platforms = platforms.all;
  };
}