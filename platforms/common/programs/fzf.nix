# FZF configuration (Cross-Platform)
# Migrated from dotfiles/.fzf.zsh
# Home Manager manages completion and keybindings automatically
_: {
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    enableFishIntegration = true;

    # FZF options
    defaultOptions = [
      "--height 40%"
      "--layout=reverse"
      "--border"
      "--cycle"
    ];

    # Use ripgrep for better search performance
    defaultCommand = "rg --files --hidden --glob '!.git'";

    # Ctrl+T and Ctrl+R keybindings are configured automatically
    # No manual sourcing needed
  };
}
