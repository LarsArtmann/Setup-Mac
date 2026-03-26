# Test wrapped niri module
{
  self,
  inputs,
  ...
}: {
  perSystem = {
    pkgs,
    lib,
    ...
  }: {
    packages.niri-wrapped = inputs.wrapper-modules.wrappers.niri.wrap {
      inherit pkgs;

      settings = {
        spawn-at-startup = [
          ["kitty"]
        ];

        binds = {
          "Mod+Return".spawn = ["kitty"];
          "Mod+Q".close-window = null;
        };

        layout = {
          gaps = 8;
        };
      };
    };
  };
}
