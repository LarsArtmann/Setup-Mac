{pkgs}: let
  inherit (pkgs) lib;
in
  pkgs.buildGoModule rec {
    pname = "crush-patched";
    version = "v0.41.0";

    src = pkgs.fetchurl {
      url = "https://github.com/charmbracelet/crush/archive/refs/tags/v0.41.0.tar.gz";
      sha256 = "sha256:1wa04vl3xzbii185bnq20866fa473ihcdxwyajri1l06pj3bvkhq";
    };

    patches = [
      # PR #2181: fix(sqlite): increase busy timeout to 30s (fixes #2129)
      # Consolidates pragma configuration for both SQLite drivers
      (pkgs.fetchpatch {
        url = "https://github.com/charmbracelet/crush/commit/2b12f560f6a350393a27347a7f28a0ca8de483b7.patch";
        hash = "sha256:04z6mavq3pgz6jrj0rigj38qwlm983mdg2g62x1673jh54gnkzc1";
      })

      # PR #2180: fix(lsp): files outside cwd (fixes #1401)
      # Makes LSP client receive working directory explicitly instead of calling os.Getwd()
      (pkgs.fetchpatch {
        url = "https://github.com/charmbracelet/crush/commit/5efab4c40a675297122f6eef18da53585b7150ba.patch";
        hash = "sha256:1h2ngplw1njrx0fi5b701vw1wkx9jvc0py645c9q2lck7lknl2q3";
      })

      # PR #2161: fix: clear regex cache on new session to prevent unbounded growth
      # Prevents memory leaks by clearing regex caches at session boundaries
      (pkgs.fetchpatch {
        url = "https://github.com/charmbracelet/crush/commit/2d5a911afd50a54aed5002ce0183263b49b712a7.patch";
        hash = "sha256:1hiv6xjjzbjxxm3z187z8qghn0fmiq318vzkalra3czaj7ipmsik";
      })
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
      "-s" # Strip symbol table
      "-w" # Strip debug info
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

    vendorHash = "sha256-2rEerdtwNAhQbdqabyyetw30DSpbmIxoiU2YPTWbEcg=";

    meta = with lib; {
      description = "Crush with Lars' PR patches applied";
      homepage = "https://github.com/charmbracelet/crush";
      license = licenses.mit;
      platforms = platforms.all;
    };
  }
