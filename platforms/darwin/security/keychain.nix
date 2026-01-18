_: {
  # KeyChain configuration for Darwin (macOS)
  # This module provides biometric authentication setup for KeyChain items

  # Note: nix-darwin doesn't provide built-in keychain item management
  # KeyChain items must be configured per-item using the security command
  # This module provides activation scripts and utilities for managing keychain

  system.activationScripts.postActivation.text = ''
    echo "Configuring KeyChain settings..."

    # Check if login keychain exists
    if [ -f "$HOME/Library/Keychains/login.keychain-db" ]; then
      echo "✓ Login keychain found"
    else
      echo "⚠ Login keychain not found, will be created on first use"
    fi

    # Set keychain settings for better security
    # Lock after 300 seconds (5 minutes) of inactivity
    if security show-keychain-info login.keychain-db 2>/dev/null; then
      security set-keychain-settings -l -u -t 300 login.keychain-db 2>/dev/null && \
        echo "✓ Keychain set to lock after 5 minutes of inactivity"
    fi

    echo "KeyChain configuration complete"
  '';
}
