{pkgs, ...}: {
  # Import common environment variables
  imports = [../common/environment/variables.nix];

  # Darwin-specific environment variables
  environment.variables = {
    # macOS-specific settings
    BROWSER = "helium";
    TERMINAL = "iTerm2"; ## TODO: <-- should we move this to the dedicated iterm2 config?
  };

  # Darwin-specific packages - NOTE: iterm2 now in common/packages/base.nix
  # (platform-scoped with lib.optionals stdenv.isDarwin)
  # No additional system packages needed here
}
