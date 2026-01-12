# LaunchAgent Management for macOS (nix-darwin)
# Declarative service management to replace imperative bash scripts
{config, pkgs, lib, ...}: let
  # User home directory (from nix-darwin users option)
  userHome = config.users.users.larsartmann.home or "/Users/larsartmann";
in {
  # LaunchAgents for user-level services
  # Replaces scripts/nix-activitywatch-setup.sh with declarative Nix configuration
  # Using nix-darwin launchd.agents option
  launchd.agents = {
    # ActivityWatch auto-start service
    # NOTE: If ActivityWatch is installed via Homebrew, path remains /Applications/ActivityWatch.app
    # TODO: Migrate ActivityWatch to Nix package when available (currently only in unstable)
    "net.activitywatch.ActivityWatch" = {
      enable = true;  # Set to false to disable
      config = {
        # Program path to ActivityWatch
        # Using Homebrew-installed app for now
        # To migrate to Nix: use "${pkgs.activitywatch}/bin/aw-qt" when available
        ProgramArguments = [
          "/Applications/ActivityWatch.app/Contents/MacOS/ActivityWatch"
          "--background"
        ];

        # Service configuration
        RunAtLoad = true;
        KeepAlive = {
          SuccessfulExit = false;
        };
        ProcessType = "Background";

        # Working directory
        WorkingDirectory = userHome;

        # Logging (optional, useful for debugging)
        # Using XDG-compliant path: ${userHome}/.local/share/
        StandardOutPath = "${userHome}/.local/share/activitywatch/stdout.log";
        StandardErrorPath = "${userHome}/.local/share/activitywatch/stderr.log";
      };
    };
  };
}
