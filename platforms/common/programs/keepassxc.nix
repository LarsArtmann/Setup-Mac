{ config, pkgs, lib, ... }:
let
  cfg = config.programs.keepassxc;
  keepassxcPkg = cfg.package;

  # Native messaging host manifest for KeePassXC browser extension
  # Required because nixpkgs keepassxc only ships a Firefox manifest
  manifest = builtins.toJSON {
    name = "org.keepassxc.keepassxc_browser";
    description = "KeePassXC integration with native messaging support";
    path = "${keepassxcPkg}/bin/keepassxc-proxy";
    type = "stdio";
    allowed_origins = [ "chrome-extension://oboonakemofpalcgghocfoadofidjkkk/" ];
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

  # Helium uses custom user data directory (not standard Chromium path)
  # macOS: ~/Library/Application Support/net.imput.helium/
  # Linux: ~/.config/helium/ (or ~/.config/net.imput.helium/)
  home.file =
    lib.mkIf pkgs.stdenv.isDarwin {
      "Library/Application Support/net.imput.helium/NativeMessagingHosts/org.keepassxc.keepassxc_browser.json" = {
        text = manifest;
        force = true;
      };
    };

  xdg.configFile =
    lib.mkIf pkgs.stdenv.isLinux {
      "helium/NativeMessagingHosts/org.keepassxc.keepassxc_browser.json" = {
        text = manifest;
        force = true;
      };
    };
}
