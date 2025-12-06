{ config, pkgs, lib, TypeAssertions, ConfigAssertions, ModuleAssertions, Types, UserConfig, PathConfig, State, Validation, ... }:

{
  imports = [
    ../common/home.nix
    ../nixos/home.nix  # Reuse NixOS home configuration with modifications
  ];

  # RISC-V specific Home Manager configuration

  # Shell configuration optimized for RISC-V
  programs.fish = {
    enable = true;

    # RISC-V specific shell configuration
    shellAbbrs = {
      # RISC-V development shortcuts
      riscv-qemu = "qemu-system-riscv64 -machine virt -cpu rv64 -m 2G -nographic";
      riscv-build = "nix build --system riscv64-linux";
      riscv-shell = "nix shell --system riscv64-linux";
    };

    # RISC-V specific environment variables in Fish
    shellInit = ''
      # RISC-V development environment
      set -x RUSTFLAGS "-C target-cpu=generic-rv64"
      set -x CARGO_BUILD_TARGET "riscv64gc-unknown-linux-gnu"
      set -x CROSS_COMPILE "riscv64-unknown-linux-gnu-"
      set -x ARCH "riscv"

      # RISC-V specific path additions
      set -x PATH $HOME/.riscv64-tools/bin $PATH

      # Optimize for embedded systems
      set -x MALLOC_TRIM_THRESHOLD_ 100000
    '';
  };

  # RISC-V specific session variables
  home.sessionVariables = {
    # RISC-V development environment
    RUSTFLAGS = "-C target-cpu=generic-rv64";
    CARGO_BUILD_TARGET = "riscv64gc-unknown-linux-gnu";
    CROSS_COMPILE = "riscv64-unknown-linux-gnu-";
    ARCH = "riscv";

    # Performance optimizations for RISC-V
    MALLOC_TRIM_THRESHOLD_ = "100000";

    # RISC-V specific paths
    RISCV_TOOLS = "$HOME/.riscv64-tools";
    RISCV_SYSROOT = "$HOME/.riscv64-sysroot";
  };

  # RISC-V specific session path additions
  home.sessionPath = [
    "$HOME/.riscv64-tools/bin"
    "$HOME/.local/bin/riscv64"
  ];

  # RISC-V specific user packages
  home.packages = with pkgs; [
    # RISC-V development tools
    gcc
    gdb
    binutils
    gnumake

    # Cross-compilation tools
    buildPackages.qemu
    riscv64-unknown-elf-binutils

    # RISC-V specific tools
    dtc              # Device Tree Compiler
    riscv-tools

    # Hardware debugging tools for embedded systems
    openocd          # On-Chip Debugger
    picocom          # Minimal serial terminal
    minicom          # Serial communication

    # Boot and firmware tools
    u-boot-tools

    # System monitoring optimized for RISC-V
    htop
    iotop
    perf

    # File systems for RISC-V boards
    e2fsprogs
    dosfstools
    btrfs-progs

    # Network debugging tools
    wireshark-cli
    tcpdump

    # Development editors with RISC-V support
    vim
  ];

  # RISC-V specific program configurations
  programs = {
    # Git configuration optimized for RISC-V development
    git = {
      enable = true;
      userName = "Lars Artmann";
      userEmail = "lars.artmann@tum.de";

      # RISC-V specific git configuration
      extraConfig = {
        # Optimize for large binary files (common in embedded development)
        core.compression = 0;
        core.looseCompression = 0;

        # Performance for slow storage (common on RISC-V boards)
        core.fsyncObjectFiles = false;

        # RISC-V development workflow
        push.autoSetupRemote = true;
        pull.rebase = true;
      };
    };

    # Vim configuration for RISC-V development
    vim = {
      enable = true;
      defaultEditor = true;

      # RISC-V specific vim settings
      settings = {
        number = true;              # Line numbers
        relativenumber = true;      # Relative line numbers
        expandtab = true;           # Use spaces instead of tabs
        tabstop = 2;               # Tab width
        shiftwidth = 2;             # Indent width
        softtabstop = 2;           # Soft tab width

        # Performance optimizations for slow systems
        lazyredraw = true;
        synmaxcol = 200;           # Limit syntax highlighting
        updatetime = 1000;         # Faster update time

        # RISC-V development settings
        foldenable = true;
        foldmethod = "syntax";
      };

      # RISC-V specific plugins
      plugins = with pkgs.vimPlugins; [
        # Add RISC-V specific vim plugins if needed
        vim-nix
      ];
    };

    # Directories for RISC-V development
    direnv = {
      enable = true;
      enableBashIntegration = true;
      enableFishIntegration = true;
      nix-direnv.enable = true;
    };
  };

  # RISC-V specific files and directories
  home.file = {
    # RISC-V development scripts
    ".local/bin/riscv64" = {
      text = ''
        #!/bin/sh
        # RISC-V development environment setup script

        echo "Setting up RISC-V development environment..."

        # Create RISC-V tools directory
        mkdir -p "$HOME/.riscv64-tools/bin"

        # Set up cross-compilation environment
        export RUSTFLAGS="-C target-cpu=generic-rv64"
        export CARGO_BUILD_TARGET="riscv64gc-unknown-linux-gnu"
        export CROSS_COMPILE="riscv64-unknown-linux-gnu-"
        export ARCH="riscv"

        # Add to PATH
        export PATH="$HOME/.riscv64-tools/bin:$PATH"

        echo "RISC-V development environment ready!"
      '';
      executable = true;
    };

    # RISC-V QEMU launch script
    ".local/bin/riscv64-qemu" = {
      text = ''
        #!/bin/sh
        # RISC-V QEMU launch script

        # Default QEMU settings for RISC-V
        MACHINE="virt"
        CPU="rv64"
        MEMORY="2G"
        KERNEL="bzImage"
        ROOTFS="rootfs.ext4"

        # Parse command line arguments
        while [ $# -gt 0 ]; do
          case $1 in
            -m|--memory)
              MEMORY="$2"
              shift 2
              ;;
            -k|--kernel)
              KERNEL="$2"
              shift 2
              ;;
            -r|--rootfs)
              ROOTFS="$2"
              shift 2
              ;;
            *)
              echo "Unknown option: $1"
              exit 1
              ;;
          esac
        done

        # Launch QEMU
        exec qemu-system-riscv64 \
          -machine "$MACHINE" \
          -cpu "$CPU" \
          -m "$MEMORY" \
          -nographic \
          -kernel "$KERNEL" \
          -append "root=/dev/vda rw console=ttyS0" \
          -drive "file=$ROOTFS,if=virtio,format=raw"
      '';
      executable = true;
    };

    # RISC-V development fish functions
    ".config/fish/functions/riscv-build.fish" = {
      text = ''
        # RISC-V build function
        function riscv-build
            set -l cmd $argv[1]
            if test -z "$cmd"
                echo "Usage: riscv-build <command>"
                return 1
            end

            # Set RISC-V environment and run command
            set -x RUSTFLAGS "-C target-cpu=generic-rv64"
            set -x CARGO_BUILD_TARGET "riscv64gc-unknown-linux-gnu"
            set -x CROSS_COMPILE "riscv64-unknown-linux-gnu-"
            set -x ARCH "riscv"

            echo "Building for RISC-V: $cmd"
            eval $argv
        end
      '';
    };
  };

  # RISC-V specific XDG user directories (adjust as needed)
  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;

      # RISC-V specific directories
      develop = "$HOME/develop/riscv64";
      documents = "$HOME/documents";
      download = "$HOME/downloads";
      music = "$HOME/music";
      pictures = "$HOME/pictures";
      videos = "$HOME/videos";
      desktop = "$HOME/desktop";
      publicShare = "$HOME/public";
      templates = "$HOME/templates";
    };
  };

  # Ghost Systems integration verification
  assertions = [
    {
      assertion = TypeAssertions != null;
      message = "Ghost Systems TypeAssertions not injected into RISC-V Home Manager!";
    }
    {
      assertion = pkgs.stdenv.isRiscV;
      message = "RISC-V Home Manager configuration should only run on RISC-V systems!";
    }
  ];

  # RISC-V specific services (user-level)
  systemd.user = {
    # RISC-V development environment service
    services.riscv-env = {
      Unit = {
        Description = "RISC-V Development Environment";
        PartOf = "graphical-session.target";
      };
      Service = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.bash}/bin/bash -c 'echo \"RISC-V development environment initialized\"'";
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };

  # Home Manager version
  home.stateVersion = "24.05";
}