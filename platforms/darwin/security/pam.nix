_: {
  # Enhanced Security Configuration for Darwin
  security.pam = {
    services = {
      # Enable Touch ID for sudo operations (Darwin-specific)
      # This allows Touch ID authentication for sudo instead of password
      # Configuration: /etc/pam.d/sudo_local
      sudo_local.touchIdAuth = true;

      # Note: Other TouchID-authenticated services:
      # - loginwindow: Login screen TouchID (enabled via System Preferences > Touch ID)
      #   Note: Requires "Use Touch ID for purchases and items in Safari" to be enabled
      #   This is configured via macOS System Preferences, not nix-darwin
      # - authorization: Authorization rights (complex policy configuration)
      #   Requires Apple Enterprise Mobility Management for programmatic control
    };
  };
}
