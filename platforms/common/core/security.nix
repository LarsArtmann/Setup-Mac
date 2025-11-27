{ lib, pkgs, ... }:

{
  # Common security settings (platform-agnostic)
  security = {
    # Enhanced PKI (Public Key Infrastructure) settings
    pki = {
      # Enable certificate verification for enhanced security
      installCACerts = true;
      # Additional certificate authorities can be added here if needed
      # certificateFiles = [ "/path/to/custom-ca.crt" ];
    };
  };

  # Common system validation
  assertions = [
    {
      assertion = pkgs.nix != null;
      message = "Nix package must be available";
    }
    {
      assertion = builtins.hasAttr "system" pkgs;
      message = "System information must be available";
    }
  ];
}