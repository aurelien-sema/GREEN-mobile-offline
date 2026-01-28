#!/usr/bin/env python3

"""FastAPI server exposing a simple vector-search over precomputed embeddings.

Startup behavior:
 - Loads `chunks.json` and `embeddings.npy` into memory on start (only once).
 - Exposes POST /search with JSON {"query": "...", "top_k": 5}
     Returns the top_k chunks with scores.

Notes:
 - This server uses TensorFlow Hub (USE) to embed queries locally (no PyTorch).
 - The LLM (Gemini) generation should be called by the Flutter client using
    the retrieved chunks as context, or you can expand this server to call
    Gemini server-side later.
"""
import json
from pathlib import Path
from typing import List

import numpy as np
import tensorflow as tf
import tensorflow_hub as hub
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

BASE = Path(__file__).parent
CHUNKS_META = BASE / "chunks.json"
EMB_FILE = BASE / "embeddings.npy"

app = FastAPI(title="RAG Retrieval Service")


class SearchRequest(BaseModel):
    query: str
    top_k: int = 5


class SearchResult(BaseModel):
    id: str
    source: str
    page: int
    chunk_index: int
    text: str
    score: float


class SearchResponse(BaseModel):
    query: str
    results: List[SearchResult]


_chunks = []
_embeddings = None
_model = None

# TF-Hub model used to embed queries
TFHUB_MODEL = "https://tfhub.dev/google/universal-sentence-encoder/4"


def load_tf_model():
    print(f"Loading TF-Hub model {TFHUB_MODEL} for query embeddings...")
    model = hub.load(TFHUB_MODEL)
    return model


@app.on_event("startup")
def startup_load():
    global _chunks, _embeddings, _model
    if not CHUNKS_META.exists() or not EMB_FILE.exists():
        raise RuntimeError("Missing chunks.json or embeddings.npy. Run index_pdfs.py and build_embeddings.py first.")
    print("Loading chunks metadata (chunks.json)...")
    _chunks = json.loads(CHUNKS_META.read_text(encoding="utf-8"))
    print(f"Loaded {_chunks and len(_chunks) or 0} chunks")
    print("Loading embeddings...")
    _embeddings = np.load(EMB_FILE)
    print(f"Embeddings shape: {_embeddings.shape}")
    print("Loading TF model for query embeddings...")
    _model = load_tf_model()
    print("Ready: RAG index loaded in memory.")


def cosine_similarity(a: np.ndarray, b: np.ndarray):
    # a: (d,), b: (n, d)
    a_norm = a / np.linalg.norm(a)
    b_norm = b / np.linalg.norm(b, axis=1, keepdims=True)
    return np.dot(b_norm, a_norm)


@app.post("/search", response_model=SearchResponse)
def search(req: SearchRequest):
    if not req.query:
        raise HTTPException(status_code=400, detail="Empty query")
    global _chunks, _embeddings, _model
    # use TF model to embed query, result is a tf.Tensor
    q_emb = np.array(_model([req.query]))[0]
    scores = cosine_similarity(q_emb, _embeddings)
    topk = min(req.top_k, len(scores))
    idx = np.argsort(-scores)[:topk]
    results = []
    for i in idx:
        c = _chunks[int(i)]
        results.append(SearchResult(
            id=c.get("id"),
            source=c.get("source"),
            page=c.get("page", -1),
            chunk_index=c.get("chunk_index", 0),
            text=c.get("text", ""),
            score=float(scores[int(i)]),
        ))
    return SearchResponse(query=req.query, results=results)


@app.get("/health")
def health():
    return {"status": "ok", "chunks": len(_chunks)}


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("server:app", host="127.0.0.1", port=8000, reload=False)
