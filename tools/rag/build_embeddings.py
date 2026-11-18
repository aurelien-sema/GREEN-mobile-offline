#!/usr/bin/env python3
"""Compute embeddings for chunks.json using TensorFlow Hub (USE).

Produces:
 - tools/rag/embeddings.npy  (numpy array of shape (n_chunks, dim))
 - tools/rag/chunks_with_meta.json (copy of chunks.json for metadata)

Usage:
 python build_embeddings.py
"""
import json
from pathlib import Path
import numpy as np
import tensorflow as tf
import tensorflow_hub as hub

BASE = Path(__file__).parent
CHUNKS_IN = BASE / "chunks.json"
CHUNKS_OUT = BASE / "chunks_with_meta.json"
EMB_OUT = BASE / "embeddings.npy"
# also write a float32 binary into the Flutter assets folder so the app can load it in release builds
EMB_BIN_OUT = Path(__file__).parent.parent / "assets" / "rag" / "embeddings_f32.bin"
CHUNKS_ASSETS_OUT = Path(__file__).parent.parent / "assets" / "rag" / "chunks.json"

# Universal Sentence Encoder (TensorFlow Hub)
TFHUB_MODEL = "https://tfhub.dev/google/universal-sentence-encoder/4"


def load_use_model():
    print(f"Loading TF-Hub model {TFHUB_MODEL} (this may download ~1GB)...")
    model = hub.load(TFHUB_MODEL)
    return model


def compute_embeddings(model, texts):
    # model returns tf.Tensor
    emb = model(texts)
    return np.array(emb)


def main():
    if not CHUNKS_IN.exists():
        raise SystemExit(f"Missing {CHUNKS_IN}. Run index_pdfs.py first.")
    chunks = json.loads(CHUNKS_IN.read_text(encoding="utf-8"))
    texts = [c.get("text", "") for c in chunks]
    model = load_use_model()
    print("Computing embeddings (TF)...")
    embeddings = compute_embeddings(model, texts)
    np.save(EMB_OUT, embeddings)
    print(f"Saved embeddings to {EMB_OUT}")
    # Save raw float32 binary for Flutter (assets)
    EMB_BIN_OUT.parent.mkdir(parents=True, exist_ok=True)
    embeddings.astype("float32").tofile(EMB_BIN_OUT)
    print(f"Saved float32 binary embeddings to {EMB_BIN_OUT}")
    # save metadata copy
    CHUNKS_OUT.write_text(json.dumps(chunks, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Saved chunks meta to {CHUNKS_OUT}")
    # also write a copy into app assets so Flutter can load them in release builds
    CHUNKS_ASSETS_OUT.parent.mkdir(parents=True, exist_ok=True)
    CHUNKS_ASSETS_OUT.write_text(json.dumps(chunks, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Saved chunks metadata to app assets {CHUNKS_ASSETS_OUT}")


if __name__ == "__main__":
    # Enable TF memory growth to be safer on limited machines
    gpus = tf.config.experimental.list_physical_devices("GPU")
    if gpus:
        try:
            for gpu in gpus:
                tf.config.experimental.set_memory_growth(gpu, True)
        except Exception:
            pass
    main()
