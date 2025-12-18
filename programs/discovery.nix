# Simple Program Discovery System
# Provides mechanism to list and manage available program modules

{ lib, pkgs, ... }:

{
  # List of all available programs
  availablePrograms = {
    vscode = {
      package = pkgs.vscode;
      description = "Visual Studio Code editor";
      category = "development";
      platforms = ["aarch64-darwin" "x86_64-linux"];
      module = ./development/editors/vscode.nix;
    };

    fish = {
      package = pkgs.fish;
      description = "Fish shell with smart completions";
      category = "core";
      platforms = ["aarch64-darwin" "x86_64-linux"];
      # Simple configuration (no external module yet)
      module = null;
    };

    starship = {
      package = pkgs.starship;
      description = "Minimal, fast, and customizable prompt";
      category = "core";
      platforms = ["aarch64-darwin" "x86_64-linux"];
      module = null;
    };

    git = {
      package = pkgs.git;
      description = "Distributed version control system";
      category = "development";
      platforms = ["aarch64-darwin" "x86_64-linux"];
      module = null;
    };
  };

  # Helper to get enabled program configurations
  getEnabledPrograms = enabledPrograms:
    let
      # Filter available programs to only enabled ones
      enabledProgramSet = lib.genAttrs enabledPrograms (name: name);
      filterFunc = name: config: lib.hasAttr name enabledProgramSet;
    in
    lib.filterAttrs filterFunc availablePrograms;

  # Helper to get packages from enabled programs
  getEnabledPackages = enabledPrograms:
    let
      enabledConfigs = getEnabledPrograms enabledPrograms;
    in
    lib.mapAttrsToList (name: config: config.package) enabledConfigs;

  # Helper to get program module imports
  getEnabledModules = enabledPrograms:
    let
      enabledConfigs = getEnabledPrograms enabledPrograms;
      hasModule = name: config: config.module != null;
    in
    lib.filterAttrs (name: config: hasModule name config) enabledConfigs;

  # List all programs with details
  listPrograms = format:
    let
      programList = lib.mapAttrsToList (name: config: {
        inherit name;
        inherit (config.description);
        inherit (config.category);
        inherit (config.platforms);
      }) availablePrograms;

      formatLine = program:
        if format == "simple" then
          "  ${program.name} - ${program.description} (${program.category})"
        else if format == "detailed" then
          "  ${program.name}:"
          + "    Description: ${program.description}"
          + "    Category: ${program.category}"
          + "    Platforms: ${lib.concatStringsSep ", " program.platforms}"
          + "    Module: ${if config.module != null then "Yes" else "No"}"
        else
          "${program.name}";
    in
    if format == "json" then
      builtins.toJSON programList
    else
      lib.concatMapStringsSep "\n" formatLine programList;
}