# 0014. Free-text ingredient extraction and application-level function calling

- Status: Accepted
- Date: 2026-07-25
- Deciders: Kntro-Soft team

## Context

Two gaps remained after the on-device Gemma path was wired up (ADR-0004):

1. Flow B's checklist is closed by design, but a caregiver typing "tengo lo que sobró del almuerzo,
   papa y un poco de hígado" instead of tapping chips is a realistic input a fuzzy string match
   cannot parse — it needs to understand the sentence, not just normalise spelling.
2. The hackathon's "Autonomous Agent Excellence" recognition rewards genuine function calling, not a
   longer prompt. `IronCalculator` was the obvious candidate: it is already the one number in the app
   that must never be model output (ADR-0005).

The naive answer to (1) is a second embedding model, which ADR-0006 already rejected for the
23-recipe corpus on cost grounds — the same reasoning applies here: no second multi-hundred-MB model
for a problem this small.

The naive answer to (2) is `flutter_gemma`'s native `Tool` / `tools_json` path. That targets
`ModelType.gemma4` specifically (the package's own doc comment: *"Native tool calling (Gemma 4 → SDK
tools_json)"*). The checkpoint this app ships is `gemma3-1b-it` — a smaller, earlier, text-only
model. Depending on native tool calling here would be relying on behaviour never verified against the
model actually running.

## Decision

**Reuse the already-loaded Gemma instance for both**, at the application level rather than through
native SDK features scoped to a different model.

### Free-text ingredients — `IngredientExtractor`

A single extra short-lived call to `InferenceService.generateText` (a new method added to the
interface for this), constrained to a **closed vocabulary**: the prompt hands the model the exact
list of ingredient names the retriever knows how to match and asks it to return only the subset it
recognises, as a JSON array. Anything outside that vocabulary is dropped by the parser, not passed
through — the model is allowed to *select*, never to *name* an ingredient unprompted.

This is retrieval-adjacent but is explicitly **not** the vector-embedding RAG ADR-0006 rejected: no
second model, no vector store, no similarity search. `InsRecipeRetriever`'s deterministic
overlap-and-iron-density ranking (ADR-0011) runs unchanged afterward; only how the ingredient list
gets populated changes.

### Function calling — `PlanVerificationAgent`

The model is asked which of two functions to run — `checkIronCoverage` or `checkBudget` — and
returns that choice as JSON. The app parses it and dispatches to the real Dart implementation
(`IronCalculator.coverageOf`, a `Recipe.referenceCostPen` sum). **The model never computes the
number.** This extends ADR-0005's guarantee rather than relaxing it: before, the app called the
function; now, the model decides *that* a function should be called and *which* one, but the app is
still the only thing that ever calls it.

`checkBudget`'s result is explicitly reported as an estimate — `referenceCostPen` is not from an
official source (ADR-0011) — so this can only ever validate a rough sort, never a guaranteed figure.

Any malformed or unparseable model response falls back to `PlanTool.checkIronCoverage`: a caregiver
seeing the coverage bar matters more than the model having successfully chosen how to compute it.

## Consequences

- Zero additional model weights, zero additional native dependencies. The entire feature is ~200
  lines of Dart calling a method that already existed for the plan itself.
- Both features are pure request/response over a scripted `InferenceService`, so they are unit-tested
  without a model or a device (`test/rag/ingredient_extractor_test.dart`,
  `test/nutrition/plan_verification_agent_test.dart`) — the same pattern as `buildPrompt` in
  `GemmaInferenceService` (ADR-0004).
- The Autonomous Agent story is honestly narrower than native tool calling would suggest: the model
  chooses between two hand-written functions from a two-line menu, not an open function-calling loop
  with arbitrary tools and arguments. That is what is safely claimable on `gemma3-1b-it`; the writeup
  should not overstate it.
- If the checkpoint is later upgraded to a `gemma4` variant, `flutter_gemma`'s native `Tool` path
  becomes available and this application-level orchestration can be superseded — but only once it is
  verified against that model, not assumed to work by analogy.
- `InferenceService.generateText` is now part of the interface every implementation must satisfy;
  `FakeInferenceService` echoes its input back, which is enough for tests that only need a
  deterministic, non-empty response and never asserts anything about content.
