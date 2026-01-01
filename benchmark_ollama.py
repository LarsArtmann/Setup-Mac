#!/usr/bin/env python3
"""
Benchmark Ollama model performance using the API
"""
import requests
import time
import json
import sys

OLLAMA_URL = "http://127.0.0.1:11434"

def benchmark_model(model_name, prompt_tokens=128, max_tokens=128, num_runs=3, coding_test=False):
    """Benchmark an Ollama model"""

    print(f"🚀 Benchmarking {model_name}")
    print(f"   Prompt: ~{prompt_tokens} tokens")
    print(f"   Generation: ~{max_tokens} tokens")
    print(f"   Runs: {num_runs}")
    if coding_test:
        print(f"   Mode: Coding Test")
    print()

    # Prepare prompt
    if coding_test:
        # Generate a coding-related prompt
        prompt = "You are an expert programmer. Write detailed code for a complex application. " \
                 "Include comments, error handling, and documentation. " \
                 "Generate production-ready code with the following sections:\n\n" \
                 + " " * prompt_tokens
    else:
        # Simple word repetition for token count
        prompt = "Say the following words: " + " ".join(["test"] * prompt_tokens)

    # Warmup run
    print("🔥 Warmup run...")
    # Adjust warmup timeout based on token count
    warmup_timeout = max(120, (prompt_tokens + max_tokens) / 20)  # Conservative estimate
    if max_tokens > 1000:
        print(f"   ⏱️  Warmup timeout: {warmup_timeout:.0f}s")
    try:
        response = requests.post(
            f"{OLLAMA_URL}/api/generate",
            json={
                "model": model_name,
                "prompt": prompt,
                "stream": False,
                "options": {"num_predict": max_tokens}
            },
            timeout=warmup_timeout
        )
        if response.status_code != 200:
            print(f"❌ Warmup failed: {response.status_code}")
            return None
    except Exception as e:
        print(f"❌ Warmup error: {e}")
        return None

    print("✅ Warmup complete")
    print()

    # Benchmark runs
    results = []

    for run in range(1, num_runs + 1):
        print(f"📊 Run {run}/{num_runs}...")
        if max_tokens > 1000:
            print(f"   ⏱️  This may take several minutes (~{max_tokens/24:.0f}s expected)...")

        start_time = time.time()

        try:
            response = requests.post(
                f"{OLLAMA_URL}/api/generate",
                json={
                    "model": model_name,
                    "prompt": prompt,
                    "stream": False,
                    "options": {"num_predict": max_tokens}
                },
                timeout=600  # 10 minutes for large token counts
            )

            if response.status_code != 200:
                print(f"❌ Run {run} failed: {response.status_code}")
                continue

            end_time = time.time()
            data = response.json()

            total_time = end_time - start_time

            # Calculate tokens per second - Ollama returns durations in nanoseconds
            prompt_eval_count = data.get("prompt_eval_count", 0)
            eval_count = data.get("eval_count", 0)

            # Convert nanoseconds to seconds
            prompt_eval_duration = data.get("prompt_eval_duration", 0) / 1e9
            eval_duration = data.get("eval_duration", 0) / 1e9

            # If Ollama doesn't provide timing, estimate from total_time
            if prompt_eval_count > 0 and prompt_eval_duration == 0:
                # Estimate: prompt typically takes 10-20% of total time
                prompt_eval_duration = total_time * 0.15
            if eval_count > 0 and eval_duration == 0:
                eval_duration = total_time * 0.85

            prompt_tps = prompt_eval_count / prompt_eval_duration if prompt_eval_duration > 0 else 0
            eval_tps = eval_count / eval_duration if eval_duration > 0 else 0

            # Show actual tokens vs requested
            actual_gen_pct = (eval_count / max_tokens * 100) if max_tokens > 0 else 0
            print(f"   ⏱️  Total: {total_time:.2f}s | Prompt: {prompt_tps:.1f} t/s | Gen: {eval_tps:.1f} t/s")
            print(f"   📊 Tokens: {prompt_eval_count} prompt, {eval_count}/{max_tokens} generated ({actual_gen_pct:.1f}%)")

            results.append({
                "run": run,
                "total_time": total_time,
                "prompt_time": prompt_eval_duration,
                "eval_time": eval_duration,
                "prompt_tps": prompt_tps,
                "eval_tps": eval_tps,
                "total_tokens": data.get("eval_count", 0) + data.get("prompt_eval_count", 0)
            })

            print(f"   ⏱️  Total: {total_time:.2f}s | Prompt: {prompt_tps:.1f} t/s | Gen: {eval_tps:.1f} t/s")

        except Exception as e:
            print(f"❌ Run {run} error: {e}")
            continue

    # Filter out failed runs (0 t/s)
    successful_results = [r for r in results if r["prompt_tps"] > 0 and r["eval_tps"] > 0]

    # Calculate averages
    if not successful_results:
        print("\n❌ No successful runs")
        return None

    if len(successful_results) < len(results):
        print(f"⚠️  {len(results) - len(successful_results)} runs failed, using {len(successful_results)} successful runs")

    print()
    print("=" * 60)
    print("📈 RESULTS")
    print("=" * 60)

    avg_prompt_tps = sum(r["prompt_tps"] for r in successful_results) / len(successful_results)
    avg_eval_tps = sum(r["eval_tps"] for r in successful_results) / len(successful_results)
    avg_total_time = sum(r["total_time"] for r in successful_results) / len(successful_results)

    print(f"\n📊 Average Performance ({len(successful_results)} runs):")
    print(f"   Prompt Processing: {avg_prompt_tps:.1f} tokens/second")
    print(f"   Token Generation:  {avg_eval_tps:.1f} tokens/second")
    print(f"   Total Time:        {avg_total_time:.2f} seconds")

    # Performance assessment
    print(f"\n📊 Performance Assessment:")
    if avg_prompt_tps > 3000:
        print(f"   ✅ Prompt: EXCELLENT (>3000 t/s)")
    elif avg_prompt_tps > 2000:
        print(f"   ✅ Prompt: GOOD (2000-3000 t/s)")
    elif avg_prompt_tps > 1000:
        print(f"   ⚠️  Prompt: FAIR (1000-2000 t/s)")
    else:
        print(f"   ❌ Prompt: POOR (<1000 t/s)")

    if avg_eval_tps > 50:
        print(f"   ✅ Generation: EXCELLENT (>50 t/s)")
    elif avg_eval_tps > 30:
        print(f"   ✅ Generation: GOOD (30-50 t/s)")
    elif avg_eval_tps > 10:
        print(f"   ⚠️  Generation: FAIR (10-30 t/s)")
    else:
        print(f"   ❌ Generation: POOR (<10 t/s)")

    print()
    return {
        "model": model_name,
        "avg_prompt_tps": avg_prompt_tps,
        "avg_eval_tps": avg_eval_tps,
        "avg_total_time": avg_total_time,
        "num_runs": len(successful_results),
        "total_attempts": len(results),
        "results": successful_results
    }


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python benchmark_ollama.py <model_name> [prompt_tokens] [max_tokens] [runs] [--coding]")
        print("Example: python benchmark_ollama.py gpt-oss:20b 128 128 3")
        print("Example: python benchmark_ollama.py gpt-oss:20b 10000 10000 1 --coding")
        sys.exit(1)

    model = sys.argv[1]
    prompt_tokens = int(sys.argv[2]) if len(sys.argv) > 2 else 128
    max_tokens = int(sys.argv[3]) if len(sys.argv) > 3 else 128
    runs = int(sys.argv[4]) if len(sys.argv) > 4 else 3
    coding_test = "--coding" in sys.argv

    benchmark_model(model, prompt_tokens, max_tokens, runs, coding_test)
