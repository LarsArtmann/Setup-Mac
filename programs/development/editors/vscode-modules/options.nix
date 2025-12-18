# VS Code Options Module
# Comprehensive option definitions for VS Code configuration

{ lib, pkgs, ... }:

with lib; {
  programs.vscode = {
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
}