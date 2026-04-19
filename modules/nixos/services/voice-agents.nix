{inputs, ...}: {
  flake.nixosModules.voice-agents = {
    config,
    pkgs,
    lib,
    ...
  }: let
    inherit (config.networking) domain;
    cfg = config.services.voice-agents;

  # Service ports
  livekitPort = 7880;
  livekitApiPort = 7881;
  whisperPort = 8000;
  pipecatPort = 8500;

  # Directories
  voiceAgentsDir = "/var/lib/voice-agents";
  whisperModelsDir = "/data/models/whisper";
  composeFile = pkgs.writeText "docker-compose.voice-agents.yml" ''
    name: voice-agents

    services:
      livekit:
        image: livekit/livekit-server:latest
        container_name: livekit-server
        restart: unless-stopped
        ports:
          - '${toString livekitPort}:${toString livekitPort}/udp'
          - '${toString livekitPort}:${toString livekitPort}/tcp'
          - '${toString livekitApiPort}:${toString livekitApiPort}'
        environment:
          - LIVEKIT_KEYS=${cfg.livekitKey} ${cfg.livekitSecret}
          - PORT=${toString livekitPort}
          - UDP_PORT=${toString livekitPort}
          - API_PORT=${toString livekitApiPort}
        volumes:
          - livekit-data:/data
        networks:
          - voice-net

      whisper-rocm:
        image: beecave/insanely-fast-whisper-rocm:main
        container_name: whisper-asr
        restart: unless-stopped
        ports:
          - '${toString whisperPort}:8000'
        environment:
          - WHISPER_MODEL=${cfg.whisperModel}
          - HSA_OVERRIDE_GFX_VERSION=11.5.1
        volumes:
          - ${whisperModelsDir}:/root/.cache/huggingface
        devices:
          - /dev/dri:/dev/dri
          - /dev/kfd:/dev/kfd
        networks:
          - voice-net

    volumes:
      livekit-data:

    networks:
      voice-net:
        name: voice-agents-net
        driver: bridge
  '';

in {
  options.services.voice-agents = {
    enable = lib.mkEnableOption "Voice agents (LiveKit + Whisper ASR + Pipecat + MiniMax TTS)";

    domain = lib.mkOption {
      type = lib.types.str;
      default = domain;
      description = "Domain for voice agent services";
    };

    livekitKey = lib.mkOption {
      type = lib.types.str;
      default = "devkey";
      description = "LiveKit API key";
    };

    livekitSecret = lib.mkOption {
      type = lib.types.str;
      default = "secret";
      description = "LiveKit API secret";
    };

    huggingfaceToken = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "HuggingFace token for private models";
    };

    whisperModel = lib.mkOption {
      type = lib.types.str;
      default = "openai/whisper-large-v3";
      description = "Whisper model to use";
    };

    openaiBaseUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://localhost:11434/v1";
      description = "OpenAI-compatible LLM API base URL";
    };

    llmModel = lib.mkOption {
      type = lib.types.str;
      default = "llama3.2";
      description = "LLM model name";
    };

    minimaxApiKey = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "MiniMax API key for TTS";
    };

    minimaxVoiceId = lib.mkOption {
      type = lib.types.str;
      default = "female-tianmei";
      description = "MiniMax TTS voice ID";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open firewall ports for external access";
    };
  };

  config = lib.mkIf cfg.enable {
    # Create directories
    systemd.tmpfiles.rules = [
      "d ${voiceAgentsDir} 0755 lars users -"
      "d ${whisperModelsDir} 0755 lars users -"
    ];

    # GPU device access for containers
    users.users.lars.extraGroups = ["docker" "render" "video"];

    systemd = {
      # Image pull services — separate from container start so that
      # slow downloads never block activation.  These run with no
      # timeout; docker pull is idempotent (no-op when image is current).

      services.livekit-pull = {
        description = "Pull LiveKit Docker Image";
        after = ["docker.service" "network-online.target"];
        requires = ["docker.service"];
        wantedBy = ["multi-user.target"];
        path = [pkgs.docker];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${pkgs.docker}/bin/docker pull livekit/livekit-server:latest";
          TimeoutStartSec = 0;
        };
      };

      services.whisper-asr-pull = {
        description = "Pull Whisper ASR Docker Image";
        after = ["docker.service" "network-online.target"];
        requires = ["docker.service"];
        wantedBy = ["multi-user.target"];
        path = [pkgs.docker];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${pkgs.docker}/bin/docker pull beecave/insanely-fast-whisper-rocm:main";
          TimeoutStartSec = 0;
        };
      };

      # LiveKit RTC Server
      services.livekit = {
        description = "LiveKit RTC Server";
        after = ["docker.service" "network-online.target" "livekit-pull.service"];
        requires = ["docker.service"];
        wants = ["livekit-pull.service"];
        wantedBy = ["multi-user.target"];
        path = [pkgs.docker pkgs.docker-compose];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${pkgs.docker-compose}/bin/docker-compose -f ${composeFile} up -d livekit";
          ExecStop = "${pkgs.docker-compose}/bin/docker-compose -f ${composeFile} down livekit";
          TimeoutStartSec = 180;
        };
      };

      # Whisper ASR Server (ROCm)
      services.whisper-asr = {
        description = "Whisper ASR Server (ROCm)";
        after = ["docker.service" "network-online.target" "whisper-asr-pull.service"];
        requires = ["docker.service"];
        wants = ["whisper-asr-pull.service"];
        wantedBy = ["multi-user.target"];
        path = [pkgs.docker pkgs.docker-compose];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${pkgs.docker-compose}/bin/docker-compose -f ${composeFile} up -d whisper-rocm";
          ExecStop = "${pkgs.docker-compose}/bin/docker-compose -f ${composeFile} down whisper-rocm";
          TimeoutStartSec = 180;
        };
      };
    };

    # Firewall ports
    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedUDPPorts = [livekitPort];
      allowedTCPPorts = [
        livekitApiPort
        whisperPort
        pipecatPort
      ];
    };

    # Caddy reverse proxy routes
    services.caddy.virtualHosts = {
      "voice.${cfg.domain}" = {
        extraConfig = ''
          reverse_proxy localhost:${toString livekitApiPort}
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
