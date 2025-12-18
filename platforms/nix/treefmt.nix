# treefmt-nix Configuration - Simplified and Working
{ pkgs, lib, inputs, ... }:

{
  # Import treefmt-nix only (remove disabled treefmt-full-flake)
  imports = [
    inputs.treefmt-nix.flakeModule
  ];

  # Core formatter configuration
  treefmt = {
    # Project configuration
    projectRootFile = "flake.nix";

    # Formatters configuration
    formatter = {
      nix = {
        package = pkgs.nixfmt-rfc-style;
      };
      shell = {
        package = pkgs.shfmt;
      };
      yaml = {
        package = pkgs.yamlfmt;
      };
      json = {
        package = pkgs.jq;
      };
      python = {
        package = pkgs.black;
      };
      rust = {
        package = pkgs.rustfmt;
      };
      toml = {
        package = pkgs.taplo;
      };
      go = {
        package = pkgs.gofumpt;
      };
    };
  };
}
