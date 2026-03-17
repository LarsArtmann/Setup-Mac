{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.programs.keepassxc;
  keepassxcPkg = cfg.package;

  # Native messaging manifest for KeePassXC browser extension
  # HM's keepassxc module handles Brave/Chromium/Firefox via nativeMessagingHosts,
  # but Helium has a non-standard user data directory that HM doesn't know about.
  # Helium uses net.imput.helium (from imputnet/helium change-chromium-branding.patch).
  #   macOS: ~/Library/Application Support/net.imput.helium/
  #   Linux: $XDG_CONFIG_HOME/net.imput.helium/
  manifest = builtins.toJSON {
    name = "org.keepassxc.keepassxc_browser";
    description = "KeePassXC integration with native messaging support";
    path = "${keepassxcPkg}/bin/keepassxc-proxy";
    type = "stdio";
    allowed_origins = ["chrome-extension://oboonakemofpalcgghocfoadofidjkkk/"];
  };
in
{
  programs.keepassxc = {
    enable = true;
    settings = {
      Browser.Enabled = true;
      Browser.UpdateBinaryPath = false;
      GUI.ApplicationTheme = "dark";
      GUI.CompactMode = true;
    };
  };

  # Helium browser native messaging host (non-standard config path)
  home.file =
    lib.mkIf pkgs.stdenv.isDarwin {
      "Library/Application Support/net.imput.helium/NativeMessagingHosts/org.keepassxc.keepassxc_browser.json" = {
        text = manifest;
        force = true;
      };
    };

  xdg.configFile =
    lib.mkIf pkgs.stdenv.isLinux {
      "net.imput.helium/NativeMessagingHosts/org.keepassxc.keepassxc_browser.json" = {
        text = manifest;
        force = true;
      };
    };
}
