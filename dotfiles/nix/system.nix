{ pkgs, lib, ... }:
let
  # Import centralized user configuration
  userConfig = (import ./core/UserConfig.nix { inherit lib; });

in {
  system = {
    primaryUser = userConfig.defaultUser.username;
    activationScripts = {
      # Consider switching to home-manager since this seems to be a user-specific configuration
      #   while it might be executed as root
      setFileAssociations.text = ''
        ${pkgs.duti}/bin/duti -s com.sublimetext.4 .txt all
        ${pkgs.duti}/bin/duti -s com.sublimetext.4 .md all
        ${pkgs.duti}/bin/duti -s com.sublimetext.4 .json all
        ${pkgs.duti}/bin/duti -s com.sublimetext.4 .jsonl all
        ${pkgs.duti}/bin/duti -s com.sublimetext.4 .yaml all
        ${pkgs.duti}/bin/duti -s com.sublimetext.4 .yml all
        ${pkgs.duti}/bin/duti -s com.sublimetext.4 .toml all
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
        # Battery configuration
        BatteryShowPercentage = true;  # Show battery percentage in menu bar

        # Control Center menu bar items (null = system default, true = show, false = hide)
        AirDrop = null;           # AirDrop control - use system default
        Bluetooth = true;         # Bluetooth control in menu bar
        Display = true;          # Screen brightness control in menu bar
        FocusModes = false;      # Focus modes control (Do Not Disturb)
        NowPlaying = true;       # Now Playing media control
        Sound = true;            # Volume control in menu bar
      };

      dock = {
        autohide = true;
        orientation = "left";
        showhidden = true;
        tilesize = 48;
        show-recents = false;
        show-process-indicators = false;
        static-only = false;
        mru-spaces = true;
        wvous-br-corner = 14; # Hot corner: bottom right - Quick Note
        persistent-apps = [];
      };
      finder = {
        # File visibility and extensions
        AppleShowAllExtensions = true;        # Always show file extensions
        AppleShowAllFiles = true;             # Show hidden files
        FXEnableExtensionChangeWarning = false; # Disable warning when changing file extensions

        # Window and view settings
        _FXShowPosixPathInTitle = true;       # Show full POSIX path in window title
        _FXSortFoldersFirst = true;           # Keep folders on top when sorting by name
        _FXSortFoldersFirstOnDesktop = true;  # Keep folders on top on desktop
        FXPreferredViewStyle = "clmv";        # Column view (icnv=icon, clmv=column, Flwv=gallery, Nlsv=list)

        # Search and navigation
        FXDefaultSearchScope = "SCcf";        # Search current folder (SCev=entire volume, SCcf=current folder, SCsp=previous scope)
        NewWindowTarget = "Home";             # New windows open to home folder
        # NewWindowTargetPath = "";           # Custom path when NewWindowTarget is "Other"

        # Desktop and external media
        CreateDesktop = true;                 # Show icons on desktop
        ShowExternalHardDrivesOnDesktop = false; # Don't show external drives on desktop
        ShowHardDrivesOnDesktop = false;      # Don't show internal drives on desktop
        ShowMountedServersOnDesktop = false;  # Don't show network volumes on desktop
        ShowRemovableMediaOnDesktop = false;  # Don't show USB drives, etc. on desktop

        # Interface elements
        ShowPathbar = true;                   # Show path breadcrumbs (was false, changing for better navigation)
        ShowStatusBar = true;                 # Show status bar with file counts and disk space
        QuitMenuItem = true;                  # Allow quitting Finder with Cmd+Q

        # Cleanup settings
        FXRemoveOldTrashItems = false;        # Don't auto-remove items from trash after 30 days

        # Quick Look settings (QLEnableTextSelection deprecated in recent nix-darwin)
        # QLEnableTextSelection = true;         # Allow text selection in Quick Look

        # Info panel settings (FXInfoPanesExpanded deprecated in recent nix-darwin)
        # FXInfoPanesExpanded = {
        #   MetaData = true;                    # Show metadata info panel expanded
        #   Preview = false;                    # Don't show preview panel expanded
        # };
      };
      hitoolbox.AppleFnUsageType = "Change Input Source";

      loginwindow = {
        # Guest account and security
        GuestEnabled = false;                    # Disable guest account for security
        DisableConsoleAccess = true;            # Disable console access for security

        # Login display options
        SHOWFULLNAME = false;                   # Show username field instead of full names (more secure)
        LoginwindowText = "Lars' MacBook Air";  # Custom login window text

        # Power management during login
        PowerOffDisabledWhileLoggedIn = false;  # Allow power off while logged in
        RestartDisabled = false;                # Allow restart from login window
        RestartDisabledWhileLoggedIn = false;   # Allow restart while logged in
        ShutDownDisabled = false;               # Allow shutdown from login window
        ShutDownDisabledWhileLoggedIn = false;  # Allow shutdown while logged in
        SleepDisabled = false;                  # Allow sleep from login window

        # Auto-login (disabled for security)
        # autoLoginUser = null;                 # No auto-login for security
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
        # File and interface behavior
        AppleShowAllFiles = true;              # Show hidden files globally
        AppleShowAllExtensions = true;         # Show all file extensions

        # Time and measurement localization
        AppleICUForce24HourTime = true;       # Use 24-hour time format
        AppleTemperatureUnit = "Celsius";     # Use Celsius for temperature
        AppleMeasurementUnits = "Centimeters"; # Use metric measurements
        AppleMetricUnits = 1;                 # Enable metric units globally (1 = true, 0 = false)

        # Interface appearance and behavior
        AppleInterfaceStyle = "Dark";         # Use dark mode
        AppleShowScrollBars = "Automatic";    # Show scrollbars automatically
        NSAutomaticWindowAnimationsEnabled = true; # Enable window animations
        NSScrollAnimationEnabled = true;     # Enable smooth scrolling

        # Keyboard and input settings
        ApplePressAndHoldEnabled = false;     # Disable press-and-hold for faster key repeat
        KeyRepeat = 2;                        # Fast key repeat (1-2 is fastest)
        InitialKeyRepeat = 15;                # Short delay before key repeat starts
        AppleKeyboardUIMode = 3;              # Enable full keyboard access for dialogs

        # Text editing behavior
        NSAutomaticCapitalizationEnabled = false;    # Disable auto-capitalization
        NSAutomaticSpellingCorrectionEnabled = false; # Disable auto-spelling correction
        NSAutomaticPeriodSubstitutionEnabled = false; # Disable automatic period substitution
        NSAutomaticQuoteSubstitutionEnabled = false;  # Disable smart quotes
        NSAutomaticDashSubstitutionEnabled = false;   # Disable smart dashes

        # System behavior
        NSDisableAutomaticTermination = true; # Prevent automatic app termination
        AppleSpacesSwitchOnActivate = false;  # Don't switch to app's space when activated

        # Window and workspace behavior
        AppleWindowTabbingMode = "always";    # Always prefer tabs in applications
        NSDocumentSaveNewDocumentsToCloud = true; # Save to iCloud by default

        # Trackpad settings (if applicable)
        "com.apple.trackpad.scaling" = 1.0;   # Trackpad tracking speed (0.0-3.0)
      };
      screencapture = {
        location = "~/Desktop";               # Save screenshots to Desktop
        type = "png";                        # Screenshot format (png, jpg, gif, pdf, tiff)
        disable-shadow = false;              # Include shadows in window screenshots
        show-thumbnail = true;               # Show thumbnail after capture
      };

      screensaver = {
        # Screensaver security settings
        askForPassword = true;               # Require password after screensaver
        askForPasswordDelay = 0;             # Require password immediately
      };

      # SMB (Server Message Block) network settings
      smb = {
        NetBIOSName = "Lars-MacBook-Air";    # NetBIOS name for network discovery
        ServerDescription = "Lars' MacBook Air"; # Server description for network
      };

      SoftwareUpdate.AutomaticallyInstallMacOSUpdates = false; # Manual macOS updates
      spaces.spans-displays = null;          # Use system default for multi-display spaces

      trackpad = {
        # Standard trackpad options
        Clicking = true;                # Enable tap to click
        TrackpadRightClick = true;      # Enable two-finger right click
        Dragging = false;               # Disable tap-to-drag
        TrackpadThreeFingerDrag = false; # Disable three finger drag
      };

      # Universal Access (Accessibility) settings
      universalaccess = {
        closeViewScrollWheelToggle = false;   # Disable zoom with scroll wheel + modifier
        closeViewZoomFollowsFocus = false;    # Don't follow focus when zooming
        mouseDriverCursorSize = 1.0;          # Standard cursor size (1.0-4.0)
        reduceMotion = false;                 # Don't reduce UI motion (keep animations)
        reduceTransparency = false;           # Keep interface transparency effects
      };

      # Window Manager settings (Stage Manager and window behavior)
      WindowManager = {
        # Stage Manager configuration
        EnableStandardClickToShowDesktop = true;  # Click desktop to show desktop
        StandardHideDesktopIcons = false;          # Show desktop icons
        StandardHideWidgets = false;               # Show widgets
        HideDesktop = false;                       # Don't hide desktop
        StageManagerHideWidgets = false;           # Show widgets in Stage Manager
        AutoHide = false;                          # Don't auto-hide windows
      };

      # Additional LaunchServices configuration for better app management
      LaunchServices = {
        LSQuarantine = false;  # Disable quarantine for downloaded apps (handle with caution)
      };

      # Custom User Defaults for enhanced functionality
      CustomUserPreferences = {
        # Enhanced Finder settings beyond the standard options
        "com.apple.finder" = {
          # Show Library folder in home directory
          "ShowLibraryFolder" = true;
          # Enable spring loading for directories
          "com.apple.springing.enabled" = true;
          # Spring loading delay
          "com.apple.springing.delay" = 0.5;
          # Remove delay for window animations
          "NSWindowResizeTime" = 0.001;
        };

        # Enhanced Dock settings
        "com.apple.dock" = {
          # Remove auto-hide delay
          "autohide-delay" = 0.0;
          # Speed up auto-hide animation
          "autohide-time-modifier" = 0.5;
          # Make hidden apps translucent in Dock
          "showhidden" = true;
          # Don't animate opening applications from the Dock
          "launchanim" = false;
        };

        # Terminal.app configuration - ensure Fish shell is used
        "com.apple.Terminal" = {
          # Set startup window settings to Basic profile
          "Startup Window Settings" = "Basic";
          # Configure Basic profile to use Fish shell
          "Window Settings" = {
            "Basic" = {
              "CommandString" = "/run/current-system/sw/bin/fish";
              "RunCommandAsShell" = true;
            };
          };
        };

        # iTerm2 configuration - ensure Fish shell is used
        "com.googlecode.iterm2" = {
          # Configure default bookmark to use Fish shell
          "New Bookmarks" = [
            {
              "Command" = "/run/current-system/sw/bin/fish";
              "Custom Command" = "Custom Shell";
              "Name" = "Default";
              "Guid" = "274FECB6-1D34-4A45-A1F9-23DFA78BA94B";
            }
          ];
          # Note: iTerm2 respects system restoration when NSQuitAlwaysKeepsWindows=true
          # and the Dock setting "Close windows when quitting an application" is disabled.
        };

        # Screenshot enhancements
        "com.apple.screencapture" = {
          # Include mouse cursor in screenshots
          "showsCursor" = false;
          # Disable drop shadow in screenshots
          "disable-shadow" = true;
        };

        # Safari security and privacy
        "com.apple.Safari" = {
          # Enable debug menus
          "IncludeInternalDebugMenu" = true;
          "IncludeDevelopMenu" = true;
          "WebKitDeveloperExtrasEnabledPreferenceKey" = true;
          "com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled" = true;
          # Privacy settings
          "UniversalSearchEnabled" = false;
          "SuppressSearchSuggestions" = true;
          "SendDoNotTrackHTTPHeader" = true;
          # Security settings
          "AutoOpenSafeDownloads" = false;
          # Disable auto-fill
          "AutoFillFromAddressBook" = false;
          "AutoFillPasswords" = false;
          "AutoFillCreditCardData" = false;
          "AutoFillMiscellaneousForms" = false;
        };

        # Menu bar clock with more precision
        "com.apple.menuextra.clock" = {
          "DateFormat" = "EEE d MMM HH:mm:ss";
          "FlashDateSeparators" = false;
          "IsAnalog" = false;
        };

        # Performance optimizations
        "NSGlobalDomain" = {
          # Reduce window resize animations
          "NSWindowResizeTime" = 0.025;
          # Increase window resize speed for Cocoa applications
          "NSDocumentRevisionsDebugMode" = true;
          # System window restoration must be enabled for iTerm2 to restore windows.
          # Disable System Settings > Desktop & Dock > "Close windows when quitting an application".
          "NSQuitAlwaysKeepsWindows" = true;
        };

        # System file management
        "com.apple.desktopservices" = {
          # Avoid creating .DS_Store files on external volumes
          "DSDontWriteUSBStores" = true;
          "DSDontWriteNetworkStores" = true;
        };

        # Privacy and advertising settings
        "com.apple.AdLib" = {
          "forceLimitAdTracking" = true;
          "allowApplePersonalizedAdvertising" = false;
          "allowIdentifierForAdvertising" = false;
        };
      };
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
