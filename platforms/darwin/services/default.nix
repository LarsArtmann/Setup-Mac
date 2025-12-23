_: {
  # Homebrew integration (Darwin-specific)
  # This is handled through the homebrew.nix module at root level

  # Touch ID for sudo
  security.pam.services = {
    sudo_local.touchIdAuth = true;
  };

  # Darwin-specific service configurations
  # Add any macOS-specific services here
}
