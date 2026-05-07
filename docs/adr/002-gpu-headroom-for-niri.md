# ADR-002: GPU Memory Headroom for Niri

**Date:** 2026-05-08
**Status:** Accepted

## Context

AI workloads (Ollama, ComfyUI) on the AMD APU iGPU can starve the Niri Wayland compositor of GPU cycles, causing desktop lag. AMD APUs lack MPS-style GPU scheduling.

## Decision

Use `PYTORCH_CUDA_ALLOC_CONF=per_process_memory_fraction:0.95` system-wide to cap PyTorch/Ollama GPU memory at 95%, leaving VRAM free for niri rendering. Reduce `OLLAMA_NUM_PARALLEL` from 4 to 2 to limit concurrent GPU batches.

## Consequences

- Desktop stays responsive during heavy AI inference
- AI workloads have slightly less GPU memory available (5% reserved)
- `gpu-python` wrapper allows ad-hoc adjustment per script
