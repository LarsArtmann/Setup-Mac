{inputs, ...}: {
  flake.nixosModules.voice-agents = {
    config,
    pkgs,
    lib,
    utils,
    ...
  }: let
    inherit (config.networking) domain;
    cfg = config.services.voice-agents;

    whisperPort = 7860;
    pipecatPort = 8500;
    whisperModelsDir = "/data/models/whisper";

    whisperComposeFile = pkgs.writeText "docker-compose.whisper-asr.yml" ''
      name: voice-agents

      services:
        whisper-rocm:
          image: beecave/insanely-fast-whisper-rocm:main
          container_name: whisper-asr
          restart: unless-stopped
          command: app.py
          ports:
            - '${toString whisperPort}:7860'
          environment:
            - WHISPER_MODEL=${cfg.whisperModel}
            - HSA_OVERRIDE_GFX_VERSION=11.5.1
          volumes:
            - ${whisperModelsDir}:/root/.cache/huggingface
          devices:
            - /dev/dri:/dev/dri
            - /dev/kfd:/dev/kfd
    '';
  in {
    options.services.voice-agents = {
      enable = lib.mkEnableOption "Voice agents (LiveKit + Whisper ASR)";

      domain = lib.mkOption {
        type = lib.types.str;
        default = domain;
        description = "Domain for voice agent services";
      };

      whisperModel = lib.mkOption {
        type = lib.types.str;
        default = "openai/whisper-large-v3";
        description = "Whisper model to use";
      };

      openFirewall = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Open firewall ports for external access";
      };
    };

    config = lib.mkIf cfg.enable {
      sops.secrets.livekit_keys = {
        restartUnits = ["livekit.service"];
      };

      sops.templates."livekit-keys.env" = {
        content = ''
          ${config.sops.placeholder.livekit_keys}
        '';
      };

      services.livekit = {
        enable = true;
        keyFile = config.sops.templates."livekit-keys.env".path;
        settings = {
          port = 7880;
          rtc = {
            port_range_start = 50000;
            port_range_end = 51000;
            use_external_ip = false;
          };
        };
      };

      systemd.tmpfiles.rules = [
        "d ${whisperModelsDir} 0755 lars users -"
      ];

      users.users.lars.extraGroups = ["docker" "render" "video"];

      systemd = {
        services.whisper-asr-pull = {
          description = "Pull Whisper ASR Docker Image";
          after = ["docker.service" "network-online.target"];
          requires = ["docker.service"];
          wants = ["network-online.target"];
          wantedBy = ["multi-user.target"];
          path = [pkgs.docker];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = "${pkgs.docker}/bin/docker pull beecave/insanely-fast-whisper-rocm:main";
            TimeoutStartSec = 0;
          };
        };

        services.whisper-asr = {
          description = "Whisper ASR Server (ROCm)";
          after = ["docker.service" "network-online.target" "whisper-asr-pull.service"];
          requires = ["docker.service"];
          wants = ["whisper-asr-pull.service" "network-online.target"];
          wantedBy = ["multi-user.target"];
          path = [pkgs.docker pkgs.docker-compose];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = "${pkgs.docker-compose}/bin/docker-compose -f ${whisperComposeFile} up -d whisper-rocm";
            ExecStop = "${pkgs.docker-compose}/bin/docker-compose -f ${whisperComposeFile} down whisper-rocm";
            TimeoutStartSec = 180;
          };
        };
      };

      networking.firewall = lib.mkIf cfg.openFirewall {
        allowedTCPPorts = [
          7880
          whisperPort
          pipecatPort
        ];
        allowedUDPPortRanges = [
          {
            from = 50000;
            to = 51000;
          }
        ];
      };

      services.caddy.virtualHosts = {
        "voice.${cfg.domain}" = {
          extraConfig = ''
            reverse_proxy localhost:7880
          '';
        };
        "whisper.${cfg.domain}" = {
          extraConfig = ''
            reverse_proxy localhost:${toString whisperPort}
          '';
        };
      };
    };
  };
}
