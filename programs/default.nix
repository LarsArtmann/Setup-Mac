# Program modules entry point
# Imports and exports all isolated program modules

{ lib, pkgs }:

let
  # Import all program modules
  programModules = {
    # Development programs
    development = {
      editors = {
        vscode = import ./development/editors/vscode.nix { inherit lib config pkgs; };
        # Future editors can be added here:
        # sublime = import ./development/editors/sublime.nix { inherit lib config pkgs; };
        # vim = import ./development/editors/vim.nix { inherit lib config pkgs; };
      };

      languages = {
        # go = import ./development/languages/go.nix { inherit lib config pkgs; };
        # nodejs = import ./development/languages/nodejs.nix { inherit lib config pkgs; };
        # python = import ./development/languages/python.nix { inherit lib config pkgs; };
      };

      tools = {
        # docker = import ./development/tools/docker.nix { inherit lib config pkgs; };
        # k9s = import ./development/tools/k9s.nix { inherit lib config pkgs; };
      };
    };

    # Core system programs
    core = {
      shell = {
        # fish = import ./core/shell/fish.nix { inherit lib config pkgs; };
        # zsh = import ./core/shell/zsh.nix { inherit lib config pkgs; };
        # starship = import ./core/shell/starship.nix { inherit lib config pkgs; };
      };

      security = {
        # gpg = import ./core/security/gpg.nix { inherit lib config pkgs; };
        # ssh = import ./core/security/ssh.nix { inherit lib config pkgs; };
      };

      networking = {
        # wireguard = import ./core/networking/wireguard.nix { inherit lib config pkgs; };
        # tailscale = import ./core/networking/tailscale.nix { inherit lib config pkgs; };
      };
    };

    # Media and creative programs
    media = {
      graphics = {
        # blender = import ./media/graphics/blender.nix { inherit lib config pkgs; };
        # gimp = import ./media/graphics/gimp.nix { inherit lib config pkgs; };
      };

      audio = {
        # reaper = import ./media/audio/reaper.nix { inherit lib config pkgs; };
        # audacity = import ./media/audio/audacity.nix { inherit lib config pkgs; };
      };

      video = {
        # kdenlive = import ./media/video/kdenlive.nix { inherit lib config pkgs; };
        # obs = import ./media/video/obs.nix { inherit lib config pkgs; };
      };
    };

    # Monitoring and system utilities
    monitoring = {
      # activitywatch = import ./monitoring/activitywatch.nix { inherit lib config pkgs; };
      # netdata = import ./monitoring/netdata.nix { inherit lib config pkgs; };
      # prometheus = import ./monitoring/prometheus.nix { inherit lib config pkgs; };
    };
  };

  # Flatten all program modules into a single attribute set
  flattenPrograms = { prefix ? "", modules }:
    let
      # Helper function to recursively flatten nested modules
      flatten = attrs:
        let
          # Process each attribute
          processed = mapAttrs (name: value:
            if value ? options && value ? config then
              # This is a NixOS module, keep it as-is
              { "${prefix}${name}" = value; }
            else if isAttrs value then
              # This is a nested structure, recurse
              flatten value
            else
              {}
          ) attrs;

          # Merge all the processed results
          merged = foldl' (acc: elem: acc // elem) {} (attrValues processed);
        in
        merged;
    in
    flatten modules;

  # Get all available programs
  allPrograms = flattenPrograms { modules = programModules; };

in
{
  # Export all program modules
  inherit programModules allPrograms;

  # Function to get a specific program module
  getProgram = name: allPrograms."${name}" or (throw "Unknown program: ${name}");

  # Function to get all programs in a category
  getProgramsByCategory = category:
    let
      categoryPath = lib.splitString "." category;
      result = lib.attrsetByPath categoryPath programModules;
    in
    if result != null then result else throw "Unknown category: ${category}";

  # Function to get all program names
  listPrograms = attrNames allPrograms;

  # Function to get all categories
  listCategories = let
    # Recursively find all category paths
    findCategories = prefix: attrs:
      let
        categories = mapAttrsToList (name: value:
          if value ? options && value ? config then
            []  # This is a program, not a category
          else if isAttrs value then
            [ "${prefix}${name}" ] ++ findCategories "${prefix}${name}." value
          else
            []
        ) attrs;
      in
      flatten categories;
  in
  findCategories "" programModules;

  # Generate packages from enabled programs
  generatePackages = enabledPrograms:
    let
      # For each enabled program, generate package definitions
      programPackages = mapAttrs (name: programConfig:
        # This would create the actual package based on the program configuration
        # For now, return the primary package if available
        if programConfig ? package && programConfig.package != null then
          programConfig.package
        else if name == "vscode" then
          pkgs.vscode
        else
          null
      ) enabledPrograms;

      # Filter out null values
      validPackages = filterAttrs (n: v: v != null) programPackages;
    in
    validPackages;

  # Generate systemd services from enabled programs
  generateServices = enabledPrograms:
    let
      # For each enabled program, generate service definitions
      programServices = mapAttrs (name: programConfig:
        if programConfig ? services && programConfig.services.enable then
          # Convert service definitions to systemd format
          mapAttrs' (serviceName: serviceConfig:
            lib.nameValuePair "${name}-${serviceName}" {
              description = serviceConfig.description;
              wantedBy = serviceConfig.wantedBy;
              after = serviceConfig.after;
              serviceConfig = {
                ExecStart = serviceConfig.execStart;
                Restart = "always";
                User = serviceConfig.user;
                Environment = lib.mapAttrsToList (k: v: "${k}=${v}") serviceConfig.environment;
              };
            }
          ) (filterAttrs (n: v: v.enable) programConfig.services.definitions)
        else
          {}
      ) enabledPrograms;

      # Merge all service definitions
      allServices = foldl' (acc: services: acc // services) {} (attrValues programServices);
    in
    allServices;

  # Export as both modules and utilities
  lib = {
    inherit flattenPrograms getProgram getProgramsByCategory listPrograms listCategories;
    inherit generatePackages generateServices;
  };
}