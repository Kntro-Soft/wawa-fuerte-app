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

> ⚠️ Real Gemma inference requires a **physical iPhone**. The iOS Simulator is CPU-only with
> a 256 MB Metal cap and cannot run the model. To develop UI without the model, use the
> `FakeInferenceService`.

The `.task` model is **not in the repo** (it weighs > 1 GB) — it is shared over AirDrop/USB and
goes into `assets/models/`, which is git-ignored.

## Documentation

| Document | Contents |
|---|---|
| [AGENTS.md](AGENTS.md) | Working agreement, folder structure, who touches what |
| [docs/FLOWS.md](docs/FLOWS.md) | User flows with the exact data per screen |
| [docs/DECISIONS.md](docs/DECISIONS.md) | Technical decision log |

## Team

| Role | Area | Owner |
|---|---|---|
| P1 | Inference engine (Gemma + MediaPipe), `pubspec.yaml` | _(unassigned)_ |
| P2 | RAG + nutrition calculation | _(unassigned)_ |
| P3 | UI, screens, TTS | _(unassigned)_ |
| P4 | Data and local persistence | _(unassigned)_ |

## Licensing

- **App code**: Apache License 2.0 — see [LICENSE](LICENSE).
- **Gemma model**: subject to Google's [Gemma Terms of Use](https://ai.google.dev/gemma/terms),
  including its Prohibited Use Policy. Not covered by this repository's license.
- **Recipe book data**: [Instituto Nacional de Salud (INS) — Peru](https://anemia.ins.gob.pe/recetario-de-ninos).
