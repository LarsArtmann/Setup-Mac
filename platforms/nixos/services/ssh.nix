_: {
  # Enable OpenSSH daemon with hardening
  services.openssh = {
    enable = true;
    settings = {
      # Basic hardening
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      PermitEmptyPasswords = false;

      # Key-based authentication only
      PubkeyAuthentication = true;
      AuthorizedKeysFile = ".ssh/authorized_keys";

      # Security settings
      Protocol = 2;
      X11Forwarding = false;
      AllowTcpForwarding = false;
      PermitTunnel = false;

      # Access control
      AllowUsers = ["lars"]; # Only allow lars user

      # Connection limits
      MaxAuthTries = 3;
      MaxSessions = 2;
      ClientAliveInterval = 300; # 5 minutes
      ClientAliveCountMax = 2;

      # Strong cryptographic settings
      Ciphers = [
        "chacha20-poly1305@openssh.com"
        "aes256-gcm@openssh.com"
        "aes128-gcm@openssh.com"
        "aes256-ctr"
        "aes192-ctr"
        "aes128-ctr"
      ];

      KexAlgorithms = [
        "curve25519-sha256@libssh.org"
        "diffie-hellman-group16-sha512"
        "diffie-hellman-group18-sha512"
        "diffie-hellman-group14-sha256"
      ];

      # Logging
      LogLevel = "VERBOSE";

      # Banner
      Banner = "/etc/ssh/banner";
    };

    # Enable fail2ban integration for SSH protection
    openFirewall = true;
    ports = [22];
  };

  # SSH Banner
  environment.etc."ssh/banner".source = ../users/ssh-banner;
}
