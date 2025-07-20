# NUR (Nix User Repository) Configuration
# Community packages and modules
{ pkgs, nur, lib, ... }:

{
  # Enable NUR overlay for access to community packages
  nixpkgs.overlays = [
    nur.overlays.default
  ];

  # Example community packages that can be installed via NUR
  # Uncomment and add specific packages as needed
  environment.systemPackages = with pkgs; [
    # Web development tools
    # nur.repos.mic92.hello-nur  # Example package
    
    # Security tools from community
    # nur.repos.mic92.cntr       # Container introspection tool
    
    # Development utilities
    # nur.repos.bandithedoge.firefox-addons.ublock-origin  # For browser automation
  ] ++ lib.optionals pkgs.stdenv.isDarwin [
    # macOS-specific community packages
  ];

  # NUR modules can be imported here
  # imports = [
  #   nur.repos.username.modules.some-module
  # ];
}