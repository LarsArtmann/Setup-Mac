{pkgs, ...}: {
  # Import common environment variables
  imports = [../common/environment/variables.nix];

  # Darwin-specific environment variables
  environment.variables = {
    # macOS-specific settings
    BROWSER = "google-chrome"; ## TODO: <-- Helium?
    TERMINAL = "iTerm2"; ## TODO: <-- should we move this to the dedicated iterm2 config?
  };

  # Darwin-specific packages
  environment.systemPackages = with pkgs; [
    # Additional macOS-specific system packages can go here
    # Chrome and Helium are now managed through common/packages/base.nix

    # iterm2 ## TEMPORARILY DISABLED: Build fails with /usr/include error on macOS Sequoia
    # Issue: error: getting attributes of required path '/usr/include': No such file or directory
    # Root cause: iTerm2 derivation requires /usr/include which doesn't exist on modern macOS
    # Status: Waiting for nixpkgs fix or alternative installation method
  ];
}
