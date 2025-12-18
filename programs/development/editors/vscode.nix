# VS Code - Refactored Modular Program
# Complete VS Code management with modular architecture

{ config, lib, pkgs, ... }:

with lib;
{
  imports = [
    ./options.nix
    ./zfs.nix
    ./permissions.nix
    ./config.nix
    ./services.nix
  ];

  config = mkIf config.programs.vscode.enable {
    # Platform-specific configuration merging
    programs.vscode = mkMerge [
      (mkIf (config.programs.vscode.platforms.darwin.enable && pkgs.stdenv.isDarwin)
        config.programs.vscode.platforms.darwin.overrides)
      (mkIf (config.programs.vscode.platforms.linux.enable && pkgs.stdenv.isLinux)
        config.programs.vscode.platforms.linux.overrides)
    ];

    # Shell Integration
    programs.zsh.shellAliases = {
      code = "code --user-data-dir ~/.vscode";
      "code-work" = "code ~/projects/work";
      "code-personal" = "code ~/projects/personal";
    };

    # Environment Variables
    environment.sessionVariables = config.programs.vscode.configuration.environment;

    # Setup Hook Execution
    systemd.services.vscode-setup = {
      description = "VS Code setup hooks";
      wantedBy = [ "multi-user.target" ];
      after = [ "vscode-config.service" ];
      serviceConfig.Type = "oneshot";
      script = ''
        ${config.programs.vscode.hooks.preSetup}
        ${config.programs.vscode.hooks.postSetup}
      '';
    };

    # Cleanup Hook (executed on module disable)
    systemd.services.vscode-cleanup = {
      description = "VS Code cleanup hooks";
      serviceConfig.Type = "oneshot";
      script = ''
        ${config.programs.vscode.hooks.preRemove}
        ${config.programs.vscode.hooks.postRemove}
      '';
    };
  };
}