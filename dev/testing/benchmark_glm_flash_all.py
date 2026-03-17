#!/usr/bin/env python3
"""
Benchmark all GLM-4.7-Flash quantisations sequentially with OOM protection.

Safety measures:
- Runs smallest model first (Q4_K_M → Q8_0 → BF16)
- Unloads each model before loading the next
- Monitors available memory before each benchmark
- Skips models that would exceed available memory
- Saves results incrementally (won't lose data on crash)
- Sets OLLAMA_NUM_PARALLEL=1 via API options

Usage:
    python3 benchmark_glm_flash_all.py              # default: 512 prompt, 512 gen, 3 runs
    python3 benchmark_glm_flash_all.py 1024 1024 5   # custom tokens and runs
    python3 benchmark_glm_flash_all.py --quick       # fast: 128/128/1 runs
"""
import requests
import time
import json
import sys
import os
import subprocess

OLLAMA_URL = "http://127.0.0.1:11434"

MODELS = [
    {"tag": "glm-4.7-flash:latest",  "quant": "Q4_K_M", "size_gb": 19},
    {"tag": "glm-4.7-flash:q8_0",    "quant": "Q8_0",    "size_gb": 32},
    {"tag": "glm-4.7-flash:bf16",    "quant": "BF16",    "size_gb": 60},
]

MEMORY_HEADROOM_GB = 6  # reserve this much RAM for OS + overhead


def get_available_memory_gb():
    """Get available RAM in GB (excluding buffers/cache that can be reclaimed)."""
    try:
        with open("/proc/meminfo") as f:
            info = {}
            for line in f:
                parts = line.split()
                if len(parts) >= 2:
                    info[parts[0].rstrip(":")] = int(parts[1])
        mem_available = info.get("MemAvailable", info.get("MemFree", 0))
        swap_free = info.get("SwapFree", 0)
        return (mem_available + swap_free) / (1024 ** 2)
    except Exception:
        return 0


def unload_all_models():
    """Unload all models from Ollama to free VRAM/RAM."""
    for tag in ["glm-4.7-flash:latest", "glm-4.7-flash:q8_0", "glm-4.7-flash:bf16"]:
        try:
            requests.post(f"{OLLAMA_URL}/api/generate", json={
                "model": tag,
                "keep_alive": "0",
                "prompt": "",
                "options": {"num_predict": 0},
            }, timeout=30)
        except Exception:
            pass
    time.sleep(3)


def wait_for_ollama(timeout=30):
    """Wait for Ollama to be ready."""
    start = time.time()
    while time.time() - start < timeout:
        try:
            resp = requests.get(f"{OLLAMA_URL}/", timeout=5)
            if resp.status_code == 200:
                return True
        except Exception:
            pass
        time.sleep(1)
    return False


