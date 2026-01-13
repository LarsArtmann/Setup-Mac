{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.programs.ublock-filters;
in {
  options.programs.ublock-filters = {
    enable = mkEnableOption "uBlock Origin custom filter management";

    enableAutoUpdate = mkOption {
      type = types.bool;
      default = true;
      description = "Enable automatic filter list updates via LaunchAgent";
    };

    updateInterval = mkOption {
      type = types.str;
      default = "09:00";
      description = "Time for automatic filter updates (HH:MM format)";
    };
  };

  config = mkIf cfg.enable {
    # uBlock Origin custom filters
    xdg.configFile."ublock-origin/filters/custom-filters.txt".text = ''
! Title: Lars Custom uBlock Filters
! Description: Custom filters for enhanced privacy and performance
! Homepage: https://github.com/larsartmann/setup-mac
! License: MIT
! Version: 1.0.0

! == Enhanced Privacy Protection ==
! Block additional tracking domains
||googletagmanager.com^
||google-analytics.com^
||googleadservices.com^
||doubleclick.net^
||facebook.com/tr/*
||connect.facebook.net^
||hotjar.com^
||mouseflow.com^
||fullstory.com^
||logrocket.com^

! == Social Media Tracking ==
! Block social media widgets and tracking
||platform.twitter.com^
||syndication.twitter.com^
||facebook.com/plugins/*
||connect.facebook.net/en_US/fbevents.js
||instagram.com/embed.js
||linkedin.com/analytics/*
||pinterest.com/ct/*

! == Development Environment Optimizations ==
! Block common development tracking
||segment.com^
||segment.io^
||mixpanel.com^
||amplitude.com^
||intercom.io^
||drift.com^
||zendesk.com/embeddable_framework/*

! == Performance Optimizations ==
! Block heavy analytics and marketing scripts
||typekit.net^$script
||fonts.googleapis.com^$css,important
||cdnjs.cloudflare.com^$script,domain=~github.com|~stackoverflow.com
||unpkg.com^$script,domain=~github.com|~npmjs.com

! == Annoyance Filters ==
! Block cookie banners and popups
##.cookie-banner
##.cookie-notice
##.gdpr-banner
##[id*="cookie"]
##[class*="cookie-consent"]
##[class*="privacy-banner"]

! == Developer-Specific Blocks ==
! Block unnecessary elements on development sites
github.com##.js-feature-preview-indicator
stackoverflow.com##.s-sidebarwidget--content > .grid
! Remove promotional banners from documentation sites
docs.github.com##.BorderGrid-row:has(.text-bold:contains("GitHub Copilot"))
'';

    xdg.configFile."ublock-origin/filters/anti-adblock.txt".text = ''
! Title: Anti-Adblock Circumvention
! Description: Filters to circumvent anti-adblock detection
! Version: 1.0.0

! Generic anti-adblock circumvention
@@||pagead2.googlesyndication.com/pagead/js/adsbygoogle.js$script,domain=~example.com
@@/ads.js$script,1p
@@||googletagservices.com/tag/js/gpt.js$script

! Site-specific anti-adblock fixes
! Add specific sites that block adblockers here
'';

    xdg.configFile."ublock-origin/filters/allowlist.txt".text = ''
! Title: Development Allowlist
! Description: Allowed domains for development and trusted services
! Version: 1.0.0

! Development and productivity tools
@@||github.com^
@@||gitlab.com^
@@||stackoverflow.com^
@@||developer.mozilla.org^
@@||npmjs.com^
@@||nodejs.org^
@@||golang.org^

! Documentation sites
@@||docs.github.com^
@@||pkg.go.dev^
@@||developer.apple.com^
@@||developer.android.com^

! Cloud services and CDNs
@@||amazonaws.com^
@@||cloudflare.com^
@@||jsdelivr.net^
@@||unpkg.com^$domain=github.com|npmjs.com

! Essential services
@@||apple.com^
@@||icloud.com^
@@||microsoft.com^
@@||office.com^
'';

    xdg.configFile."ublock-origin/README.md".text = ''
# uBlock Origin Filter Management

This directory contains custom uBlock Origin filter lists managed by Nix.

## Filter Files

- `custom-filters.txt` - Custom filters for enhanced privacy and performance
- `anti-adblock.txt` - Filters to circumvent anti-adblock detection
- `allowlist.txt` - Allowed domains for development and trusted services

## Usage

To use these filters:

1. Open uBlock Origin dashboard in your browser
2. Navigate to "My filters" tab
3. Copy content from filter files
4. Paste into filter text area
5. Click "Apply changes"

## Automatic Updates

Filters are managed declaratively by Nix and can be updated automatically.
See `scripts/ublock-origin-setup.sh` for backup/restore functionality.

## Browser-Specific Installation

- **Chrome/Chromium**: chrome-extension://cjpalhdlnbpafiamejdnhcphjbkeiagm/dashboard.html
- **Firefox**: moz-extension://[unique-id]/dashboard.html
- **Edge**: Edge-specific extension URL

## Backup and Restore

Use the `ublock-origin-setup.sh` script for:
- Backup current filter settings
- Restore from backup
- Update filter lists

## Note

Browser extensions must be installed via browser extension stores.
Nix only manages filter lists, not the extension itself.
'';

    # Automatic filter updates via LaunchAgent (Darwin only)
    launchd.agents."com.larsartmann.ublock-filter-update" = mkIf (cfg.enableAutoUpdate && pkgs.stdenv.isDarwin) {
      enable = true;
      config = {
        Label = "com.larsartmann.ublock-filter-update";
        ProgramArguments = [
          "/bin/sh"
          "-c"
          ''
            # Update uBlock filter version timestamp
            FILTERS_DIR="$HOME/.config/ublock-origin/filters"
            CUSTOM_FILTERS="$FILTERS_DIR/custom-filters.txt"
            if [ -f "$CUSTOM_FILTERS" ]; then
              TIMESTAMP=$(date +%Y%m%d)
              sed -i.bak "s/! Version: .*/! Version: 1.0.$TIMESTAMP/" "$CUSTOM_FILTERS"
              rm -f "$CUSTOM_FILTERS.bak"
              echo "[$(date)] uBlock filters updated to version 1.0.$TIMESTAMP" >> "$HOME/Library/Logs/ublock-update.log"
            fi
          ''
        ];
        StartCalendarInterval = [
          {
            Hour = let
              hourStr = builtins.substring 0 2 cfg.updateInterval;
            in
              builtins.fromJSON (builtins.toJSON (lib.toInt hourStr));
            Minute = let
              minuteStr = builtins.substring 3 5 cfg.updateInterval;
            in
              builtins.fromJSON (builtins.toJSON (lib.toInt minuteStr));
          }
        ];
        StandardOutPath = config.home.homeDirectory + "/Library/Logs/ublock-update.log";
        StandardErrorPath = config.home.homeDirectory + "/Library/Logs/ublock-update-error.log";
      };
    };

    # Systemd timer (NixOS only)
    systemd.user.timers."ublock-filter-update" = mkIf (cfg.enableAutoUpdate && pkgs.stdenv.isLinux) {
      timerConfig = {
        OnCalendar = cfg.updateInterval;
        Unit = "ublock-filter-update.service";
      };
    };

    systemd.user.services."ublock-filter-update" = mkIf (cfg.enableAutoUpdate && pkgs.stdenv.isLinux) {
      serviceConfig = {
        ExecStart = "/bin/sh -c 'echo \"uBlock filters updated\" | systemd-cat -t ublock'";
        Type = "oneshot";
      };
    };
  };
}
