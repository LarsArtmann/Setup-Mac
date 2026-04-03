{
  pkgs,
  nix-ssh-config,
  crush-config,
  config,
  ...
}: {
  # Import common Home Manager modules
  imports = [
    ../common/home-base.nix
    ./programs/shells.nix
    nix-ssh-config.homeManagerModules.ssh
  ];

  # SSH client configuration
  ssh-config = {
    enable = true;
    user = "lars";
    hosts = {
      onprem = {
        hostname = "192.168.1.100";
        user = "root";
      };
      "evo-x2" = {
        hostname = "192.168.1.150";
        user = "lars";
        serverAliveInterval = 60;
        serverAliveCountMax = 3;
        extraOptions = {
          TCPKeepAlive = "yes";
        };
      };
    };
  };

  # Darwin-specific Home Manager overrides
  home.sessionVariables = {
    # Empty for now, use common defaults from home-base.nix
    # Add Darwin-specific variables here if needed in the future
  };

  # Note: Starship Fish integration is handled by Home Manager
  # via programs.starship.enableFishIntegration = true (in common/programs/starship.nix)
  # No manual 'starship init fish | source' needed here

  # Note: Shell aliases and initialization are now in ./programs/shells.nix
  # to avoid duplication between home.nix and shells.nix

  # Darwin-specific packages (user-level)
  home.packages = with pkgs; [
    # Add Darwin-specific user packages if needed
    # Most packages are in common/packages/base.nix
  ];

  # Crush AI Agent Configuration — deployed from flake input
  # This ensures AGENTS.md and all references are synced across all machines
  home.file = {
    # Core AGENTS.md - the main AI agent instructions
    ".config/crush/AGENTS.md".source = "${crush-config}/AGENTS.md";

    # Reference documentation
    ".config/crush/references/composition-patterns.md".source = "${crush-config}/references/composition-patterns.md";
    ".config/crush/references/architecture.md".source = "${crush-config}/references/architecture.md";
    ".config/crush/references/git-workflow.md".source = "${crush-config}/references/git-workflow.md";
    ".config/crush/references/languages.md".source = "${crush-config}/references/languages.md";

    # Tech stack documentation
    ".config/crush/tech-stacks/go.md".source = "${crush-config}/tech-stacks/go.md";
    ".config/crush/tech-stacks/typescript.md".source = "${crush-config}/tech-stacks/typescript.md";
    ".config/crush/tech-stacks/css.md".source = "${crush-config}/tech-stacks/css.md";

    # Personality configurations
    ".config/crush/personalities/architect-extreme.md".source = "${crush-config}/personalities/architect-extreme.md";
    ".config/crush/personalities/engineer-pragmatic.md".source = "${crush-config}/personalities/engineer-pragmatic.md";
  };
}
