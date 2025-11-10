# User Configuration Module
# Centralized single source of truth for all user-specific configuration
# Eliminates split-brain user configuration across multiple files

{ lib, ... }:

let
  # Type definitions for user configuration
  UserType = lib.types.submodule {
    options = {
      username = lib.mkOption {
        type = lib.types.str;
        description = "System username";
        example = "larsartmann";
      };

      fullName = lib.mkOption {
        type = lib.types.str;
        description = "User's full name";
        example = "Lars Artmann";
        default = "";
      };

      email = lib.mkOption {
        type = lib.types.str;
        description = "User's email address";
        example = "lars@example.com";
        default = "";
      };

      homeDir = lib.mkOption {
        type = lib.types.path;
        description = "User's home directory";
        example = "/Users/larsartmann";
        readOnly = true;
      };

      configDir = lib.mkOption {
        type = lib.types.path;
        description = "User's configuration directory";
        example = "/Users/larsartmann/.config";
        readOnly = true;
      };
    };
  };

in {
  # Export types for external use
  inherit UserType;

  # Default user configuration with strong typing
  defaultUser = {
    username = "larsartmann";
    fullName = "Lars Artmann";
    email = "lars@larsartmann.de";
    homeDir = "/Users/larsartmann";
    configDir = "/Users/larsartmann/.config";
  };

  # Helper functions for user configuration
  mkUserConfig = user: {
    inherit (user) username fullName email;
    homeDir = "/Users/${user.username}";
    configDir = "/Users/${user.username}/.config";
  };

  # Validation functions
  validateUserConfig = user:
    lib.assertions.assertionMsg
      (lib.hasPrefix "/Users/" user.homeDir)
      "homeDir must be under /Users directory"
    &&
    lib.assertions.assertionMsg
      (lib.hasPrefix "/Users/" user.configDir)
      "configDir must be under /Users directory";
}