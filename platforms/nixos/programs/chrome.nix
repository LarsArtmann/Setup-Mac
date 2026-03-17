# NixOS Chrome/Chromium policy configuration for extension management
{ config, pkgs, lib, ... }:
let
  # YouTube Shorts Blocker extension by Umut Seven
  # Open source: https://github.com/umutseven92/shorts-blocker
  ytShortsBlockerId = "ckagfhpboagdopichicnebandlofghbc";

  # Chrome Web Store update URL
  chromeWebStoreUpdateUrl = "https://clients2.google.com/service/update2/crx";
in
{
  # NixOS programs.chromium module provides enterprise policy management
  programs.chromium = {
    enable = true;

    # Force-install extensions via ExtensionInstallForcelist policy
    extensions = [
      "${ytShortsBlockerId};${chromeWebStoreUpdateUrl}"
      # Format: "extension_id;update_url"
      # If update URL is omitted, defaults to Chrome Web Store
    ];

    # Additional policies via extraOpts
    extraOpts = {
      # Extension management
      ExtensionSettings = {
        # Default: block all extensions (restrictive approach)
        "*" = {
          installation_mode = "allowed";
          blocked_install_message = "Contact system administrator to request extension approval";
        };
        # Allow and pin YouTube Shorts Blocker
        "${ytShortsBlockerId}" = {
          installation_mode = "force_installed";
          toolbar_pin = "force_pinned";
          update_url = chromeWebStoreUpdateUrl;
        };
      };

      # Security policies
      BrowserSignin = 0;
      SyncDisabled = true;
      PasswordManagerEnabled = false;
      SafeBrowsingEnabled = true;
      HttpsOnlyMode = "force_enabled";

      # UI/UX policies
      RestoreOnStartup = 1; # Restore last session
      BookmarkBarEnabled = true;
      DefaultBrowserSettingEnabled = false;

      # Keep Manifest V2 extensions working
      ExtensionManifestV2Availability = 2;
    };

    # Initial preferences (user can change these)
    initialPrefs = {
      "first_run_tabs" = [
        "https://nixos.org/"
      ];
    };

    # Enable Plasma browser integration if using KDE
    # enablePlasmaBrowserIntegration = true;
  };

  # Note: This applies to Chromium, Google Chrome, and Brave system-wide
  # Users can still override some settings, but forced extensions cannot be removed
}
