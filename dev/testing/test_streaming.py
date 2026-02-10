#!/usr/bin/env python3
"""
Test streaming generation for large token counts
"""
import requests
import json

OLLAMA_URL = "http://127.0.0.1:11434"

def test_streaming(model_name, prompt, max_tokens=10000):
    """Test streaming generation"""

    print(f"🚀 Testing streaming generation with {model_name}")
    print(f"   Max tokens: {max_tokens}")
    print(f"   Prompt length: {len(prompt)} characters")
    print()

    # Streaming request
    response = requests.post(
        f"{OLLAMA_URL}/api/generate",
        json={
            "model": model_name,
            "prompt": prompt,
            "stream": True,
            "options": {
                "num_predict": max_tokens,
                "temperature": 0.7,
                "top_p": 0.9
            }
        },
        stream=True,
        timeout=600
    )

    total_tokens = 0
    char_count = 0
    start_time = None

    print("📝 Streaming output...")
    print("-" * 60)

    try:
        for line in response.iter_lines():
            if line:
                if start_time is None:
                    import time
                    start_time = time.time()

                data = json.loads(line)
                token = data.get("response", "")

                if token:
                    print(token, end="", flush=True)
                    total_tokens += 1
                    char_count += len(token)

                if data.get("done", False):
                    break

        print()
        print("-" * 60)

        if start_time:
            import time
            total_time = time.time() - start_time
            tps = total_tokens / total_time if total_time > 0 else 0

            print(f"\n📊 Results:")
            print(f"   Tokens generated: {total_tokens} / {max_tokens}")
            print(f"   Characters: {char_count}")
            print(f"   Time: {total_time:.2f}s")
            print(f"   Speed: {tps:.2f} tokens/second")

    except Exception as e:
        print(f"\n❌ Error: {e}")

if __name__ == "__main__":
    # Large coding prompt
    prompt = """You are an expert programmer. Write a complete, production-ready application.

Requirements:
- Full-stack web application
- REST API with Node.js/Express
- PostgreSQL database
- React frontend
- Authentication system
- Real-time notifications
- Unit tests
- Docker deployment

Generate all the code with detailed comments and documentation."""

    test_streaming("gpt-oss:20b", prompt, max_tokens=10000)
