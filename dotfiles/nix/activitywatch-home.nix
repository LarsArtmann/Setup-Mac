{ config, pkgs, lib, ... }:

{
  # ActivityWatch auto-start configuration using Home Manager services
  # This provides declarative management of ActivityWatch startup

  home.file.".config/activitywatch/aw-server/aw-server.toml".text = ''
[server]
host = "localhost"
port = "5600"
storage = "peewee"
cors_origins = ["http://localhost:5600"]

[server.custom_static]
  '';

  # Configure ActivityWatch server settings
  home.file.".config/activitywatch/aw-server/settings.json".text = ''
{
  "database": {
    "type": "sqlite",
    "path": "peewee-sqlite.v2.db"
  },
  "server": {
    "port": 5600,
    "cors_origins": ["http://localhost:5600"]
  },
  "storage": {
    "retention_days": 90,
    "auto_cleanup": true
  }
}
  '';

  # Configure AFK watcher
  home.file.".config/activitywatch/aw-watcher-afk/aw-watcher-afk.toml".text = ''
timeout = 300
poll_time = 5

[client]
commit_interval = 10
  '';

  # Configure window watcher
  home.file.".config/activitywatch/aw-watcher-window/aw-watcher-window.toml".text = ''
# Window watcher configuration
[client]
commit_interval = 10

[window]
# Exclude certain applications from tracking
exclude = [
  "loginwindow",
  "ScreenSaverEngine",
]
  '';

  # Configure QT interface
  home.file.".config/activitywatch/aw-qt/aw-qt.toml".text = ''
[client]
host = "http://localhost:5600"

[ui]
theme = "dark"
  '';

  # Create script to manage ActivityWatch auto-start
  home.file.".local/bin/activitywatch-autostart" = {
    text = ''
#!/bin/bash

# ActivityWatch Auto-Start Management Script
# This script ensures ActivityWatch starts on login

set -euo pipefail

LAUNCH_AGENT_PLIST="$HOME/Library/LaunchAgents/net.activitywatch.ActivityWatch.plist"
ACTIVITYWATCH_APP="/Applications/ActivityWatch.app"

# Create launch agent if it doesn't exist
create_launch_agent() {
    echo "🔧 Creating ActivityWatch launch agent..."

    mkdir -p "$(dirname "$LAUNCH_AGENT_PLIST")"

    cat > "$LAUNCH_AGENT_PLIST" << 'EOF'
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
    <string>''${HOME}</string>
</dict>
</plist>
EOF

    echo "✅ Launch agent created at $LAUNCH_AGENT_PLIST"
}

# Add ActivityWatch to login items
add_to_login_items() {
    echo "🔗 Adding ActivityWatch to login items..."

    osascript -e 'tell application "System Events" to get the name of every login item' | grep -q "ActivityWatch" || {
        osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/ActivityWatch.app", hidden:false}' 2>/dev/null || true
        echo "✅ ActivityWatch added to login items"
    }
}

# Load the launch agent
load_launch_agent() {
    echo "🚀 Loading ActivityWatch launch agent..."
    launchctl load -w "$LAUNCH_AGENT_PLIST" 2>/dev/null || echo "⚠️  Launch agent already loaded"
    echo "✅ Launch agent loaded"
}

# Main execution
main() {
    if [[ ! -d "$ACTIVITYWATCH_APP" ]]; then
        echo "❌ ActivityWatch not found at $ACTIVITYWATCH_APP"
        echo "Please install ActivityWatch first: brew install --cask activitywatch"
        exit 1
    fi

    create_launch_agent
    add_to_login_items
    load_launch_agent

    echo ""
    echo "🎉 ActivityWatch auto-start configuration complete!"
    echo "   - Launch agent: ✅ Configured"
    echo "   - Login items: ✅ Configured"
    echo "   - Web interface: http://localhost:5600"
}

main "$@"
    '';
    executable = true;
  };

  # Systemd-like user service (using fish login script)
  programs.fish.shellInit = ''
    # Setup ActivityWatch auto-start on shell login
    if test -x "$HOME/.local/bin/activitywatch-autostart"
        $HOME/.local/bin/activitywatch-autostart >/dev/null 2>&1 &
    end
  '';
}