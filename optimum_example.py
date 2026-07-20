"""
OpenVINO-optimized causal LM inference example.

Setup:
    Set your Hugging Face token as an environment variable before running,
    instead of hardcoding it:

        export HF_TOKEN="hf_xxx"          # macOS/Linux
        setx HF_TOKEN "hf_xxx"            # Windows (new shell after)

    Or just run `huggingface-cli login` once and skip the env var entirely —
    the token will be cached locally and picked up automatically.
"""

import os
import sys
import time
from pathlib import Path

from huggingface_hub import login
from optimum.intel import OVModelForCausalLM
from transformers import AutoTokenizer, TextStreamer

# ---- Config ----------------------------------------------------------
MODEL_ID = "OpenVINO/phi-2-fp16-ov"
# MODEL_ID = "OpenVINO/TinyLlama-1.1B-Chat-v1.0-fp16-ov"
CACHE_DIR = Path("./model_cache")
PROMPT = "Write a short story about an AI."
MAX_NEW_TOKENS = 500
STREAM_OUTPUT = True  # print tokens as they're generated
# ------------------------------------------------------------------------


def authenticate() -> None:
    """Log in to Hugging Face Hub using a token from the environment.

    Falls back silently to a cached CLI login if HF_TOKEN isn't set —
    login() only needs to be called explicitly if you want to pass a token.
    """
    token = os.environ.get("HF_TOKEN")
    if token:
        login(token=token)
    else:
        print(
            "No HF_TOKEN environment variable found — relying on a cached "
            "`huggingface-cli login` session, if one exists.",
            file=sys.stderr,
        )


def pick_device() -> str:
    """Return 'GPU' if an OpenVINO-visible GPU is available, else 'CPU'."""
    try:
        import openvino as ov

        core = ov.Core()
        available = core.available_devices
        if any(d.startswith("GPU") for d in available):
            return "GPU"
    except Exception as e:
        print(f"Could not query OpenVINO devices ({e}); defaulting to CPU.", file=sys.stderr)
    return "CPU"


def load_model(model_id: str, device: str):
    try:
        model = OVModelForCausalLM.from_pretrained(
            model_id,
            ov_config={"CACHE_DIR": str(CACHE_DIR)},
            device=device,
        )
        tokenizer = AutoTokenizer.from_pretrained(model_id)
    except Exception as e:
        print(f"Failed to load model '{model_id}': {e}", file=sys.stderr)
        raise
    model.compile()
    return model, tokenizer


def main() -> None:
    authenticate()

    device = pick_device()
    print(f"Using device: {device}")

    model, tokenizer = load_model(MODEL_ID, device)

    inputs = tokenizer(PROMPT, return_tensors="pt")

    streamer = TextStreamer(tokenizer, skip_special_tokens=True) if STREAM_OUTPUT else None

    start_time = time.time()
    outputs = model.generate(
        **inputs,
        max_new_tokens=MAX_NEW_TOKENS,  # unlike max_length, this isn't affected by prompt length
        streamer=streamer,
    )
    elapsed = time.time() - start_time

    if not STREAM_OUTPUT:
        print(tokenizer.decode(outputs[0], skip_special_tokens=True))

    generated_tokens = outputs.shape[-1] - inputs["input_ids"].shape[-1]
    print(f"\nInference took {elapsed:.2f}s for {generated_tokens} new tokens "
          f"({generated_tokens / elapsed:.1f} tok/s)")


if __name__ == "__main__":
    main()
