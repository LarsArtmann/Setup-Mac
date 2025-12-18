# 🚀 NIX NATIVE PATH FIX - Remove Conda Bullshit

{ config, pkgs, lib }:

let
  # Create custom environment with proper PATH
  cleanEnv = pkgs.buildEnv {
    name = "clean-user-env";
    paths = with pkgs; [
      # Essential system tools - ensure macOS native tools available
      nano  # Text editor at /usr/bin/nano
      open  # macOS file operations at /usr/bin/open
      clear # Terminal management at /usr/bin/clear

      # Nix-managed tools
      git vim fish starship curl wget tree ripgrep fd eza bat jq yq-go just
      glow bun git-town golangci-lint go gopls gitleaks iterm2 carapace
      bottom procs sd dust coreutils findutils gnused
    ];
  };

in
{
  # ✅ PROPER NIX PATH MANAGEMENT - No Manual PATH Overrides
  environment = {
    # Use buildEnv for clean PATH management
    systemPackages = [ cleanEnv ];

    # ✅ ONLY SET ESSENTIAL ENVIRONMENT VARIABLES
    variables = {
      EDITOR = "nano";
      SHELL = "${pkgs.fish}/bin/fish";
      LANG = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";

      # ✅ EXTEND PATH PROPERLY (don't override)
      PATH_EXTRA = [
        "${config.home.homeDirectory}/go/bin"
      ];
    };
  };
}
