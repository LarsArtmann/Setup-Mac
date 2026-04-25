{
  config,
  pkgs,
  nix-colors,
  nix-ssh-config,
  lib,
  ...
}: {
  imports = [
    # Import common packages shared with macOS
    ../../common/packages/base.nix
    ../../common/packages/fonts.nix
    # Include hardware configuration - essential for NixOS to boot
    ../hardware/hardware-configuration.nix
    # ESSENTIAL MODULES FOR FUNCTIONAL DESKTOP
    ./boot.nix
    ./networking.nix
    ./local-network.nix
    ./dns-blocker-config.nix # DNS blocker with unbound + block page (replaces Technitium)
    ./snapshots.nix # BTRFS snapshots with Timeshift
    ./scheduled-tasks.nix # Daily scheduled tasks (crush update-providers, etc.)
    ./sudo.nix # Passwordless sudo for wheel group
    # ../services/ssh.nix # SSH hardening - now loaded via flake module
    # ../services/default.nix # Docker + default services - now loaded via flake module
    # ../services/gitea.nix # Local Gitea for GitHub mirror sync - now loaded via flake module
    # ../services/sops.nix # Secrets management via sops-nix - now loaded via flake module
    # ../services/immich.nix # Self-hosted photo/video management - now loaded via flake module
    # ../services/caddy.nix # Reverse proxy for local domains - now loaded via flake module

    # ../services/homepage.nix # Service overview dashboard - now loaded via flake module
    ../hardware/amd-gpu.nix
    ../hardware/amd-npu.nix
    ../hardware/bluetooth.nix
    ../hardware/emeet-pixy.nix
    # Import common Nix settings for consistent configuration
    ../../common/core/nix-settings.nix
    # Desktop modules — now loaded via flake modules
    # ../desktop/display-manager.nix
    # ../desktop/audio.nix
    # ../desktop/niri-config.nix
    # ../desktop/security-hardening.nix
    # ../desktop/ai-stack.nix
    # ../desktop/monitoring.nix
    # ../desktop/multi-wm.nix
    # ../programs/chromium-policies.nix
    # ../programs/steam.nix
  ];

  # Define color scheme option
  options.colorScheme = lib.mkOption {
    type = lib.types.attrs;
    default = nix-colors.colorSchemes.catppuccin-mocha;
    description = "Color scheme for the system";
  };

  # Define colorSchemeLib option (different name to avoid conflict with lib)
  options.colorSchemeLib = lib.mkOption {
    type = lib.types.attrs;
    default = nix-colors.lib;
    description = "nix-colors library functions";
  };

  # Wrap all configuration in config attribute
  config = {
    # dnsblockd CA is trusted via security.pki.certificates in the dns-blocker module

    # Define color scheme and utilities
    colorScheme = nix-colors.colorSchemes.catppuccin-mocha;
    colorSchemeLib = nix-colors.lib;

    # Fix for Home Manager + xdg.portal integration
    environment.pathsToLink = ["/share/applications" "/share/xdg-desktop-portal"];

    # XDG Desktop Portal for app integration and dark mode preference
    xdg.portal = {
      enable = true;
      extraPortals = [pkgs.xdg-desktop-portal-gtk];
      config.common.default = ["*"];
    };

    # Boot configuration is now handled by ./boot.nix module
    # which provides systemd-boot with proper nvme and Ryzen AI Max+ support

    # User account
    users.users.lars = {
      isNormalUser = true;
      description = "Lars";
      extraGroups = ["networkmanager" "wheel" "docker" "input" "video" "audio" "i2c" "render"];
      # INFO: Set password manually with `passwd lars` after installation
      # NOTE: After SSH hardening, password auth will be disabled - you MUST set up SSH keys
      shell = pkgs.fish;
      openssh.authorizedKeys.keys = [
        nix-ssh-config.sshKeys.lars
      ];
      packages = with pkgs; [
        firefox
        obs-studio
      ];
    };

    # AccountsService avatar for SDDM login/lock screen
    services.accounts-daemon.enable = true;
    systemd.tmpfiles.rules = [
      "L+ /var/lib/AccountsService/icons/lars - - - - ${../../../assets/avatar.png}"
    ];

    # Ensure Home Manager profile directory exists for user lars
    # This is required for home-manager.useUserPackages = true to work properly
    system.activationScripts.home-manager-profile-dirs = ''
      mkdir -p /nix/var/nix/profiles/per-user/lars
      chown lars:users /nix/var/nix/profiles/per-user/lars
    '';

    programs.obs-studio = {
      enable = true;
      enableVirtualCamera = true;
    };

    # Enable Fish shell system-wide
    programs.fish.enable = true;

    # EMEET PIXY webcam auto-activation
    hardware.emeet-pixy = {
      enable = true;
      autoTracking = true;
      autoPrivacy = true;
      defaultAudio = "nc";
    };

    # AMD GPU Support - imported from hardware module
    #
    # Font configuration (cross-platform)
    # Note: Font packages are now imported from common/packages/fonts.nix
    # to avoid duplication across platforms
    # System packages for audio/video codec support
    environment.systemPackages = with pkgs; [
      libopus # Opus audio codec for Discord voice support
    ];

    fonts.fontconfig.defaultFonts = {
      monospace = ["JetBrainsMono Nerd Font" "Noto Sans Mono"];
      sansSerif = ["DejaVu Sans" "Noto Sans"];
      serif = ["DejaVu Serif" "Noto Serif"];
      emoji = ["Noto Color Emoji"];
    };

    # Experimental features
    # Note: Nix settings now imported from common/core/nix-settings.nix

    # System state version
    system.stateVersion = "25.11";

    services = {
      udisks2.enable = true;

      libinput = {
        enable = true;
        mouse = {
          accelProfile = "flat";
        };
        touchpad = {
          tapping = true;
          naturalScrolling = true;
          disableWhileTyping = true;
          clickMethod = "clickfinger";
        };
      };

      fstrim.enable = true;

      signoz = {
        enable = true;
      };

      twenty = {
        enable = true;
      };

      # Voice agents (LiveKit + Whisper ASR)
      voice-agents = {
        enable = true;
      };

      # Hermes AI Agent Gateway (Discord, cron jobs, messaging)
      hermes = {
        enable = true;
      };

      # ComfyUI — persistent AI image generation (Z-Image-Turbo stays in GPU memory)
      comfyui = {
        enable = true;
      };

      # Minecraft server (local network only, whitelisted)
      minecraft = {
        enable = true;
        whitelist = {
          LartyHD = "8c9ec1ab-f64f-4003-9110-f98a1f0d7f47";
        };
      };

      # Monitor365 device monitoring agent (disabled: high RAM usage)
      monitor365 = {
        enable = false;
      };

      smartd = {
        enable = true;
        autodetect = true;
        defaults.monitored = "-a -o on -s (S/../.././02|L/../../6/03)";
      };

      # SSH server with hardening (from nix-ssh-config)
      ssh-server = {
        enable = true;
        allowUsers = ["lars"];
        passwordAuthentication = false;
        allowRootLogin = false;
        authorizedKeys = [nix-ssh-config.sshKeys.lars];
      };

      # Configure fail2ban for SSH protection
      fail2ban = {
        enable = true;
        daemonSettings = {
          DEFAULT = {
            bantime = 3600;
            findtime = 600;
            maxretry = 3;
            backend = "systemd";
            ignoreip = "127.0.0.1/8 ::1 ${config.networking.local.subnet} 10.0.0.0/8 172.16.0.0/12";
          };
        };
        jails = {
          sshd = {
            enabled = true;
            settings = {
              filter = "sshd";
              action = "iptables-multiport[name=sshd, port=ssh, protocol=tcp]";
              logpath = "/var/log/auth.log";
              maxretry = 3;
              bantime = 3600;
              ignoreip = "127.0.0.1/8 ::1 ${config.networking.local.subnet} 10.0.0.0/8 172.16.0.0/12";
            };
          };
        };
      };

      # Declarative Gitea repository mirroring
      gitea-repos = {
        enable = true;
        repos = [
          "git@github.com:LarsArtmann/dnsblockd.git"
          "git@github.com:LarsArtmann/BuildFlow.git"
        ];
        autoSync = true;
      };
    };
  };
}
