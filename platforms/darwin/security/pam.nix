_: {
  # Enhanced Security Configuration for Darwin
  security.pam = {
    services = {
      # Enable Touch ID for sudo operations (Darwin-specific)
      sudo_local.touchIdAuth = true;
      # TODO: Are there other touchIdAuth's we should enable? RESEARCH REQUIRED
    };
  };
}
