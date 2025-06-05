{ pkgs, ... }: {
  system = {
    primaryUser = "larsartmann";
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

      # Set Finder to always calculate folder sizes
      setFinderCalculateAllSizes.text = ''
        defaults write com.apple.finder FXCalculateAllSizes -bool true
        killall Finder
      '';

      # Register applications with Launch Services and update Spotlight index for Nix apps
      registerApplications.text = ''
        echo "Registering applications with Launch Services..."
        /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "/Applications/Nix Apps"

        echo "Updating Spotlight index for Nix applications..."
        mdimport "/Applications/Nix Apps"
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
      controlcenter = {
        AirDrop = true;                  # Show AirDrop control in menu bar
        BatteryShowPercentage = true;    # Show battery percentage in menu bar
        Bluetooth = true;                # Show bluetooth control in menu bar
        Display = true;                  # Show Screen Brightness control in menu bar
        FocusModes = true;               # Show Focus control in menu bar
        NowPlaying = true;               # Show Now Playing control in menu bar
        Sound = true;                    # Show sound control in menu bar
      };

      dock = {
        autohide = true;
        orientation = "bottom";
        showhidden = false;
        tilesize = 67;
        show-recents = false;
        show-process-indicators = true;
        static-only = false;
        mru-spaces = true;
        wvous-br-corner = 14; # Hot corner: bottom right - Quick Note
      };
      finder = {
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        FXEnableExtensionChangeWarning = true;
        FXRemoveOldTrashItems = false; # Remove items from the Trash after 30 days
        ShowPathbar = false;
        ShowStatusBar = true;
        _FXShowPosixPathInTitle = true;  # Show full POSIX path in Finder title
        CreateDesktop = true;            # Show desktop icons
        QuitMenuItem = true;             # Allow quitting Finder
        FXDefaultSearchScope = "SCcf";   # Search current folder by default
        FXPreferredViewStyle = "Nlsv";   # Use list view by default
      };
      hitoolbox.AppleFnUsageType = "Change Input Source";
      loginwindow = {
        GuestEnabled = false;
        DisableConsoleAccess = true;     # Disable console access at login
        LoginwindowText = "Welcome to Lars's Mac";  # Custom login message
        ShutDownDisabled = false;        # Allow shutdown from login window
        RestartDisabled = false;         # Allow restart from login window
        SleepDisabled = false;           # Allow sleep from login window
      };
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
        AppleShowAllFiles = true;               # Show hidden files everywhere
        AppleICUForce24HourTime = true;         # Use 24-hour time format
        AppleTemperatureUnit = "Celsius";       # Use Celsius for temperature
        AppleMeasurementUnits = "Centimeters";  # Use metric measurements
        AppleKeyboardUIMode = 3;                # Enable full keyboard access
        ApplePressAndHoldEnabled = false;       # Disable press-and-hold for accented characters
        AppleScrollerPagingBehavior = true;     # Jump to the spot clicked on scroll bar
        AppleShowScrollBars = "WhenScrolling";  # Show scroll bars when scrolling
        InitialKeyRepeat = 15;                  # Fast key repeat initial delay
        KeyRepeat = 2;                          # Fast key repeat rate
        NSAutomaticCapitalizationEnabled = false;      # Disable automatic capitalization
        NSAutomaticDashSubstitutionEnabled = false;    # Disable smart dashes
        NSAutomaticPeriodSubstitutionEnabled = false;  # Disable period substitution
        NSAutomaticQuoteSubstitutionEnabled = false;   # Disable smart quotes
        NSAutomaticSpellingCorrectionEnabled = false;  # Disable auto-correct
        NSDocumentSaveNewDocumentsToCloud = false;     # Save to disk by default
        NSNavPanelExpandedStateForSaveMode = true;     # Expand save panel by default
        NSNavPanelExpandedStateForSaveMode2 = true;    # Expand save panel by default
        NSTableViewDefaultSizeMode = 2;                # Use medium size for table views
        NSTextShowsControlCharacters = true;           # Show control characters in text
        NSUseAnimatedFocusRing = false;                # Disable animated focus ring
        NSWindowResizeTime = 0.001;                    # Fast window resize animations
        PMPrintingExpandedStateForPrint = true;        # Expand print panel by default
        PMPrintingExpandedStateForPrint2 = true;       # Expand print panel by default
      };
      screencapture.location = "~/Desktop";
      # TODO: ADD https://mynixos.com/nix-darwin/options/system.defaults.screencapture
      # TODO: ADD https://mynixos.com/nix-darwin/options/system.defaults.screensaver
      # TODO: ADD https://mynixos.com/nix-darwin/options/system.defaults.smb
      SoftwareUpdate.AutomaticallyInstallMacOSUpdates = false;
      spaces.spans-displays = null;

      trackpad = {
        # Standard trackpad options
        Clicking = true;                # Enable tap to click
        TrackpadRightClick = true;      # Enable two-finger right click
        Dragging = false;               # Disable tap-to-drag
        TrackpadThreeFingerDrag = false; # Disable three finger drag
      };

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
