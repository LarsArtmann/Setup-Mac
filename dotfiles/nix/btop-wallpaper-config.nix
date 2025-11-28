# Ghost Btop Wallpaper Configuration
# Enable the btop wallpaper service with default settings
{
  services.ghost-btop-wallpaper = {
    enable = true;
    updateRate = 2000;
    backgroundOpacity = "0.0";
    autoStart = true;
  };
}