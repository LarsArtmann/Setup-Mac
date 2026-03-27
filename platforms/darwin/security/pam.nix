_: {
  # Enhanced Security Configuration for Darwin
  # TouchID and Apple Watch PAM authentication for sudo
  security.pam = {
    services = {
      sudo_local = {
        # Enable Touch ID for sudo operations
        # Allows fingerprint authentication instead of password
        touchIdAuth = true;

        # Explicitly disable Apple Watch for sudo
        # Reason: Prefer TouchID on MacBook Air (no strong use case for Watch)
        watchIdAuth = false;

        # Enable reattach for tmux/screen sessions
        # Fixes TouchID authentication inside tmux by reattaching to user session
        # Without this, TouchID fails with "Unable to authenticate" in tmux
        reattach = true;
      };
    };
  };

  # Note: Other TouchID-authenticated services are managed by macOS directly:
  # - loginwindow: Login screen TouchID (System Preferences > Touch ID)
  # - screensaver: Screen unlock (System Preferences > Touch ID)
  # These cannot be configured via nix-darwin PAM module
}
