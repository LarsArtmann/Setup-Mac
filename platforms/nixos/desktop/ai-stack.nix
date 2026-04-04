{
  pkgs,
  config,
  ...
}: let
  inherit (pkgs.rocmPackages) rocwmma;

  rocmEnv = {
    ROCBLAS_USE_HIPBLASLT = "1";
    HSA_OVERRIDE_GFX_VERSION = "11.5.1";
    HSA_ENABLE_SDMA = "0";
  };

  rocmRuntimeLibs = with pkgs; [
    stdenv.cc.cc.lib
    zstd
    rocmPackages.clr
    rocmPackages.rocminfo
    rocmPackages.rocrand
    rocmPackages.rocblas
    rocmPackages.rocm-runtime
    rocmPackages.rocm-comgr
  ];

  ollama-rocm-0_20 = pkgs.ollama-rocm.overrideAttrs (old: rec {
    version = "0.20.0";
    src = pkgs.fetchFromGitHub {
      owner = "ollama";
      repo = "ollama";
      tag = "v${version}";
      hash = "sha256-QQKPXdXlsT+uMGGIyqkVZqk6OTa7VHrwDVmgDdgdKOY=";
    };
  });
  llama-cpp-rocwmma =
    (pkgs.llama-cpp.override {
      rocmSupport = true;
    }).overrideAttrs (finalAttrs: {
      buildInputs =
        finalAttrs.buildInputs
        ++ [rocwmma];
      cmakeFlags =
        finalAttrs.cmakeFlags
        ++ [
          "-DGGML_HIP_ROCWMMA_FATTN=ON"
          "-DGGML_HIP_MMQ_MFMA=ON"
        ];
      postPatch =
        (finalAttrs.postPatch or "")
        + ''
          sed -i '/target_link_libraries(ggml-hip PRIVATE/a\  target_include_directories(ggml-hip SYSTEM PRIVATE ${rocwmma}/include)' \
            ggml/src/ggml-hip/CMakeLists.txt
        '';
    });

  unslothDataDir = "/data/unsloth";
  venvPython = "${unslothDataDir}/venv/bin/python";
  venvPip = "${unslothDataDir}/venv/bin/pip";
  sitePkgs = "${unslothDataDir}/venv/lib/python3.13/site-packages";
  studioBackend = "${sitePkgs}/studio/backend";
  studioFrontend = "${sitePkgs}/studio/frontend";
  studioReq = "${studioBackend}/requirements";
  setupDone = "${unslothDataDir}/.studio-setup-done";
