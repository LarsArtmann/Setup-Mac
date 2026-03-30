{inputs, ...}: {
  flake.nixosModules.ssh = _: {
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
        # Accept both modern (rsa-sha2-256/512) and legacy (ssh-rsa) key algorithms
        # OpenSSH 10.2p1 removed ssh-rsa from defaults; macOS clients may still offer it
        # Explicitly list all algorithms instead of + prefix for reliability
        PubkeyAcceptedAlgorithms = "ssh-rsa,rsa-sha2-256,rsa-sha2-512,ssh-ed25519,sk-ssh-ed25519@openssh.com";
        AuthorizedKeysFile = "%h/.ssh/authorized_keys /etc/ssh/authorized_keys.d/%u";

        # Security settings
        Protocol = 2;
        X11Forwarding = false;
        AllowTcpForwarding = false;
        PermitTunnel = false;

        # Access control
        AllowUsers = ["lars" "art"]; # Only allow lars user

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
    environment.etc."ssh/banner".text = ''
      ╔══════════════════════════════════════════╗
      ║  AUTHORIZED ACCESS ONLY - All activity logged ║
      ╚══════════════════════════════════════════╝
    '';
  };
}
