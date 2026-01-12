# LaunchAgent Management for macOS (nix-darwin)
# Declarative service management to replace imperative bash scripts
{config, pkgs, lib, ...}: let
  # User home directory (from nix-darwin users option)
  userHome = config.users.users.larsartmann.home or "/Users/larsartmann";
in {
  # LaunchAgents for user-level services
  # Replaces scripts/nix-activitywatch-setup.sh with declarative Nix configuration
  # Using nix-darwin environment.userLaunchAgents option
  environment.userLaunchAgents = {
    # ActivityWatch auto-start service
    # NOTE: Binary is aw-qt, not ActivityWatch (Homebrew-installed app bundle)
    # TODO: Migrate ActivityWatch to Nix package when available (currently only in unstable)
    "net.activitywatch.ActivityWatch.plist" = {
      enable = true;  # Set to false to disable
      text = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>net.activitywatch.ActivityWatch</string>
            <key>ProgramArguments</key>
            <array>
                <string>/Applications/ActivityWatch.app/Contents/MacOS/aw-qt</string>
                <string>--background</string>
            </array>
            <key>RunAtLoad</key>
            <true/>
            <key>KeepAlive</key>
            <dict>
                <key>SuccessfulExit</key>
                <false/>
            </dict>
            <key>ProcessType</key>
            <string>Background</string>
            <key>WorkingDirectory</key>
            <string>${userHome}</string>
            <key>StandardOutPath</key>
            <string>${userHome}/.local/share/activitywatch/stdout.log</string>
            <key>StandardErrorPath</key>
            <string>${userHome}/.local/share/activitywatch/stderr.log</string>
        </dict>
        </plist>
      '';
    };
  };
}
