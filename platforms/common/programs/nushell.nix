# Nushell shell configuration (Cross-Platform)
# Migrated from dotfiles/.config/nushell/
_: {
  programs.nushell = {
    enable = true;

    # Environment configuration
    envFile.text = ''
      # Ensure nushell inherits system PATH from nix-darwin/nixos
      # This approach ensures consistency across shells

      # Get the system PATH from environment
      # This will capture PATH set by nix-darwin/nixos
      let system_path = $env.PATH?

      # If we have a system PATH, use it
      if $system_path != null {
        # PATH is already a list in nushell
        $env.PATH = $system_path
      } else {
        # Fallback minimal PATH if system PATH is not available
        $env.PATH = [
          "/opt/homebrew/bin"
          "/opt/homebrew/sbin"
          "/usr/local/bin"
          "/usr/bin"
          "/bin"
          "/usr/sbin"
          "/sbin"
        ]
      }

      # Set other environment variables
      $env.EDITOR = "micro"  # micro-full is installed in base.nix
      $env.LANG = "en_GB.UTF-8"

      # Fix GitHub CLI pager issues by disabling pager
      $env.GH_PAGER = ""

      # Debug: Uncomment to see PATH when nushell starts
      # print $"PATH: ($env.PATH | str join ':')"
    '';

    # Main configuration
    configFile.text = ''
      # Nushell configuration

      # Custom aliases
      alias l = ls -la
      alias c2p = code2prompt . --output=code2prompt.md --tokens

      # Note: nixup, diskStealer aliases are platform-specific:
      # - nixup: Use darwin-rebuild/nixos-rebuild via shell aliases
      # - diskStealer: Use ncdu directly
    '';
  };
}
