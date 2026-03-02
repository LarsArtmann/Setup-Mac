# LaunchAgent Management for macOS (nix-darwin)
# Declarative service management to replace imperative bash scripts
{config, pkgs, ...}: let
  # User home directory (from nix-darwin users option - guaranteed to exist)
  userHome = config.users.users.larsartmann.home;
in {
  # LaunchAgents for user-level services
  # Replaces scripts/nix-activitywatch-setup.sh with declarative Nix configuration
  # Using nix-darwin environment.userLaunchAgents option
  environment.userLaunchAgents = {
    # ActivityWatch auto-start service
    # NOTE: Binary is aw-qt, not ActivityWatch (Homebrew-installed app bundle)
    # TODO: Migrate ActivityWatch to Nix package when available (currently only in unstable)
    "net.activitywatch.ActivityWatch.plist" = {
      enable = true; # Set to false to disable
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
                <string>--no-gui</string>
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

    # SublimeText configuration sync service
    # Replaces scripts/sublime-text-sync.sh LaunchAgent creation
    # Automatically exports SublimeText settings to dotfiles daily at 18:00
    "com.larsartmann.sublime-sync.plist" = {
      enable = true;
      text = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>com.larsartmann.sublime-sync</string>
            <key>ProgramArguments</key>
            <array>
                <string>${userHome}/projects/SystemNix/scripts/sublime-text-sync.sh</string>
                <string>--export</string>
            </array>
            <key>StartCalendarInterval</key>
            <dict>
                <key>Hour</key>
                <integer>18</integer>
                <key>Minute</key>
                <integer>0</integer>
            </dict>
            <key>StandardOutPath</key>
            <string>${userHome}/.local/share/sublime-text/sync.log</string>
            <key>StandardErrorPath</key>
            <string>${userHome}/.local/share/sublime-text/sync-error.log</string>
        </dict>
        </plist>
      '';
    };

    # ActivityWatch Utilization Watcher
    # Nix-managed system resource monitoring (replaces manual pip install)
    # Connects to ActivityWatch server on localhost:5600
    "net.activitywatch.aw-watcher-utilization.plist" = {
      enable = true;
      text = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>net.activitywatch.aw-watcher-utilization</string>
            <key>ProgramArguments</key>
            <array>
                <string>${pkgs.aw-watcher-utilization}/bin/aw-watcher-utilization</string>
                <string>--host</string>
                <string>localhost</string>
                <string>--port</string>
                <string>5600</string>
                <string>--poll-time</string>
                <string>5</string>
            </array>
            <key>RunAtLoad</key>
            <true/>
            <key>KeepAlive</key>
            <true/>
            <key>ProcessType</key>
            <string>Background</string>
            <key>WorkingDirectory</key>
            <string>${userHome}</string>
            <key>StandardOutPath</key>
            <string>${userHome}/.local/share/activitywatch/aw-watcher-utilization.log</string>
            <key>StandardErrorPath</key>
            <string>${userHome}/.local/share/activitywatch/aw-watcher-utilization.error.log</string>
        </dict>
        </plist>
      '';
    };
  };
}
