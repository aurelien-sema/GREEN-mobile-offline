#!/usr/bin/env python3
"""Compute embeddings for chunks.json using the Gemini Embedding API
(models/text-embedding-004), so the vector space matches exactly what the
Flutter app produces at query time via google_generative_ai's embedContent.

IMPORTANT: this replaces the previous Universal Sentence Encoder (TF-Hub,
512-dim) pipeline. USE and Gemini embeddings live in *different* vector
spaces — mixing them silently produces meaningless cosine-similarity scores
(see RagService's dimension guard). Re-running this script fully replaces
embeddings_f32.bin with 768-dim Gemini vectors; there is no partial/mixed
state.

Produces:
 - tools/rag/embeddings.npy  (numpy array of shape (n_chunks, dim))
 - tools/rag/chunks_with_meta.json (copy of chunks.json for metadata)
 - assets/rag/embeddings_f32.bin (float32 binary consumed by the Flutter app)
 - assets/rag/chunks.json (copy of chunks.json consumed by the Flutter app)

Usage:
 export GEMINI_API_KEY=your_key_here   # same key used by the Flutter app
 python build_embeddings.py
"""
import json
import os
import time
from pathlib import Path

import numpy as np
import google.generativeai as genai

BASE = Path(__file__).parent
CHUNKS_IN = BASE / "chunks.json"
CHUNKS_OUT = BASE / "chunks_with_meta.json"
EMB_OUT = BASE / "embeddings.npy"
EMB_BIN_OUT = Path(__file__).parent.parent.parent / "assets" / "rag" / "embeddings_f32.bin"
CHUNKS_ASSETS_OUT = Path(__file__).parent.parent.parent / "assets" / "rag" / "chunks.json"

# Doit correspondre exactement au modèle utilisé côté Flutter
# (lib/services/gemini/gemini_service.dart) pour que la requête et les
# documents vivent dans le même espace vectoriel.
EMBEDDING_MODEL = "models/text-embedding-004"
EXPECTED_DIM = 768

BATCH_SIZE = 100  # max accepté par embed_content en mode batch
MAX_RETRIES = 5


def load_api_key() -> str:
    key = os.environ.get("GEMINI_API_KEY")
    if not key:
        raise SystemExit(
            "GEMINI_API_KEY manquant. Exportez la même clé que celle utilisée "
            "par l'application Flutter avant de lancer ce script."
        )
    return key


def embed_batch(texts, retries=MAX_RETRIES):
    """Embed a batch of texts as RETRIEVAL_DOCUMENT vectors, with backoff on rate limits."""
    delay = 2
    for attempt in range(retries):
        try:
            result = genai.embed_content(
                model=EMBEDDING_MODEL,
                content=texts,
                task_type="RETRIEVAL_DOCUMENT",
            )
            return result["embedding"]
        except Exception as e:
            if attempt == retries - 1:
                raise
            print(f"  Erreur d'embedding ({e}), nouvelle tentative dans {delay}s...")
            time.sleep(delay)
            delay = min(delay * 2, 30)


def compute_embeddings(texts):
    all_vectors = []
    for i in range(0, len(texts), BATCH_SIZE):
        batch = texts[i : i + BATCH_SIZE]
        print(f"  Embedding chunks {i}..{i + len(batch) - 1} / {len(texts)}")
        vectors = embed_batch(batch)
        all_vectors.extend(vectors)
    return np.array(all_vectors, dtype="float32")


def main():
    if not CHUNKS_IN.exists():
        raise SystemExit(f"Missing {CHUNKS_IN}. Run index_pdfs.py first.")

    genai.configure(api_key=load_api_key())

    chunks = json.loads(CHUNKS_IN.read_text(encoding="utf-8"))
    texts = [c.get("text", "") for c in chunks]

    print(f"Computing {EMBEDDING_MODEL} embeddings for {len(texts)} chunks...")
    embeddings = compute_embeddings(texts)

    if embeddings.shape[1] != EXPECTED_DIM:
        raise SystemExit(
            f"Dimension inattendue : {embeddings.shape[1]} (attendu {EXPECTED_DIM}). "
            "Le modèle d'embedding a peut-être changé côté API — mettez à jour "
            "EXPECTED_DIM ici et la constante correspondante côté Flutter (RagService)."
        )

    np.save(EMB_OUT, embeddings)
    print(f"Saved embeddings to {EMB_OUT}")

    EMB_BIN_OUT.parent.mkdir(parents=True, exist_ok=True)
    embeddings.tofile(EMB_BIN_OUT)
    print(f"Saved float32 binary embeddings to {EMB_BIN_OUT}")

    CHUNKS_OUT.write_text(json.dumps(chunks, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Saved chunks meta to {CHUNKS_OUT}")

    CHUNKS_ASSETS_OUT.parent.mkdir(parents=True, exist_ok=True)
    CHUNKS_ASSETS_OUT.write_text(json.dumps(chunks, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Saved chunks metadata to app assets {CHUNKS_ASSETS_OUT}")

    print(
        "\nTerminé. Reconstruisez l'application (les assets sont embarqués au "
        "build) pour que le nouveau fichier embeddings_f32.bin soit utilisé."
    )


if __name__ == "__main__":
    main()
