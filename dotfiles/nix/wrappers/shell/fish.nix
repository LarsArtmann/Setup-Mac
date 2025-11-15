# Fish Shell Wrapper
# Embedded Fish configuration with optimized performance

{ pkgs, lib, writeShellScriptBin, symlinkJoin, makeWrapper }:

let
  # Simple wrapper function using writeShellScriptBin
  wrapWithConfig = { name, package, configFiles ? {}, env ? {}, preHook ? "", postHook ? "" }:
    writeShellScriptBin name ''
      ${preHook}
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v: "export ${k}=\"${v}\"") env)}

      # Ensure config directories exist
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (configPath: source: ''
        mkdir -p "$(dirname "$HOME/.${configPath}")"
        ln -sf "${source}" "$HOME/.${configPath}" 2>/dev/null || true
      '') configFiles)}

      # Run the original binary
      exec "${lib.getBin package}/bin/${name}" "$@"
      ${postHook}
    '';

  # Optimized fish configuration
  fishConfig = pkgs.writeText "config.fish" ''
    # 🐟 Optimized Fish Configuration
    # Performance-optimized with 400ms timeout protection

    # Performance settings
    set -U fish_greeting ""  # Disable greeting for faster startup
    set -U fish_prompt_timeout 400  # 400ms timeout

    # Path optimization - high-frequency tools first
    set -gx PATH /run/current-system/sw/bin /usr/local/bin $PATH

    # Environment variables
    set -gx EDITOR "code --wait"
    set -gx VISUAL "code --wait"
    set -gx LANG en_US.UTF-8
    set -gx LC_ALL en_US.UTF-8

    # Go development
    set -gx GOPATH $HOME/go
    set -gx GOPROXY https://proxy.golang.org,direct
    set -gx GOSUMDB sum.golang.org
    set -gx PATH $GOPATH/bin $PATH

    # Node.js development
    set -gx NODE_OPTIONS "--max-old-space-size=4096"

    # Python development
    set -gx PYTHONPATH $HOME/.local/lib/python3.11/site-packages

    # Nix optimization
    set -gx NIX_PATH "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixpkgs"

    # History optimization
    set -U fish_history_max_entries 5000
    set -U fish_history_save_time 3600  # Save every hour

    # Completions optimization
    set -U fish_complete_path /usr/local/share/fish/completions /run/current-system/sw/share/fish/completions

    # Source additional configs if they exist (for backward compatibility)
    if test -f $HOME/.config/fish/conf.d/custom.fish
        source $HOME/.config/fish/conf.d/custom.fish
    end

    # Initialize starship if available
    if command -v starship >/dev/null
        starship init fish | source
    end

    # Initialize direnv if available
    if command -v direnv >/dev/null
        direnv hook fish | source
    end
  '';

  # Fish functions for enhanced productivity
  fishFunctions = {
    "ll.fish" = pkgs.writeText "ll.fish" ''
      function ll --description 'List files in long format with color'
        ls -la $argv
      end
    '';

    "la.fish" = pkgs.writeText "la.fish" ''
      function la --description 'List all files including hidden'
        ls -la $argv
      end
    '';

    "mkcd.fish" = pkgs.writeText "mkcd.fish" ''
      function mkcd --description 'Create directory and change to it'
        mkdir -p $argv[1] and cd $argv[1]
      end
    '';
  };

  # Create Fish wrapper
  fishWrapper = wrapWithConfig {
    name = "fish";
    package = pkgs.fish;
    configFiles = {
      "config/fish/config.fish" = fishConfig;
    } // (lib.mapAttrs' (name: source: {
      name = "config/fish/functions/${name}";
      value = source;
    }) fishFunctions);
    env = {
      SHELL = "${pkgs.fish}/bin/fish";
      FISH_CONFIG_DIR = "$HOME/.config/fish";
    };
    preHook = ''
      # Create fish directories
      mkdir -p "$FISH_CONFIG_DIR"/{functions,completions,conf.d}
    '';
  };

in
{
  # Export the wrapper for use in system packages
  fish = fishWrapper;
}