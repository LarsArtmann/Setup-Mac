{ pkgs, lib, ... }:

{
  # Enable CRUSH AI assistant (Cross-Platform)
  programs.crush = {
    enable = true;
    settings = {
      options = {
        context_paths = [
          "$HOME/.config/crush/AGENTS.md"
          "AGENTS.md"
          "CRUSH.md"
        ];
        tui = { compact_mode = true; };
        debug = false;
      };
    };
  };
}