in {
  security.pam.loginLimits = [
    {
      domain = "*";
      type = "hard";
      item = "memlock";
      value = "unlimited";
    }
    {
      domain = "*";
      type = "soft";
      item = "memlock";
      value = "unlimited";
    }
  ];

  services.ollama = {
    enable = true;
    package = ollama-rocm-0_20;
    home = "/data/models/ollama";
    host = "127.0.0.1";
    port = 11434;
    environmentVariables = {
      OLLAMA_FLASH_ATTENTION = "1";
      OLLAMA_NUM_PARALLEL = "1";
      ROCBLAS_USE_HIPBLASLT = "1";
      # GPU detection for AMD Strix Halo (gfx1151)
      HSA_OVERRIDE_GFX_VERSION = "11.5.1";
      # Fix for gfx11 APU SDMA issues
      HSA_ENABLE_SDMA = "0";
    };
  };

  # Force-fix ollama directory permissions on boot
  # Handles directories created by other users (e.g., nobody) that block access
  systemd.services.ollama-permissions = {
    description = "Fix Ollama data directory permissions";
    # Run after ollama service user is available
    after = ["local-fs.target" "ollama.service"];
    # But before ollama actually needs to write
    before = [];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      # Use numeric UID/GID since ollama is a dynamic user
      # UID 61547 is the typical dynamic UID for ollama
      ExecStart = pkgs.writeShellScript "fix-ollama-perms" ''
        # Ensure directory exists and is traversable
        mkdir -p /data/models/ollama
        chmod 755 /data/models/ollama 2>/dev/null || true
        # Try to fix ownership (will work if root, fail silently otherwise)
        chown -R 61547:61547 /data/models/ollama 2>/dev/null || \
          chown -R ollama:ollama /data/models/ollama 2>/dev/null || true
        # Ensure read/write for owner
        chmod -R u+rwX /data/models/ollama 2>/dev/null || true
      '';
    };
  };

  environment.systemPackages = with pkgs; [
    llama-cpp-rocwmma
    tesseract5
    poppler-utils
    jupyter
    python313
  ];

  # Unsloth Studio - no-code AI model training & inference web UI
  # Native ROCm GPU acceleration on AMD Strix Halo (gfx1151)
  #
  # Architecture: single Python venv, no inner venv
  # - unsloth-setup (oneshot): creates venv, installs all pip deps, builds frontend
  # - unsloth-studio (simple): runs backend directly via run.py
  # - ConditionPathExists gates studio until setup completes
  #
  # run.py is standalone (has its own argparse) so we skip the
  # `unsloth studio` CLI wrapper and its two-venv architecture.

  systemd.services.unsloth-setup = {
    description = "Unsloth Studio - First-time setup";
    after = ["network-online.target"];
    wants = ["network-online.target"];
    wantedBy = ["multi-user.target"];
    path = with pkgs; [
      python313
      git
      gcc
      gnumake
      cmake
      ninja
      cacert
      nodejs_22
      coreutils
      bash
    ];
    environment = {
      HOME = unslothDataDir;
      PYTHONDONTWRITEBYTECODE = "1";
    };
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "unsloth-setup" ''
        set -euo pipefail

        # Phase 1: Create venv with unsloth CLI + PyTorch ROCm
        if [ ! -f ${venvPython} ]; then
          echo "Creating Python venv..."
          ${pkgs.python313}/bin/python -m venv ${unslothDataDir}/venv
          ${venvPip} install --no-cache-dir --upgrade pip setuptools wheel
          echo "Installing PyTorch ROCm 6.3 (~4.9GB)..."
          ${venvPip} install --no-cache-dir \
            torch torchvision torchaudio \
            --index-url https://download.pytorch.org/whl/rocm6.3
          echo "Installing unsloth[amd]..."
          ${venvPip} install --no-cache-dir \
            "unsloth[amd] @ git+https://github.com/unslothai/unsloth"
          echo "CLI install complete."
        fi

        if [ -f ${setupDone} ]; then
          echo "Studio setup already complete, skipping."
          exit 0
        fi

        # Phase 2: Install studio backend + ML deps from the package's own requirements
        # Install order matches setup.sh / install_python_stack.py
        echo "Installing studio Python dependencies..."

        ${venvPip} install --no-cache-dir \
          -r ${studioReq}/base.txt

        ${venvPip} install --no-cache-dir \
          -r ${studioReq}/extras.txt

        ${venvPip} install --no-deps --no-cache-dir \
          -r ${studioReq}/extras-no-deps.txt

        ${venvPip} install --force-reinstall --no-cache-dir \
          -r ${studioReq}/overrides.txt

        if [ -f ${studioReq}/triton-kernels.txt ]; then
          ${venvPip} install --no-deps --no-cache-dir \
            -r ${studioReq}/triton-kernels.txt
        fi

        ${venvPip} install --no-cache-dir \
          -r ${studioReq}/studio.txt

        # Data designer deps
        if [ -f ${studioReq}/single-env/data-designer-deps.txt ]; then
          ${venvPip} install --no-cache-dir \
            -c ${studioReq}/single-env/constraints.txt \
            -r ${studioReq}/single-env/data-designer-deps.txt
          ${venvPip} install --no-deps --no-cache-dir \
            -c ${studioReq}/single-env/constraints.txt \
            -r ${studioReq}/single-env/data-designer.txt
        fi

        # Phase 3: Build frontend with Nix-provided nodejs (no nvm)
        # Copy to temp dir — npm can't handle the venv's symlinked node_modules
        echo "Building frontend..."
        tmpdir=$(mktemp -d)
        cp -r ${studioFrontend}/* "$tmpdir"/
        cd "$tmpdir"
        ${pkgs.nodejs_22}/bin/npm install --no-fund --no-audit --loglevel=error
        ${pkgs.nodejs_22}/bin/npm run build
        mkdir -p ${studioFrontend}/dist
        cp -r dist/* ${studioFrontend}/dist/
        rm -rf "$tmpdir"

        # Phase 4: oxc-validator runtime
        if [ -f ${studioBackend}/core/data_recipe/oxc-validator/package.json ]; then
          tmpdir=$(mktemp -d)
          cp -r ${studioBackend}/core/data_recipe/oxc-validator/* "$tmpdir"/
          cd "$tmpdir"
          ${pkgs.nodejs_22}/bin/npm install --no-fund --no-audit --loglevel=error
          cp -r node_modules ${studioBackend}/core/data_recipe/oxc-validator/
          rm -rf "$tmpdir"
        fi

        date -Iseconds > ${setupDone}
        echo "Studio setup complete."
      '';
      User = "lars";
      Group = "users";
      TimeoutStartSec = "3600";
    };
  };

  systemd.services.unsloth-studio = {
    description = "Unsloth Studio - AI Model Training & Inference UI";
    after = ["network.target" "unsloth-setup.service"];
    requires = ["unsloth-setup.service"];
    wantedBy = ["multi-user.target"];
    path = with pkgs; [git python313 llama-cpp-rocwmma];
    environment = {
      HOME = unslothDataDir;
      LLAMA_SERVER_PATH = "${llama-cpp-rocwmma}/bin/llama-server";
      LD_LIBRARY_PATH = with pkgs;
        lib.makeLibraryPath [
          stdenv.cc.cc.lib
          zstd
          rocmPackages.clr
          rocmPackages.rocminfo
          rocmPackages.rocrand
          rocmPackages.rocblas
        ];
    };
    unitConfig = {
      ConditionPathExists = setupDone;
    };
    serviceConfig = {
      Type = "simple";
      ExecStart = "${venvPython} ${studioBackend}/run.py --host 127.0.0.1 --port 8888";
      User = "lars";
      Group = "video";
      WorkingDirectory = "${unslothDataDir}/workspace";
      Restart = "on-failure";
      RestartSec = "10s";
      SupplementaryGroups = ["render"];
      TimeoutStartSec = "60";
    };
  };

  systemd.tmpfiles.rules = [
    # Recursively fix ownership/permissions on ollama data dir (handles pre-existing dirs)
    "R /data/models/ollama 0755 ollama ollama - -"
    # Ensure directory exists with correct ownership (in case it was deleted)
    "d /data/models/ollama 0755 ollama ollama -"
    "d ${unslothDataDir} 0755 lars users -"
    "d ${unslothDataDir}/workspace 0755 lars users -"
    "d ${unslothDataDir}/models 0755 lars users -"
    "d ${unslothDataDir}/.unsloth 0755 lars users -"
    "d ${unslothDataDir}/.unsloth/studio 0755 lars users -"
    # Centralized AI models directory
    "d /data/models 0755 lars users -"
  ];

  environment.sessionVariables = {
    ROCBLAS_USE_HIPBLASLT = "1";
    # HuggingFace cache locations (centralized on /data)
    HF_HOME = "/data/cache/huggingface";
    HUGGINGFACE_HUB_CACHE = "/data/cache/huggingface/hub";
    TRANSFORMERS_CACHE = "/data/cache/huggingface/transformers";
    # Unsloth model location
    UNSLOTH_MODELS = "/data/models";
    # Llama.cpp model location
    LLAMA_MODEL_PATH = "/data/models";
  };
}
