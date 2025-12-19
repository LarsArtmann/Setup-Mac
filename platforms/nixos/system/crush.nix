{ config, pkgs, lib, ... }:

{
  imports = 
    # Import CRUSH module from NUR - only available after overlay is applied
    lib.optionals (lib.hasAttr "nur" pkgs && lib.hasAttr "repos" pkgs.nur && lib.hasAttr "charmbracelet" pkgs.nur.repos) [
      pkgs.nur.repos.charmbracelet.modules.crush
    ];

  # Enable CRUSH AI assistant if module was imported
  programs.crush = lib.mkIf (lib.hasAttr "nur" pkgs && lib.hasAttr "repos" pkgs.nur && lib.hasAttr "charmbracelet" pkgs.nur.repos) {
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
  
  # Add warning if NUR is not available
  warnings = lib.mkIf !(lib.hasAttr "nur" pkgs && lib.hasAttr "repos" pkgs.nur && lib.hasAttr "charmbracelet" pkgs.nur.repos) [
    "NUR (nix-user-repository) is not available - CRUSH module cannot be loaded"
  ];
}