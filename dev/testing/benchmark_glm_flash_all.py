#!/usr/bin/env python3
"""
Benchmark all GLM-4.7-Flash quantisations sequentially with OOM protection.

Safety measures:
- Runs smallest model first (Q4_K_M -> Q8_0 -> BF16)
- Unloads each model before loading the next
- Monitors available memory before each benchmark
- Skips models that would exceed available memory
- Saves results incrementally (won't lose data on crash)
- Sets keep_alive to prevent model eviction between runs

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

OLLAMA_URL = "http://127.0.0.1:11434"
KEEP_ALIVE = "10m"

MODELS = [
    {"tag": "glm-4.7-flash:latest", "quant": "Q4_K_M", "size_gb": 19},
    {"tag": "glm-4.7-flash:q8_0",   "quant": "Q8_0",   "size_gb": 32},
    {"tag": "glm-4.7-flash:bf16",   "quant": "BF16",   "size_gb": 60},
]

MEMORY_HEADROOM_GB = 6


def get_available_memory_gb():
    try:
        with open("/proc/meminfo") as f:
            info = {}
            for line in f:
                parts = line.split()
                if len(parts) >= 2:
                    info[parts[0].rstrip(":")] = int(parts[1])
        return info.get("MemAvailable", 0) / (1024 ** 2)
    except Exception:
        return 0


def unload_all_models():
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


def generate_payload(model_tag, prompt, max_tokens):
    return {
        "model": model_tag,
        "prompt": prompt,
        "stream": False,
        "keep_alive": KEEP_ALIVE,
        "options": {
            "num_predict": max_tokens,
            "num_parallel": 1,
        },
    }


def run_inference(model_tag, prompt, max_tokens, timeout=900):
    resp = requests.post(
        f"{OLLAMA_URL}/api/generate",
        json=generate_payload(model_tag, prompt, max_tokens),
        timeout=timeout,
    )
    resp.raise_for_status()
    return resp.json(), time.time() - 0  # elapsed measured by caller


def extract_timings(data, elapsed_wall):
    prompt_count = data.get("prompt_eval_count", 0)
    eval_count = data.get("eval_count", 0)
    load_ns = data.get("load_duration", 0)
    prompt_ns = data.get("prompt_eval_duration", 0)
    eval_ns = data.get("eval_duration", 0)
    total_ns = data.get("total_duration", 0)

    load_s = load_ns / 1e9
    prompt_s = prompt_ns / 1e9
    eval_s = eval_ns / 1e9
    total_s = total_ns / 1e9

    if prompt_s > 0:
        p_tps = prompt_count / prompt_s
    elif prompt_count > 0 and total_s > load_s:
        p_tps = prompt_count / max(0.01, total_s - load_s - eval_s)
    else:
        p_tps = 0

    if eval_s > 0:
        e_tps = eval_count / eval_s
    elif eval_count > 0 and total_s > load_s:
        e_tps = eval_count / max(0.01, total_s - load_s - prompt_s)
    else:
        e_tps = 0

    return {
        "prompt_tokens": prompt_count,
        "eval_tokens": eval_count,
        "load_time": load_s,
        "prompt_time": prompt_s,
        "eval_time": eval_s,
        "total_time": total_s if total_s > 0 else elapsed_wall,
        "prompt_tps": p_tps,
        "eval_tps": e_tps,
        "has_thinking": bool(data.get("thinking")),
        "response_len": len(data.get("response", "")),
        "thinking_len": len(data.get("thinking", "")),
    }


def benchmark_single(model_tag, prompt_tokens, max_tokens, num_runs):
    print(f"\n{'='*60}")
    print(f"  Benchmarking: {model_tag}")
    print(f"  Prompt tokens: {prompt_tokens} | Generation tokens: {max_tokens} | Runs: {num_runs}")
    print(f"{'='*60}\n")

    prompt = (
        "You are a helpful assistant. Please write a detailed and comprehensive "
        "explanation of how large language models work, covering attention mechanisms, "
        "transformer architecture, tokenization, and training methodology. Be thorough "
        "and include specific examples. "
        + "Continue explaining: " * max(1, prompt_tokens // 8)
    )

    print("  Warmup (includes model load)...", flush=True)
    t0 = time.time()
    try:
        data = requests.post(
            f"{OLLAMA_URL}/api/generate",
            json=generate_payload(model_tag, prompt, max_tokens),
            timeout=max(300, max_tokens * 2),
        ).json()
    except Exception as e:
        print(f"  FAIL: Warmup error: {e}")
        return None
    elapsed = time.time() - t0

    warmup = extract_timings(data, elapsed)
    print(f"    Load: {warmup['load_time']:.1f}s | "
          f"Prompt: {warmup['prompt_tps']:.1f} t/s | "
          f"Gen: {warmup['eval_tps']:.1f} t/s | "
          f"Tokens: {warmup['prompt_tokens']}+{warmup['eval_tokens']}", flush=True)

    if warmup["eval_tokens"] == 0:
        print(f"  WARNING: Model returned 0 generated tokens. Response may be in thinking field.")
        print(f"    response length: {warmup['response_len']} chars")
        print(f"    thinking length: {warmup['thinking_len']} chars")
        if warmup["thinking_len"] > 0 and warmup["response_len"] == 0:
            print(f"  INFO: All output in 'thinking' field (expected for reasoning models). eval_count still valid.")

    results = []
    for run in range(1, num_runs + 1):
        print(f"  Run {run}/{num_runs}...", end=" ", flush=True)
        t0 = time.time()
        try:
            data = requests.post(
                f"{OLLAMA_URL}/api/generate",
                json=generate_payload(model_tag, prompt, max_tokens),
                timeout=max(300, max_tokens * 2),
            ).json()
            elapsed = time.time() - t0

            timing = extract_timings(data, elapsed)

            print(f"Prompt: {timing['prompt_tps']:.1f} t/s | "
                  f"Gen: {timing['eval_tps']:.1f} t/s | "
                  f"Tokens: {timing['prompt_tokens']}+{timing['eval_tokens']} | "
                  f"Time: {timing['total_time']:.1f}s", flush=True)

            results.append({"run": run, **timing})

        except Exception as e:
            print(f"FAIL: {e}", flush=True)
            continue

    good = [r for r in results if r["eval_tps"] > 0]
    if not good:
        print(f"\n  No successful runs for {model_tag}")
        if results:
            print(f"  Raw data from last failed run: {json.dumps(results[-1], indent=2)}")
        return None

    avg_p = sum(r["prompt_tps"] for r in good) / len(good)
    avg_e = sum(r["eval_tps"] for r in good) / len(good)
    avg_t = sum(r["total_time"] for r in good) / len(good)
    avg_load = sum(r["load_time"] for r in good) / len(good)

    print(f"\n  AVERAGE ({len(good)} runs):")
    print(f"    Prompt: {avg_p:.1f} t/s | Gen: {avg_e:.1f} t/s | Time: {avg_t:.1f}s (load: {avg_load:.1f}s)")

    return {
        "model": model_tag,
        "quant": next((m["quant"] for m in MODELS if m["tag"] == model_tag), "unknown"),
        "size_gb": next((m["size_gb"] for m in MODELS if m["tag"] == model_tag), 0),
        "avg_prompt_tps": round(avg_p, 1),
        "avg_eval_tps": round(avg_e, 1),
        "avg_total_time": round(avg_t, 1),
        "avg_load_time": round(avg_load, 1),
        "num_runs": len(good),
        "runs": good,
    }


def save_results(results, path):
    summary = []
    for r in results:
        s = {k: v for k, v in r.items() if k != "runs"}
        summary.append(s)
    with open(path, "w") as f:
        json.dump(summary, f, indent=2)


def print_comparison_table(all_results):
    print("\n")
    print("=" * 90)
    print("  GLM-4.7-FLASH QUANTISATION COMPARISON")
    print("=" * 90)
    print(f"  {'Quant':<10} {'Size':>6} {'Prompt t/s':>12} {'Gen t/s':>12} {'Avg Time':>10} {'Load':>8} {'Runs':>6}")
    print(f"  {'-'*10} {'-'*6} {'-'*12} {'-'*12} {'-'*10} {'-'*8} {'-'*6}")

    for r in all_results:
        q = r.get("quant", r["model"].split(":")[-1])
        sz = r.get("size_gb", 0)
        print(f"  {q:<10} {sz:>5}G {r['avg_prompt_tps']:>12.1f} {r['avg_eval_tps']:>12.1f} "
              f"{r['avg_total_time']:>9.1f}s {r.get('avg_load_time', 0):>7.1f}s {r['num_runs']:>6}")

    print("=" * 90)

    if len(all_results) >= 2:
        best_p = max(all_results, key=lambda r: r["avg_prompt_tps"])
        best_e = max(all_results, key=lambda r: r["avg_eval_tps"])
        print(f"\n  Fastest prompt processing: {best_p.get('quant', '?')} ({best_p['avg_prompt_tps']:.1f} t/s)")
        print(f"  Fastest generation:       {best_e.get('quant', '?')} ({best_e['avg_eval_tps']:.1f} t/s)")


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

    avail = get_available_memory_gb()
    print(f"  Available memory: {avail:.1f} GB (need {MEMORY_HEADROOM_GB} GB headroom)\n")

    all_results = []

    for model in MODELS:
        tag = model["tag"]
        size = model["size_gb"]
        quant = model["quant"]

        print(f"\n--- Unloading previous models...", flush=True)
        unload_all_models()

        avail = get_available_memory_gb()
        needed = size + MEMORY_HEADROOM_GB
        print(f"--- Memory check: {avail:.1f} GB available, {needed:.1f} GB needed for {quant}", flush=True)

        if avail < needed:
            print(f"  SKIP: Not enough memory for {quant} ({avail:.1f} < {needed:.1f} GB)")
            all_results.append({
                "model": tag, "quant": quant, "size_gb": size,
                "avg_prompt_tps": 0, "avg_eval_tps": 0, "avg_total_time": 0,
                "num_runs": 0, "skipped": True,
                "reason": f"Insufficient memory: {avail:.1f} GB available, {needed:.1f} GB needed",
            })
            save_results(all_results, output_path)
            continue

        result = benchmark_single(tag, prompt_tokens, max_tokens, num_runs)
        if result:
            all_results.append(result)
        else:
            all_results.append({
                "model": tag, "quant": quant, "size_gb": size,
                "avg_prompt_tps": 0, "avg_eval_tps": 0, "avg_total_time": 0,
                "num_runs": 0, "skipped": True, "reason": "Benchmark failed",
            })

        save_results(all_results, output_path)

    successful = [r for r in all_results if not r.get("skipped")]
    if successful:
        print_comparison_table(successful)
    else:
        print("\nNo successful benchmarks to compare.")

    print(f"\nResults saved to: {output_path}")
    print("Done.")


if __name__ == "__main__":
    main()
