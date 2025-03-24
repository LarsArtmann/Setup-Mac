{ pkgs, ... }: {
  system = {
    activationScripts = {
      # Consider switching to home-manager since this seems to be a user-specific configuration
      #   while it might be executed as root
      setFileAssociations.text = ''
        ${pkgs.duti}/bin/duti -s com.sublimetext.4 .txt all
        ${pkgs.duti}/bin/duti -s com.sublimetext.4 .md all
        ${pkgs.duti}/bin/duti -s com.sublimetext.4 .json all
        ${pkgs.duti}/bin/duti -s com.sublimetext.4 .yaml all
        ${pkgs.duti}/bin/duti -s com.sublimetext.4 .yml all
        ${pkgs.duti}/bin/duti -s com.apple.TextEdit .rtf all
      '';
    };

    checks = {
      verifyBuildUsers = true;
      verifyMacOSVersion = true;
      #verifyNixPath = true; DO NOT enable! "error: file 'darwin-config' was not found in the Nix search path"
    };

    defaults = {
      ActivityMonitor = {
        IconType = null;
        OpenMainWindow = true;
        ShowCategory = null;
        SortColumn = "CPUUsage";
        SortDirection = 0;
      };
      controlcenter.BatteryShowPercentage = true;
      # TODO: ADD https://mynixos.com/nix-darwin/options/system.defaults.controlcenter
      # TODO: ADD https://mynixos.com/nix-darwin/options/system.defaults.dock
      finder = {
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        FXEnableExtensionChangeWarning = true;
        FXRemoveOldTrashItems = false; # Remove items from the Trash after 30 days
        ShowPathbar = false;
        ShowStatusBar = true;
        # TODO: ADD https://mynixos.com/nix-darwin/options/system.defaults.finder
      };
      hitoolbox.AppleFnUsageType = "Change Input Source";
      loginwindow.GuestEnabled = false;
      # TODO: ADD https://mynixos.com/nix-darwin/options/system.defaults.loginwindow
      menuExtraClock = {
        FlashDateSeparators = false;
        IsAnalog = null;
        Show24Hour = true;
        ShowDate = 0;
        ShowDayOfMonth = null;
        ShowDayOfWeek = null;
        ShowSeconds = true;
      };
      NSGlobalDomain = {
        AppleShowAllFiles = true;
        AppleICUForce24HourTime = true;
        AppleTemperatureUnit = "Celsius";
        AppleMeasurementUnits = "Centimeters";
        # TODO: ADD https://mynixos.com/nix-darwin/options/system.defaults.NSGlobalDomain
      };
      screencapture.location = "~/Desktop";
      # TODO: ADD https://mynixos.com/nix-darwin/options/system.defaults.screencapture
      # TODO: ADD https://mynixos.com/nix-darwin/options/system.defaults.screensaver
      # TODO: ADD https://mynixos.com/nix-darwin/options/system.defaults.smb
      SoftwareUpdate.AutomaticallyInstallMacOSUpdates = false;
      spaces.spans-displays = null;
      # TODO: ADD https://mynixos.com/nix-darwin/options/system.defaults.trackpad
      # TODO: ADD https://mynixos.com/nix-darwin/options/system.defaults.universalaccess
      # TODO: ADD https://mynixos.com/nix-darwin/options/system.defaults.WindowManager
    };

    keyboard = {
      nonUS = {
        remapTilde = false;
      };
      enableKeyMapping = true;
      remapCapsLockToControl = false;
      remapCapsLockToEscape = true;
      swapLeftCommandAndLeftAlt = false;
      swapLeftCtrlAndFn = false;
    };

    startup = {
      chime = true;
    };

    # Set Git commit hash for darwin-version.
    #configurationRevision = self.rev or self.dirtyRev or null;

    #darwinLabel = "";
    nixpkgsRelease = "unstable";

    #patches = [ ];
    #profile = "";

    # Used for backwards compatibility, please read the changelog before changing.
    # $ darwin-rebuild changelog
    #    2025-01-18
    #    - The default configuration path for all new installations
    #      is `/etc/nix-darwin`. This was already the undocumented
    #      default for `darwin-rebuild switch` when using flakes. This
    #      is implemented by setting `environment.darwinConfig` to
    #      `"/etc/nix-darwin/configuration.nix"` by default when
    #      `system.stateVersion` ≥ 6.
    stateVersion = 6;
  };
}
