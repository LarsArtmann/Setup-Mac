# ActivityWatch Wrapper
# Multi-service wrapper system for ActivityWatch with embedded configurations

{ pkgs, lib, wrappers }:

let
  # ActivityWatch configuration
  awConfig = pkgs.writeText "config.toml" ''
    # ActivityWatch Configuration
    # Embedded in wrapper for portability

    [server]
    host = "127.0.0.1"
    port = 5600

    [database]
    # Use a portable database location
    path = "$(pwd)/.local/share/activitywatch/aw-server.db"

    [logging]
    level = "INFO"

    [api]
    # Enable CORS for web UI
    enable_cors = true
    cors_origins = ["http://localhost:5680", "http://localhost:3000"]
  '';

  # ActivityWatch watcher configuration
  awWatcherConfig = pkgs.writeText "config.toml" ''
    # ActivityWatch Watcher Configuration

    [watcher]
    # Polling interval in seconds
    poll_time = 1.0

    [filters]
    # Don't track activity when idle for more than 300 seconds (5 minutes)
    idle_threshold = 300

    # Exclude common non-productive applications
    exclude_applications = ["Screen Saver", "loginwindow", "Dock"]

    # Exclude specific windows
    exclude_window_titles = ["Private Browsing", "Incognito"]
  '';
in
wrappers.wrapperModules.activitywatch.apply {
  inherit pkgs;

  configFiles = {
    "config/activitywatch/config.toml" = awConfig;
    "config/activitywatch/aw-watcher-window/config.toml" = awWatcherConfig;
    "config/activitywatch/aw-watcher-afk/config.toml" = awWatcherConfig;
  };

  environment = {
    AW_DB_PATH = "$(pwd)/.local/share/activitywatch/aw-server.db";
    AW_CONFIG_DIR = "$(pwd)/.config/activitywatch";
    AW_LOG_LEVEL = "INFO";
  };

  # Setup script for ActivityWatch
  postHook = ''
    # Create required directories
    mkdir -p "$(dirname "$AW_DB_PATH")"
    mkdir -p "$AW_CONFIG_DIR"

    # Initialize database if it doesn't exist
    if [ ! -f "$AW_DB_PATH" ]; then
      echo "Initializing ActivityWatch database..."
      aw-server --init-db --datastore "$AW_DB_PATH" --host 127.0.0.1 --port 5600
    fi
  '';
}