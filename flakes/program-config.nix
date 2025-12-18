# Simple program configuration management
# Provides type-safe configuration for program modules

{ lib, ... }:

{
  options = {
    setup-mac.programs = {
      enable = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "List of enabled program modules";
        example = ["vscode" "fish" "starship"];
      };
      
      settings = lib.mkOption {
        type = lib.types.attrsOf (lib.types.attrs);
        default = {};
        description = "Program-specific configuration settings";
        example = {
          vscode = {
            theme = "dark";
            extensions = ["ms-python.python"];
          };
        };
      };
      
      autoEnable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Automatically enable all available programs";
      };
    };
  };
}