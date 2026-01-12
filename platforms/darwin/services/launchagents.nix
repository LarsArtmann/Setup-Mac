# LaunchAgent Management for macOS (nix-darwin)
# Declarative service management to replace imperative bash scripts
{config, pkgs, lib, ...}: {
  # LaunchAgents for user-level services
  # Replaces scripts/nix-activitywatch-setup.sh with declarative Nix configuration
  launchd.userAgents = {
    # ActivityWatch auto-start service
    # NOTE: If ActivityWatch is installed via Homebrew, the path remains /Applications/ActivityWatch.app
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
        WorkingDirectory = "/Users/larsartmann";

        # Logging (optional, useful for debugging)
        StandardOutPath = "/tmp/net.activitywatch.ActivityWatch.stdout.log";
        StandardErrorPath = "/tmp/net.activitywatch.ActivityWatch.stderr.log";
      };
    };
  };
}
