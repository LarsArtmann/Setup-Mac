_: {
  # Enable sound with pipewire
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # JACK audio support for professional audio applications
    # Provides low-latency audio processing and audio app interconnection
    jack.enable = true;
  };

  # Pulseaudio disabled (conflicts with pipewire)
  services.pulseaudio.enable = false;

  # Realtime scheduling for audio
  security.rtkit.enable = true;
}
