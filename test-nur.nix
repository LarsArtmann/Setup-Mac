{ config, pkgs, ... }:

{
  # Test file to verify NUR packages are accessible
  # Add this to your configuration.nix temporarily to test
  
  environment.systemPackages = with pkgs; [
    # Regular package
    hello
    
    # Test NUR package - should work now!
    # Note: Replace with an actual NUR package you want
    # nur.repos.<repo-name>.<package-name>
    
    # Example of how to use NUR packages (commented out)
    # nur.repos.iopq.xraya  # Xray proxy
    # nur.repos.mic92.hello-nur  # Example package
    # nur.repos.rycee.mozilla-addons-to-nix  # Firefox addons
  ];
  
  # Print for debugging - remove after verification
  system.activationScripts.nurTest = ''
    echo "=== NUR Verification ==="
    echo "NUR overlay available: ${if (builtins.hasAttr "nur" pkgs) then "YES" else "NO"}"
    echo "pkgs.nur.repos available: ${if (builtins.hasAttr "repos" (pkgs.nur or {})) then "YES" else "NO"}"
    echo "========================"
  '';
}