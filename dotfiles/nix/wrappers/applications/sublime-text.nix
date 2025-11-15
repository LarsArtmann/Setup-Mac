# Sublime Text Wrapper
# Complete Sublime Text configuration with embedded settings

{ pkgs, lib, writeShellScriptBin, symlinkJoin, makeWrapper }:

let
  # Simple wrapper function for GUI applications
  wrapWithConfig = { name, package, configFiles ? {}, env ? {}, preHook ? "", postHook ? "" }:
    writeShellScriptBin name ''
      ${preHook}
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v: "export ${k}=\"${v}\"") env)}

      # Ensure config directories exist
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (configPath: source: ''
        mkdir -p "$(dirname "$HOME/.${configPath}")"
        ln -sf "${source}" "$HOME/.${configPath}" 2>/dev/null || true
      '') configFiles)}

      # Run the original binary
      exec "${lib.getBin package}/Applications/${name}.app/Contents/MacOS/${name}" "$@"
      ${postHook}
    '';

  # Sublime Text preferences
  sublimePreferences = pkgs.writeText "Preferences.sublime-settings" ''
    {
      "auto_complete": true,
      "auto_complete_commit_on_tab": true,
      "auto_complete_with_fields": true,
      "color_scheme": "Packages/Color Scheme - Default/Monokai.sublime-color-scheme",
      "font_face": "JetBrains Mono",
      "font_size": 14,
      "highlight_line": true,
      "highlight_modified_tabs": true,
      "ignored_packages":
      [
        "Vintage",
        "Markdown"
      ],
      "line_numbers": true,
      "rulers": [80, 120],
      "scroll_past_end": true,
      "show_encoding": true,
      "show_line_endings": true,
      "tab_size": 2,
      "translate_tabs_to_spaces": true,
      "trim_automatic_white_space": true,
      "trim_trailing_white_space_on_save": true,
      "word_wrap": true,
      "wrap_width": 80
    }
  '';

  # Package Control settings
  packageControlSettings = pkgs.writeText "Package Control.sublime-settings" ''
    {
      "bootstrap": true,
      "installed_packages": [
        "Package Control",
        "GitSavvy",
        "SublimeLinter",
        "SublimeLinter-contrib-golangci-lint",
        "SublimeLinter-eslint",
        "Prettier",
        "Docker",
        "Nix",
        "TypeScript",
        "GoSublime"
      ]
    }
  '';

  # macOS keymap
  osxKeymap = pkgs.writeText "Default (OSX).sublime-keymap" ''
    [
      { "keys": ["super+shift+f"], "command": "show_panel", "args": {"panel": "find_in_files"} },
      { "keys": ["super+alt+down"], "command": "duplicate_line" },
      { "keys": ["super+alt+up"], "command": "swap_line_up" },
      { "keys": ["super+l"], "command": "show_overlay", "args": {"overlay": "goto", "text": "@"} },
      { "keys": ["super+shift+l"], "command": "show_overlay", "args": {"overlay": "goto", "text": ":"} },
      { "keys": ["super+ctrl+p"], "command": "prompt_select_workspace" }
    ]
  '';

  # Create Sublime Text wrapper
  sublimeTextWrapper = wrapWithConfig {
    name = "sublime-text";
    package = pkgs.sublime-text;
    configFiles = {
      # Sublime Text settings
      "Library/Application Support/Sublime Text/Packages/User/Preferences.sublime-settings" = sublimePreferences;
      "Library/Application Support/Sublime Text/Packages/User/Package Control.sublime-settings" = packageControlSettings;
      "Library/Application Support/Sublime Text/Packages/User/Default (OSX).sublime-keymap" = osxKeymap;
    };
    env = {
      SUBLIME_SETTINGS = "$(pwd)/Library/Application Support/Sublime Text/Packages/User";
    };
    postHook = ''
      # Install required packages on first run
      if [ ! -d "$HOME/Library/Application Support/Sublime Text/Installed Packages/Package Control.sublime-package" ]; then
        echo "Installing Package Control for Sublime Text..."
        mkdir -p "$HOME/Library/Application Support/Sublime Text/Installed Packages"
        curl -o "$HOME/Library/Application Support/Sublime Text/Installed Packages/Package Control.sublime-package" \
          "https://packagecontrol.io/Package%20Control.sublime-package"
      fi
    '';
  };

in
{
  # Export wrapper for use in system packages
  "sublime-text" = sublimeTextWrapper;
}