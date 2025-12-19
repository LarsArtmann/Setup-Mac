#!/usr/bin/env bash

echo "🔍 Quick NUR test..."

# Test if flake loads correctly
echo "1. Testing flake structure..."
nix flake show --json | jq '.nodes' | grep -q nur && echo "✅ NUR node found in flake" || echo "❌ NUR node not found"

# Test NixOS configuration with overlay
echo "2. Testing NixOS with NUR overlay..."
nix eval --impure --expr '
  let 
    flake = builtins.getFlake (toString ./.);
    # Recreate the NixOS configuration
    pkgs = import flake.inputs.nixpkgs {
      system = "x86_64-linux";
      overlays = [ flake.inputs.nur.overlays.default ];
      config.allowUnfree = true;
    };
  in 
    "NUR available: " + (if builtins.hasAttr "nur" pkgs then "YES" else "NO") + 
    "\nRepos available: " + (if builtins.hasAttr "repos" (pkgs.nur or {}) then "YES" else "NO")
'

echo ""
echo "🔗 How to use NUR packages in your configuration:"
echo "--------------------------------------------"
echo "In your system configuration (configuration.nix):"
echo "  environment.systemPackages = with pkgs; ["
echo "    nur.repos.<repo-name>.<package-name>"
echo "  ];"
echo ""
echo "Examples:"
echo "  nur.repos.iopq.xraya"
echo "  nur.repos.rycee.mozilla-addons-to-nix"
echo "  nur.repos.mic92.hello-nur"