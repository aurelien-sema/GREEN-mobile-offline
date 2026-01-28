#!/usr/bin/env python3
"""Extract text from PDFs in tools/rag/input_pdfs/ and write chunks to JSON.

Outputs:
 - tools/rag/chunks.json  (list of {id, source, page, text, meta})

Usage:
 python index_pdfs.py
"""
import os
import json
import uuid
from pathlib import Path
import fitz  # PyMuPDF

INPUT_DIR = Path(__file__).parent / "input_pdfs"
OUTPUT = Path(__file__).parent / "chunks.json"

CHUNK_SIZE_CHARS = 1000
CHUNK_OVERLAP = 200


def extract_text_from_pdf(path: Path):
    doc = fitz.open(str(path))
    texts = []
    for page_no in range(len(doc)):
        page = doc[page_no]
        txt = page.get_text()
        texts.append((page_no + 1, txt))
    return texts


def chunk_text(text: str, size: int = CHUNK_SIZE_CHARS, overlap: int = CHUNK_OVERLAP):
    if not text:
        return []
    chunks = []
    start = 0
    L = len(text)
    while start < L:
        end = min(start + size, L)
        chunk = text[start:end]
        chunks.append(chunk.strip())
        if end == L:
            break
        start = max(0, end - overlap)
    return chunks


def main():
    all_chunks = []
    for pdf in sorted(INPUT_DIR.glob("*.pdf")):
        print(f"Processing {pdf.name}")
        try:
            pages = extract_text_from_pdf(pdf)
            for page_no, text in pages:
                page_chunks = chunk_text(text)
                for i, c in enumerate(page_chunks):
                    chunk_id = str(uuid.uuid4())
                    all_chunks.append({
                        "id": chunk_id,
                        "source": pdf.name,
                        "page": page_no,
                        "chunk_index": i,
                        "text": c,
                    })
        except Exception as e:
            print(f"Failed to extract {pdf}: {e}")

    with open(OUTPUT, "w", encoding="utf-8") as f:
        json.dump(all_chunks, f, ensure_ascii=False, indent=2)

    print(f"Wrote {len(all_chunks)} chunks to {OUTPUT}")


if __name__ == "__main__":
    main()
