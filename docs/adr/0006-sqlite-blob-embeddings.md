# 0006. Embeddings as SQLite BLOBs with in-memory search

- Status: Accepted
- Date: 2026-07-25
- Deciders: Kntro-Soft team

## Context

ADR-0005 requires retrieval over the INS recipe book. That corpus is small — on the order of tens
of recipes, not thousands.

The obvious options for vector search on-device are:

- **`sqlite-vec`** — a modern SQLite extension with a native vector column type and KNN in SQL.
- **`sqlite-vss`** — older, Faiss-backed, built for very large corpora.
- **Plain BLOB columns** with cosine similarity computed in Dart.

Both extensions are native artifacts that must be compiled and linked per platform. At this corpus
size their index structures provide no measurable benefit over a linear scan.

## Decision

Store each recipe's embedding as a **`BLOB` in ordinary SQLite** and compute cosine similarity in
Dart over all vectors held in memory.

```sql
CREATE TABLE recipe_embeddings (
  recipe_id INTEGER PRIMARY KEY,
  recipe_text TEXT,
  embedding BLOB          -- float32 vector, serialised to bytes
);
```

- Embeddings are **precomputed before the sprint** by a separate script and shipped as an asset.
  Nothing is embedded at runtime on the device.
- All vectors are loaded once at startup; they total a few hundred KB.
- Retrieval is a linear scan returning the top-k matches.

## Consequences

- Zero native dependencies for search, so no per-platform build configuration and no chance of an
  extension failing to load on a specific Android device.
- Search latency is negligible at this corpus size and is not on the critical path — model inference
  dominates end-to-end time by orders of magnitude.
- Precomputing embeddings removes an embedding model from the app entirely, shrinking the bundle and
  removing a second inference path to debug.
- This does not scale. Growing the corpus to thousands of recipes would justify revisiting
  `sqlite-vec` in a superseding ADR.
- Because embeddings are a build-time artifact, changing the recipe corpus means re-running the
  script and shipping a new asset — the data is not editable at runtime.
