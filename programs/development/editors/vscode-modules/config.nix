# VS Code Configuration Module
# Configuration management for VS Code settings, extensions, and files

{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.programs.vscode.configuration;
in {
  config = mkIf config.programs.vscode.enable {
    # Configuration Management
    systemd.services.vscode-config = {
      description = "Manage VS Code configuration";
      wantedBy = [ "multi-user.target" ];
      after = [ "vscode-permissions.service" ];
      serviceConfig.Type = "oneshot";
      script = ''
        echo "Configuring VS Code..."

        # Create configuration directories
        mkdir -p ~/.vscode/{extensions,keybindings,snippets}
        mkdir -p ~/.vscode-server

        # Write VS Code settings
        echo "Writing VS Code settings..."
        cat > ~/.vscode/settings.json << 'EOF'
${builtins.toJSON cfg.settings}
EOF

        # Write keybindings
        echo "Writing VS Code keybindings..."
        cat > ~/.vscode/keybindings.json << 'EOF'
${builtins.toJSON cfg.keybindings}
EOF

        # Write snippets
        echo "Writing VS Code snippets..."
        cat > ~/.vscode/snippets/global.code-snippets << 'EOF'
${builtins.toJSON cfg.snippets}
EOF

        # Write additional configuration files
        ${concatStringsSep "\n" (mapAttrsToList (path: content: ''
          echo "Writing configuration to ${path}"
          mkdir -p "$(dirname "${path}")"
          cat > "${path}" << 'EOF'
${content}
EOF
        '') cfg.files)}

        # Set ownership for all config files
        chown -R $USER:$USER ~/.vscode ~/.vscode-server

        echo "VS Code configuration completed"
      '';
    };
  };
}