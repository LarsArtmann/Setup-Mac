{
  lib,
  sox,
  runCommand,
}:
runCommand "notification-tone" { nativeBuildInputs = [ sox ]; } ''
  mkdir -p $out/share/sounds

  # Three ascending pings: A5(880) → E6(1318) → A6(1760)
  # Power chord spread — bright, futuristic, satisfying
  sox -n $out/share/sounds/notification.ogg \
    synth 0.15 sine 880 fade 0.002 0.15 0.12 \
    : newfile : restart \
    synth 0.15 sine 1318 fade 0.002 0.15 0.12 \
    : newfile : restart \
    synth 0.4 sine 1760 fade 0.002 0.4 0.35

  sox \
    $out/share/sounds/notification001.ogg \
    $out/share/sounds/notification002.ogg \
    $out/share/sounds/notification003.ogg \
    $out/share/sounds/notification.ogg \
    splice 0.06,0.02 \
    splice 0.06,0.02 \
    gain -4

  rm $out/share/sounds/notification00*.ogg
''
