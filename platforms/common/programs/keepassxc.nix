{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.programs.keepassxc;
  keepassxcPkg = cfg.package;

  # Wrapper that provides Chromium-native messaging manifests.
  # nixpkgs keepassxc only ships $out/lib/mozilla/ (Firefox format).
  # HM's chromium/brave modules expect $out/etc/chromium/native-messaging-hosts/.
  # This wrapper symlinks everything from keepassxc and adds the missing dir.
  keepassxcWithChromiumManifests = pkgs.runCommandLocal "keepassxc-with-chromium-manifests" {} ''
    cp -rsT ${keepassxcPkg} $out
    chmod -R u+w $out
    mkdir -p $out/etc/chromium/native-messaging-hosts
    cat > $out/etc/chromium/native-messaging-hosts/org.keepassxc.keepassxc_browser.json <<MANIFEST
    ${builtins.toJSON {
      name = "org.keepassxc.keepassxc_browser";
      description = "KeePassXC integration with native messaging support";
      path = "${keepassxcPkg}/bin/keepassxc-proxy";
      type = "stdio";
      allowed_origins = [ "chrome-extension://oboonakemofpalcgghocfoadofidjkkk/" ];
    }}
    MANIFEST
  '';

  # Native messaging manifest for Helium browser extension.
  # HM's keepassxc module handles Brave/Chromium/Firefox via nativeMessagingHosts,
  # but Helium has a non-standard user data directory that HM doesn't know about.
  # Helium uses net.imput.helium (from imputnet/helium change-chromium-branding.patch).
  #   macOS: ~/Library/Application Support/net.imput.helium/
  #   Linux: $XDG_CONFIG_HOME/net.imput.helium/
  heliumManifest = builtins.toJSON {
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
    package = keepassxcWithChromiumManifests;
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
        text = heliumManifest;
        force = true;
      };
    };

  xdg.configFile =
    lib.mkIf pkgs.stdenv.isLinux {
      "net.imput.helium/NativeMessagingHosts/org.keepassxc.keepassxc_browser.json" = {
        text = heliumManifest;
        force = true;
      };
    };
}
