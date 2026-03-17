{ config, pkgs, lib, ... }:
let
  cfg = config.programs.keepassxc;
  keepassxcPkg = cfg.package;

  manifest = builtins.toJSON {
    name = "org.keepassxc.keepassxc_browser";
    description = "KeePassXC integration with native messaging support";
    path = "${keepassxcPkg}/bin/keepassxc-proxy";
    type = "stdio";
    allowed_origins = [ "chrome-extension://oboonakemofpalcgghocfoadofidjkkk/" ];
  };

  chromiumManifests = {
    "BraveSoftware/Brave-Browser/NativeMessagingHosts/org.keepassxc.keepassxc_browser.json" = manifest;
    "net.imput.helium/NativeMessagingHosts/org.keepassxc.keepassxc_browser.json" = manifest;
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

  # Chromium-based browsers native messaging host manifests
  # nixpkgs keepassxc only ships a Firefox manifest at $out/lib/mozilla/
  # Home Manager's programs.chromium.nativeMessagingHosts expects $out/etc/chromium/
  # so we place manifests directly into each browser's NativeMessagingHosts directory
  home.file =
    lib.mkIf pkgs.stdenv.isDarwin
      (lib.mapAttrs' (name: value:
        lib.nameValuePair
          ("Library/Application Support/${name}")
          { text = value; force = true; }
      ) chromiumManifests);

  xdg.configFile =
    lib.mkIf pkgs.stdenv.isLinux
      (lib.mapAttrs' (name: value:
        lib.nameValuePair
          name
          { text = value; force = true; }
      ) chromiumManifests);
}
