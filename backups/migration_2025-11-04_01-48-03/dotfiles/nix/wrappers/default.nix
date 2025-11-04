# Advanced Nix Software Wrapping System
# Transforms traditional dotfiles into self-contained, portable packages

{ config, lib, pkgs, ... }:

with lib;

let
  # Simple wrapper function using writeShellScriptBin
  wrapBinary = { name, package, env ? {}, preHook ? "", postHook ? "" }:
    pkgs.writeShellScriptBin name ''
      ${preHook}
      ${concatStringsSep "\n" (mapAttrsToList (k: v: "export ${k}=\"${v}\"") env)}
      exec "${lib.getBin package}/bin/${name}" "$@"
      ${postHook}
    '';
  
  # Function to create a package with embedded config files
  wrapWithConfig = { name, package, configFiles ? {}, env ? {} }:
    let
      # Generate config file symlinks
      configSymlinks = mapAttrs' (configPath: source: {
        name = "$HOME/.${configPath}";
        value = source;
      }) configFiles;
    in pkgs.runCommand "${name}-wrapped" { } ''
      mkdir -p $out/bin
      
      # Create a wrapper script
      cat > $out/bin/${name} << EOF
      #!/bin/sh
      ${concatStringsSep "\n" (mapAttrsToList (k: v: "export ${k}=\"${v}\"") env)}
      
      # Ensure config directories exist
      ${concatStringsSep "\n" (mapAttrsToList (configPath: source: ''
        mkdir -p "$(dirname "$HOME/.${configPath}")"
        ln -sf "${source}" "$HOME/.${configPath}" 2>/dev/null || true
      '') configFiles)}
      
      # Run the original binary
      exec "${lib.getBin package}/bin/${name}" "\$@"
      EOF
      
      chmod +x $out/bin/${name}
    '';
  
  # Wrappers for specific applications
  batWrapper = wrapWithConfig {
    name = "bat";
    package = pkgs.bat;
    configFiles = {
      "config/bat/config" = pkgs.writeText "bat-config" ''
        --theme="gruvbox-dark"
        --style="numbers,changes,header"
      '';
    };
    env = {
      BAT_CONFIG_PATH = "$HOME/.config/bat/config";
      BAT_THEME = "gruvbox-dark";
      BAT_STYLE = "numbers,changes,header";
    };
  };
  
  starshipWrapper = wrapWithConfig {
    name = "starship";
    package = pkgs.starship;
    configFiles = {
      "config/starship.toml" = pkgs.writeText "starship.toml" ''
        # 🚀 Optimized Starship Configuration
        [character]
        success_symbol = "[➜](bold #50fa7b)"
        error_symbol = "[➜](bold #ff5555)"
        [aws]
        disabled = true
        [gcloud]
        disabled = true
        [git_branch]
        symbol = ""
        format = "on [$symbol$branch]($style) "
        [cmd_duration]
        min_time = 1000
        [nix_shell]
        symbol = "❄️"
        [go]
        format = "via [$symbol$version]($style) "
      '';
    };
    env = {
      STARSHIP_CONFIG = "$HOME/.config/starship.toml";
      STARSHIP_CACHE = "$HOME/.cache/starship";
      STARSHIP_LOG = "error";
    };
  };
  
  fishWrapper = wrapWithConfig {
    name = "fish";
    package = pkgs.fish;
    configFiles = {
      "config/fish/config.fish" = pkgs.writeText "config.fish" ''
        # 🐟 Optimized Fish Configuration
        set -U fish_greeting ""
        set -U fish_prompt_timeout 400
        
        # Environment variables
        set -gx EDITOR "code --wait"
        set -gx VISUAL "code --wait"
        set -gx LANG en_US.UTF-8
        
        # Go development
        set -gx GOPATH $HOME/go
        set -gx GOPROXY https://proxy.golang.org,direct
        set -gx GOSUMDB sum.golang.org
        set -gx PATH $GOPATH/bin $PATH
        
        # Initialize starship if available
        if command -v starship >/dev/null
            starship init fish | source
        end
      '';
    };
    env = {
      FISH_CONFIG_DIR = "$HOME/.config/fish";
    };
  };

in
{
  # Core wrapper system configuration
  config = {
    # Development tools with embedded configurations
    environment.systemPackages = with pkgs; [
      batWrapper
      starshipWrapper
      fishWrapper
    ];
    
    # Set wrapped tools as defaults
    environment.shellAliases = {
      cat = "bat";  # Use wrapped bat instead of cat
    };
  };
}