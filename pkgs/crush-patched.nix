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

  patches = [
    # PR #1854: fix(grep): prevent tool from hanging when context is cancelled
    pkgs.fetchpatch {
      url = "https://github.com/charmbracelet/crush/pull/1854.patch";
      sha256 = "sha256:fWWY+3/ycyvGtRsPxKIYVOt/CdQfmMAcAa8H6gONAFA=";
      stripLength = 1;
    }
    # PR #1617: refactor: eliminate all duplicate code blocks over 200 tokens
    pkgs.fetchpatch {
      url = "https://github.com/charmbracelet/crush/pull/1617.patch";
      sha256 = "sha256:yFprXfDfWxeWrsmhGmXvxrfjD0GK/DVDi6mugdrM/sg=";
      stripLength = 1;
    }
    # PR #1589: feat: add UI feedback when messages are dropped due to slow consumer
    pkgs.fetchpatch {
      url = "https://github.com/charmbracelet/crush/pull/1589.patch";
      sha256 = "sha256:oVa/WZo+rjmdHh6v6ueUVNrC8glAKWvdZ2mGe7Jsv74=";
      stripLength = 1;
    }
  ];

  doCheck = false; # Tests require network access to fetch providers

  # Will be updated after first build attempt
  vendorHash = "sha256:8Tw+O57E5aKFO2bKimiXRK9tGnAAQr3qsuP6P9LgBjw=";
  
  meta = with lib; {
    description = "Crush with Lars' PR patches applied";
    homepage = "https://github.com/charmbracelet/crush";
    license = licenses.mit;
    platforms = platforms.all;
  };
}