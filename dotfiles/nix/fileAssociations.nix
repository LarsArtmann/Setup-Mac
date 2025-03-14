{ config, pkgs, lib, ... }:
{
  system.activationScripts = {
    # Consider switching to home-manager since this seems to be a user-specific configuration
    #   while it might be executed as root
    setFileAssociations.text = ''
      ${pkgs.duti}/bin/duti -s com.sublimetext.4 .txt all
      ${pkgs.duti}/bin/duti -s com.sublimetext.4 .md all
      ${pkgs.duti}/bin/duti -s com.sublimetext.4 .json all
      ${pkgs.duti}/bin/duti -s com.sublimetext.4 .yaml all
      ${pkgs.duti}/bin/duti -s com.sublimetext.4 .yml all
      ${pkgs.duti}/bin/duti -s com.apple.TextEdit .rtf all
    '';
  };
}