{
  pkgs,
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.hardware.emeet-pixy;
in {
  options.hardware.emeet-pixy = {
    enable = mkEnableOption "EMEET PIXY webcam auto-activation daemon";

    user = mkOption {
      type = types.str;
      default = "lars";
      description = "User account for the daemon systemd service";
    };

    autoTracking = mkOption {
      type = types.bool;
      default = true;
      description = "Enable auto face tracking when video call detected";
    };

    autoPrivacy = mkOption {
      type = types.bool;
      default = true;
      description = "Enable privacy mode when no call is active";
    };

    defaultAudio = mkOption {
      type = types.enum ["nc" "live" "org"];
      default = "nc";
      description = "Default audio mode (nc=noise cancel, live, org=original)";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      v4l-utils
    ];

    services.udev.extraRules = ''
      # EMEET PIXY HID access for camera control (tracking, audio, gesture, privacy)
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="328f", ATTRS{idProduct}=="00c0", GROUP="video", MODE="0660", TAG+="uaccess"
      # EMEET PIXY video device access
      SUBSYSTEM=="video4linux", ATTRS{idVendor}=="328f", ATTRS{idProduct}=="00c0", GROUP="video", MODE="0660", TAG+="uaccess"
    '';

    # State directory
    systemd.tmpfiles.rules = [
      "d /run/emeet-pixyd 0755 ${cfg.user} video -"
    ];

    # User-level systemd service — inherits Wayland/pipewire session environment
    systemd.user.services.emeet-pixyd = {
      description = "EMEET PIXY Webcam Auto-Activation Daemon";
      after = ["pipewire.service" "graphical-session.target"];
      wants = ["pipewire.service"];
      partOf = ["graphical-session.target"];
      wantedBy = ["default.target"];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.emeet-pixyd}/bin/emeet-pixyd";
        Restart = "on-failure";
        RestartSec = "3";
      };

      path = [pkgs.v4l-utils pkgs.wireplumber];
    };
  };
}
