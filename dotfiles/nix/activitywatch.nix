{ config, pkgs, lib, ... }:

{
  # ActivityWatch auto-start configuration via Nix
  # This creates the launch agent and manages it declaratively

  # Create the ActivityWatch launch agent
  environment.etc."ActivityWatch-LaunchAgent/net.activitywatch.ActivityWatch.plist".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
        <key>Label</key>
        <string>net.activitywatch.ActivityWatch</string>
        <key>ProgramArguments</key>
        <array>
            <string>/Applications/ActivityWatch.app/Contents/MacOS/ActivityWatch</string>
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
        <key>StandardOutPath</key>
        <string>/tmp/net.activitywatch.ActivityWatch.stdout.log</string>
        <key>StandardErrorPath</key>
        <string>/tmp/net.activitywatch.ActivityWatch.stderr.log</string>
        <key>WorkingDirectory</key>
        <string>/Users/larsartmann</string>
    </dict>
    </plist>
  '';

  # Setup script to configure ActivityWatch auto-start
  system.activationScripts.activitywatch-setup = {
    text = ''
      # Create launch agents directory if it doesn't exist
      mkdir -p /Users/larsartmann/Library/LaunchAgents

      # Copy the launch agent to user directory
      if [ -f /etc/ActivityWatch-LaunchAgent/net.activitywatch.ActivityWatch.plist ]; then
        cp /etc/ActivityWatch-LaunchAgent/net.activitywatch.ActivityWatch.plist \
           /Users/larsartmann/Library/LaunchAgents/net.activitywatch.ActivityWatch.plist
        chown larsartmann:staff /Users/larsartmann/Library/LaunchAgents/net.activitywatch.ActivityWatch.plist
      fi

      # Add ActivityWatch to login items via AppleScript (if installed)
      if [ -d "/Applications/ActivityWatch.app" ]; then
        # Check if ActivityWatch is already in login items
        osascript -e 'tell application "System Events" to get the name of every login item' | grep -q "ActivityWatch" || {
          # Add to login items if not present
          osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/ActivityWatch.app", hidden:false}' 2>/dev/null || true
        }
      fi

      # Load the launch agent
      sudo -u larsartmann launchctl load -w /Users/larsartmann/Library/LaunchAgents/net.activitywatch.ActivityWatch.plist 2>/dev/null || true
    '';
    deps = [];
  };

  # Cleanup script for ActivityWatch configuration
  system.activationScripts.activitywatch-cleanup = {
    text = ''
      # Remove old manual launch agents if they exist and differ from Nix-managed one
      if [ -f /Users/larsartmann/Library/LaunchAgents/net.activitywatch.ActivityWatch.plist ]; then
        # Check if the file differs from our Nix-managed version
        if ! cmp -s /Users/larsartmann/Library/LaunchAgents/net.activitywatch.ActivityWatch.plist \
                  /etc/ActivityWatch-LaunchAgent/net.activitywatch.ActivityWatch.plist 2>/dev/null; then
          # Backup and replace with Nix-managed version
          cp /Users/larsartmann/Library/LaunchAgents/net.activitywatch.ActivityWatch.plist \
             /Users/larsartmann/Library/LaunchAgents/net.activitywatch.ActivityWatch.plist.backup
          cp /etc/ActivityWatch-LaunchAgent/net.activitywatch.ActivityWatch.plist \
             /Users/larsartmann/Library/LaunchAgents/net.activitywatch.ActivityWatch.plist
          chown larsartmann:staff /Users/larsartmann/Library/LaunchAgents/net.activitywatch.ActivityWatch.plist
          # Reload the launch agent
          sudo -u larsartmann launchctl unload -w /Users/larsartmann/Library/LaunchAgents/net.activitywatch.ActivityWatch.plist 2>/dev/null || true
          sudo -u larsartmann launchctl load -w /Users/larsartmann/Library/LaunchAgents/net.activitywatch.ActivityWatch.plist 2>/dev/null || true
        fi
      fi
    '';
    deps = [ "activitywatch-setup" ];
  };
}