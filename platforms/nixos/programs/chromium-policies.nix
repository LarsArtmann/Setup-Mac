# Force-install extensions via Helium's proxied update URL
# No explicit update_url → Helium routes through services.helium.imput.net
{
  config,
  pkgs,
  lib,
  ...
}: let
  # YouTube Shorts Blocker extension by Umut Seven
  # Open source: https://github.com/umutseven92/shorts-blocker
  ytShortsBlockerId = "ckagfhpboagdopichicnebandlofghbc";

  # OneTab - tab memory saver
  # https://chromewebstore.google.com/detail/onetab/chphlpgkkbolifaimnlloiipkdnihall
  oneTabId = "chphlpgkkbolifaimnlloiipkdnihall";
in {
  programs.chromium = {
    enable = true;

    extensions = [
      ytShortsBlockerId
      oneTabId
    ];

    extraOpts = {
      ExtensionSettings = {
        "${ytShortsBlockerId}" = {
          installation_mode = "force_installed";
          toolbar_pin = "force_pinned";
        };
        "${oneTabId}" = {
          installation_mode = "force_installed";
          toolbar_pin = "force_pinned";
        };
      };
    };
  };
}
