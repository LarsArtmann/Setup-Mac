# Kitty Terminal Wrapper
# GUI application wrapper with embedded configuration

{ pkgs, lib, wrappers }:

let
  # Kitty configuration optimized for development
  kittyConfig = pkgs.writeText "kitty.conf" ''
    # 🐱 Optimized Kitty Configuration
    # Performance-optimized with developer-friendly settings

    # Font settings
    font_family      JetBrains Mono
    font_size        14
    bold_font        JetBrains Mono Bold
    italic_font      JetBrains Mono Italic
    bold_italic_font JetBrains Mono Bold Italic

    # Performance settings
    repaint_delay    10
    input_delay      3
    sync_to_monitor  yes

    # Visual settings
    background_opacity         0.95
    window_padding_width       8
    tab_bar_style              fade
    tab_bar_edge               bottom
    tab_margin_height          0
    foreground                 #f8f8f2
    background                 #282a36
    cursor                     #f8f8f2

    # Color scheme - Dracula
    color0     #000000
    color1     #ff5555
    color2     #50fa7b
    color3     #f1fa8c
    color4     #bd93f9
    color5     #ff79c6
    color6     #8be9fd
    color7     #f8f8f2
    color8     #6272a4
    color9     #ff6e6e
    color10    #69ff94
    color11    #ffffa5
    color12    #d6acff
    color13    #ff92df
    color14    #a4ffff
    color15    #ffffff

    # Mouse settings
    mouse_hide_wait 3.0
    copy_on_select yes

    # Shell integration
    shell_integration enabled
    enable_audio_bell no

    # Performance optimizations
    tab_powerline_style round
    active_tab_foreground   #282a36
    active_tab_background   #f8f8f2
    inactive_tab_foreground #f8f8f2
    inactive_tab_background #6272a4

    # Keyboard shortcuts
    map cmd+v        paste_from_clipboard
    map cmd+c        copy_to_clipboard
    map cmd+shift+c  copy_to_clipboard
    map cmd+shift+v  paste_from_clipboard
    map cmd+t        new_tab
    map cmd+w        close_tab
    map cmd+q        close_window
    map cmd+enter    new_window

    # Developer-friendly shortcuts
    map ctrl+shift+1 launch --location=hsplit --cwd=current
    map ctrl+shift+2 launch --location=vsplit --cwd=current
  '';
in
wrappers.wrapperModules.kitty.apply {
  inherit pkgs;

  configFiles = {
    "config/kitty/kitty.conf" = kittyConfig;
  };

  environment = {
    KITTY_CONFIG_DIRECTORY = "$(pwd)/.config/kitty";
    KITTY_CACHE_DIRECTORY = "$(pwd)/.cache/kitty";
  };

  preHook = ''
    # Create kitty directories
    mkdir -p "$KITTY_CONFIG_DIRECTORY"
    mkdir -p "$KITTY_CACHE_DIRECTORY"
  '';
}