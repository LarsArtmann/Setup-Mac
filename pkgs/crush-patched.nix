{
  lib,
  buildGoModule,
  fetchFromGitHub,
  fetchurl,
  stdenv,
}:
let
  # PR configuration - add your PRs here
  # Format: { pr = PR_NUMBER; version = "override_version"; }
  # version is optional, defaults to date-based
  prs = [
    { pr = 1854; } # fix(grep): prevent tool from hanging when context is cancelled
    { pr = 1617; } # refactor: eliminate all duplicate code blocks over 200 tokens
    { pr = 1589; } # feat: add UI feedback when messages are dropped due to slow consumer
  ];

  # Fetch patch files for a given PR
  fetchPrPatch = prNum: fetchurl {
    url = "https://github.com/charmbracelet/crush/pull/${toString prNum}.patch";
    name = "pr-${toString prNum}.patch";
    hash = lib.fakeHash; # Will be auto-detected on first build
  };

  # Collect all patch files
  patches = map (pr: fetchPrPatch pr.pr) prs;
in
buildGoModule rec {
  pname = "crush-patched";

  src = fetchFromGitHub {
    owner = "charmbracelet";
    repo = "crush";
    rev = "main";
    hash = lib.fakeHash; # Will be auto-detected on first build
  };

  inherit patches;

  postPatch = ''
    # Copy patches to a accessible location for debugging
    mkdir -p $out/patches
    for i in ''${!patches[@]}; do
      cp "''${patches[$i]}" "$out/patches/pr-$(( i + 1 )).patch" || true
    done
  '';

  vendorHash = lib.fakeHash; # Will be auto-detected on first build

  meta = {
    description = "Crush with Lars' PR patches applied";
    homepage = "https://github.com/charmbracelet/crush";
    license = lib.licenses.mit;
  };
}