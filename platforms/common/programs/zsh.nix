{config, ...}: {
  # Common Zsh shell configuration
  programs.zsh = {
    enable = true;
    dotDir = "${config.xdg.configHome}/zsh";

    # Common aliases (platform-specific added via lib.mkAfter in platform configs)
    shellAliases = {
      # Essential shortcuts
      l = "ls -laSh";
      t = "tree -h -L 2 -C --dirsfirst";
    };
  };
}
