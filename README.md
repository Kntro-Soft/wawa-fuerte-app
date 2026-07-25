# Wawa Fuerte

> **100% offline** mobile app that generates weekly nutrition plans against childhood
> anemia, with **Gemma running on-device**. No backend, no connectivity.
>
> Build with Gemma: GDG Callao · SDG 2 (Zero Hunger) and SDG 3 (Good Health and Well-being)

## The problem

Peru has critical rates of childhood anemia, especially in rural and peri-urban areas where
families cannot always afford expensive supplements or daily red meat — and where connectivity
is intermittent or non-existent.

## The solution

A mother enters the cheap ingredients available in her region (sangrecita, spleen, quinoa,
tarwi, liver) and her budget. The app generates a balanced weekly menu to raise iron levels,
computing the real coverage against the child's requirement for their age.

**Everything runs inside the phone**: the model, the recipe book and the database. Zero network.

## Why this is different

- The [INS recipe book](https://anemia.ins.gob.pe/recetario-de-ninos) is official but
  **static**: it does not adapt to what the family actually has.
- International AI nutrition apps cover neither **Andean/Amazonian ingredients** nor
  contexts without connectivity.
- We combine the three things nobody puts together: dynamic generation + low-cost local
  ingredients + **genuinely offline** operation.

## Architecture

No server. Everything local:

```
[Bundled assets]
├── recetario_ins.json           → official INS recipes
├── ingredientes_regionales.json → ingredients by region/season/cost
└── embeddings_recetas.db        → PRECOMPUTED (BLOB in SQLite)

[Generated on the device]
├── perfil_nino        → supports SEVERAL children per family
├── planes_generados   → history and adherence
└── temporary photo    → never stored, processed and discarded
```

Gemma is **neither trained nor fine-tuned** — it is used pre-trained and specialised via
**prompting + RAG** over the INS recipe book, which avoids nutritional hallucinations.

## Getting started

```bash
flutter pub get
flutter run
```

> ⚠️ **Android is the primary target** ([ADR-0003](docs/adr/0003-android-as-primary-target.md)):
> the demo runs on a **physical Android phone**. Real Gemma inference cannot run on a simulator
> or emulator — it needs real hardware. To develop UI and logic without the model, use the
> `FakeInferenceService` — on the macOS machine that runs against the iOS Simulator. iOS remains
> buildable as a bonus, not as a deliverable.

The `.task` model is **not in the repo** (it weighs > 1 GB) — it is shared out-of-band (USB /
file transfer) and goes into `assets/models/`, which is git-ignored.

## Documentation

| Document | Contents |
|---|---|
| [AGENTS.md](AGENTS.md) | Working agreement, folder structure, who touches what |
| [docs/FLOWS.md](docs/FLOWS.md) | User flows with the exact data per screen |
| [docs/adr/](docs/adr/README.md) | Architecture Decision Records — the source of truth for technical decisions |

## Team

| Role | Area | Owner | Hardware |
|---|---|---|---|
| P1 | Inference engine (Gemma + MediaPipe), `pubspec.yaml`, `main.dart`, `android/` | [@sharvel-irigoyen](https://github.com/sharvel-irigoyen) — Javier Sharvel | Windows + Android |
| P2 | RAG + nutrition calculation, `ios/`, tech lead | [@jhosepmyr](https://github.com/jhosepmyr) — Jhosepmyr Orlando Gutierrez Soto | macOS + iPhone |
| P3 | UI, screens, TTS | [@farioraro](https://github.com/farioraro) — Carlos Alberto Ochoa Colonio | Windows + Android |
| P4 | Data and local persistence | [@Eric396](https://github.com/Eric396) — Eric Hernández | Windows + Android |

The inference module belongs to an Android developer on purpose: real inference can only be
validated on a physical handset, and three of the four devs have one
([ADR-0003](docs/adr/0003-android-as-primary-target.md)). The macOS machine does not install the
Android SDK; it owns the pure-Dart work (RAG, nutrition), which is verified with `flutter test`
and the iOS Simulator. These owners must stay in sync with
[`.github/CODEOWNERS`](.github/CODEOWNERS).

## Licensing

- **App code**: Apache License 2.0 — see [LICENSE](LICENSE).
- **Gemma model**: subject to Google's [Gemma Terms of Use](https://ai.google.dev/gemma/terms),
  including its Prohibited Use Policy. Not covered by this repository's license.
- **Recipe book data**: [Instituto Nacional de Salud (INS) — Peru](https://anemia.ins.gob.pe/recetario-de-ninos).
