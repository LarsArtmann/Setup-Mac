_: {
  # Enable sound with pipewire
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;
  };

  # Pulseaudio disabled (conflicts with pipewire)
  services.pulseaudio.enable = false;

  # Realtime scheduling for audio
  security.rtkit.enable = true;
}
