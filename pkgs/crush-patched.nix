{
  lib,
  buildGoModule,
  fetchFromGitHub,
  fetchurl,
  stdenv,
}:
buildGoModule rec {
  pname = "crush-patched";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "charmbracelet";
    repo = "crush";
    rev = "main";
    hash = "sha256-1nzlgrl8f30lyzqli3y3iic9wdpz45f73vabj8yxnmp2x2yl4ay6";
  };

  # TODO: PR patches temporarily disabled due to hash mismatch issues
  # See: docs/notes/crush-patches.md for instructions on re-enabling
  patches = [];


  vendorHash = lib.fakeHash; # Will be auto-detected on first build

  meta = {
    description = "Crush with Lars' PR patches applied";
    homepage = "https://github.com/charmbracelet/crush";
    license = lib.licenses.mit;
  };
}