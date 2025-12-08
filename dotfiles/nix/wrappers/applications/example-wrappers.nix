# Example Wrappers for Common Non-Nix Applications
# Demonstrating advanced dynamic library management patterns

{ pkgs, lib }:

let
  inherit (import ./dynamic-libs.nix { inherit pkgs lib; })
    wrapCliTool wrapGuiApp wrapDownloadedBinary;

  # Example 1: VS Code with enhanced library support
  vscodeWrapper = wrapGuiApp {
    name = "vscode-enhanced";
    package = pkgs.vscode;
    dynamicLibs = with pkgs; [
      openssl
      curl
      git
      nodejs
      python3
    ];
    environment = {
      VSCODE_PATH = "${pkgs.vscode}";
      ELECTRON_RUN_AS_NODE = "1";
      VSCODE_FORCE_USER_ENV = "1";
    };
    patchInstallNames = true;
    postHook = ''
      # VS Code specific extensions setup
      if [ "$1" = "--install-extensions" ] && [ -n "$2" ]; then
        echo "Installing VS Code extensions: $2"
      fi
    '';
  };

  # Example 2: Docker CLI with dynamic library dependencies
  dockerWrapper = wrapCliTool {
    name = "docker-enhanced";
    package = pkgs.docker;
    dynamicLibs = with pkgs; [
      glibc
      zlib
      xz
    ];
    environment = {
      DOCKER_CONFIG = "$HOME/.docker";
      DOCKER_BUILDKIT = "1";
      COMPOSE_DOCKER_CLI_BUILD = "1";
    };
    libSearchPaths = [
      "/usr/local/lib"
      "/opt/homebrew/lib"
    ];
  };

  # Example 3: Downloaded binary wrapper (e.g., custom tool)
  customToolWrapper = wrapDownloadedBinary {
    name = "custom-downloaded-tool";
    binaryPath = "/usr/local/bin/custom-tool"; # Example path
    dynamicLibs = with pkgs; [
      libiconv
      gettext
      openssl
    ];
    environment = {
      CUSTOM_TOOL_CONFIG = "$HOME/.config/custom-tool";
      CUSTOM_PLUGIN_DIR = "$HOME/.config/custom-tool/plugins";
    };
    preHook = ''
      # Check if binary exists and offer download if not
      if [ ! -f "/usr/local/bin/custom-tool" ]; then
        echo "Custom tool not found at /usr/local/bin/custom-tool"
        echo "Download from: https://example.com/custom-tool"
        echo "Then place it at /usr/local/bin/custom-tool"
        exit 1
      fi
    '';
  };

  # Example 4: JetBrains IDEs (complex macOS applications)
  jetbrainsWrapper = { name, package, additionalLibs ? [] }:
    wrapGuiApp {
      inherit name package;
      dynamicLibs = with pkgs; [
        jdk11
        coreutils
        bash
        gnugrep
        findutils
        git
      ] ++ additionalLibs;
      environment = {
        # JetBrains specific environment
        _JAVA_AWT_WM_NONREPARENTING = "1";
        IDEA_JDK = "${pkgs.jdk11.home}";
        JETBRAINS_CLIENT_PORT = "63342";
      };
      libSearchPaths = [
        "/System/Library/Java/JavaVirtualMachines"
        "/Library/Java/JavaVirtualMachines"
      ];
      installLibs = true;
      patchInstallNames = true;
      postHook = ''
        # JetBrains IDE specific setup
        if [ ! -d "$HOME/Library/Application Support/JetBrains" ]; then
          mkdir -p "$HOME/Library/Application Support/JetBrains"
        fi
      '';
    };

  # Example 5: Gaming or creative applications
  creativeAppWrapper = { name, package, requiredFrameworks ? [] }:
    wrapGuiApp {
      inherit name package;
      dynamicLibs = with pkgs; [
        libogg
        libvorbis
        libpng
        libjpeg
        freetype
        fontconfig
      ];
      environment = {
        # Graphics and media environment
        VDPAU_DRIVER = "auto";
        __GL_THREADED_OPTIMIZATIONS = "1";
      };
      libSearchPaths = [
        "/System/Library/Frameworks"
        "/Library/Frameworks"
      ] ++ requiredFrameworks;
      patchInstallNames = true;
      preHook = ''
        # Check for required frameworks
        for framework in ${lib.concatStringsSep " " requiredFrameworks}; do
          if [ ! -d "/System/Library/Frameworks/$framework.framework" ]; then
            echo "Warning: Required framework $framework.framework not found"
          fi
        done
      '';
    };

  # Example 6: Database tools with complex dependencies
  databaseWrapper = { name, package, clientLibs ? [] }:
    wrapCliTool {
      inherit name package;
      dynamicLibs = with pkgs; [
        openssl
        readline
        libpq
        sqlite
      ] ++ clientLibs;
      environment = {
        # Database environment
        PAGER = "less";
        EDITOR = "nano";
        DATABASE_URL = "postgresql://localhost:5432";
      };
      libSearchPaths = [
        "/opt/homebrew/opt/postgresql/lib"
        "/opt/homebrew/opt/mysql/lib"
        "/usr/local/lib"
      ];
      postHook = ''
        # Database connection validation
        if command -v pg_isready >/dev/null 2>&1; then
          pg_isready -q || echo "Warning: PostgreSQL is not running"
        fi
      '';
    };

in {
  vscode = vscodeWrapper;
  docker = dockerWrapper;
  customTool = customToolWrapper;
  jetbrains = jetbrainsWrapper;
  creativeApp = creativeAppWrapper;
  database = databaseWrapper;

  # Export individual wrapper functions for custom use
  inherit wrapCliTool wrapGuiApp wrapDownloadedBinary;
}