# AGENTS.md

Working agreement for the 4 devs (and for any AI agent touching this repo).
**6-hour sprint. Priority: get the demo running on a physical Android phone. Not architectural
purity.**

## Purpose

Flutter mobile app that generates weekly nutrition plans against childhood anemia,
using **Gemma running 100% on-device**. Everything (model, recipe book, database) lives inside
the device, and **the default build has no backend and opens no socket**.

Since [ADR-0015](docs/adr/0015-hosted-nutrition-agent.md) a build may *opt in* to the hosted
nutrition agent by compiling in a channel key. That is the only network path in the app, it is
off by default, and the on-device path stays fully working.

## Big Picture

- Flutter stable + Dart 3. State management: **decided at minute 0** →
  see [ADR-0009](docs/adr/0009-state-management.md).
- **Android is the primary target** ([ADR-0003](docs/adr/0003-android-as-primary-target.md)). The
  demo runs on a physical Android phone; CI, testing and the "does it work" bar are defined
  against Android. iOS stays buildable as a bonus, not as a deliverable.
- Inference: `flutter_gemma` over the MediaPipe LLM Inference API
  ([ADR-0004](docs/adr/0004-flutter-gemma-over-mediapipe.md)). **A physical phone is mandatory**
  — no simulator or emulator can run the model (the iOS Simulator is CPU-only with a 256 MB Metal
  cap). This is why P1 (inference) is one of the Android devs.
- The Gemma model is a pre-trained black box: **it is neither trained nor fine-tuned**.
  It is specialised via **prompting + RAG** over the INS recipe book
  ([ADR-0005](docs/adr/0005-rag-instead-of-fine-tuning.md)).
- The **ADRs in `docs/adr/` are the source of truth**. If this file contradicts an ADR, the ADR
  wins and this file gets fixed.

## Who is who

| Role | Area | Owner | Hardware |
|---|---|---|---|
| P1 | Inference, `pubspec.yaml`, `main.dart`, `android/` | @sharvel-irigoyen | Windows + Android |
| P2 | RAG + nutrition, `ios/`, tech lead | @jhosepmyr | macOS + iPhone |
| P3 | UI, screens, TTS | @farioraro | Windows + Android |
| P4 | Data and local persistence | @Eric396 | Windows + Android |

The three Windows devs install Flutter + the Android SDK and test on their own handsets. The
macOS dev does **not** install the Android SDK and develops non-inference work against the iOS
Simulator, which Xcode already provides. Anything platform-specific (permissions, file paths, TTS
voices) must be checked on Android before it counts as done, even if it looked fine on iOS.

```
lib/
  core/
    inference/   # Gemma + MediaPipe.        OWNER: P1
    remote/      # hosted agent (ADR-0015).  OWNER: P1
    rag/         # recipe search.            OWNER: P2
    nutrition/   # iron calculation.         OWNER: P2
    storage/     # local SQLite/Hive.        OWNER: P4
    theme/       # colors, typography.       OWNER: P3
  features/
    onboarding/  # Flow 0 + A.               OWNER: P3
    home/        # Flow E (child selector).  OWNER: P3
    plan/        # Flow B + D.               OWNER: P3
  main.dart                                # OWNER: P1
assets/
  data/          # recetario_ins.json, etc.  OWNER: P4
  models/        # Gemma .task (git-ignored, >1GB)
```

## Non-negotiable rules

- **Nobody commits the `.task` model** — it weighs more than 1 GB and blows up the repo. It goes
  in `assets/models/`, which is git-ignored. It is shared out-of-band (USB / file transfer).
- **No API keys in the repository.** The default build is 100% offline. Plan generation may
  optionally run against the hosted nutrition agent ([ADR-0015](docs/adr/0015-hosted-nutrition-agent.md)),
  and that key is supplied at build time with `--dart-define=QONPANIA_API_KEY=…` — never committed,
  never given a default in the source. If you need any *other* key, raise it first.
- **Only P1 edits `pubspec.yaml` and `main.dart`.** If you need a package, ask for it — do not
  add it yourself. `pubspec.yaml` is the #1 source of merge conflicts with 4 devs.
- **Do not edit another owner's folders.** If your change crosses boundaries, ask in the chat.
- **`main` always builds.** If your PR breaks startup it gets reverted — `main` is not where we
  debug.
- **The hemoglobin value is OPTIONAL everywhere in the code.** Never assume it exists; the app
  must generate a standard age-based preventive plan when it is `null`. See `docs/FLOWS.md`.

## Working in parallel without blocking each other

For the first hours **everyone works against mocks**, nobody waits for anybody:

- P3 (UI) uses a `FakeInferenceService` that returns a hardcoded plan.
- P2 (RAG) tests search against a `recetario_ins.json` with 5 sample recipes.
- P1 validates Gemma on a physical Android phone with a standalone prompt, without depending on
  the UI. Native linking is the highest-risk task of the sprint: validate it in hour 1.
- P4 builds the data schema and fills it with seeds.

Real integration happens at the **hour-4 checkpoint**, not before.

## Commands

```
flutter pub get
flutter run                  # physical Android phone (real Gemma) or,
                             # on the macOS machine, the iOS Simulator with the fake service
dart format .
flutter analyze
flutter test
```

## Working Agreement

- Before creating a new screen, open the closest existing one and **copy its folder structure,
  naming and widget shape**. Consistency is worth more than elegance.
- If this file and the code disagree: **the code wins**. Update this file.
- **Branches (Gitflow)**: `main` (release/demo) ← `develop` (integration) ← `feature/*`,
  `bugfix/*`, `hotfix/*`. Never commit directly to `main` or `develop`. Those are the ONLY branch
  prefixes: `chore`, `docs`, `ci` are commit types, **not** branch prefixes.
- **Commits**: Conventional Commits, `<type>(<scope>): description` — e.g.
  `feat(plan): add iron coverage calculation`. Scopes: `inference`, `rag`, `nutrition`, `storage`,
  `onboarding`, `home`, `plan`, `ci`, `docs`.
- **Atomic commits**: one logical change per commit. No large commits mixing things together —
  they cannot be reviewed or reverted separately.
- CODEOWNERS notifies the area owner but **does not block the merge** (it would block 4 devs who
  are all coding at once). The gate is a red CI, not a person.
