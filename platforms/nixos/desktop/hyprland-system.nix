{ pkgs, lib, ... }:

{
  services = {
    # Enable X11 windowing system.
    xserver = {
      enable = true;
      
      # Configure keymap in X11
      xkb = {
        layout = "us";
        variant = "";
      };
    };
    
    # Enable SDDM (Simple Desktop Display Manager) with X11 support
    # Replaces heavier GDM/GNOME setup
    # Note: Wayland disabled for stability with AMD GPU
    displayManager.sddm = {
      enable = true;
      wayland.enable = false;  # Disabled for AMD GPU stability
      theme = "sugar-dark";
      enableHidpi = true;
      autoNumlock = true;
      extraPackages = [ pkgs.sddm-sugar-dark ];
    };
    
    # Enable D-Bus for portal communication
    dbus = {
      enable = true;
      # Use dbus-broker for better Wayland support (UWSM preferred)
      implementation = "broker";
    };
    
    # Enable sound with pipewire.
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      # If you want to use JACK applications, uncomment this
      #jack.enable = true;
    };
    
    # Pulseaudio disabled (conflicts with pipewire)
    pulseaudio.enable = false;
  };

  # Enable Hyprland with proper configuration
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;  # ESSENTIAL for X11 application compatibility
    # Ensure the portal package is properly set
    portalPackage = pkgs.xdg-desktop-portal-hyprland;
    # Use UWSM for improved systemd support (recommended)
    withUWSM = true;
    # Set systemd path for proper application launching
    systemd.setPath.enable = true;
  };

  # Enable comprehensive security monitoring
  security = {
    # Enable polkit for authentication
    polkit.enable = true;
    
    # Add Swaylock PAM service for screen locking
    pam.services.swaylock = {};
    
    # Realtime scheduling for audio
    rtkit.enable = true;
    
    # System audit daemon for comprehensive logging
    auditd.enable = true;
    
    # AppArmor for mandatory access control
    apparmor.enable = true;
  };

  # Enable comprehensive AI/ML setup for Ryzen AI Max+ 395
  hardware = {
    # OpenGL and GPU support
    graphics = {
      enable = true;
      enable32Bit = true;
      # AMD GPU configuration
      extraPackages = with pkgs; [
        rocmPackages.rocm-runtime
        rocmPackages.rocblas
        rocmPackages.hipblas
        rocmPackages.rocrand
        rocmPackages.rocm-smi
      ];
    };
    
    # Enable AMD GPU acceleration
    amdgpu.opencl.enable = true;
  };

  # AMD ROCm configuration for AI acceleration
  environment.variables = {
    HIP_VISIBLE_DEVICES = "0";
    ROCM_PATH = "${pkgs.rocmPackages.rocm-runtime}";
    HSA_OVERRIDE_GFX_VERSION = "11.0.0";  # For RDNA3
    PYTORCH_ROCM_ARCH = "gfx1100";  # For Ryzen AI Max+ 395
  };

  # System services for AI and ML
  services = {
    # Fail2ban for intrusion prevention
    fail2ban.enable = true;
    
    # ClamAV antivirus
    clamav.daemon.enable = true;
    clamav.updater.enable = true;
    
    # OpenSSH server with security hardening
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
        X11Forwarding = false;
        PermitEmptyPasswords = false;
        ChallengeResponseAuthentication = false;
        UsePAM = true;
        AcceptEnv = "LANG LC_*";
        Subsystem = "sftp /run/current-system/sw/libexec/sftp-server";
        Banner = "/etc/ssh/banner";
      };
    };
    
    # Ollama service for AI models
    ollama = {
      enable = true;
      package = pkgs.ollama-rocm;  # Use AMD GPU version
      host = "127.0.0.1";
      port = 11434;
      environmentVariables = {
        HIP_VISIBLE_DEVICES = "0";
        ROCM_PATH = "${pkgs.rocmPackages.rocm-runtime}";
      };
    };
  };
  
  # Note: polkit-gnome authentication agent handled by system-level services
  # Removing manual user service to avoid conflicts

  # XDG Desktop Portals configuration (Hyprland module will set up the basic ones)
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk  # For file picker support
    ];
  };





  # Add essential system packages for Hyprland + AI + Security
  environment.systemPackages = with pkgs; [
    # SDDM theme for beautiful login screen
    sddm-sugar-dark
    # Authentication and portal support
    polkit_gnome
    xdg-utils
    # Qt Wayland support (required by some applications)
    qt5.qtwayland
    qt6.qtwayland
    # Desktop integration
    glib
    # Authentication helper
    gnome-keyring
    
    # AI/ML tools and libraries
    python311
    python311Packages.vllm
    python311Packages.ollama
    python311Packages.torch
    python311Packages.torchvision
    python311Packages.torchaudio
    python311Packages.transformers
    python311Packages.diffusers
    python311Packages.accelerate
    python311Packages.datasets
    python311Packages.bitsandbytes
    python311Packages.pillow
    python311Packages.opencv4
    python311Packages.pytesseract
    python311Packages.optimum
    python311Packages.peft
    python311Packages.tokenizers
    python311Packages.tensorboard
    
    # Model management and serving
    ollama  # Model server
    llama-cpp  # Alternative inference
    
    # OCR tools
    tesseract  # OCR engine
    tesseract4  # Better OCR
    poppler-utils  # PDF utilities
    
    # Development tools for AI
    jupyter  # Interactive development
    
    # Performance monitoring
    nvtopPackages.amd  # GPU monitoring
    
    # System monitoring and debugging
    strace  # System call tracer
    ltrace  # Library call tracer
    
    # Network monitoring
    nethogs  # Network process monitoring
    iftop  # Network bandwidth
    
    # Security tools
    wireshark-cli  # Packet analysis
    nmap  # Network scanning
    lynis  # Security auditing
  ];

  # Enable dconf for settings management
  programs.dconf.enable = true;
  
  # Enable SSH banner for security
  environment.etc."ssh/banner".text = lib.mkForce ''
    ╔═════════════════════════════════════════════════════════════════╗
    ║              THIS IS A PRIVATE SECURE SYSTEM                ║
    ║          Unauthorized access is prohibited by law          ║
    ║          All activities are logged and monitored          ║
    ║                NIXOS + HYPRLAND + AI                     ║
    ╚═════════════════════════════════════════════════════════════════╝
  '';

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;
}