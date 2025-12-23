{ pkgs, lib, ... }:

{
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
    xdg-utils
    # Authentication helper
    gnome-keyring

    # Security tools
    wireshark-cli  # Packet analysis
    nmap  # Network scanning
    lynis  # Security auditing
  ];
}
