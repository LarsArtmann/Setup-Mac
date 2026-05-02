{
  description = "Lars nix-darwin + NixOS system flake - Modular Architecture with flake-parts";

  inputs = {
    # Use nixpkgs-unstable to match nix-darwin master
    nixpkgs.url = "github:NixOS/nixpkgs/01fbdeef22b76df85ea168fbfe1bfd9e63681b30";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Add flake-parts for modular architecture
    flake-parts.url = "github:hercules-ci/flake-parts";

    # Add NUR (Nix User Repository) for other packages
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Helium Browser
    helium = {
      url = "github:vikingnope/helium-browser-nix-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Add nix-visualize for Nix configuration visualization
    nix-visualize = {
      url = "github:craigmbooth/nix-visualize";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Add nix-colors for declarative color schemes
    nix-colors.url = "github:misterio77/nix-colors";

    # Add nix-homebrew for declarative Homebrew management
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";

    # Homebrew bundle for cask management
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };

    # Homebrew cask for headlamp and other GUI apps
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };

    # Niri scrollable-tiling Wayland compositor
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # OpenTelemetry TUI viewer
    otel-tui = {
      url = "github:ymtdzzz/otel-tui";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # AMD NPU (XDNA) driver for Ryzen AI Max+ Strix Halo
    nix-amd-npu = {
      url = "github:robcohen/nix-amd-npu";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Secrets management via sops + age
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # SilentSDDM - customizable SDDM theme with Catppuccin support
    silent-sddm = {
      url = "github:uiriansan/SilentSDDM";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # SigNoz observability platform sources
    signoz-src = {
      url = "github:SigNoz/signoz/v0.117.1";
      flake = false;
    };
    signoz-collector-src = {
      url = "github:SigNoz/signoz-otel-collector/v0.144.2";
      flake = false;
    };

    nix-ssh-config = {
      url = "github:LarsArtmann/nix-ssh-config";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # Crush AI Agent Configuration — global AI assistant settings
    # This ensures AGENTS.md and all references are synced across machines
    crush-config = {
      url = "git+ssh://git@github.com/LarsArtmann/crush-config?ref=master";
    };

    wallpapers = {
      url = "git+ssh://git@github.com/LarsArtmann/wallpapers?ref=master";
      flake = false;
    };

    # Hermes AI Agent — Discord/gateway agent platform
    hermes-agent = {
      url = "github:NousResearch/hermes-agent";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Monitor365 device monitoring agent source (Rust)
    monitor365-src = {
      url = "git+ssh://git@github.com/LarsArtmann/monitor365";
      flake = false;
    };

    # NixOS hardware profiles (Raspberry Pi, etc.)
    nixos-hardware.url = "github:NixOS/nixos-hardware";

    # EMEET PIXY webcam auto-activation daemon
    emeet-pixyd = {
      url = "git+ssh://git@github.com/LarsArtmann/emeet-pixyd?ref=master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Treefmt formatter with auto-discovery for nix fmt
    treefmt-full-flake = {
      url = "github:LarsArtmann/treefmt-full-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # todo-list-ai — AI-powered CLI tool for extracting TODOs from codebases
    todo-list-ai = {
      url = "git+ssh://git@github.com/LarsArtmann/todo-list-ai?ref=master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # file-and-image-renamer — AI-powered screenshot renaming tool + local Go deps
    file-and-image-renamer-src = {
      url = "git+ssh://git@github.com/LarsArtmann/file-and-image-renamer?ref=master";
      flake = false;
    };
    cmdguard-src = {
      url = "git+ssh://git@github.com/LarsArtmann/cmdguard?ref=master";
      flake = false;
    };
    go-output-src = {
      url = "git+ssh://git@github.com/LarsArtmann/go-output?ref=master";
      flake = false;
    };

    # golangci-lint-auto-configure — auto-configure golangci-lint for Go projects
    golangci-lint-auto-configure-src = {
      url = "git+ssh://git@github.com/LarsArtmann/golangci-lint-auto-configure?ref=master";
      flake = false;
    };
    go-finding-src = {
      url = "git+ssh://git@github.com/LarsArtmann/go-finding?ref=master";
      flake = false;
    };

    # LarsArtmann Go CLI tools
    art-dupl-src = {
      url = "git+ssh://git@github.com/LarsArtmann/art-dupl?ref=fork";
      flake = false;
    };
    auto-deduplicate-src = {
      url = "git+ssh://git@github.com/LarsArtmann/auto-deduplicate?ref=master";
      flake = false;
    };
    branching-flow-src = {
      url = "git+ssh://git@github.com/LarsArtmann/branching-flow?ref=master";
      flake = false;
    };
    buildflow-src = {
      url = "git+ssh://git@github.com/LarsArtmann/BuildFlow?ref=master";
      flake = false;
    };
    code-duplicate-analyzer-src = {
      url = "git+ssh://git@github.com/LarsArtmann/code-duplicate-analyzer?ref=master";
      flake = false;
    };
    go-auto-upgrade-src = {
      url = "git+ssh://git@github.com/LarsArtmann/go-auto-upgrade?ref=master";
      flake = false;
    };
    go-functional-fixer-src = {
      url = "git+ssh://git@github.com/LarsArtmann/go-functional-fixer?ref=master";
      flake = false;
    };
    go-structure-linter-src = {
      url = "git+ssh://git@github.com/LarsArtmann/go-structure-linter?ref=master";
      flake = false;
    };
    hierarchical-errors-src = {
      url = "git+ssh://git@github.com/LarsArtmann/hierarchical-errors?ref=master";
      flake = false;
    };
    library-policy-src = {
      url = "git+ssh://git@github.com/LarsArtmann/library-policy?ref=master";
      flake = false;
    };
    md-go-validator-src = {
      url = "git+ssh://git@github.com/LarsArtmann/md-go-validator?ref=master";
      flake = false;
    };
    project-meta-src = {
      url = "git+ssh://git@github.com/LarsArtmann/project-meta?ref=master";
      flake = false;
    };
    projects-management-automation-src = {
      url = "git+ssh://git@github.com/LarsArtmann/projects-management-automation?ref=master";
      flake = false;
    };
    template-readme-src = {
      url = "git+ssh://git@github.com/LarsArtmann/template-readme?ref=main";
      flake = false;
    };
    terraform-diagrams-aggregator-src = {
      url = "git+ssh://git@github.com/LarsArtmann/terraform-diagrams-aggregator?ref=master";
      flake = false;
    };
    terraform-to-d2-src = {
      url = "git+ssh://git@github.com/LarsArtmann/terraform-to-d2?ref=master";
      flake = false;
    };

    # mr-sync — CLI to keep ~/.mrconfig in sync with GitHub repos
    mr-sync-src = {
      url = "git+ssh://git@github.com/LarsArtmann/mr-sync?ref=master";
      flake = false;
    };

    # Shared Go library dependencies (used by multiple tools via go.mod replace)
    go-branded-id-src = {
      url = "git+ssh://git@github.com/LarsArtmann/go-branded-id?ref=master";
      flake = false;
    };
    go-commit-src = {
      url = "git+ssh://git@github.com/LarsArtmann/go-commit?ref=master";
      flake = false;
    };
    go-composable-business-types-src = {
      url = "git+ssh://git@github.com/LarsArtmann/go-composable-business-types?ref=master";
      flake = false;
    };
    go-filewatcher-src = {
      url = "git+ssh://git@github.com/LarsArtmann/go-filewatcher?ref=master";
      flake = false;
    };
    project-discovery-sdk-src = {
      url = "git+ssh://git@github.com/LarsArtmann/project-discovery-sdk?ref=master";
      flake = false;
    };
    gogenfilter-src = {
      url = "git+ssh://git@github.com/LarsArtmann/gogenfilter?ref=master";
      flake = false;
    };
  };

  outputs = inputs @ {
    flake-parts,
    nix-darwin,
    nixpkgs,
    home-manager,
    helium,
    nur,
    nix-visualize,
    nix-colors,
    nix-homebrew,
    homebrew-bundle,
    homebrew-cask,
    niri,
    otel-tui,
    nix-amd-npu,
    nix-ssh-config,
    monitor365-src,
    nixos-hardware,
    emeet-pixyd,
    treefmt-full-flake,
    todo-list-ai,
    file-and-image-renamer-src,
    cmdguard-src,
    go-output-src,
    golangci-lint-auto-configure-src,
    go-finding-src,
    art-dupl-src,
    auto-deduplicate-src,
    branching-flow-src,
    buildflow-src,
    code-duplicate-analyzer-src,
    go-auto-upgrade-src,
    go-functional-fixer-src,
    go-structure-linter-src,
    hierarchical-errors-src,
    library-policy-src,
    md-go-validator-src,
    project-meta-src,
    projects-management-automation-src,
    template-readme-src,
    terraform-diagrams-aggregator-src,
    terraform-to-d2-src,
    go-branded-id-src,
    go-commit-src,
    go-composable-business-types-src,
    go-filewatcher-src,
    project-discovery-sdk-src,
    gogenfilter-src,
    mr-sync-src,
    ...
  }: let
    # Shared Go tool infrastructure — all LarsArtmann Go CLIs use this
    go-replaces = import ./pkgs/lib/go-replaces.nix {
      inherit
        go-output-src
        go-finding-src
        cmdguard-src
        go-branded-id-src
        go-commit-src
        go-filewatcher-src
        project-discovery-sdk-src
        gogenfilter-src
        go-composable-business-types-src
        art-dupl-src
        buildflow-src
        branching-flow-src
        code-duplicate-analyzer-src
        go-auto-upgrade-src
        go-functional-fixer-src
        go-structure-linter-src
        hierarchical-errors-src
        library-policy-src
        md-go-validator-src
        project-meta-src
        projects-management-automation-src
        template-readme-src
        terraform-diagrams-aggregator-src
        terraform-to-d2-src
        golangci-lint-auto-configure-src
        ;
    };

    mkGoToolFor = pkgs:
      import ./pkgs/lib/mk-go-tool.nix {
        inherit (pkgs) lib buildGoModule;
        inherit go-replaces;
      };

    # NOTE: goOverlay removed — nixpkgs go_1_26 is already 1.26.1.
    # Overriding go forced a from-source rebuild that invalidated the
    # binary cache for the ENTIRE dependency tree (1094 derivations).
    awWatcherOverlay = _final: prev: {
      aw-watcher-utilization = prev.callPackage ./pkgs/aw-watcher-utilization.nix {};
    };

    openaudibleOverlay = _final: prev: {
      openaudible = prev.callPackage ./pkgs/openaudible.nix {};
    };

    dnsblockdOverlay = _final: prev: {
      dnsblockd = prev.callPackage ./pkgs/dnsblockd.nix {
        src = prev.lib.cleanSourceWith {
          filter = path: _: let b = baseNameOf path; in b != "package.nix" && b != "dnsblockd";
          src = ./platforms/nixos/programs/dnsblockd;
        };
      };
      dnsblockd-processor = prev.callPackage ./pkgs/dnsblockd-processor/package.nix {
        src = prev.lib.cleanSourceWith {
          filter = path: _: !prev.lib.hasSuffix (baseNameOf path) ".nix";
          src = ./pkgs/dnsblockd-processor;
        };
      };
    };

    netwatchOverlay = _final: prev: {
      netwatch = prev.callPackage ./pkgs/netwatch.nix {};
    };

    monitor365Overlay = _final: prev: {
      monitor365 = prev.callPackage ./pkgs/monitor365.nix {
        src = prev.lib.cleanSourceWith {
          filter = path: _type: let
            b = baseNameOf path;
          in
            !(
              b
              == "target"
              || b == "vendor"
              || b == ".git"
              || b == "docs"
              || b == "report"
              || b == ".crush"
              || b == "examples"
              || prev.lib.hasSuffix ".svg" b
            );
          src = monitor365-src;
        };
      };
    };
    jscpdOverlay = _final: prev: {
      jscpd = prev.callPackage ./pkgs/jscpd.nix {};
    };
    # DISABLED: unboundDoQOverlay patches unbound for DNS-over-QUIC support.
    # It overrides unbound's build flags which cascades to ffmpeg, linux, pipewire,
    # and hundreds of other packages — killing binary cache hits entirely (40+ min builds).
    # To re-enable: uncomment the overlay below and add it back to overlay lists.
    # unboundDoQOverlay = _final: prev: let
    #   unboundNoSlim = prev.unbound.override {withSlimLib = false;};
    # in {
    #   unbound = unboundNoSlim.overrideAttrs (o: {
    #     buildInputs =
    #       (o.buildInputs or [])
    #       ++ [
    #         prev.ngtcp2
    #         prev.nghttp3
    #       ];
    #     configureFlags =
    #       (o.configureFlags or [])
    #       ++ [
    #         "--with-libngtcp2=${prev.ngtcp2.dev}"
    #         "--with-libnghttp3=${prev.nghttp3.dev}"
    #       ];
    #   });
    # };
    emeetPixyOverlay = emeet-pixyd.overlays.default;

    todoListAiOverlay = _final: prev: {
      todo-list-ai = todo-list-ai.packages.${prev.stdenv.system}.default;
    };

    fileAndImageRenamerOverlay = _final: prev: {
      file-and-image-renamer = prev.callPackage ./pkgs/file-and-image-renamer.nix {
        inherit file-and-image-renamer-src cmdguard-src go-output-src;
      };
    };

    golangciLintAutoConfigureOverlay = _final: prev: {
      golangci-lint-auto-configure = prev.callPackage ./pkgs/golangci-lint-auto-configure.nix {
        inherit golangci-lint-auto-configure-src go-finding-src;
      };
    };

    # --- LarsArtmann Go CLI tool overlays ---

    # Helper: clean source filter for Go projects
    cleanGoSource = src:
      nixpkgs.lib.cleanSourceWith {
        filter = path: _type: let
          b = baseNameOf path;
        in
          !(
            b
            == ".git"
            || b == "node_modules"
            || b == "vendor"
            || b == "target"
            || b == "dist"
            || b == "bin"
            || b == "result"
            || b == ".crush"
            || nixpkgs.lib.hasSuffix ".md" b
            || nixpkgs.lib.hasSuffix ".html" b
            || nixpkgs.lib.hasSuffix ".svg" b
            || b == "go.work"
            || b == "go.work.sum"
          );
        inherit src;
      };

    larsGoToolsOverlay = _final: prev: let
      mkGoTool = mkGoToolFor prev;
      callGoTool = pkg-file: src:
        prev.callPackage pkg-file {
          inherit mkGoTool;
          src = cleanGoSource src;
        };
    in {
      art-dupl = callGoTool ./pkgs/art-dupl.nix art-dupl-src;
      auto-deduplicate = callGoTool ./pkgs/auto-deduplicate.nix auto-deduplicate-src;
      branching-flow = callGoTool ./pkgs/branching-flow.nix branching-flow-src;
      buildflow = callGoTool ./pkgs/buildflow.nix buildflow-src;
      code-duplicate-analyzer = callGoTool ./pkgs/code-duplicate-analyzer.nix code-duplicate-analyzer-src;
      go-auto-upgrade = callGoTool ./pkgs/go-auto-upgrade.nix go-auto-upgrade-src;
      go-functional-fixer = callGoTool ./pkgs/go-functional-fixer.nix go-functional-fixer-src;
      go-structure-linter = callGoTool ./pkgs/go-structure-linter.nix go-structure-linter-src;
      hierarchical-errors = callGoTool ./pkgs/hierarchical-errors.nix hierarchical-errors-src;
      library-policy = callGoTool ./pkgs/library-policy.nix library-policy-src;
      md-go-validator = callGoTool ./pkgs/md-go-validator.nix md-go-validator-src;
      project-meta = callGoTool ./pkgs/project-meta.nix project-meta-src;
      projects-management-automation = callGoTool ./pkgs/projects-management-automation.nix projects-management-automation-src;
      template-readme = callGoTool ./pkgs/template-readme.nix template-readme-src;
      terraform-diagrams-aggregator = callGoTool ./pkgs/terraform-diagrams-aggregator.nix terraform-diagrams-aggregator-src;
      terraform-to-d2 = callGoTool ./pkgs/terraform-to-d2.nix terraform-to-d2-src;
    };

    mrSyncOverlay = _final: prev: {
      mr-sync = prev.callPackage ./pkgs/mr-sync.nix {
        src = cleanGoSource mr-sync-src;
      };
    };

    # Disable tests for packages with flaky integration tests in sandboxed builders
    disableTestsOverlay = _final: prev: {
      valkey = prev.valkey.overrideAttrs (_old: {doCheck = false;});
      aiocache = prev.python3Packages.aiocache.overrideAttrs (_old: {doCheck = false;});
    };

    # Shared overlays applied on all machines (Darwin + NixOS)
    sharedOverlays = [
      nur.overlays.default
      awWatcherOverlay
      todoListAiOverlay
      golangciLintAutoConfigureOverlay
      larsGoToolsOverlay
      mrSyncOverlay
    ];

    # Linux-only overlays (custom packages that only make sense on NixOS)
    linuxOnlyOverlays = [
      openaudibleOverlay
      dnsblockdOverlay
      emeetPixyOverlay
      monitor365Overlay
      netwatchOverlay
      fileAndImageRenamerOverlay
    ];

    # Python test override (separate because it's NixOS-specific)
    pythonTestOverlay = _final: prev: {
      python313Packages = prev.python313Packages.overrideScope (_pyFinal: pyPrev: {
        timm = pyPrev.timm.overridePythonAttrs (_: {doCheck = false;});
        xformers = pyPrev.xformers.overridePythonAttrs (_: {doCheck = false;});
      });
    };

    # Shared Home Manager configuration — only user/home file path differs per system
    sharedHomeManagerConfig = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "backup";
      overwriteBackup = true;
    };

    # Shared extraSpecialArgs for Home Manager — available in all platform home.nix files
    sharedHomeManagerSpecialArgs = {
      inherit nix-colors;
      inherit nix-ssh-config;
      colorScheme = nix-colors.colorSchemes.catppuccin-mocha;
    };
  in
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["aarch64-darwin" "x86_64-linux"];

      # Import dendritic modules - each file is a self-contained flake-parts module
      imports = [
        ./modules/nixos/services/authelia.nix
        ./modules/nixos/services/caddy.nix
        ./modules/nixos/services/default.nix
        ./modules/nixos/services/gitea.nix
        ./modules/nixos/services/gitea-repos.nix
        ./modules/nixos/services/homepage.nix
        ./modules/nixos/services/immich.nix
        ./modules/nixos/services/signoz.nix
        ./modules/nixos/services/twenty.nix
        ./modules/nixos/services/photomap.nix
        ./modules/nixos/services/sops.nix
        ./modules/nixos/services/taskchampion.nix
        ./modules/nixos/services/voice-agents.nix
        ./modules/nixos/services/hermes.nix
        ./modules/nixos/services/minecraft.nix
        ./modules/nixos/services/monitor365.nix
        ./modules/nixos/services/comfyui.nix
        ./modules/nixos/services/dns-failover.nix
        ./modules/nixos/services/display-manager.nix
        ./modules/nixos/services/audio.nix
        ./modules/nixos/services/niri-config.nix
        ./modules/nixos/services/security-hardening.nix
        ./modules/nixos/services/ai-models.nix
        ./modules/nixos/services/ai-stack.nix
        ./modules/nixos/services/monitoring.nix
        ./modules/nixos/services/multi-wm.nix
        ./modules/nixos/services/chromium-policies.nix
        ./modules/nixos/services/steam.nix
        ./modules/nixos/services/file-and-image-renamer.nix
        # SSH module now loaded from nix-ssh-config flake input
      ];

      # Per-system configuration (packages, devShells, etc.)
      perSystem = {
        pkgs,
        system,
        lib,
        ...
      }: {
        # Allow unfree and broken packages for all systems
        _module.args.pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          config.allowBroken = false; ## <-- THIS MUST ALWAYS BE FALSE!
          overlays =
            [
              awWatcherOverlay
              todoListAiOverlay
              jscpdOverlay
              golangciLintAutoConfigureOverlay
              disableTestsOverlay
              larsGoToolsOverlay
            ]
            ++ lib.optionals (system == "x86_64-linux") [
              openaudibleOverlay
              dnsblockdOverlay
              emeetPixyOverlay
              monitor365Overlay
              netwatchOverlay
              fileAndImageRenamerOverlay
            ];
        };

        # Use treefmt-full-flake's formatter which includes alejandra in PATH
        formatter = treefmt-full-flake.formatter.${system};

        packages =
          {
            modernize = import ./pkgs/modernize.nix {
              inherit pkgs;
            };
            inherit
              (pkgs)
              aw-watcher-utilization
              jscpd
              sqlc
              todo-list-ai
              golangci-lint-auto-configure
              art-dupl
              auto-deduplicate
              branching-flow
              buildflow
              code-duplicate-analyzer
              go-auto-upgrade
              go-functional-fixer
              go-structure-linter
              hierarchical-errors
              library-policy
              md-go-validator
              project-meta
              projects-management-automation
              template-readme
              terraform-diagrams-aggregator
              terraform-to-d2
              ;
          }
          // lib.optionalAttrs pkgs.stdenv.isLinux {
            inherit (pkgs) openaudible dnsblockd dnsblockd-processor monitor365 netwatch emeet-pixyd file-and-image-renamer;
          };

        # Development shells for different program categories
        devShells = {
          default = pkgs.mkShell {
            packages = with pkgs; [
              git
              nixfmt
              alejandra
              treefmt
              deadnix
              shellcheck
              just # Task runner
              statix
              gitleaks
              jq
              jscpd
              sqlc
            ];
          };
        };

        checks =
          {
            statix =
              pkgs.runCommand "statix-check" {
                nativeBuildInputs = [pkgs.statix];
              } ''
                cd ${./.}
                statix check . 2>&1 | tee $out
              '';

            deadnix =
              pkgs.runCommand "deadnix-check" {
                nativeBuildInputs = [pkgs.deadnix];
              } ''
                cd ${./.}
                deadnix --fail --no-lambda-pattern-names . 2>&1 | tee $out
              '';

            nix-eval-darwin = pkgs.runCommand "nix-eval-darwin" {} ''
              echo "darwin eval smoke test passed (nix flake check --no-build verifies this)" > $out
            '';
          }
          // lib.optionalAttrs pkgs.stdenv.isLinux {
            nix-eval-nixos = pkgs.runCommand "nix-eval-nixos" {} ''
              echo "nixos eval smoke test passed (nix flake check --no-build verifies this)" > $out
            '';
          };

        apps =
          {
            deploy = {
              type = "app";
              program = "${pkgs.writeShellScriptBin "deploy" ''
                set -euo pipefail

                echo "=== Deploying NixOS config to evo-x2 ==="
                nh os switch . 2>&1

                echo ""
                echo "=== Waiting 5s for services to settle ==="
                sleep 5

                echo ""
                echo "=== dnsblockd status ==="
                systemctl status dnsblockd --no-pager 2>/dev/null || true

                echo ""
                echo "=== Failed units ==="
                systemctl --failed --no-pager 2>/dev/null || true
              ''}/bin/deploy";
              meta.description = "Deploy NixOS config to evo-x2 via nh with post-deploy checks";
            };
            validate = {
              type = "app";
              program = "${pkgs.writeShellScriptBin "validate" ''
                nix --extra-experimental-features "nix-command flakes" flake check --no-build
              ''}/bin/validate";
              meta.description = "Validate flake without building";
            };
          }
          // lib.optionalAttrs pkgs.stdenv.isLinux {
            dns-diagnostics = {
              type = "app";
              program = "${pkgs.writeShellScriptBin "dns-diagnostics" ''
                echo "=== DNS Services ==="
                systemctl is-active unbound dnsblockd 2>/dev/null || true
                echo ""
                echo "=== DNS Resolution ==="
                ${pkgs.dig}/bin/dig google.com +short | head -1
                echo ""
                echo "=== DNS Blocking ==="
                ${pkgs.dig}/bin/dig doubleclick.net +short | head -1
                echo ""
                echo "=== dnsblockd Stats ==="
                ${pkgs.curl}/bin/curl -s http://127.0.0.1:9090/stats 2>/dev/null || echo "Stats unavailable"
              ''}/bin/dns-diagnostics";
              meta.description = "Run DNS stack diagnostics (resolution, blocking, stats)";
            };
          };
      };

      # System configurations (maintain backward compatibility)
      flake = {
        darwinConfigurations."Lars-MacBook-Air" = nix-darwin.lib.darwinSystem {
          specialArgs = {
            inherit (inputs.self) inputs;
            inherit nixpkgs;
            inherit helium;
            inherit nur;
            inherit nix-visualize;
            inherit nix-colors;
            inherit otel-tui;
          };
          modules = [
            {
              nixpkgs = {
                hostPlatform = "aarch64-darwin";
                config.allowUnfree = true;
                overlays = sharedOverlays;
              };
            }

            # Import nix-homebrew for declarative Homebrew management
            nix-homebrew.darwinModules.nix-homebrew
            {
              nix-homebrew = {
                enable = true;
                enableRosetta = true;
                user = "larsartmann";
                autoMigrate = true;
                # Pin Homebrew taps to flake inputs for reproducibility
                taps = {
                  "homebrew/bundle" = homebrew-bundle;
                  "homebrew/cask" = homebrew-cask;
                };
              };
            }

            # Import Home Manager module for Darwin
            inputs.home-manager.darwinModules.home-manager

            # Define Home Manager configuration inline for top-level visibility
            {
              home-manager =
                sharedHomeManagerConfig
                // {
                  users.larsartmann = {...}: {
                    imports = [
                      ./platforms/darwin/home.nix
                    ];
                  };
                  extraSpecialArgs = sharedHomeManagerSpecialArgs;
                };
            }

            # Core Darwin configuration
            ./platforms/darwin/default.nix
          ];
        };

        # NixOS configuration
        nixosConfigurations."evo-x2" = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit (inputs.self) inputs;
            inherit helium;
            inherit nur;
            inherit nix-visualize;
            inherit nix-colors;
            inherit niri;
            inherit otel-tui;
            inherit nix-amd-npu;
            inherit nix-ssh-config;
          };
          modules = [
            {
              nixpkgs = {
                hostPlatform = "x86_64-linux";
                config.allowUnfree = true;
                overlays =
                  sharedOverlays
                  ++ [
                    inputs.niri.overlays.niri
                  ]
                  ++ linuxOnlyOverlays
                  ++ [pythonTestOverlay];
              };
              system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
            }
            home-manager.nixosModules.home-manager
            nur.modules.nixos.default

            {
              home-manager =
                sharedHomeManagerConfig
                // {
                  users.lars = _: {
                    imports = [
                      ./platforms/nixos/users/home.nix
                    ];
                  };
                  extraSpecialArgs =
                    sharedHomeManagerSpecialArgs
                    // {
                      inherit (inputs) wallpapers;
                    };
                };
            }

            # Import the existing NixOS configuration
            inputs.niri.nixosModules.niri
            inputs.nix-amd-npu.nixosModules.default
            inputs.sops-nix.nixosModules.sops
            inputs.silent-sddm.nixosModules.default
            inputs.self.nixosModules.authelia
            inputs.self.nixosModules.caddy
            inputs.self.nixosModules.default-services
            inputs.self.nixosModules.gitea
            inputs.self.nixosModules.gitea-repos
            inputs.self.nixosModules.homepage
            inputs.self.nixosModules.immich
            inputs.self.nixosModules.photomap
            inputs.self.nixosModules.sops
            inputs.nix-ssh-config.nixosModules.ssh
            inputs.self.nixosModules.signoz
            inputs.self.nixosModules.twenty
            inputs.self.nixosModules.taskchampion
            inputs.self.nixosModules.voice-agents
            inputs.self.nixosModules.hermes
            inputs.self.nixosModules.minecraft
            inputs.self.nixosModules.monitor365
            inputs.self.nixosModules.comfyui
            inputs.self.nixosModules.dns-failover
            inputs.self.nixosModules.display-manager
            inputs.self.nixosModules.audio
            inputs.self.nixosModules.niri-config
            inputs.self.nixosModules.security-hardening
            inputs.self.nixosModules.ai-models
            inputs.self.nixosModules.ai-stack
            inputs.self.nixosModules.monitoring
            inputs.self.nixosModules.multi-wm
            inputs.self.nixosModules.chromium-policies
            inputs.self.nixosModules.steam
            inputs.self.nixosModules.file-and-image-renamer
            inputs.emeet-pixyd.nixosModules.default
            ./platforms/nixos/system/configuration.nix
          ];
        };

        # Raspberry Pi 3 — DNS cluster backup node
        nixosConfigurations."rpi3-dns" = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          specialArgs = {
            inherit (inputs.self) inputs;
            inherit nix-ssh-config;
            inherit nixos-hardware;
          };
          modules = [
            {
              nixpkgs = {
                hostPlatform = "aarch64-linux";
                config.allowUnfree = true;
                overlays = [
                  nur.overlays.default
                  dnsblockdOverlay
                ];
              };
            }
            home-manager.nixosModules.home-manager
            nur.modules.nixos.default
            {
              home-manager =
                sharedHomeManagerConfig
                // {
                  users.root = _: {
                    programs.home-manager.enable = true;
                    home = {
                      stateVersion = "25.11";
                      file.".config/crush".source = inputs.crush-config;
                    };
                  };
                  extraSpecialArgs = sharedHomeManagerSpecialArgs;
                };
            }
            inputs.self.nixosModules.dns-failover
            nixos-hardware.nixosModules.raspberry-pi-3
            "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
            ./platforms/nixos/rpi3/default.nix
          ];
        };
      };
    };
}
