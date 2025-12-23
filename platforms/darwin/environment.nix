{pkgs, ...}: {
  # Import common environment variables
  imports = [../common/environment/variables.nix];

  # Darwin-specific environment variables
  environment.variables = {
    # macOS-specific settings
    BROWSER = "google-chrome";
    TERMINAL = "iTerm2";
  };

  # Darwin-specific packages
  environment.systemPackages = with pkgs; [
    # Additional macOS-specific system packages can go here
    # Chrome and Helium are now managed through common/packages/base.nix
  ];
}
