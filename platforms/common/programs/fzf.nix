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
      "--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8"
      "--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc"
      "--color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"
      "--color=selected-bg:#45475a,border:#585b70,label:#a6adc8"
    ];

    # Use ripgrep for better search performance
    defaultCommand = "rg --files --hidden --glob '!.git'";

    # Ctrl+T and Ctrl+R keybindings are configured automatically
    # No manual sourcing needed
  };
}
