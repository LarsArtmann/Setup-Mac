{ pkgs, lib, ... }:
{
  programs = {
    # TODO: ADD https://mynixos.com/nix-darwin/options/programs
    #https://github.com/LnL7/nix-darwin/blob/master/modules/programs/zsh/default.nix
    zsh = {
      enable = true;
      enableCompletion = true;
      enableFzfCompletion = true;
      enableSyntaxHighlighting = true;
      #autosuggestions.enable = true;
      #syntaxHighlighting.enable = true;
      #shellAliases = {
      #  l = "ls -laSh";
      #  rm = "rm -i";
      #  nixup = "darwin-rebuild switch";
      #  mkdir = "mkdir -p";
      #};
      #histSize = 10000;
      #oh-my-zsh = {
      #  enable = true;
      #  plugins = [ "aliases" "fuck" ];
      #  theme = "robbyrussell";
      #};
    };
    #nushell = {
    #  enable = true;
    #  shellAliases = (import ./environment.nix { pkgs = pkgs; lib = lib; }).environment.shellAliases;
    #};
    #error: The option `programs.nh' does not exist.
    #nh = {
    #  enable = true;
    #  package = nixpkgs-nh-dev;
    #  clean = {
    #    enable = true;
    #    extraArgs = "--keep-since 4d --keep 3";
    #  };
    #  flake = "/etc/nix-darwin/";
    #};
    #git = {
    #  enable = true;
    #  lfs.enable = true;
    #  userName = "Lars Artmann";
    #  userEmail = "git@lars.software";
    #};
  };
}
