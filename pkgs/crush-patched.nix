{ pkgs }:
let
  inherit (pkgs) lib;
in
pkgs.buildGoModule rec {
  pname = "crush-patched";
  version = "v0.39.3";

  src = pkgs.fetchurl {
    url = "https://github.com/charmbracelet/crush/archive/refs/tags/v0.39.3.tar.gz";
    sha256 = "sha256:1gshc4hcvz6b2vary8295wy3fqsyh2rf0arrjzvy47j7jx3m6545";
  };

  patches = [
    # PR #1854: fix(grep): prevent tool from hanging when context is cancelled
    # REMOVED: Superseded by PR #1906 which merged into v0.39.0
    # Functionality is now included in v0.39.0+
    #
    # PR #1617: refactor: eliminate all duplicate code blocks over 200 tokens
    # REMOVED: PR closed due to UI rewrite (internal/tui → internal/ui in v0.39.0)
    # PR targets old codebase structure
    #
    # PR #2068: fix: ensure commands and models dialogs render with borders
    # REMOVED: Already merged and included in v0.39.1
    #
    # PR #2019: feat: Plan mode with readonly permission enforcement
    # REMOVED: Has merge conflict with v0.37.0 (Hunk #3 FAILED at 132)
    #
    # PR #2070: fix(ui): show grep search parameters in pending state
    # REMOVED: OPEN as of 2026-02-06
    #
    # PR #2050: feat: prompt with warning for dangerous commands instead of blocking
    # REMOVED: Has merge conflict with v0.37.0 (Hunk #3 FAILED at 132)
    #
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

  vendorHash = "sha256-Y7QterJ5Mmjg/kMqFGbeSvd+3UwG8uGFTrdIBET5yRI=";

  meta = with lib; {
    description = "Crush with Lars' PR patches applied";
    homepage = "https://github.com/charmbracelet/crush";
    license = licenses.mit;
    platforms = platforms.all;
  };
}