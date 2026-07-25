# 0004. On-device inference with flutter_gemma

- Status: Accepted
- Date: 2026-07-25
- Deciders: Kntro-Soft team

## Context

ADR-0002 rules out any server-side inference, so the model must execute inside the Flutter app.
The realistic options for running Gemma on-device from Flutter are:

- **`flutter_gemma`** — a published package wrapping MediaPipe's LLM Inference API, supporting
  `.task` and `.litertlm` formats on Android, iOS, and Web.
- **Hand-rolled platform channels** to MediaPipe or LiteRT — full control, but it means writing and
  debugging Kotlin/Swift interop inside a 6-hour sprint.

Model weights are over 1 GB. Committing them would blow past GitHub's file-size limits and make
every clone unusable.

## Decision

Use **`flutter_gemma`** over MediaPipe's LLM Inference API, with a quantized Gemma checkpoint.

- The model file lives in `assets/models/` which is **git-ignored**, and is distributed to the team
  out-of-band (USB / file transfer).
- All inference goes through a single `InferenceService` interface with two implementations: the
  real `GemmaInferenceService` and a `FakeInferenceService` returning a hardcoded plan.
- The fake is the default during development so that UI, RAG, storage, and nutrition work proceed
  without a device and without waiting on the model.

## Consequences

- Everyone except the inference owner is unblocked from minute zero; nobody idles waiting for the
  model to load.
- The interface seam means a total failure of the on-device path degrades to a demoable app with a
  canned plan, rather than to nothing.
- Native linking is the highest-risk task in the sprint and must be validated in the first hour, not
  discovered at hour four. This is the single item that can invalidate the whole approach.
- Because the weights are not in the repo, a fresh clone cannot run real inference until the model
  is copied in. This must be stated in the README or reviewers will assume the app is broken.
- Model load time and memory pressure on mid-range Android hardware are unknown until measured; the
  quantization level may need to be reduced late in the sprint.
