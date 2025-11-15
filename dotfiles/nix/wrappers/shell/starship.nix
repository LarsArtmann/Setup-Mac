# Starship Prompt Wrapper
# Embedded starship configuration for portable shell experience

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

  # Starship configuration with optimized settings
  starshipConfig = pkgs.writeText "starship.toml" ''
    # 🚀 Optimized Starship Configuration
    # Embedded in wrapper for portability

    [character]
    success_symbol = "[➜](bold #50fa7b)"
    error_symbol = "[➜](bold #ff5555)"

    [aws]
    disabled = true

    [gcloud]
    disabled = true

    [jobs]
    symbol = ""

    [cmd_duration]
    min_time = 1000
    format = "took [$duration]($style) "

    [git_branch]
    symbol = ""
    truncation_symbol = ""
    format = "on [$symbol$branch]($style) "

    [git_status]
    format = "([\\[$all_status$ahead_behind\\]]($style) )"
    conflicted = "=$count"
    ahead = "⇡$count"
    behind = "⇣$count"
    diverged = "⇕$count"
    untracked = "?$count"
    modified = "!$count"
    staged = "+$count"
    renamed = "»$count"
    deleted = "✘$count"

    [nix_shell]
    symbol = "❄️"
    format = "via [$symbol$state( \($name\))]($style) "

    [nodejs]
    format = "via [$symbol$version]($style) "

    [python]
    format = "via [$symbol$pyenv_prefix]($style)python[$version]($style) "

    [go]
    format = "via [$symbol$version]($style) "

    [rust]
    format = "via [$symbol$version]($style) "

    [docker_context]
    symbol = "🐳"
    format = "via [$symbol$context]($style) "

    [time]
    disabled = false
    format = "at [$time]($style) "
    time_format = "%T"

    [package]
    disabled = false
    format = "is [$symbol$version]($style) "

    [lua]
    format = "via [$symbol$version]($style) "

    [vlang]
    format = "via [$symbol$version]($style) "

    [zig]
    format = "via [$symbol$version]($style) "
  '';

  # Create Starship wrapper
  starshipWrapper = wrapWithConfig {
    name = "starship";
    package = pkgs.starship;
    configFiles = {
      "config/starship.toml" = starshipConfig;
    };
    env = {
      STARSHIP_CONFIG = "$(pwd)/.config/starship.toml";
      STARSHIP_CACHE = "$(pwd)/.cache/starship";
      STARSHIP_LOG = "error";  # Reduce noise
    };
    preHook = ''
      # Create starship cache directory
      mkdir -p "$STARSHIP_CACHE"
    '';
  };

in
{
  # Export wrapper for use in system packages
  starship = starshipWrapper;
}