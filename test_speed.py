#!/usr/bin/env python3
"""Test download speed from Hugging Face"""
import requests
import time

URLS = [
    ("BF16 small chunk", "https://huggingface.co/unsloth/GLM-4.7-Flash-GGUF/resolve/main/BF16/GLM-4.7-Flash-BF16-00002-of-00002.gguf", 10*1024*1024),
    ("Q8_0 small chunk", "https://huggingface.co/unsloth/GLM-4.7-Flash-GGUF/resolve/main/GLM-4.7-Flash-Q8_0.gguf", 10*1024*1024),
    ("Q5_K_M small chunk", "https://huggingface.co/unsloth/GLM-4.7-Flash-GGUF/resolve/main/GLM-4.7-Flash-Q5_K_M.gguf", 10*1024*1024),
]

def test_speed(name, url, chunk_size):
    """Test download speed for a chunk"""
    print(f"🧪 Testing: {name}")
    print(f"   Chunk size: {chunk_size/1024/1024:.1f} MB")

    headers = {"Range": f"bytes=0-{chunk_size-1}"}

    try:
        start_time = time.time()
        r = requests.get(url, headers=headers, stream=True, timeout=120)
        r.raise_for_status()

        downloaded = 0
        for data in r.iter_content(chunk_size=1024*1024):  # 1MB chunks
            downloaded += len(data)

        elapsed = time.time() - start_time
        speed_mb = (downloaded / 1024 / 1024) / elapsed
        speed_gb = speed_mb / 1024

        print(f"   ✅ Downloaded: {downloaded/1024/1024:.2f} MB")
        print(f"   ⏱️  Time: {elapsed:.2f}s")
        print(f"   🚀 Speed: {speed_mb:.1f} MB/s ({speed_gb:.3f} GB/s)")
        print()

        return speed_mb

    except Exception as e:
        print(f"   ❌ Error: {e}\n")
        return 0

def main():
    print("="*60)
    print("Hugging Face Download Speed Test")
    print("="*60)
    print()

    results = []
    for name, url, chunk_size in URLS:
        speed = test_speed(name, url, chunk_size)
        if speed > 0:
            results.append((name, speed))

    if results:
        print("="*60)
        print("Summary")
        print("="*60)
        avg_speed = sum(r[1] for r in results) / len(results)

        print(f"Average speed: {avg_speed:.1f} MB/s")
        print()

        # Estimate download times
        print("Estimated download times:")
        print(f"   Q8_0 (31.8 GB):  {31.8*1024/avg_speed/60:.0f} minutes")
        print(f"   Q5_K_M (21.4 GB): {21.4*1024/avg_speed/60:.0f} minutes")
        print(f"   BF16 Part 1 (49.9 GB): {49.9*1024/avg_speed/60:.0f} minutes")
        print(f"   BF16 Part 2 (10.0 GB): {10.0*1024/avg_speed/60:.0f} minutes")
        print(f"   BF16 Total: {(49.9+10.0)*1024/avg_speed/60:.0f} minutes")

if __name__ == "__main__":
    main()
