# AGENTS.md

Contrato de trabajo para los 4 devs (y para agentes de IA que toquen este repo).
**Sprint de 6 horas. Prioridad: que la demo corra en el iPhone. No la pureza arquitectónica.**

## Purpose

App móvil Flutter que genera planes nutricionales semanales contra la anemia infantil,
usando **Gemma corriendo 100% on-device**. **No hay backend, no hay red.**
Todo (modelo, recetario, base de datos) vive dentro del dispositivo.

## Big Picture

- Flutter estable + Dart 3. Estado: **decidido en el minuto 0** → ver `docs/DECISIONS.md`.
- Inferencia: `flutter_gemma` sobre MediaPipe LLM Inference API. **iPhone físico obligatorio**
  (el simulador es CPU-only con tope de 256 MB de Metal → no corre el modelo).
- El modelo Gemma es una caja negra pre-entrenada: **no se entrena ni se hace fine-tuning**.
  Se especializa vía **prompting + RAG** con el recetario del INS.

```
lib/
  core/
    inference/   # Gemma + MediaPipe.        DUEÑO: P1
    rag/         # búsqueda de recetas.      DUEÑO: P2
    nutrition/   # cálculo de hierro.        DUEÑO: P2
    storage/     # SQLite/Hive local.        DUEÑO: P4
    theme/       # colores, tipografía.      DUEÑO: P3
  features/
    onboarding/  # Flujo 0 + A.              DUEÑO: P3
    home/        # Flujo E (selector niños). DUEÑO: P3
    plan/        # Flujo B + D.              DUEÑO: P3
  main.dart                                # DUEÑO: P1
assets/
  data/          # recetario_ins.json, etc.  DUEÑO: P4
  models/        # .task de Gemma (git-ignored, pesa >1GB)
```

## Reglas que no se negocian

- **Nadie commitea el modelo `.task`** — pesa más de 1 GB y revienta el repo. Va en
  `assets/models/` que está git-ignored. Se comparte por AirDrop/USB entre los devs.
- **Nada de API keys.** Este proyecto es 100% offline; si alguien necesita una key, algo
  se diseñó mal. Consúltalo antes.
- **Solo P1 edita `pubspec.yaml` y `main.dart`.** Si necesitas un paquete, pídeselo — no lo
  agregues tú. `pubspec.yaml` es la fuente #1 de conflictos de merge con 4 devs.
- **No edites carpetas de otro dueño.** Si tu cambio cruza fronteras, pídelo por el chat.
- **`main` siempre compila.** Si tu PR rompe el arranque, se revierte — no se debuggea en `main`.
- **El dato de hemoglobina es OPCIONAL en todo el código.** Nunca asumas que existe; la app
  debe generar un plan preventivo estándar por edad cuando es `null`. Ver `docs/FLOWS.md`.

## Trabajar en paralelo sin bloquearse

Las primeras horas **todos trabajan contra mocks**, nadie espera a nadie:

- P3 (UI) usa un `FakeInferenceService` que devuelve un plan hardcodeado.
- P2 (RAG) prueba su búsqueda con un `recetario_ins.json` de 5 recetas de ejemplo.
- P1 valida Gemma en el iPhone con un prompt suelto, sin depender de la UI.
- P4 arma el esquema de datos y lo llena con seeds.

La integración real es en el **checkpoint de la hora 4**, no antes.

## Comandos

```
flutter pub get
flutter run                  # simulador (UI) o iPhone físico (Gemma real)
dart format .
flutter analyze
flutter test
```

## Working Agreement

- Antes de crear una pantalla nueva, abre la más parecida que ya exista y **copia su
  estructura de carpetas, nombres y forma de widget**. La consistencia vale más que la elegancia.
- Ante conflicto entre este archivo y el código: **gana el código**. Actualiza este archivo.
- **Ramas (Gitflow)**: `main` (release/demo) ← `develop` (integración) ← `feature/*`, `bugfix/*`,
  `hotfix/*`. Nunca commitees directo a `main` ni a `develop`. Los prefijos de rama son SOLO esos:
  `chore`, `docs`, `ci` son tipos de commit, **no** prefijos de rama.
- **Commits**: Conventional Commits, `<tipo>(<área>): descripción` — ej.
  `feat(plan): add iron coverage calculation`. Áreas: `inference`, `rag`, `nutrition`, `storage`,
  `onboarding`, `home`, `plan`, `ci`, `docs`.
- **Commits atómicos**: un cambio lógico por commit. Nada de commits grandes que mezclan cosas —
  no se pueden revisar ni revertir por separado.
- CODEOWNERS notifica al dueño del área, pero **no bloquea el merge** (bloquearía a 4 devs que están
  todos codeando a la vez). El gate es el CI en rojo, no una persona.
