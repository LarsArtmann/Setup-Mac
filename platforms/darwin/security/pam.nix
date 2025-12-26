_ {
  # Enhanced Security Configuration for Darwin
  security.pam = {
    services = {
      # Enable Touch ID for sudo operations (Darwin-specific)
      sudo_local.touchIdAuth = true;
    };
  };
}