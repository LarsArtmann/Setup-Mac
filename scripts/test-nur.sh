#!/usr/bin/env bash

echo "🧪 Testing NUR package accessibility..."

echo ""
echo "=== Testing NUR in NixOS configuration ==="
nix eval --raw --impure --expr '
  let
    flake = builtins.getFlake (toString ./.);
    nixosConfig = flake.nixosConfigurations.evo-x2;
    config = nixosConfig.config;
    pkgs = nixosConfig.pkgs;
  in
    "NUR available in pkgs: " + 
    (if builtins.hasAttr "nur" pkgs then "YES" else "NO") + 
    "\nNUR repos available: " +
    (if builtins.hasAttr "repos" (pkgs.nur or {}) then "YES" else "NO")
'

echo ""
echo "=== Checking available NUR repos ==="
nix eval --raw --impure --expr '
  let
    flake = builtins.getFlake (toString ./.);
    nixosConfig = flake.nixosConfigurations.evo-x2;
    pkgs = nixosConfig.pkgs;
  in
    if builtins.hasAttr "nur" pkgs && builtins.hasAttr "repos" pkgs.nur
    then "Available NUR repos: " + builtins.concatStringsSep ", " (builtins.attrNames pkgs.nur.repos)
    else "NUR repos not available"
'

echo ""
echo "=== Testing build ==="
nix build --expr '
  let
    flake = builtins.getFlake (toString ./.);
    nixosConfig = flake.nixosConfigurations.evo-x2;
    pkgs = nixosConfig.pkgs;
  in
    # Test building with NUR
    pkgs.runCommand "nur-test" {} ''
      echo "NUR is available: ${if builtins.hasAttr "nur" pkgs then "YES" else "NO"}" > $out
    ''
'

echo ""
echo "✅ NUR test complete!"