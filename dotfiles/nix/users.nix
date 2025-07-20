{ pkgs, lib, ... }:
let
  # User configuration validation
  username = "larsartmann";
  userShell = pkgs.fish;

  # Validate user configuration
  validateUserShell = shell:
    if shell == null then
      throw "User shell cannot be null"
    else if !(lib.hasAttr "outPath" shell) then
      throw "Invalid shell package provided"
    else shell;

in {
  # Enhanced user configuration with validation
  assertions = [
    {
      assertion = username != null && username != "";
      message = "Username must be defined and non-empty";
    }
    {
      assertion = userShell != null;
      message = "User shell must be defined";
    }
  ];

  users = {
    # Enhanced user configuration
    # Note: defaultUserShell option does not exist in nix-darwin
    users.${username} = {
      shell = validateUserShell userShell;
      # Additional user configuration options:
      # home = "/Users/${username}";
      # uid = 501;  # Specify if needed for consistency
      # description = "Lars Artmann";
    };
  };
}
