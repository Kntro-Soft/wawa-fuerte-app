# Wawa Fuerte

> App móvil **100% offline** que genera planes nutricionales semanales contra la anemia
> infantil, con **Gemma corriendo on-device**. Sin backend, sin conectividad.
>
> Build with Gemma: GDG Callao · ODS 2 (Hambre Cero) y ODS 3 (Salud y Bienestar)

## El problema

Perú tiene tasas críticas de anemia infantil, especialmente en zonas rurales y periurbanas
donde las familias no siempre tienen presupuesto para suplementos caros o carne roja a diario
— y donde la conectividad es intermitente o inexistente.

## La solución

Una madre ingresa los ingredientes baratos disponibles en su región (sangrecita, bazo, quinua,
tarwi, hígado) y su presupuesto. La app genera un menú semanal balanceado para elevar los
niveles de hierro, calculando la cobertura real frente al requerimiento del niño según su edad.

**Todo corre dentro del teléfono**: el modelo, el recetario y la base de datos. Cero red.

## Por qué es diferente

- El [recetario del INS](https://anemia.ins.gob.pe/recetario-de-ninos) es oficial pero
  **estático**: no se personaliza según lo que la familia realmente tiene.
- Apps internacionales de nutrición con IA no cubren **ingredientes andinos/amazónicos**
  ni contextos sin conectividad.
- Nosotros combinamos las tres cosas que nadie junta: generación dinámica + ingredientes
  locales de bajo costo + funcionamiento **genuinamente offline**.

## Arquitectura

Sin servidor. Todo local:

```
[Assets empaquetados]
├── recetario_ins.json           → recetas oficiales del INS
├── ingredientes_regionales.json → ingredientes por región/temporada/costo
└── embeddings_recetas.db        → PRECALCULADO (BLOB en SQLite)

[Generado en el dispositivo]
├── perfil_nino        → soporta VARIOS niños por familia
├── planes_generados   → historial y cumplimiento
└── foto temporal      → nunca se guarda, se procesa y descarta
```

Gemma **no se entrena ni se hace fine-tuning** — se usa pre-entrenado y se especializa vía
**prompting + RAG** con el recetario del INS, lo que evita alucinaciones nutricionales.

## Empezar

```bash
flutter pub get
flutter run
```

> ⚠️ La inferencia real de Gemma requiere un **iPhone físico**. El simulador de iOS es
> CPU-only con tope de 256 MB de Metal y no puede correr el modelo. Para desarrollar UI
> sin el modelo, usa el `FakeInferenceService`.

El modelo `.task` **no está en el repo** (pesa > 1 GB) — se comparte por AirDrop/USB y va
en `assets/models/`, que está git-ignored.

## Documentación

| Documento | Contenido |
|---|---|
| [AGENTS.md](AGENTS.md) | Contrato de trabajo, estructura de carpetas, quién toca qué |
| [docs/FLOWS.md](docs/FLOWS.md) | Flujos de usuario con datos exactos por pantalla |
| [docs/DECISIONS.md](docs/DECISIONS.md) | Bitácora de decisiones técnicas |

## Equipo

| Rol | Área | Dueño |
|---|---|---|
| P1 | Motor de inferencia (Gemma + MediaPipe), `pubspec.yaml` | _(por asignar)_ |
| P2 | RAG + cálculo nutricional | _(por asignar)_ |
| P3 | UI, pantallas, TTS | _(por asignar)_ |
| P4 | Datos y persistencia local | _(por asignar)_ |

## Licencias

- **Código de la app**: Apache License 2.0 — ver [LICENSE](LICENSE).
- **Modelo Gemma**: sujeto a los [Términos de Uso de Gemma](https://ai.google.dev/gemma/terms)
  de Google, incluida su Política de Uso Prohibido. No cubiertos por la licencia de este repo.
- **Datos del recetario**: [Instituto Nacional de Salud (INS) — Perú](https://anemia.ins.gob.pe/recetario-de-ninos).
