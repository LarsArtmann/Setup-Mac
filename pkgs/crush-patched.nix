{ pkgs }:
let
  lib = pkgs.lib;
in
pkgs.buildGoModule rec {
  pname = "crush-patched";
  version = "v0.36.0";

  src = pkgs.fetchurl {
    url = "https://github.com/charmbracelet/crush/archive/refs/tags/v0.36.0.tar.gz";
    sha256 = "sha256:HtcnWbgya8AbzT6lf2e3/Xy/oLWYR28iLj3V4hh5Neg=";
  };

  patches = [
    # PR #1854: fix(grep): prevent tool from hanging when context is cancelled
    (pkgs.fetchurl {
      url = "https://github.com/charmbracelet/crush/pull/1854.patch";
      sha256 = "fWWY+3/ycyvGtRsPxKIYVOt/CdQfmMAcAa8H6gONAFA=";
    })
    # PR #1617: refactor: eliminate all duplicate code blocks over 200 tokens
    (pkgs.fetchurl {
      url = "https://github.com/charmbracelet/crush/pull/1617.patch";
      sha256 = "yFprXfDfWxeWrsmhGmXvxrfjD0GK/DVDi6mugdrM/sg=";
    })
    # NOTE: PR #1589 temporarily removed - events.go patch fails due to file changes
    # Will be re-added once patch is regenerated for current main branch
  ];

  # Build environment for optimal binary
  env = {
    # Enable experimental Green Tea garbage collector
    GOEXPERIMENT = "greenteagc";
    # Disable CGO for static binary
    CGO_ENABLED = "0";
  };

  # Linker flags: set version, strip symbols for smaller binary
  ldflags = [
    "-s"    # Strip symbol table
    "-w"    # Strip debug info
    "-X=github.com/charmbracelet/crush/internal/version.Version=${version}"
  ];

  # Build flags for reproducible builds (trimpath is added automatically by buildGoModule)
  # GOFLAGS = [ "-trimpath" ];

  # Additional build options for size optimization
  postBuild = ''
    # Strip debug symbols and non-essential sections
    strip --strip-all --remove-section=.comment --remove-section=.note --strip-debug --discard-all $out/bin/crush 2>/dev/null || true
  '';

  doCheck = false; # Tests require network access to fetch providers

  vendorHash = "sha256:8Tw+O57E5aKFO2bKimiXRK9tGnAAQr3qsuP6P9LgBjw=";

  meta = with lib; {
    description = "Crush with Lars' PR patches applied";
    homepage = "https://github.com/charmbracelet/crush";
    license = licenses.mit;
    platforms = platforms.all;
  };
}