def benchmark_single(model_tag, prompt_tokens, max_tokens, num_runs):
    """Benchmark a single model and return results dict or None on failure."""
    print(f"\n{'='*60}")
    print(f"  Benchmarking: {model_tag}")
    print(f"  Prompt tokens: {prompt_tokens} | Generation tokens: {max_tokens} | Runs: {num_runs}")
    print(f"{'='*60}\n")

    prompt = "Say the following words: " + " ".join(["test"] * prompt_tokens)

    # Warmup
    print("  Warmup run...", flush=True)
    warmup_timeout = max(120, (prompt_tokens + max_tokens) / 10)
    try:
        resp = requests.post(f"{OLLAMA_URL}/api/generate", json={
            "model": model_tag,
            "prompt": prompt,
            "stream": False,
            "options": {
                "num_predict": max_tokens,
                "num_parallel": 1,
            }
        }, timeout=warmup_timeout)
        if resp.status_code != 200:
            print(f"  FAIL: Warmup returned {resp.status_code}: {resp.text[:200]}")
            return None
    except Exception as e:
        print(f"  FAIL: Warmup error: {e}")
        return None

    print("  Warmup OK\n", flush=True)

    results = []
    for run in range(1, num_runs + 1):
        print(f"  Run {run}/{num_runs}...", flush=True)
        start = time.time()
        try:
            resp = requests.post(f"{OLLAMA_URL}/api/generate", json={
                "model": model_tag,
                "prompt": prompt,
                "stream": False,
                "options": {
                    "num_predict": max_tokens,
                    "num_parallel": 1,
                }
            }, timeout=900)
            elapsed = time.time() - start
            if resp.status_code != 200:
                print(f"    FAIL: {resp.status_code}")
                continue

            data = resp.json()
            prompt_count = data.get("prompt_eval_count", 0)
            eval_count = data.get("eval_count", 0)
            prompt_dur_ns = data.get("prompt_eval_duration", 0)
            eval_dur_ns = data.get("eval_duration", 0)
            load_dur_ns = data.get("load_duration", 0)

            prompt_dur = prompt_dur_ns / 1e9 if prompt_dur_ns > 0 else 0
            eval_dur = eval_dur_ns / 1e9 if eval_dur_ns > 0 else 0

            if prompt_dur == 0 and prompt_count > 0 and eval_dur > 0:
                prompt_dur = max(0.01, elapsed - eval_dur - load_dur_ns / 1e9)
            if eval_dur == 0 and eval_count > 0 and prompt_dur > 0:
                eval_dur = max(0.01, elapsed - prompt_dur - load_dur_ns / 1e9)
            if prompt_dur == 0 and eval_dur == 0 and prompt_count > 0 and eval_count > 0:
                prompt_dur = max(0.01, elapsed * 0.2)
                eval_dur = max(0.01, elapsed * 0.8)

            p_tps = prompt_count / prompt_dur if prompt_dur > 0 else 0
            e_tps = eval_count / eval_dur if eval_dur > 0 else 0

            print(f"    Total: {elapsed:.1f}s | Prompt: {p_tps:.1f} t/s | Gen: {e_tps:.1f} t/s | Tokens: {prompt_count}+{eval_count}", flush=True)
            results.append({
                "run": run,
                "total_time": elapsed,
                "prompt_tps": p_tps,
                "eval_tps": e_tps,
                "prompt_tokens": prompt_count,
                "eval_tokens": eval_count,
            })
        except Exception as e:
            print(f"    FAIL: {e}", flush=True)
            continue

    good = [r for r in results if r["prompt_tps"] > 0 and r["eval_tps"] > 0]
    bad = [r for r in results if r not in good]
    if bad:
        print(f"  NOTE: {len(bad)}/{len(results)} runs had zero timing data (Ollama API issue)")
    if not good:
        print(f"\n  No successful runs for {model_tag}")
        return None

    avg_p = sum(r["prompt_tps"] for r in good) / len(good)
    avg_e = sum(r["eval_tps"] for r in good) / len(good)
    avg_t = sum(r["total_time"] for r in good) / len(good)

    print(f"\n  AVERAGE ({len(good)} runs): Prompt {avg_p:.1f} t/s | Gen {avg_e:.1f} t/s | Time {avg_t:.1f}s")

    return {
        "model": model_tag,
        "avg_prompt_tps": round(avg_p, 1),
        "avg_eval_tps": round(avg_e, 1),
        "avg_total_time": round(avg_t, 1),
        "num_runs": len(good),
        "runs": good,
    }


def save_results(results, path):
    """Save results incrementally."""
    # Remove per-run details for summary
    summary = []
    for r in results:
        s = {k: v for k, v in r.items() if k != "runs"}
        summary.append(s)
    with open(path, "w") as f:
        json.dump(summary, f, indent=2)


