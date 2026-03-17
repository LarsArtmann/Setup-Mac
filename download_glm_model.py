#!/usr/bin/env python3
"""Download GLM-4.7-Flash BF16 model from Hugging Face"""
import requests
import os
import time
from pathlib import Path

MODEL_DIR = Path.home() / ".ollama" / "models"
MODEL_DIR.mkdir(parents=True, exist_ok=True)

FILES = [
    ("GLM-4.7-Flash-BF16-00001-of-00002.gguf", 49.9),
    ("GLM-4.7-Flash-BF16-00002-of-00002.gguf", 10.0),
]

BASE_URL = "https://huggingface.co/unsloth/GLM-4.7-Flash-GGUF/resolve/main/BF16/"

def download_file(filename, expected_size_gb):
    """Download a file with progress tracking"""
    url = f"{BASE_URL}{filename}"
    filepath = MODEL_DIR / filename
    expected_size_bytes = expected_size_gb * 1024**3

    # Check if file exists and get its size
    if filepath.exists():
        existing_size = filepath.stat().st_size
        print(f"✅ File exists: {filename}")
        print(f"   Size: {existing_size / 1024**3:.2f} GB / {expected_size_gb:.2f} GB")
        print(f"   {existing_size / expected_size_bytes * 100:.1f}% complete")

        # If file is complete, skip
        if existing_size >= expected_size_bytes * 0.99:
            print(f"   Download already complete! ✅\n")
            return True

        # Otherwise, resume download
        headers = {"Range": f"bytes={existing_size}-"}
        print(f"   Resuming download from byte {existing_size}...\n")
    else:
        headers = {}
        existing_size = 0
        print(f"📥 Downloading: {filename}")
        print(f"   Expected size: {expected_size_gb:.2f} GB\n")

    # Stream download
    try:
        mode = "ab" if existing_size > 0 else "wb"
        with requests.get(url, headers=headers, stream=True, timeout=600) as r:
            r.raise_for_status()
            total_size = int(r.headers.get('content-length', 0))
            initial_size = existing_size
            start_time = time.time()

            with open(filepath, mode) as f:
                for chunk in r.iter_content(chunk_size=8*1024*1024):  # 8MB chunks
                    if chunk:
                        f.write(chunk)
                        current_size = f.tell()
                        elapsed = time.time() - start_time

                        # Calculate progress and speed
                        downloaded = current_size - initial_size
                        progress = (current_size / expected_size_bytes) * 100
                        speed = (downloaded / (1024**2)) / elapsed if elapsed > 0 else 0

                        # Clear line and show progress
                        print(f"\r   Progress: {progress:.1f}% | "
                              f"{current_size/1024**3:.2f}/{expected_size_gb:.2f} GB | "
                              f"{speed:.1f} MB/s   ", end="", flush=True)

        print(f"\n   ✅ Complete: {filename}")
        final_size = filepath.stat().st_size
        print(f"   Final size: {final_size / 1024**3:.2f} GB\n")
        return True

    except Exception as e:
        print(f"\n   ❌ Error downloading {filename}: {e}\n")
        return False

def main():
    print("="*60)
    print("Downloading GLM-4.7-Flash BF16 Model")
    print("="*60)
    print(f"Target directory: {MODEL_DIR}")
    print(f"Total size: 59.9 GB (2 files)")
    print()

    success_count = 0
    for filename, size_gb in FILES:
        if download_file(filename, size_gb):
            success_count += 1

    print("="*60)
    if success_count == len(FILES):
        print("✅ All files downloaded successfully!")
        print()
        print("Next steps:")
        print("1. Run benchmark:")
        print("   python benchmark_ollama.py glm-4.7-flash:bf16 512 256 3")
    else:
        print(f"⚠️  {success_count}/{len(FILES)} files downloaded")
        print("You can re-run to resume partial downloads")
    print("="*60)

if __name__ == "__main__":
    main()
