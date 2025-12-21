{ lib, pkgs, system ? pkgs.stdenv.hostPlatform.system }:

let
  # Platform detection
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
  isAarch64 = pkgs.stdenv.isAarch64;
  isx86_64 = pkgs.stdenv.isx86_64;

in
pkgs.stdenv.mkDerivation rec {
  pname = "helium";
  version = "0.7.6.1";

  # Platform-specific source handling
  src = if isDarwin then
    pkgs.fetchurl {
      url = "https://github.com/imputnet/helium-macos/releases/download/${version}/helium_${version}_${if isAarch64 then "arm64" else "x86_64"}-macos.dmg";
      sha256 = if isAarch64
        then "sha256-f35ecf26fdde1d8cd85222e65b1b670553a553fe964b9435d8a2945503703808" # ARM64 hash
        else "sha256-81030f17fddc05fe18797cd9561b565a9478813b5e2e3cd38fe2b7b0ebb83914"; # x86_64 hash
    }
  else if isLinux then
    pkgs.fetchurl {
      url = "https://github.com/imputnet/helium-linux/releases/download/${version}/helium-${version}_${if isAarch64 then "arm64" else "x86_64"}_linux.tar.xz";
      sha256 = if isAarch64
        then "sha256-1fasgax0d74nlxziqwh10x5xh25p82gnq9dh5qll2wc14hc98jmn" # ARM64 Linux hash
        else "sha256-12z2zhbchyq0jzhld57inkaxfwm2z8gxkamnnwcvlw96qqr0rga4"; # x86_64 Linux hash
    }
  else
    throw "Unsupported platform: ${system}";

  # Platform-specific build inputs
  nativeBuildInputs = with pkgs; 
    [ makeWrapper copyDesktopItems ] ++
    lib.optionals isDarwin [ undmg ] ++
    lib.optionals isLinux [ autoPatchelfHook ];

  # Platform-specific runtime dependencies
  buildInputs = with pkgs;
    lib.optionals isLinux [
      # Chromium runtime dependencies for Linux
      alsa-lib
      at-spi2-atk
      at-spi2-core
      atk
      cairo
      cups
      dbus
      expat
      fontconfig
      freetype
      gdk-pixbuf
      glib
      gtk3
      libGL
      xorg.libX11
      xorg.libXScrnSaver
      xorg.libXcomposite
      xorg.libXcursor
      xorg.libXdamage
      xorg.libXext
      xorg.libXfixes
      xorg.libXi
      xorg.libXrandr
      xorg.libXrender
      xorg.libXtst
      libdrm
      libgbm
      libpulseaudio
      xorg.libxcb
      libxkbcommon
      mesa
      nspr
      nss
      pango
      systemd
      vulkan-loader
      wayland
      libxshmfence
      libuuid
      kdePackages.qtbase
    ];

  # Platform-specific configuration
  sourceRoot = ".";
  
  # Ignore missing Qt libraries that might be bundled
  autoPatchelfIgnoreMissingDeps = lib.optionals isLinux [
    "libQt6Core.so.6"
    "libQt6Gui.so.6"
    "libQt6Widgets.so.6"
    "libQt5Core.so.5"
    "libQt5Gui.so.5"
    "libQt5Widgets.so.5"
  ];

  # Don't wrap Qt apps automatically on Linux
  dontWrapQtApps = true;

  # Platform-specific installation
  installPhase = ''
    runHook preInstall

    ${if isDarwin then ''
      # macOS installation
      mkdir -p $out/Applications
      cp -R "Helium.app" $out/Applications/
      
      # Create CLI wrapper for macOS
      mkdir -p $out/bin
      makeWrapper "$out/Applications/Helium.app/Contents/MacOS/Helium" $out/bin/helium
    '' else if isLinux then ''
      # Linux installation
      mkdir -p $out/opt/helium $out/bin
      cp -r * $out/opt/helium/
      
      # Create CLI wrapper for Linux with Wayland support
      makeWrapper "$out/opt/helium/chrome" $out/bin/helium \
        --prefix LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath (with pkgs; [
          libGL
          libvdpau
          libva
        ])}" \
        --add-flags "--ozone-platform-hint=auto" \
        --add-flags "--enable-features=WaylandWindowDecorations"
      
      # Install icon for Linux
      mkdir -p $out/share/icons/hicolor/256x256/apps
      cp $out/opt/helium/product_logo_256.png $out/share/icons/hicolor/256x256/apps/helium.png || true
    '' else ''
      throw "Unsupported platform"
    ''}

    runHook postInstall
  '';

  # Desktop integration (Linux only)
  desktopItems = lib.optionals isLinux [
    (pkgs.makeDesktopItem {
      name = "helium";
      exec = "helium %U";
      icon = "helium";
      desktopName = "Helium";
      genericName = "Web Browser";
      categories = [ "Network" "WebBrowser" ];
      terminal = false;
      mimeTypes = [ "text/html" "text/xml" "application/xhtml+xml" "x-scheme-handler/http" "x-scheme-handler/https" ];
    })
  ];

  # Passthru attributes for better integration
  passthru = {
    # Provide the binary path for easy access
    binaryPath = if isDarwin
      then "Applications/Helium.app/Contents/MacOS/Helium"
      else "opt/helium/chrome";
    
    # Platform identification
    platform = if isDarwin then "darwin" else if isLinux then "linux" else "unknown";
    
    # Architecture identification
    arch = if isAarch64 then "arm64" else if isx86_64 then "x86_64" else "unknown";
    
    # Update helper
    updateScript = pkgs.writeShellScript "update-helium" ''
      echo "Updating Helium browser to latest version..."
      # Add update logic here if needed
    '';
  };

  # Comprehensive metadata
  meta = with lib; {
    description = "Private, fast, and honest web browser based on ungoogled-chromium";
    longDescription = ''
      Helium is a privacy-focused web browser built on ungoogled-chromium that
      prioritizes user privacy and provides a clean, fast browsing experience
      without Google's telemetry and bloat. It includes built-in ad-blocking and
      enhanced privacy features by default.
    '';
    homepage = "https://helium.computer";
    downloadPage = "https://github.com/imputnet/helium-macos/releases";
    changelog = "https://github.com/imputnet/helium-macos/releases/tag/${version}";
    license = licenses.gpl3Only;
    platforms = platforms.darwin ++ platforms.linux;
    maintainers = with maintainers; [];
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    mainProgram = "helium";
    
    # Platform-specific broken conditions
    broken = (isDarwin && isx86_64 && lib.versionOlder pkgs.stdenv.hostPlatform.darwinMinVersion "10.15") ||
             (isLinux && !(isAarch64 || isx86_64));
    
    # Timeout settings for build
    timeout = 600;
    
    # Priority (higher means more likely to be chosen when multiple packages provide the same functionality)
    priority = 10;
    
    # Package can be built in parallel
    enableParallelBuilding = true;
    
    # Additional meta information
    hydraPlatforms = platforms.darwin ++ platforms.linux;
  };
}