def print_comparison_table(all_results):
    """Print a comparison table of all benchmarks."""
    print("\n")
    print("=" * 85)
    print("  GLM-4.7-FLASH QUANTISATION COMPARISON")
    print("=" * 85)
    print(f"  {'Quant':<10} {'Size':>6} {'Prompt t/s':>12} {'Gen t/s':>12} {'Avg Time':>10} {'Runs':>6}")
    print(f"  {'-'*10} {'-'*6} {'-'*12} {'-'*12} {'-'*10} {'-'*6}")

    size_map = {"glm-4.7-flash:latest": 19, "glm-4.7-flash:q8_0": 32, "glm-4.7-flash:bf16": 60}
    for r in all_results:
        tag = r["model"].split(":")[-1] if r["model"].split(":")[-1] != "latest" else "Q4_K_M"
        size = size_map.get(r["model"], 0)
        print(f"  {tag:<10} {size:>5}G {r['avg_prompt_tps']:>12.1f} {r['avg_eval_tps']:>12.1f} {r['avg_total_time']:>9.1f}s {r['num_runs']:>6}")

    print("=" * 85)

    if len(all_results) >= 2:
        best_prompt = max(all_results, key=lambda r: r["avg_prompt_tps"])
        best_gen = max(all_results, key=lambda r: r["avg_eval_tps"])
        ptag = best_prompt['model'].split(':')[-1] if best_prompt['model'].split(':')[-1] != 'latest' else 'Q4_K_M'
        gtag = best_gen['model'].split(':')[-1] if best_gen['model'].split(':')[-1] != 'latest' else 'Q4_K_M'
        print(f"\n  Fastest prompt processing: {ptag} ({best_prompt['avg_prompt_tps']:.1f} t/s)")
        print(f"  Fastest generation:       {gtag} ({best_gen['avg_eval_tps']:.1f} t/s)")


def main():
    prompt_tokens = 512
    max_tokens = 512
    num_runs = 3

    args = sys.argv[1:]
    if "--quick" in args:
        args.remove("--quick")
        prompt_tokens, max_tokens, num_runs = 128, 128, 1
    if len(args) >= 1:
        prompt_tokens = int(args[0])
    if len(args) >= 2:
        max_tokens = int(args[1])
    if len(args) >= 3:
        num_runs = int(args[2])

    output_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "glm_flash_benchmark_results.json")

    print("GLM-4.7-Flash Quantisation Benchmark")
    print(f"  Models: {[m['tag'] for m in MODELS]}")
    print(f"  Config: {prompt_tokens} prompt tokens, {max_tokens} gen tokens, {num_runs} runs each")
    print(f"  Output: {output_path}")

    if not wait_for_ollama():
        print("ERROR: Ollama is not running. Start it first.")
        sys.exit(1)

    total_ram = get_available_memory_gb()
    print(f"  Available memory: {total_ram:.1f} GB (need {MEMORY_HEADROOM_GB} GB headroom)\n")

    all_results = []

    for model in MODELS:
        tag = model["tag"]
        size = model["size_gb"]
        quant = model["quant"]

        # Unload previous model to free memory
        print(f"\n--- Unloading previous models...", flush=True)
        unload_all_models()

        # Check memory
        avail = get_available_memory_gb()
        needed = size + MEMORY_HEADROOM_GB
        print(f"--- Memory check: {avail:.1f} GB available, {needed:.1f} GB needed for {quant}", flush=True)

        if avail < needed:
            print(f"  SKIP: Not enough memory for {quant} ({avail:.1f} < {needed:.1f} GB)")
            print(f"  Close other applications and try again, or run with smaller models only.")
            all_results.append({
                "model": tag,
                "avg_prompt_tps": 0,
                "avg_eval_tps": 0,
                "avg_total_time": 0,
                "num_runs": 0,
                "skipped": True,
                "reason": f"Insufficient memory: {avail:.1f} GB available, {needed:.1f} GB needed",
            })
            save_results(all_results, output_path)
            continue

        # Run benchmark
        result = benchmark_single(tag, prompt_tokens, max_tokens, num_runs)
        if result:
            all_results.append(result)
        else:
            all_results.append({
                "model": tag,
                "avg_prompt_tps": 0,
                "avg_eval_tps": 0,
                "avg_total_time": 0,
                "num_runs": 0,
                "skipped": True,
                "reason": "Benchmark failed",
            })

        # Save after each model (incremental)
        save_results(all_results, output_path)

    # Final comparison
    successful = [r for r in all_results if not r.get("skipped")]
    if successful:
        print_comparison_table(successful)
    else:
        print("\nNo successful benchmarks to compare.")

    print(f"\nResults saved to: {output_path}")
    print("Done.")


if __name__ == "__main__":
    main()
