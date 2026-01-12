# LaunchAgent Management for macOS (nix-darwin)
# Declarative service management to replace imperative bash scripts
{config, pkgs, lib, ...}: with lib; let
  # ActivityWatch path (Homebrew installation)
  activityWatchPath = "/Applications/ActivityWatch.app/Contents/MacOS/ActivityWatch";
  # User home directory (from nix-darwin users option)
  userHome = config.users.users.larsartmann.home or "/Users/larsartmann";
in {
  # LaunchAgents for user-level services
  # Replaces scripts/nix-activitywatch-setup.sh with declarative Nix configuration
  # Using nix-darwin launchd.agents option structure
  launchd.agents.activitywatch = mkIf (pkgs.stdenv.isDarwin) {
    enable = true;
    Label = "net.activitywatch.ActivityWatch";

    # Program path to ActivityWatch
    # NOTE: Using Homebrew-installed app for now
    # TODO: Migrate to Nix package when available (currently only in unstable)
    ProgramArguments = [activityWatchPath "--background"];

    # Service configuration
    RunAtLoad = true;
    KeepAlive = {
      SuccessfulExit = false;
    };
    ProcessType = "Background";

    # Working directory
    WorkingDirectory = userHome;

    # Logging (optional, useful for debugging)
    StandardOutPath = "${userHome}/.local/share/activitywatch/stdout.log";
    StandardErrorPath = "${userHome}/.local/share/activitywatch/stderr.log";
  };
}
