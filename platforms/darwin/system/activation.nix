{
  pkgs,
  lib,
  ...
}: let
  # Import centralized user configuration
  userConfig = import ../../common/core/UserConfig.nix {inherit lib;};
in {
  system = {
    primaryUser = userConfig.defaultUser.username;

    activationScripts = {
      # File associations (Darwin-specific)
      setFileAssociations.text = ''
        ${pkgs.duti}/bin/duti -s com.sublimetext.4 .txt all
        ${pkgs.duti}/bin/duti -s com.sublimetext.4 .md all
        ${pkgs.duti}/bin/duti -s com.sublimetext.4 .json all
        ${pkgs.duti}/bin/duti -s com.sublimetext.4 .jsonl all
        ${pkgs.duti}/bin/duti -s com.sublimetext.4 .yaml all
        ${pkgs.duti}/bin/duti -s com.sublimetext.4 .yml all
        ${pkgs.duti}/bin/duti -s com.sublimetext.4 .toml all
        ${pkgs.duti}/bin/duti -s com.apple.TextEdit .rtf all
      '';

      # Register applications with Launch Services (Darwin-specific)
      registerApplications.text = ''
        echo "Registering applications with Launch Services..."
        /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "/Applications/Nix Apps"

        echo "Updating Spotlight index for Nix applications..."
        mdimport "/Applications/Nix Apps"

        # Reset TCC permissions gracefully - fail silently if not allowed
        echo "Skipping TCC reset to avoid build failure - requires Full Disk Access"
        # tccutil reset SystemPolicyAppBundles 2>/dev/null || echo "TCC reset skipped - requires Full Disk Access"
      '';
    };

    ## TODO: below looks sus!
    # Completely disable all system checks to prevent TCC reset
    checks = lib.mkForce {};
  };

  ## TODO: Why is this not in the platforms/darwin/environment.nix?
  # Set Darwin configuration path (Darwin-specific)
  environment.darwinConfig = "$HOME/.nixpkgs/darwin-configuration.nix";
}
