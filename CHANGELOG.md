# Changelog — Wawa Fuerte

All notable changes to this app are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and versioning
follows [Semantic Versioning](https://semver.org/).

---

## [Unreleased]

_Hackathon sprint in progress — Build with Gemma: GDG Callao, 25 July 2026._

### Added (Repository scaffolding)

- **Architecture Decision Records** in [`docs/adr/`](docs/adr/README.md), recording the decisions
  that would be expensive to reverse: no backend and on-device only (ADR-0002), Android as the
  primary demo target (ADR-0003), `flutter_gemma` over MediaPipe for inference (ADR-0004), RAG over
  the INS recipe book instead of fine-tuning (ADR-0005), embeddings as SQLite BLOBs with in-memory
  similarity search (ADR-0006), hemoglobin always optional (ADR-0007), and the Gitflow branching
  model (ADR-0008). State management (ADR-0009) remains `Proposed` and must be closed at sprint
  start.
- **[`AGENTS.md`](AGENTS.md)** — working agreement defining the feature-first folder layout, a
  single owner per directory, and the mock-first parallel workflow that keeps four developers
  unblocked until the hour-4 integration checkpoint.
- **[`docs/FLOWS.md`](docs/FLOWS.md)** — screen-by-screen specification of the six user flows with
  the exact data requested per screen, including the optional CRED booklet step.
- **Community health files** — contributing guide, code of conduct, security policy, issue
  templates, and support guide.
- **CI** — a single GitHub Actions job running `dart format`, `flutter analyze` and `flutter test`
  on pull requests and on pushes to `main` and `develop`, with in-progress runs cancelled on
  re-push.
- **Repository hygiene** — `CODEOWNERS` mapping each area to its owner, a pull request template,
  `.editorconfig`, `.gitattributes`, and a Lefthook pre-commit hook running `dart format` on staged
  files.

[Unreleased]: https://github.com/Kntro-Soft/wawa-fuerte-app/commits/develop
