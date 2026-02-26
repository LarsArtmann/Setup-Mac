{ lib, buildGoModule, fetchurl, fetchpatch }:

buildGoModule rec {
  pname = "crush-patched";
  version = "v0.45.0";

  src = fetchurl {
    url = "https://github.com/charmbracelet/crush/archive/refs/tags/${version}.tar.gz";
    hash = "sha256:00s8c4dpyly5yx68cbk6pqbgfxm2fp57w7ygc3z9zxfn8p4caydn";
  };

  # Note: Patches for v0.45.0:
  # - PR #2181 (SQLite busy timeout) - merged upstream
  # - PR #2180 (LSP files outside cwd) - merged upstream
  # - PR #2161 (Regex cache memory leak) - merged upstream
  # - PR #1589 (Slow consumer notification) - closed, obsolete (targets old internal/tui)
  patches = [
    # PR #2070: fix(ui): show grep search parameters in pending state
    # Displays pattern, path, include filters while grep is running
    # Still open, awaiting review
    (fetchpatch {
      url = "https://github.com/charmbracelet/crush/commit/e4aa1742699db27c2ccd5e9c2b9f4d0948870581.patch";
      hash = "sha256:03fm5x8w80m9ghb2ccilhz0aqlzf76avr8cmfaqb0bb4ggzy1sgd";
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

  # Additional build options for size optimization
  postBuild = ''
    # Strip debug symbols and non-essential sections
    strip --strip-all --remove-section=.comment --remove-section=.note --strip-debug --discard-all $out/bin/crush 2>/dev/null || true
  '';

  doCheck = false; # Tests require network access to fetch providers

  vendorHash = "sha256-toatZYuXDn6aJXhgcMWXqvGVnp7+85K6QNYCNwIZfQY=";

  meta = with lib; {
    description = "Crush CLI - AI-powered coding assistant (v0.45.0 + PR #2070 grep UI fix)";
    homepage = "https://github.com/charmbracelet/crush";
    license = licenses.mit;
    platforms = platforms.all;
    maintainers = [ "Lars Artmann" ];
  };
}
