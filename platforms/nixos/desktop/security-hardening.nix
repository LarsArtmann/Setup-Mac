{pkgs, ...}: {
  # Enable comprehensive security monitoring
  security = {
    # Enable polkit for authentication
    polkit.enable = true;

    # Add Swaylock PAM service for screen locking
    pam.services.swaylock = {};

    # System audit daemon for comprehensive logging
    auditd.enable = true;

    # AppArmor for mandatory access control
    apparmor.enable = true;
  };

  # Enable D-Bus for portal communication
  services.dbus = {
    enable = true;
    # Use dbus-broker for better Wayland support (UWSM preferred)
    implementation = "broker";
  };

  # Security services (SSH is configured separately in ../services/ssh.nix)
  services = {
    # Fail2ban for intrusion prevention
    fail2ban.enable = true;

    # ClamAV antivirus
    clamav.daemon.enable = true;
    clamav.updater.enable = true;
  };

  # Security tools
  environment.systemPackages = with pkgs; [
    # Authentication and portal support
    polkit_gnome
    # Note: xdg-utils moved to base.nix for cross-platform consistency
    gnome-keyring

    # Authentication & Access Control
    pamtester # PAM testing
    openssl # Cryptographic toolkit
    gnupg # Encryption & signing
    pass # Password manager

    # Network & Connection Monitoring
    iptraf-ng # IP traffic monitoring
    bmon # Network bandwidth monitor
    netsniff-ng # Network packet capture
    wireshark # Network protocol analyzer (GUI)
    aircrack-ng # WiFi security testing

    # System Security Monitoring
    aide # File integrity monitoring
    osquery # OS monitoring & security analytics

    # Process & File Monitoring
    lsof # List open files
    inotify-tools # File system monitoring
    iotop # I/O monitoring
    perf # Performance analysis

    # Log Analysis & Security
    goaccess # Web log analyzer
    ccze # Log colorizer

    # Privacy & Anonymity
    tor-browser # Anonymous browsing
    openvpn # VPN client
    wireguard-tools # Modern VPN

    # Vulnerability Assessment
    masscan # Fast port scanner
    sqlmap # SQL injection testing
    nikto # Web server scanner
    nuclei # Fast vulnerability scanner

    # Incident Response
    sleuthkit # Forensic toolkit
    tcpdump # Packet capture

    # Security tools (existing)
    wireshark-cli # Packet analysis (CLI)
    nmap # Network scanning
    lynis # Security auditing
  ];
}
