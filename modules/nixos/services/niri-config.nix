_: {
  flake.nixosModules.niri-config = {
    config,
    pkgs,
    lib,
    ...
  }: let
    cfg = config.services.niri-desktop;
    niriPkg = pkgs.niri-unstable;
  in {
    options.services.niri-desktop = {
      enable = lib.mkEnableOption "Niri Wayland compositor with XWayland support";
    };

    config = lib.mkIf cfg.enable {
      programs.niri = {
        enable = true;
        package = niriPkg;
      };

      # Install niri's systemd user units into the generated /etc/systemd/user/.
      # The niri-flake module disables the nixpkgs niri module (which normally
      # does this via systemd.packages), so we add the package's unit files directly
      # to systemd.user.units. Without this, the compositor service has no ExecStart
      # and the user session fails to activate.
      #
      # For niri.service specifically, we patch the upstream unit:
      #
      #   BindsTo=graphical-session.target  →  Wants=graphical-session.target
      #
      # Rationale: BindsTo kills niri when the target stops during `just switch`,
      # and PartOf (tried previously) doesn't pull in the target at all, leaving
      # waybar and other graphical services dead. Wants= activates the target
      # (starting waybar, cliphist, etc.) without hard-binding niri to it, so
      # niri survives target restarts during system reconfiguration.
      #
      # We also append OOMScoreAdjust=-900 to protect the compositor from the
      # OOM killer, and Restart=always for crash recovery.
      systemd.user.units = let
        unitFiles = builtins.readDir "${niriPkg}/lib/systemd/user";
        mkUnit = name: let
          baseText = builtins.readFile "${niriPkg}/lib/systemd/user/${name}";
          text =
            if name == "niri.service"
            then let
              noBindsTo =
                builtins.replaceStrings
                ["BindsTo=graphical-session.target"]
                ["Wants=graphical-session.target"]
                baseText;
              unitLimits =
                builtins.replaceStrings
                ["[Unit]"]
                [
                  ''                    [Unit]
                    StartLimitBurst=3
                    StartLimitIntervalSec=60''
                ]
                noBindsTo;
            in
              unitLimits
              + "\nRestart=always\nRestartSec=2s\nOOMScoreAdjust=-900\nLimitNPROC=infinity\nLimitNOFILE=524288\n"
              + "\n[Install]\nWantedBy=graphical-session.target\n"
            else baseText;
        in {inherit text;};
      in
        lib.listToAttrs (map
          (name: {
            inherit name;
            value = mkUnit name;
          })
          (lib.filter
            (name: lib.hasSuffix ".service" name || lib.hasSuffix ".target" name)
            (builtins.attrNames unitFiles)));

      environment.systemPackages = with pkgs; [
        xwayland-satellite
      ];
    };
  };
}
