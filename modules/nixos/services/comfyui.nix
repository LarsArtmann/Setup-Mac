{inputs, ...}: {
  flake.nixosModules.comfyui = {
    config,
    pkgs,
    lib,
    ...
  }: let
    cfg = config.services.comfyui;
    primaryUser = "lars";

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

    rocmEnv = {
      ROCBLAS_USE_HIPBLASLT = "1";
      HSA_OVERRIDE_GFX_VERSION = "11.5.1";
      HSA_ENABLE_SDMA = "0";
      PYTORCH_HIP_ALLOC_CONF = "garbage_collection_threshold:0.6,max_split_size_mb:128";
      TORCH_ROCM_AOTRITON_ENABLE_EXPERIMENTAL = "1";
      TORCH_COMPILE_DISABLE = "1";
      PYTHONDONTWRITEBYTECODE = "1";
    };
  in {
    options.services.comfyui = {
      enable = lib.mkEnableOption "ComfyUI — persistent AI image generation server with GPU model caching";

      package = lib.mkOption {
        type = lib.types.path;
        default = /home/lars/projects/anime-comic-pipeline/ComfyUI;
        description = "Path to ComfyUI installation";
      };

      venvPython = lib.mkOption {
        type = lib.types.str;
        default = "/home/lars/projects/anime-comic-pipeline/venv/bin/python";
        description = "Path to the Python venv with torch/diffusers installed";
      };

      host = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
        description = "Listen host";
      };

      port = lib.mkOption {
        type = lib.types.int;
        default = 8188;
        description = "Listen port";
      };

      user = lib.mkOption {
        type = lib.types.str;
        default = primaryUser;
        description = "User to run ComfyUI as (needs render/video group access for GPU)";
      };
    };

    config = lib.mkIf cfg.enable {
      systemd.services.comfyui = {
        description = "ComfyUI — Persistent AI Image Generation Server";
        after = ["network.target"];
        wantedBy = ["multi-user.target"];

        environment =
          rocmEnv
          // {
            HOME = "/home/${cfg.user}";
            LD_LIBRARY_PATH = lib.makeLibraryPath rocmRuntimeLibs;
            HF_HOME = "/data/cache/huggingface";
          };

        path = with pkgs; [
          git
          python313
        ];

        serviceConfig = {
          Type = "simple";
          User = cfg.user;
          Group = "users";
          WorkingDirectory = toString cfg.package;
          ExecStart = "${cfg.venvPython} ${toString cfg.package}/main.py --listen ${cfg.host} --port ${toString cfg.port} --bf16-unet --bf16-vae --bf16-text-enc";
          Restart = "on-failure";
          RestartSec = "10";
          OOMScoreAdjust = -100;

          SupplementaryGroups = ["render" "video"];
          PrivateTmp = true;
          ProtectClock = true;
          ProtectHostname = true;
          RestrictNamespaces = true;
          LockPersonality = true;

          TimeoutStartSec = "300";
          TimeoutStopSec = "60";
        };
      };
    };
  };
}
