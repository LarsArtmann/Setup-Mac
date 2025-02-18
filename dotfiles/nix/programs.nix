{
  zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      l = "ls -laSh";
      rm = "rm -i";
      nixup = "darwin-rebuild switch";
      mkdir = "mkdir -p";
    };
    histSize = 10000;
    oh-my-zsh = {
      enable = true;
      plugins = [ "aliases" ];
      theme = "robbyrussell";
    };
  };

  nushell = {
    enable = true;
  };

  nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
    flake = " /etc/nix-darwin/";
  };

  git = {
    enable = true;
    lfs.enable = true;
    userName = "Lars Artmann";
    userEmail = "git@lars.softare";
  };
}
