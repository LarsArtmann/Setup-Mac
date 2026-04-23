# NixOS Chromium enterprise policies for Helium browser extension management
# Helium proxies all extension downloads through services.helium.imput.net
# No explicit update_url = Helium uses its own proxied default
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
        "*" = {
          installation_mode = "allowed";
        };
        "${ytShortsBlockerId}" = {
          installation_mode = "force_installed";
          toolbar_pin = "force_pinned";
        };
        "${oneTabId}" = {
          installation_mode = "force_installed";
          toolbar_pin = "force_pinned";
        };
      };

      BrowserSignin = 0;
      SyncDisabled = true;
      PasswordManagerEnabled = false;
      HttpsOnlyMode = "force_enabled";

      RestoreOnStartup = 1;
      BookmarkBarEnabled = true;
      DefaultBrowserSettingEnabled = false;

      ExtensionManifestV2Availability = 2;
    };

    initialPrefs = {
      "first_run_tabs" = [
        "https://nixos.org/"
      ];
    };
  };
}
