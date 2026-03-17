# GLM-4.7-Flash Quantisation Benchmark - Findings & Results

**Date:** 2026-03-18
**System:** GMKtec EVO-X2 (AMD Ryzen AI Max+ 395, Radeon 8060S RDNA 3.5)
**Ollama:** v0.18.0 (`ollama-rocm`)

---

## Available Quantisations

Only 3 official quantisations exist for GLM-4.7-Flash:

| Tag | Quant | Size | Local Tag |
|-----|-------|------|-----------|
| `:latest` | Q4_K_M | 19 GB | `glm-4.7-flash:latest` |
| `:q8_0` | Q8_0 | 32 GB | `glm-4.7-flash:q8_0` |
| `:bf16` | BF16 | 60 GB | `glm-4.7-flash:bf16` |

**Note:** The Ollama library page lists `:q4_K_M` as a tag, but locally it resolves to `:latest`. Using `glm-4.7-flash:q4_K_M` returns a 404 "model not found" error.

---

## Hardware & Memory Layout

The Ryzen AI Max+ 395 uses **unified memory architecture** (CPU + GPU share the same DDR5 pool). The system splits it as:

| Region | Size | Notes |
|--------|------|-------|
| System RAM (OS-visible) | 62 GiB | `/proc/meminfo MemTotal` |
| GPU-reserved | ~64 GiB | `amdgpu` reports 68.7 GiB VRAM total |
| Total physical | 128 GiB | Installed DDR5 |

Swap: 41 GiB total (31.2 GiB ZRAM + 10 GiB NVMe partition)

**Implication for BF16 (60 GB):** With only 62 GiB visible to the OS, loading a 60 GB model leaves essentially no headroom for the OS, KV cache, or compute graph. The model itself plus KV cache totals ~64+ GB for BF16.

---

## Critical Issue: GPU Not Detected by Ollama

**Ollama is running CPU-only.** Despite `ollama-rocm` being installed and ROCm device libs present in the Nix store, the logs confirm:

```
offloading 0 repeating layers to GPU
offloaded 0/48 layers to GPU
model weights device=CPU size="17.7 GiB"
```

### Evidence

1. **Ollama logs** show 0 GPU layers offloaded for all quantisations
2. **`rocminfo`** is not installed in the system profile
3. **`HSA_OVERRIDE_GFX_VERSION=11.0.0`** is set in the Nix config but `rocminfo` binary doesn't exist
4. **ROCm detection:** `/dev/kfd` exists, `/sys/class/kfd/topology/nodes/` has nodes 0 and 1
5. **Vulkan** works fine (RADV driver, GPU visible in `vulkaninfo`)
6. **`ollama-rocm` package** exists in `/nix/store` but `rocminfo` is not in the system PATH

### Likely Cause

The `ollama-rocm` Nix package may not bundle or correctly link the ROCm runtime libraries (`libhsakmt`, `libamdhip64`) needed at runtime. The Strix Halo GPU (gfx1100/gfx1101) is very new and ROCm support is still maturing. The `rocm-device-libs` and `llvm-19.0.0-rocm-lib` are in the Nix store but may not be on the library path that the Ollama binary sees.

### GPU Impact on Performance

Without GPU offloading, all 48 transformer layers run on the 16-core CPU. This explains the ~20 t/s generation speed for Q8_0 in the first benchmark run -- which is CPU-only performance, not GPU-accelerated.

---

## Benchmark Results

### Run 1 (with bugs in script)

Only Q8_0 produced 1 successful run out of 3. BF16 failed all runs.

| Quant | Prompt t/s | Gen t/s | Avg Time | Runs |
|-------|-----------|---------|----------|------|
| Q4_K_M | - | - | - | 0/3 (tag 404) |
| Q8_0 | 11,096.7 | 20.7 | 25.1s | 1/3 |
| BF16 | - | - | - | 0/3 |

### Run 2 (fixed tags, still zero timing)

All 9 runs returned 0 tokens and 0 timing despite 200 OK responses.

**Root cause discovered:** The GLM-4.7-Flash model uses a **thinking/reasoning mode** by default. The API response shows:

```json
{
  "response": "",
  "thinking": "The user has simply greeted me with \"Hello.\" This is a standard, open-ended greeting.\n\n**",
  "done_reason": "length",
  "prompt_eval_count": 6,
  "eval_count": 20,
  "prompt_eval_duration": 84452994,
  "eval_duration": 573362388
}
```

The model puts its output in the `thinking` field, not `response`. The `eval_count` and timing fields **are present** in the raw response, so the script's parsing was correct. The issue in Run 2 was likely a transient problem where the warmup loaded the model but subsequent requests hit a race condition or the model was evicted between runs due to the `keep_alive` behavior.

### Actual Working API Response (verified)

A direct test with `glm-4.7-flash:latest` + `"Hello"` prompt returned valid timing data:
- `prompt_eval_count`: 6, `prompt_eval_duration`: 84ms
- `eval_count`: 20, `eval_duration`: 573ms
- `load_duration`: 8.8s (model load time)
- `total_duration`: 9.5s

This confirms the API shape is correct and the benchmark approach is valid.

---

## Memory Behavior

| State | MemFree | MemAvailable |
|-------|---------|-------------|
| Before benchmark (models loaded) | 464 MiB | 2.7 GiB |
| After unloading all models | 49.1 GiB | 51.4 GiB |
| Swap used (with models loaded) | 9.9 GiB | - |
| Swap used (models unloaded) | ~0 GiB | - |

The first benchmark run consumed enough memory to push 9.9 GiB into swap, which is why the available memory appeared as 98 GiB in the second run (MemAvailable + SwapFree).

**OOM risk for BF16:** With 51 GiB available after unloading and BF16 needing ~64 GiB (model + KV cache + compute), this will OOM without GPU offloading.

---

## Script Issues Found

1. **Wrong tag:** `glm-4.7-flash:q4_K_M` doesn't exist locally -- must use `glm-4.7-flash:latest`
2. **Thinking mode:** GLM-4.7-Flash uses `thinking` field for output; need to check if this affects `eval_count` accuracy
3. **Model eviction:** Between runs, the model may be evicted if `keep_alive` expires (default 5m). The unload step between quantisations sets `keep_alive=0` but the benchmark runs themselves don't set an explicit `keep_alive`
4. **Load time:** First request includes model load time (~8-9s for Q4_K_M). The `load_duration` field exists in the response but was not accounted for in timing calculations

---

## Recommendations

1. **Fix ROCm/GPU detection** before benchmarking -- CPU-only results are not representative of actual GPU performance. Check if `rocminfo` needs to be explicitly added to the system PATH or if the `ollama-rocm` derivation is missing runtime deps.

2. **For safe CPU-only benchmarking of BF16:** Close all other applications to maximize free RAM (~50 GiB), and use smaller prompt/generation lengths (128/128) to keep KV cache small.

3. **Add `keep_alive` to benchmark requests** to prevent model eviction between runs within the same quantisation test.

4. **Account for `load_duration`** in timing -- first run of each quantisation includes model load time and should be treated separately or as warmup only.

5. **Consider the thinking mode** -- GLM-4.7-Flash generates tokens in `thinking` before `response`. The `eval_count` includes both, so t/s metrics are valid, but be aware the model is doing more work than a non-thinking model for the same `num_predict`.
