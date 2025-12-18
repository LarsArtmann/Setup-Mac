{
  description = "Minimal test flake";

  inputs = {
    nixpkgs.url = "git+ssh://git@github.com/NixOS/nixpkgs?ref=nixpkgs-unstable";
    nix-darwin = {
      url = "git+ssh://git@github.com/LnL7/nix-darwin?ref=master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nix-darwin, nixpkgs, ... }:
    let
      system = "aarch64-darwin";
    in
    {
      darwinConfigurations."test" = nix-darwin.lib.darwinSystem {
        inherit system;
        modules = [
          ({ pkgs, ... }: {
            environment.systemPackages = [ pkgs.hello ];
            system.stateVersion = 5;
          })
        ];
      };
    };
}