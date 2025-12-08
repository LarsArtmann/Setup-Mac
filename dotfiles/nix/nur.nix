# NUR (Nix User Repository) Configuration
# Community packages and modules
{ pkgs, nur, lib, ... }:

{
  # Enable NUR overlay for access to community packages
  nixpkgs.overlays = [
    nur.overlays.default
  ];

  # Community packages installed via NUR
  environment.systemPackages = with pkgs; [
    # Development utilities from community
    # nur.repos.mic92.cntr       # Container introspection tool (if needed)

    # Browser automation and security tools
    # nur.repos.bandithedoge.firefox-addons.ublock-origin  # For browser automation

    # Additional community packages can be added here as needed
    # Browse available packages: https://nur.nix-community.org/
  ] ++ lib.optional pkgs.stdenv.isLinux [
    # Linux-specific community packages from NUR
    # Add Linux-specific NUR packages here
  ] ++ lib.optional pkgs.stdenv.isDarwin [
    # macOS-specific community packages from NUR
    # Add Darwin-specific NUR packages here
  ];

  # NUR modules can be imported here
  # imports = [
  #   nur.repos.username.modules.some-module
  # ];
}