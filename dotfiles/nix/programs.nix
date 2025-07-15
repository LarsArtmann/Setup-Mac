{ pkgs, lib, ... }:
{
  services.tailscale = {
    enable = true;
    # TODO: add
    # useRoutingFeatures = "both";
    #  openFirewall = true;
    #  authKeyFile = "/Users/larsartmann/.config/tailscale/authkey";
    #  extraUpFlags = [ "--ssh" "--accept-routes" ];
  };
  programs = {
    # MINIMAL CONFIGURATION: Fish shell only
    fish = {
      enable = true;
      useBabelfish = true;  # Bash/POSIX compatibility
      shellAliases = {
        # Essential shortcuts only
        l = "ls -la";
        t = "tree -h -L 2 -C --dirsfirst";
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
      '';
    };
  };
}
