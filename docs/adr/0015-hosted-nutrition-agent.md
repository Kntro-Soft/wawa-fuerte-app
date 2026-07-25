# 0015. Optional hosted nutrition agent for plan generation

- Status: Accepted
- Date: 2026-07-25
- Deciders: Kntro-Soft team
- Amends: [ADR-0002](0002-no-backend-on-device-only.md)

## Context

[ADR-0002](0002-no-backend-on-device-only.md) rules out a server, and its
reasoning has not stopped being true: connectivity in rural Peru is intermittent,
and health data about minors should not travel. It also says, explicitly, that a
feature which inherently needs a server "would require superseding this ADR".
This is that ADR.

Two things pushed against the offline-only position:

1. **Gemma 3 1B is at the edge of the task.** It sequences a list of recipe names
   acceptably, but it cannot reliably produce quantities and preparation steps
   for a specific child, and it cannot hold a strict output format while doing
   it. The plan a caregiver reads is thinner than the one the pitch describes.
2. **The model file is a distribution problem.** 557 MB shared out-of-band, on
   handsets that may not have the storage, is a demo risk on the day.

Qonpania operates a hosted nutrition agent behind a two-level mobile API: a
channel API key identifies the app, and a Sanctum token identifies the device's
contact. It returns a full seven-day menu as strict JSON.

## Decision

Add the hosted agent as an **optional third `InferenceService`**, alongside
on-device Gemma and the fake. It is off unless a channel key is compiled in:

```
flutter run --dart-define=QONPANIA_API_KEY=qpa_xxxxxxxx
```

With no key the app opens no socket and ADR-0002 holds unchanged, which is what
keeps `flutter test`, CI, and the airplane-mode demo working. Precedence when
several are available: hosted agent → on-device Gemma → fake.

### What crosses the wire, and what does not

Sent: the child's **age in months**, region, the pantry ingredients and budget
the caregiver typed, the retrieved INS recipe names, and — when a hemoglobin
reading exists — that value. Plus a random per-install identifier and, if she
gave one, the caregiver's own first name.

Never sent: the child's name, date of birth, the CRED check-up date, any stored
plan, any photo, or anything at all when no key is compiled in. The database
still never leaves the phone (ADR-0013).

Hemoglobin is the one genuinely sensitive field that does travel. It travels
because a plan that ignores it is the wrong plan, and it travels attached to an
age and a random identifier rather than to a named child.

### The grounding survives the move

The remote path is not allowed to be the weak path:

- The prompt is **the same text** as the on-device one — `plan_prompt_builder.dart`
  builds it for both, and only the requested response format differs. The agent
  is handed the retrieved INS candidates and told to copy their names verbatim.
- `QonpaniaPlanParser` matches each returned `titulo_plato` back against those
  candidates. A match inherits the INS recipe's transcribed `ironMg` and cost
  ([ADR-0011](0011-ins-recipe-data-provenance.md)).
- A dish that matches nothing still reaches the screen, with the agent's own
  ingredients and steps, but with **zero iron**. Its iron is genuinely unknown,
  and the corpus notes are already explicit that understating iron is the safe
  direction for a child-nutrition app.
- `meta_hierro_cubierta_porcentaje` is discarded. Coverage stays local
  arithmetic over sourced figures ([ADR-0005](0005-rag-instead-of-fine-tuning.md),
  [ADR-0012](0012-iron-requirement-tables.md)). A model's opinion of its own plan
  is not evidence.

## Consequences

- The offline claim narrows: it is now "the app works offline, and works better
  online" rather than "the app has no network". The airplane-mode demo still
  runs, but it runs the on-device path, and that has to be said honestly rather
  than glossed.
- Hemoglobin readings reach a third party. That is a real change in the privacy
  posture ADR-0002 chose deliberately, and it is the part of this decision most
  worth revisiting.
- The API key ships inside the APK. `--dart-define` is a deployment
  convenience, not a secret store — a released build has published its key, and
  rotation is a panel operation. A key committed to this repository would be
  worse still, which is why there is no default value anywhere in the source.
- The release `AndroidManifest.xml` now declares `INTERNET`. It previously did
  not; only the debug and profile manifests did, so this would have worked for
  every developer and failed on the demo handset.
- Two response formats now exist for one task, so a generator and a parser must
  be chosen together. `PlanPipeline` in `app/providers.dart` makes that one
  decision instead of two independent ones.
- Every network failure is one `QonpaniaException`, which `PlanController`
  already turns into its existing retryable failure state. No new error screen.
