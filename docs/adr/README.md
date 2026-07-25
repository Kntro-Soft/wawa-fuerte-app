# Architecture Decision Records

This directory records the significant architectural decisions for Wawa Fuerte using
[Michael Nygard's ADR format](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions).

Each ADR is immutable once accepted. To change a decision, add a new ADR that **supersedes** the old
one (and update the old one's status).

## Index

| ADR                                                        | Title                                             | Status   |
|------------------------------------------------------------|---------------------------------------------------|----------|
| [0001](./0001-record-architecture-decisions.md)            | Record architecture decisions                     | Accepted |
| [0002](./0002-no-backend-on-device-only.md)                | No backend, on-device only                        | Accepted |
| [0003](./0003-android-as-primary-target.md)                | Android as the primary demo target                | Accepted |
| [0004](./0004-flutter-gemma-over-mediapipe.md)             | On-device inference with flutter_gemma            | Accepted |
| [0005](./0005-rag-instead-of-fine-tuning.md)               | RAG over the INS recipe book instead of fine-tuning | Accepted |
| [0006](./0006-sqlite-blob-embeddings.md)                   | Embeddings as SQLite BLOBs with in-memory search  | Accepted |
| [0007](./0007-hemoglobin-is-always-optional.md)            | Hemoglobin is always optional                     | Accepted |
| [0008](./0008-gitflow-branching.md)                        | Gitflow branching model                           | Accepted |
| [0009](./0009-state-management.md)                         | State management library                          | Proposed |
| [0010](./0010-macos-as-development-target.md)              | macOS as a development-only target                | Accepted |
| [0012](./0012-iron-requirement-tables.md)                  | Iron requirement tables from INS/FAO-WHO          | Accepted |
| [0013](./0013-local-persistence-schema.md)                 | Local persistence schema for profiles and plans   | Accepted |

## Template

```markdown
# NNNN. Title

- Status: Proposed | Accepted | Deprecated | Superseded by ADR-XXXX
- Date: YYYY-MM-DD
- Deciders: <names>

## Context
<the forces at play, the problem>

## Decision
<what we decided>

## Consequences
<positive, negative, and neutral outcomes>
```
