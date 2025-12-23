# Path Configuration Module
# Centralized path management with type safety
# Eliminates hardcoded path fragmentation across the system
{lib, ...}: let
  # Path type definitions with validation
  PathType = lib.types.submodule {
    options = {
      home = lib.mkOption {
        type = lib.types.path;
        description = "User home directory";
        example = "/Users/larsartmann";
      };

      config = lib.mkOption {
        type = lib.types.path;
        description = "Configuration directory";
        example = "/Users/larsartmann/.config";
      };

      dotfiles = lib.mkOption {
        type = lib.types.path;
        description = "Dotfiles repository path";
        example = "/Users/larsartmann/Desktop/Setup-Mac/dotfiles";
      };

      nixConfig = lib.mkOption {
        type = lib.types.path;
        description = "Nix configuration directory";
        example = "/Users/larsartmann/Desktop/Setup-Mac/dotfiles/nix";
      };

      core = lib.mkOption {
        type = lib.types.path;
        description = "Core configuration modules";
        example = "/Users/larsartmann/Desktop/Setup-Mac/dotfiles/nix/core";
      };

      wrappers = lib.mkOption {
        type = lib.types.path;
        description = "Wrapper configurations";
        example = "/Users/larsartmann/Desktop/Setup-Mac/dotfiles/nix/wrappers";
      };
    };
  };

  # Default path configuration
  defaultPaths = {
    home = "/Users/larsartmann";
    config = "/Users/larsartmann/.config";
    dotfiles = "/Users/larsartmann/Desktop/Setup-Mac/dotfiles";
    nixConfig = "/Users/larsartmann/Desktop/Setup-Mac/dotfiles/nix";
    core = "/Users/larsartmann/Desktop/Setup-Mac/dotfiles/nix/core";
    wrappers = "/Users/larsartmann/Desktop/Setup-Mac/dotfiles/nix/wrappers";
  };
in {
  # Export types for external use
  inherit PathType;

  # Default configuration
  inherit defaultPaths;

  # Helper functions
  mkPathConfig = username: {
    home = "/Users/${username}";
    config = "/Users/${username}/.config";
    dotfiles = "/Users/${username}/Desktop/Setup-Mac/dotfiles";
    nixConfig = "/Users/${username}/Desktop/Setup-Mac/dotfiles/nix";
    core = "/Users/${username}/Desktop/Setup-Mac/dotfiles/nix/core";
    wrappers = "/Users/${username}/Desktop/Setup-Mac/dotfiles/nix/wrappers";
  };

  # Path manipulation helpers
  joinPaths = baseDir: subDir: "${baseDir}/${subDir}";

  # Validation helpers
  validatePathConfig = paths:
    lib.all (path: lib.pathExists path || path == "/Users/${builtins.getEnv "USER"}") [
      paths.home
      paths.config
      paths.dotfiles
      paths.nixConfig
      paths.core
    ];

  # assertions for path validation
  pathAssertions = paths: [
    {
      assertion = lib.hasPrefix "/Users/" paths.home;
      message = "home directory must be under /Users";
    }
    {
      assertion = lib.hasPrefix "/Users/" paths.config;
      message = "config directory must be under /Users";
    }
    {
      assertion = lib.hasPrefix "dotfiles" paths.dotfiles;
      message = "dotfiles path must contain 'dotfiles'";
    }
    {
      assertion = lib.hasPrefix "nix" paths.nixConfig;
      message = "nixConfig path must contain 'nix'";
    }
  ];
}
