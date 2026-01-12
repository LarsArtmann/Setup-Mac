{ pkgs, lib, ... }:
let
  # Platform-specific SSH configuration includes
  # These are conditionally added based on the platform
  platformIncludes =
    if pkgs.stdenv.isDarwin then [
      "~/.orbstack/ssh/config"  # OrbStack (macOS-only)
      "~/.colima/ssh_config"     # Colima (macOS-only)
    ] else [];

  # Cross-platform SSH hosts (work on both macOS and NixOS)
  commonMatchBlocks = {
    # On-prem server (cross-platform)
    "onprem" = {
      hostname = "192.168.1.100";
      user = "root";
    };

    # GitHub with connection pooling and optimizations (cross-platform)
    "github.com" = {
      user = "git";
      compression = true;
      serverAliveInterval = 60;
      controlMaster = "auto";
      controlPath = "~/.ssh/sockets/%r@%h-%p";
      controlPersist = "600";
      extraOptions = {
        TCPKeepAlive = "yes";
      };
    };
  };

  # Default SSH configuration values (replaces enableDefaultConfig)
  defaultMatchBlocks = {
    "*" = {
      forwardAgent = lib.mkDefault false;
      addKeysToAgent = lib.mkDefault "no";
      compression = lib.mkDefault false;
      serverAliveInterval = lib.mkDefault 0;
      serverAliveCountMax = lib.mkDefault 3;
      hashKnownHosts = lib.mkDefault false;
      userKnownHostsFile = lib.mkDefault "~/.ssh/known_hosts";
      controlMaster = lib.mkDefault "no";
      controlPath = lib.mkDefault "~/.ssh/master-%r@%n:%p";
      controlPersist = lib.mkDefault "no";
    };
  };
  darwinMatchBlocks = {
    # macOS-only: Secretive integration (commented in original, keeping reference)
    "secretive-example" = lib.mkIf pkgs.stdenv.isDarwin {
      identityAgent = lib.mkDefault "/Users/larsartmann/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh";
    };
  };

in {
  # Enable SSH configuration management via Home Manager
  programs.ssh = {
    enable = true;

    # Disable default config to prevent deprecation warning
    # We manually set all values we need
    enableDefaultConfig = false;

    # Include platform-specific config files (macOS-only)
    includes = platformIncludes;

    # Merge default, cross-platform, and platform-specific match blocks
    matchBlocks = lib.mkMerge [
      defaultMatchBlocks
      commonMatchBlocks
      darwinMatchBlocks
    ];
  };
}
