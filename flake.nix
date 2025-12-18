{
  description = "Lars nix-darwin system flake";

  inputs = {
    # Use nixpkgs-unstable to match nix-darwin master
    nixpkgs.url = "git+ssh://git@github.com/NixOS/nixpkgs?ref=nixpkgs-unstable";
    nix-darwin = {
      url = "git+ssh://git@github.com/LnL7/nix-darwin?ref=master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nix-darwin, nixpkgs }:
    let
      base = {
        system.configurationRevision = self.rev or self.dirtyRev or null;
      };

      # Custom packages overlay (2025 best practice: modular)
      heliumOverlay = final: prev: {
        helium = final.callPackage ./dotfiles/nix/packages/helium.nix { };
      };

      # Import lib for ghost system dependencies
      lib = nixpkgs.lib;
      pkgs = import nixpkgs {
        localSystem.system = "aarch64-darwin";
        stdenv.hostPlatform.system = "aarch64-darwin";
      };
    in
    {
      # Expose minimal packages
      packages.${pkgs.stdenv.hostPlatform.system}.hello = pkgs.hello;
    };
}
