{ config, pkgs, lib, nur, ... }:

{
  imports = [
    # Import CRUSH module from NUR - passed as parameter from flake.nix
    nur.repos.charmbracelet.modules.crush
  ];

  # Enable CRUSH AI assistant
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