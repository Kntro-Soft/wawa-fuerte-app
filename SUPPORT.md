# Support — Kntro-Soft / wawa-fuerte

## About This Repository

This repository contains **Wawa Fuerte**, a Flutter app that generates weekly nutrition plans
against childhood anemia in Peru with **Gemma running 100% on-device**. It was built by the
**Kntro-Soft** team during the **Build with Gemma: GDG Callao** hackathon, and targets UN SDG 2
(Zero Hunger) and SDG 3 (Good Health and Well-Being).

There is no backend, no account, and no server to be down. The app is the whole system.

## Getting Help

### Running or building the project

Start with the documentation:

- [README.md](./README.md) — what the app does and how to start it
- [.github/CONTRIBUTING.md](.github/CONTRIBUTING.md) — setup, commands, branches, commits, PRs
- [AGENTS.md](./AGENTS.md) — working agreement, folder structure, who owns what
- [docs/adr/](./docs/adr/) — architecture decisions and the reasoning behind them
- [docs/FLOWS.md](./docs/FLOWS.md) — user flows with the exact data on each screen

### Common problems

| Symptom | Cause and fix |
|---|---|
| The app runs but every plan is identical | You are on `FakeInferenceService`. The Gemma `.task` file is not in `assets/models/` — it is over 1 GB and git-ignored, so get it from a teammate over USB or file transfer. |
| The model fails to load or the app runs out of memory on iOS | You are on the iOS Simulator, which is CPU-only with a 256 MB Metal cap and cannot run the model. Inference requires a **physical Android phone** ([ADR-0003](./docs/adr/0003-android-as-primary-target.md)). |
| CI fails on a branch that builds locally | Run `dart format --set-exit-if-changed .`, then `flutter analyze` and `flutter test`. Formatting is the usual culprit if you committed with `--no-verify`. |
| `flutter run` finds no device | `flutter devices`. On Android, enable USB debugging and accept the pairing prompt on the handset. |
| A plan cannot be generated without a hemoglobin value | That is a bug, not intended behavior — hemoglobin is optional everywhere ([ADR-0007](./docs/adr/0007-hemoglobin-is-always-optional.md)). Please report it. |

### Questions and discussions

- [Open an Issue](https://github.com/Kntro-Soft/wawa-fuerte/issues/new/choose) using the appropriate template
- [GitHub Discussions](https://github.com/Kntro-Soft/wawa-fuerte/discussions) for general questions

When reporting a bug, **do not include a real child's data**. Use made-up values that reproduce the
problem.

## Team Contact

| Member                                        | Email                                                                       |
|-----------------------------------------------|-----------------------------------------------------------------------------|
| Gutiérrez Soto, Jhosepmyr Orlando (Tech Lead) | [jhosepmyrgutierrezsoto@gmail.com](mailto:jhosepmyrgutierrezsoto@gmail.com) |

## Security and Privacy Issues

The app handles health data about minors. To report a vulnerability, a privacy problem, or an
exposed secret, **do not open a public Issue**. Follow the instructions in
[SECURITY.md](.github/SECURITY.md).

## Not a Medical Device

Wawa Fuerte is an educational nutrition-planning aid. It does not diagnose or treat anemia and does
not replace a health professional. For medical questions, consult your local health post and the
child's CRED follow-up.
