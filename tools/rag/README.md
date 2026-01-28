RAG tools and server

Overview
- input PDFs: tools/rag/input_pdfs/  (place your .pdf files here)
- index_pdfs.py: extracts text and writes tools/rag/chunks.json
- build_embeddings.py: computes embeddings and writes tools/rag/embeddings.npy and tools/rag/chunks_with_meta.json
- server.py: FastAPI service that loads the embeddings and chunks into memory at startup and exposes /search

Quick start (Linux)

1) Create a venv and install dependencies:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

2) Extract and index PDFs (using TensorFlow-based embeddings):

```bash
python index_pdfs.py
python build_embeddings.py
```

Note: `build_embeddings.py` uses Universal Sentence Encoder (TF-Hub). The model will be downloaded at first run and can be large (~1GB). Ensure you have enough disk space and a stable network connection.

3) Start the server (loads index into memory at startup):

```bash
python server.py
```

4) Search example (curl):

```bash
curl -X POST -H "Content-Type: application/json" -d '{"query":"maladie feuille", "top_k":3}' http://127.0.0.1:8000/search
```

Integration with Flutter / Gemini
- The server returns the most relevant chunks and their text. The Flutter client can call the existing `google_generative_ai` Dart package to send a generation request to Gemini, providing the retrieved chunks as context in the prompt.
- Alternatively, you can extend `server.py` to call a hosted LLM (Gemini) server-side — add your credentials and implement a call in `server.py`.

Security
- Do not commit credentials to the repo. Use environment variables or secure secret stores.

*** End of README
