{ pkgs, lib, ... }:
{
  services.tailscale = {
    enable = true;
    # Note: Some options may not be available in nix-darwin version
    # Enable local DNS override for macOS compatibility
    # overrideLocalDns = true;  # Disabled due to DNS assertion failure

    # Advanced routing features - Carefully tested configuration
    useRoutingFeatures = "client";  # Safe client-only routing

    # Firewall - disabled to avoid conflicts with macOS firewall
    # openFirewall = true;  # May conflict with macOS firewall

    # Auth key - Configure through external management
    # authKeyFile = "/Users/larsartmann/.config/tailscale/authkey";

    # Additional flags for enhanced functionality - Safe options only
    extraUpFlags = [
      "--accept-dns"       # Accept DNS configuration from network
      "--accept-routes"    # Accept subnet routes
      "--ssh"             # Enable SSH access through Tailscale
      "--reset"           # Reset settings on startup for consistency
    ];

    # Enhanced package configuration
    package = null; # Use system Tailscale from environment.nix
  };
  programs = {
    # MINIMAL CONFIGURATION: Fish shell only
    fish = {
      enable = true;
      useBabelfish = true;  # Bash/POSIX compatibility
      shellAliases = {
        # Essential shortcuts only
        l = "ls -laSh";
        t = "tree -h -L 2 -C --dirsfirst";
        nixup = "darwin-rebuild switch --flake .";
        nixbuild = "darwin-rebuild build --flake .";
        nixcheck = "darwin-rebuild check --flake .";
      };
      shellInit = ''
        # PERFORMANCE: Disable greeting for faster startup
        set -g fish_greeting

        # COMPLETIONS: Universal completion engine (1000+ commands)
        carapace _carapace fish | source

        # PROMPT: Beautiful Starship prompt with 400ms timeout protection
        starship init fish | source

        # PERFORMANCE: Optimized history settings
        set -g fish_history_size 5000
        set -g fish_save_history 5000

        # Additional Fish-specific optimizations
        set -g fish_autosuggestion_enabled 1
        set -g fish_complete_path /usr/local/share/fish/completions $fish_complete_path
      '';
    };

    # Enhanced Git configuration
    git = {
      enable = true;
      package = null; # Use system Git from environment.nix
      config = {
        core = {
          editor = "nano";
          autocrlf = false;
          safecrlf = true;
          quotepath = false;
        };
        init.defaultBranch = "main";
        pull.rebase = true;
        push.default = "simple";
        merge.conflictstyle = "diff3";
        diff.algorithm = "patience";
        rerere.enabled = true;
        # Enhanced security settings
        transfer.fsckobjects = true;
        fetch.fsckobjects = true;
        receive.fsckObjects = true;
      };
    };

    # Enhanced Zsh configuration (fallback shell)
    zsh = {
      enable = true;
      enableCompletion = true;
      enableSyntaxHighlighting = true;
      syntaxHighlighting.enable = true;
      autosuggestions.enable = true;
      histSize = 50000;
      histFile = "$HOME/.zsh_history";
      histFileSize = 50000;
      setOptions = [
        "HIST_VERIFY"
        "SHARE_HISTORY"
        "EXTENDED_HISTORY"
        "HIST_IGNORE_DUPS"
        "HIST_IGNORE_ALL_DUPS"
        "HIST_IGNORE_SPACE"
        "HIST_SAVE_NO_DUPS"
        "HIST_REDUCE_BLANKS"
        "INC_APPEND_HISTORY"
        "AUTO_CD"
        "CORRECT"
        "CORRECT_ALL"
      ];
      shellAliases = {
        l = "ls -laSh";
        t = "tree -h -L 2 -C --dirsfirst";
        nixup = "darwin-rebuild switch --flake .";
        nixbuild = "darwin-rebuild build --flake .";
        nixcheck = "darwin-rebuild check --flake .";
      };
    };

    # Bash configuration for compatibility
    bash = {
      enable = true;
      completion.enable = true;
      shellAliases = {
        l = "ls -laSh";
        t = "tree -h -L 2 -C --dirsfirst";
        nixup = "darwin-rebuild switch --flake .";
        nixbuild = "darwin-rebuild build --flake .";
        nixcheck = "darwin-rebuild check --flake .";
      };
    };

    # Starship prompt configuration
    starship = {
      enable = true;
      enableFishIntegration = true;
      enableZshIntegration = true;
      enableBashIntegration = true;
      settings = {
        format = "$all$character";
        add_newline = false;
        scan_timeout = 10;
        command_timeout = 1000;

        character = {
          success_symbol = "[➜](bold green)";
          error_symbol = "[➜](bold red)";
        };

        git_branch = {
          truncation_length = 20;
          truncation_symbol = "…";
        };

        git_status = {
          ahead = "⇡\${count}";
          diverged = "⇕⇡\${ahead_count}⇣\${behind_count}";
          behind = "⇣\${count}";
        };

        directory = {
          truncation_length = 3;
          fish_style_pwd_dir_length = 1;
        };

        nix_shell = {
          format = "via [$symbol$state( \\($name\\))]($style) ";
          symbol = "❄️ ";
        };
      };
    };
  };
}
