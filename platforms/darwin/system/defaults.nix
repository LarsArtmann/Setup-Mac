{ pkgs, lib, ... }:

let
  # Import centralized user configuration
  userConfig = import ../../../../dotfiles/nix/core/UserConfig.nix { inherit lib; };

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

      # Finder settings (Darwin-specific)
      setFinderCalculateAllSizes.text = ''
        defaults write com.apple.finder FXCalculateAllSizes -bool true
        killall Finder
      '';

      # Register applications with Launch Services (Darwin-specific)
      registerApplications.text = ''
        echo "Registering applications with Launch Services..."
        /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "/Applications/Nix Apps"

        echo "Updating Spotlight index for Nix applications..."
        mdimport "/Applications/Nix Apps"
      '';
    };

    checks = {
      verifyBuildUsers = true;
      verifyMacOSVersion = true;
      # verifyNixPath = true; # DO NOT enable! "error: file 'darwin-config' was not found in the Nix search path"
    };
  };

  # Enhanced Security Configuration for Darwin
  security.pam.services = {
    # Enable Touch ID for sudo operations (Darwin-specific)
    sudo_local.touchIdAuth = true;
  };

  # Set Darwin configuration path (Darwin-specific)
  environment.darwinConfig = "$HOME/.nixpkgs/darwin-configuration.nix";
}