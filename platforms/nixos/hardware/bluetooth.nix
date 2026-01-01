{
  # Bluetooth configuration for audio casting to Google Nest Audio
  # Nest Audio supports Bluetooth audio streaming natively
  # This is the recommended approach over Google Cast for system-wide audio

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        # Enable audio source and sink roles
        Enable = "Source,Sink,Media,Socket";
        # Auto-connect to paired devices
        AutoEnable = true;
      };
    };
  };

  # Blueman: GTK+ Bluetooth Manager with GUI
  services.blueman.enable = true;

  # PulseAudio/PipeWire Bluetooth audio support
  # PipeWire handles Bluetooth audio automatically when enabled
}
