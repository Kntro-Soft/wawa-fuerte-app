# Acknowledgments — Wawa Fuerte

The **Kntro-Soft** team thanks the people, institutions, and open-source projects that make this
app possible.

## Data and Domain Sources

- **[Instituto Nacional de Salud (INS) — Peru](https://anemia.ins.gob.pe/recetario-de-ninos)** —
  For the official recipe book for preventing anemia in children, which is the knowledge base this
  app retrieves from. Every nutritional recommendation the app produces traces back to this source
  rather than to model invention. The data belongs to INS; we only reference and cite it.
- **Ministerio de Salud del Perú (MINSA)** — For the *Carné de Crecimiento y Desarrollo* (CRED)
  programme, which is where the families using this app already hold their children's hemoglobin
  readings.

## Model

- **[Google](https://ai.google.dev/gemma)** — For releasing Gemma with open weights, which is what
  makes fully offline, on-device inference possible for a population without reliable connectivity.
  Use of the model is subject to the [Gemma Terms of Use](https://ai.google.dev/gemma/terms).

## Event

- **[Google Developer Group Callao](https://gdg.community.dev/)** — For organising *Build with
  Gemma: GDG Callao* and framing it around the UN Sustainable Development Goals.
- **Moventi** — For hosting the event.

## Technologies and Frameworks

| Project                                                                 | Use in the app                                        |
|-------------------------------------------------------------------------|-------------------------------------------------------|
| [Flutter](https://flutter.dev)                                          | Cross-platform mobile application framework           |
| [Dart](https://dart.dev)                                                | Application language                                  |
| [flutter_gemma](https://pub.dev/packages/flutter_gemma)                 | On-device Gemma inference from Flutter                |
| [MediaPipe LLM Inference API](https://ai.google.dev/edge/mediapipe)     | Native on-device model execution                      |
| [SQLite](https://www.sqlite.org)                                        | Local persistence and embedding storage (as BLOBs)    |
| [Provider](https://pub.dev/packages/provider)                           | State management (ADR-0009)                           |
| [wakelock_plus](https://pub.dev/packages/wakelock_plus)                 | Keeping the screen awake during on-device generation  |
| [flutter_tts](https://pub.dev/packages/flutter_tts)                     | Reading recipe steps aloud                            |
| [Lefthook](https://github.com/evilmartians/lefthook)                    | Pre-commit formatting hook                            |

## Typeface and Icons

- **[Lexend](https://www.lexend.com/)** — Bonnie Shaver-Troup, Thomas Jockin, Santiago Orozco and
  contributors. Lexend was developed around research on reading proficiency, which is why it is the
  only typeface in this app: a share of the caregivers we are designing for read slowly, and the
  typeface is doing accessibility work, not decoration. Four weights are bundled with the app rather
  than fetched, because there is no network on the target device (ADR-0002). Licensed under the
  [SIL Open Font License 1.1](https://openfontlicense.org/).
- **[Lucide](https://lucide.dev/)** — Community fork of Feather Icons, used through
  [lucide_icons_flutter](https://pub.dev/packages/lucide_icons_flutter). Licensed under the ISC
  License. Every icon in the app is paired with a text label, so the set carries no meaning alone.

## Reference Methodologies

- [Architecture Decision Records](https://adr.github.io/) — Michael Nygard
- [Retrieval-Augmented Generation](https://arxiv.org/abs/2005.11401) — Lewis et al.
- [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)
- [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
- [Semantic Versioning](https://semver.org/)
- [Gitflow](https://nvie.com/posts/a-successful-git-branching-model/) — Vincent Driessen
