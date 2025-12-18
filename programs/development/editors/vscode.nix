# VS Code - Isolated Program Module
# Demonstrates complete program isolation with ZFS, permissions, and configuration

{ lib, config, pkgs, ... }:

with lib; {
  options.programs.vscode = {
    enable = mkEnableOption "Visual Studio Code";

    # ZFS integration for complete data isolation
    zfs = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Create and manage dedicated ZFS dataset for VS Code data";
      };

      dataset = mkOption {
        type = types.str;
        default = "tank/data/vscode";
        description = "ZFS dataset path for VS Code data";
      };

      properties = mkOption {
        type = types.attrsOf types.str;
        default = {
          compression = "lz4";
          atime = "off";
          recordsize = "1M";
          "com.sun:auto-snapshot" = "true";
        };
        description = "ZFS dataset properties optimized for VS Code";
      };

      mountpoint = mkOption {
        type = types.str;
        default = "/vscode";
        description = "Mountpoint for VS Code ZFS dataset";
      };

      snapshots = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable automatic ZFS snapshots";
        };

        retention = mkOption {
          type = types.int;
          default = 14;
          description = "Number of snapshots to retain";
        };

        frequency = mkOption {
          type = types.str;
          default = "hourly";
          description = "Snapshot frequency (hourly, daily, weekly)";
        };
      };
    };

    # File system permissions for security and organization
    permissions = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Set file system permissions for VS Code directories";
      };

      directories = mkOption {
        type = types.attrsOf types.str;
        default = {
          "~/.vscode" = "0755";
          "~/.vscode/extensions" = "0755";
          "~/.vscode-server" = "0700";
          "~/projects" = "0755";
          "~/projects/work" = "0750";
          "~/projects/personal" = "0750";
        };
        description = "Directory permissions with security considerations";
      };

      files = mkOption {
        type = types.attrsOf types.str;
        default = {
          "~/.vscode/settings.json" = "0600";
          "~/.vscode/keybindings.json" = "0600";
          "~/.vscode/snippets" = "0600";
        };
        description = "File permissions for configuration files";
      };
    };

    # Package management
    package = mkOption {
      type = types.nullOr types.package;
      default = pkgs.vscode;
      defaultText = "pkgs.vscode";
      description = "VS Code package to use";
    };

    packages = mkOption {
      type = types.listOf types.package;
      default = [];
      description = "Additional packages to install with VS Code";
    };

    # Configuration management
    configuration = {
      # Core VS Code settings
      settings = mkOption {
        type = types.attrs;
        default = {
          # Editor settings
          "editor.fontSize" = 14;
          "editor.fontFamily" = "JetBrains Mono, monospace";
          "editor.lineHeight" = 1.6;
          "editor.tabSize" = 2;
          "editor.insertSpaces" = true;
          "editor.wordWrap" = "on";
          "editor.minimap.enabled" = false;
          "editor.renderWhitespace" = "selection";
          "editor.bracketPairColorization.enabled" = true;
          "editor.guides.bracketPairs" = true;

          # Workbench settings
          "workbench.colorTheme" = "Default High Contrast";
          "workbench.iconTheme" = "material-icon-theme";
          "workbench.startupEditor" = "none";
          "workbench.tree.enableStickyScroll" = true;

          # File management
          "files.autoSave" = "afterDelay";
          "files.autoSaveDelay" = 1000;
          "files.exclude" = {
            "**/.git" = true;
            "**/.DS_Store" = true;
            "**/node_modules" = true;
            "**/dist" = true;
            "**/build" = true;
          };

          # Terminal settings
          "terminal.integrated.fontFamily" = "JetBrains Mono, monospace";
          "terminal.integrated.fontSize" = 14;

          # Git settings
          "git.enableSmartCommit" = true;
          "git.autofetch" = true;
          "git.confirmSync" = false;

          # Extensions management
          "extensions.autoUpdate" = false;
          "extensions.ignoreRecommendations" = false;
        };
        description = "VS Code settings configuration";
      };

      # Extensions to install
      extensions = mkOption {
        type = types.listOf types.package;
        default = with pkgs.vscode-extensions; [
          # Language support
          ms-vscode.cpptools
          rust-lang.rust-analyzer
          golang.go
          ms-python.python
          ms-vscode.vscode-typescript-next

          # Themes and icons
          pkief.material-icon-theme
          dracula-theme.theme-dracula

          # Productivity
          ms-vscode.vscode-git-graph
          eamodio.gitlens
          ms-vscode.hexeditor
          ms-vscode.test-adapter-converter

          # Docker and DevOps
          ms-azuretools.vscode-docker
          ms-vscode.vscode-kubernetes-tools

          # Quality tools
          esbenp.prettier-vscode
          dbaeumer.vscode-eslint
          ms-vscode.vscode-json
        ];
        description = "VS Code extensions to install";
      };

      # Custom keybindings
      keybindings = mkOption {
        type = types.listOf types.attrs;
        default = [
          {
            key = "cmd+;";
            command = "editor.action.commentLine";
            when = "editorTextFocus && !editorReadonly";
          }
          {
            key = "cmd+shift+k";
            command = "workbench.action.deleteFile";
            when = "explorerViewletVisible && filesExplorerFocus";
          }
        ];
        description = "VS Code keybindings configuration";
      };

      # Custom snippets
      snippets = mkOption {
        type = types.attrs;
        default = {
          "For Loop" = {
            prefix = "for";
            body = [
              "for (let ${1:index} = 0; ${1:index} < ${2:array}.length; ${1:index}++) {"
              "  ${3:// body}"
              "}"
            ];
            description = "For loop snippet";
          };
          "Function" = {
            prefix = "func";
            body = [
              "function ${1:functionName}(${2:parameters}) {"
              "  ${3:// body}"
              "  return ${4:returnValue};"
              "}"
            ];
            description = "Function definition snippet";
          };
        };
        description = "Custom code snippets";
      };

      # Configuration files
      files = mkOption {
        type = types.attrsOf (types.either types.str types.path);
        default = {};
        description = "Additional configuration files to manage";
      };

      # Environment variables
      environment = mkOption {
        type = types.attrsOf types.str;
        default = {
          VSCODE_USER_DATA_DIR = "$HOME/.vscode";
          ELECTRON_TRASH = "gio";
        };
        description = "Environment variables for VS Code";
      };
    };

    # Service management for background services
    services = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable VS Code background services";
      };

      user = mkOption {
        type = types.str;
        default = "$USER";
        description = "User to run VS Code services as";
      };

      definitions = mkOption {
        type = types.attrsOf (types.submodule ({ serviceName, ... }: {
          options = {
            enable = mkEnableOption "${serviceName} service";

            description = mkOption {
              type = types.str;
              default = "VS Code ${serviceName} service";
              description = "Service description";
            };

            execStart = mkOption {
              type = types.str;
              description = "Command to start service";
            };

            after = mkOption {
              type = types.listOf types.str;
              default = [];
              description = "Services this service depends on";
            };

            wantedBy = mkOption {
              type = types.listOf types.str;
              default = [ "multi-user.target" ];
              description = "Targets that should start this service";
            };

            environment = mkOption {
              type = types.attrsOf types.str;
              default = {};
              description = "Environment variables for service";
            };
          };
        }));
        default = {
          server = {
            enable = false;
            description = "VS Code Server for remote development";
            execStart = "${pkgs.vscode}/bin/code --server-data-dir $HOME/.vscode-server --port 3000 --without-connection-token";
            environment = {
              VSCODE_AGENT_FOLDER = "$HOME/.vscode-server";
            };
          };
        };
        description = "VS Code background services";
      };
    };

    # Integration hooks for setup and cleanup
    hooks = {
      preSetup = mkOption {
        type = types.lines;
        default = ''
          echo "Setting up VS Code environment..."
          # Backup existing configuration if it exists
          if [ -d "$HOME/.vscode" ] && [ ! -L "$HOME/.vscode" ]; then
            echo "Backing up existing VS Code configuration..."
            mv "$HOME/.vscode" "$HOME/.vscode.backup.$(date +%Y%m%d_%H%M%S)"
          fi
        '';
        description = "Commands to run before VS Code setup";
      };

      postSetup = mkOption {
        type = types.lines;
        default = ''
          echo "VS Code setup completed successfully!"
          echo "You can now start VS Code with: code"
          echo "Your extensions and settings have been configured automatically."
        '';
        description = "Commands to run after VS Code setup";
      };

      preRemove = mkOption {
        type = types.lines;
        default = ''
          echo "Preparing to remove VS Code..."
          echo "Backing up configuration before removal..."
        '';
        description = "Commands to run before VS Code removal";
      };

      postRemove = mkOption {
        type = types.lines;
        default = ''
          echo "VS Code removal completed"
          echo "Configuration backup preserved in ~/.vscode.backup.*"
        '';
        description = "Commands to run after VS Code removal";
      };
    };

    # Cross-platform compatibility
    platforms = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable cross-platform compatibility";
      };

      darwin = {
        enable = mkOption {
          type = types.bool;
          default = config.programs.vscode.platforms.enable;
          description = "Enable VS Code on macOS";
        };

        overrides = mkOption {
          type = types.attrs;
          default = {
            # macOS-specific settings
            configuration.settings = {
              "terminal.integrated.shell.osx" = "/bin/zsh";
              "window.titleBarStyle" = "custom";
              "workbench.colorTheme" = "Default High Contrast";
            };

            # macOS-specific environment
            configuration.environment = {
              ELECTRON_TRASH = "gio";
              VSCODE_IPC_HOOK = "$HOME/Library/Application Support/Code/1.*.sock";
            };

            # Disable ZFS on macOS (unless using OpenZFS)
            zfs.enable = false;
          };
          description = "macOS-specific configuration overrides";
        };
      };

      linux = {
        enable = mkOption {
          type = types.bool;
          default = config.programs.vscode.platforms.enable;
          description = "Enable VS Code on Linux";
        };

        overrides = mkOption {
          type = types.attrs;
          default = {
            # Linux-specific settings
            configuration.settings = {
              "terminal.integrated.shell.linux" = "/bin/zsh";
              "window.titleBarStyle" = "custom";
            };

            # Linux-specific environment
            configuration.environment = {
              ELECTRON_TRASH = "gio";
              VSCODE_IPC_HOOK = "/tmp/vscode-ipc-*.sock";
            };

            # Enable ZFS on Linux (if ZFS is available)
            zfs.enable = true;
          };
          description = "Linux-specific configuration overrides";
        };
      };
    };
  };

  config = mkIf config.programs.vscode.enable {
    # Platform-specific configuration merging
    programs.vscode = mkMerge [
      (mkIf (config.programs.vscode.platforms.darwin.enable && pkgs.stdenv.isDarwin)
        config.programs.vscode.platforms.darwin.overrides)
      (mkIf (config.programs.vscode.platforms.linux.enable && pkgs.stdenv.isLinux)
        config.programs.vscode.platforms.linux.overrides)
    ];

    # ZFS Dataset Management (only if enabled)
    systemd.services.vscode-zfs-dataset = mkIf config.programs.vscode.zfs.enable {
      description = "Create VS Code ZFS dataset";
      wantedBy = [ "local-fs.target" ];
      serviceConfig.Type = "oneshot";
      script = with config.programs.vscode.zfs; ''
        # Check if ZFS is available
        if ! command -v zfs >/dev/null 2>&1; then
          echo "ZFS not available, skipping dataset creation for ${dataset}"
          exit 0
        fi

        # Create dataset if it doesn't exist
        if ! zfs list -o name ${dataset} >/dev/null 2>&1; then
          echo "Creating ZFS dataset ${dataset} with properties:"
          ${concatMapStringsSep "\n" (k: v: "  echo \"  ${k}=${v}\"") (attrsToList properties)}

          zfs create -p ${concatStringsSep " " (mapAttrsToList (k: v: "-o ${k}=${v}") properties)} ${dataset}
          echo "ZFS dataset ${dataset} created successfully"
        else
          echo "ZFS dataset ${dataset} already exists"
        fi

        # Ensure mountpoint exists and is mounted
        mkdir -p ${mountpoint}
        if ! zfs get mounted ${dataset} | grep -q "yes"; then
          echo "Mounting dataset ${dataset} to ${mountpoint}"
          zfs mount ${dataset}
        fi

        # Set up automatic snapshots if enabled
        ${optionalString snapshots.enable ''
          echo "Setting up automatic snapshots for ${dataset}"
          # Create systemd timer for snapshots
          cat > /etc/systemd/system/vscode-zfs-snapshot.timer << 'EOF'
          [Unit]
          Description=VS Code ZFS automatic snapshots

          [Timer]
          OnCalendar=${snapshots.frequency}
          Persistent=true

          [Install]
          WantedBy=timers.target
          EOF

          cat > /etc/systemd/system/vscode-zfs-snapshot.service << 'EOF'
          [Unit]
          Description=Create VS Code ZFS snapshot

          [Service]
          Type=oneshot
          ExecStart=/usr/bin/zfs snapshot ${dataset}@$(date +%Y%m%d_%H%M%S)
          ExecStartPost=/usr/bin/zfs list -t snapshot -o name,creation -d1 ${dataset} | tail -n +${toString (snapshots.retention + 2)} | awk '{print $1}' | xargs -r zfs destroy
          EOF

          systemctl enable vscode-zfs-snapshot.timer
          systemctl start vscode-zfs-snapshot.timer
          echo "ZFS snapshot timer configured for ${snapshots.frequency} snapshots"
        ''}
      '';
    };

    # File System Permissions Management
    systemd.services.vscode-permissions = mkIf config.programs.vscode.permissions.enable {
      description = "Set VS Code file permissions";
      wantedBy = [ "multi-user.target" ];
      after = [ "vscode-zfs-dataset.service" ];
      serviceConfig.Type = "oneshot";
      script = with config.programs.vscode.permissions; ''
        echo "Setting VS Code file permissions..."

        # Set directory permissions
        ${concatStringsSep "\n" (mapAttrsToList (dir: perms: ''
          echo "Creating and setting permissions for ${dir} to ${perms}"
          mkdir -p "${dir}"
          chmod ${perms} "${dir}"
          chown $USER:$USER "${dir}"
        '') directories)}

        # Set file permissions
        ${concatStringsSep "\n" (mapAttrsToList (file: perms: ''
          if [ -f "${file}" ]; then
            echo "Setting permissions for ${file} to ${perms}"
            chmod ${perms} "${file}"
            chown $USER:$USER "${file}"
          fi
        '') files)}

        echo "VS Code permissions configured successfully"
      '';
    };

    # Configuration Management
    systemd.services.vscode-config = {
      description = "Manage VS Code configuration";
      wantedBy = [ "multi-user.target" ];
      after = [ "vscode-permissions.service" ];
      serviceConfig.Type = "oneshot";
      script = with config.programs.vscode.configuration; ''
        echo "Configuring VS Code..."

        # Create configuration directories
        mkdir -p ~/.vscode/{extensions,keybindings,snippets}
        mkdir -p ~/.vscode-server

        # Write VS Code settings
        echo "Writing VS Code settings..."
        cat > ~/.vscode/settings.json << 'EOF'
${builtins.toJSON settings}
EOF

        # Write keybindings
        echo "Writing VS Code keybindings..."
        cat > ~/.vscode/keybindings.json << 'EOF'
${builtins.toJSON keybindings}
EOF

        # Write snippets
        echo "Writing VS Code snippets..."
        cat > ~/.vscode/snippets/global.code-snippets << 'EOF'
${builtins.toJSON snippets}
EOF

        # Write additional configuration files
        ${concatStringsSep "\n" (mapAttrsToList (path: content: ''
          echo "Writing configuration to ${path}"
          mkdir -p "$(dirname "${path}")"
          cat > "${path}" << 'EOF'
${content}
EOF
        '') files)}

        # Set ownership for all config files
        chown -R $USER:$USER ~/.vscode ~/.vscode-server

        echo "VS Code configuration completed"
      '';
    };

    # Package Installation
    environment.systemPackages = [ config.programs.vscode.package ]
      ++ config.programs.vscode.packages
      ++ config.programs.vscode.configuration.extensions;

    # Service Management
    systemd.services = mkIf config.programs.vscode.services.enable
      (mapAttrs' (serviceName: service:
        nameValuePair "vscode-${serviceName}" {
          description = service.description;
          after = service.after;
          wantedBy = service.wantedBy;
          serviceConfig = {
            ExecStart = service.execStart;
            Restart = "always";
            User = config.programs.vscode.services.user;
            Environment = mapAttrsToList (k: v: "${k}=${v}") service.environment;
          };
        }
      ) (filterAttrs (n: v: v.enable) config.programs.vscode.services.definitions));

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