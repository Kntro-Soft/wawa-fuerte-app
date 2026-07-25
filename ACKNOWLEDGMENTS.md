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
| [Lefthook](https://github.com/evilmartians/lefthook)                    | Pre-commit formatting hook                            |

## Reference Methodologies

- [Architecture Decision Records](https://adr.github.io/) — Michael Nygard
- [Retrieval-Augmented Generation](https://arxiv.org/abs/2005.11401) — Lewis et al.
- [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)
- [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
- [Semantic Versioning](https://semver.org/)
- [Gitflow](https://nvie.com/posts/a-successful-git-branching-model/) — Vincent Driessen
