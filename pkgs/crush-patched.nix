{ pkgs }:
let
  lib = pkgs.lib;
in
pkgs.buildGoModule rec {
  pname = "crush-patched";
  version = "v0.37.0";

  src = pkgs.fetchurl {
    url = "https://github.com/charmbracelet/crush/archive/refs/tags/v0.37.0.tar.gz";
    sha256 = "sha256:1wbkhhrq8iyjhgcrdf98q51yn599c0ckhr0gxksj3jd7gkz6wig8";
  };

  patches = [
    # PR #1854: fix(grep): prevent tool from hanging when context is cancelled
    # KEEP until PR #1906 merge conflicts are resolved
    (pkgs.fetchurl {
      url = "https://github.com/charmbracelet/crush/pull/1854.patch";
      sha256 = "fWWY+3/ycyvGtRsPxKIYVOt/CdQfmMAcAa8H6gONAFA=";
    })
    # PR #1617: refactor: eliminate all duplicate code blocks over 200 tokens
    # KEEP permanently
    (pkgs.fetchurl {
      url = "https://github.com/charmbracelet/crush/pull/1617.patch";
      sha256 = "yFprXfDfWxeWrsmhGmXvxrfjD0GK/DVDi6mugdrM/sg=";
    })
    # PR #2068: fix: ensure commands and models dialogs render with borders
    (pkgs.fetchurl {
      url = "https://github.com/charmbracelet/crush/pull/2068.patch";
      sha256 = "sha256:5f30a28e50e0d9a56a82046035d3686d9f67851a8f4519993e570053097e1a4c";
    })
    # PR #2019: feat: Plan mode with readonly permission enforcement
    (pkgs.fetchurl {
      url = "https://github.com/charmbracelet/crush/pull/2019.patch";
      sha256 = "sha256:c68f4835de3bdb0ec75cf79033b3499bc9ac495ba8a96e8a9263072f020b4c32";
    })
    # PR #2070: fix(ui): show grep search parameters in pending state
    (pkgs.fetchurl {
      url = "https://github.com/charmbracelet/crush/pull/2070.patch";
      sha256 = "sha256:ede9e0ff7b642db0b07295a1bc9539ee53acc087343226167ca902c4512fd50d";
    })
    # PR #2050: feat: prompt with warning for dangerous commands instead of blocking
    # TEMPORARILY REMOVED - Has merge conflict with v0.37.0 (Hunk #3 FAILED at 132 in permission.go)
    # Will re-add once conflict is resolved
    # PR #1611: Will be added when merge conflicts are resolved
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

  vendorHash = "sha256:hhBjQ1Wm4ZY1KX09CgpNusse3osT8b3VSsIIj6KFjFA=";

  meta = with lib; {
    description = "Crush with Lars' PR patches applied";
    homepage = "https://github.com/charmbracelet/crush";
    license = licenses.mit;
    platforms = platforms.all;
  };
}