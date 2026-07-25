# Data sources

Provenance for every file in `assets/data/`. The reasoning behind these choices — and the list of
values we could **not** source — is in
[ADR-0011](../../docs/adr/0011-ins-recipe-data-provenance.md).

All consultation was done on **2026-07-25**.

## Files

| File | Field | Source | URL | Consulted |
|---|---|---|---|---|
| `recetario_ins.json` | recipes, `ingredients`, `preparation`, `ironMg` (6–8 months) | INS/CENAN — *Recetario para prevenir la anemia en niños de 6 a 23 meses*, cards for 6–8 months | <https://anemia.ins.gob.pe/sites/default/files/2017-02/Recetas%20anemia%206-8%20meses.pdf> | 2026-07-25 |
| `recetario_ins.json` | recipes, `ingredients`, `preparation`, `ironMg` (9–11 months) | INS/CENAN — same recipe book, cards for 9–11 months | <https://anemia.ins.gob.pe/sites/default/files/2017-02/Recetas%20anemia%209-11%20meses.pdf> | 2026-07-25 |
| `recetario_ins.json` | recipes, `ingredients`, `preparation`, `ironMg` (12–23 months) | INS/CENAN — same recipe book, cards for 12–23 months | <https://anemia.ins.gob.pe/sites/default/files/2017-02/Recetas%20anemia%2012-23%20meses.pdf> | 2026-07-25 |
| `recetario_ins.json` | recipes only in the combined edition | INS/CENAN — same recipe book, complete volume | <https://anemia.ins.gob.pe/sites/default/files/2017-02/Recetario%20anemia%20completo.pdf> | 2026-07-25 |
| `recetario_ins.json` | `referenceCostPen` | **No official source.** Estimate, flagged per row | — | — |
| `recetario_ins.json` | `region` | **Not applicable.** The INS book is national and assigns no region; always `null` | — | — |
| `ingredientes_regionales.json` | `hierro_mg_por_100g`, `tpca_codigo`, `tpca_nombre` | INS/CENAN — *Tablas Peruanas de Composición de Alimentos* | <https://lamejorreceta.ins.gob.pe/sites/default/files/2020-12/tablas-peruanas-QR_0.pdf> | 2026-07-25 |
| `ingredientes_regionales.json` | `costo_referencial_pen` | **No official source.** Estimate, flagged per row | — | — |
| `ingredientes_regionales.json` | region grouping | **Editorial**, labelled in the file. Not an official classification | — | — |
| `requerimientos_hierro.json` | `dailyMg` at 15 / 12 / 10 / 5 % bio-availability | FAO/WHO — *Vitamin and mineral requirements in human nutrition*, 2nd ed. (2004), Ch. 13, Table 40 | <https://www.fao.org/3/y2809e/y2809e0j.htm> | 2026-07-25 |
| `requerimientos_hierro.json` | `weeklyMg` | Computed as `dailyMg × 7`; asserted by test | — | — |

## Landing pages

| Page | URL |
|---|---|
| INS anemia portal — children's recipe book | <https://anemia.ins.gob.pe/recetario-de-ninos> |
| INS "La Mejor Receta" — reference tables | <https://lamejorreceta.ins.gob.pe/documento/tabla-peruana-de-composicion-de-alimentos-0> |

## Attribution

The recipes and the food composition values are the work of the **Instituto Nacional de Salud (INS)
— Centro Nacional de Alimentación y Nutrición (CENAN), Ministerio de Salud del Perú**, published for
free public distribution. Wawa Fuerte reproduces them for the purpose they were published for and
presents none of this content as its own nutritional guidance. See ADR-0011 for the licensing
position.

## Known gaps

| Gap | How it is marked |
|---|---|
| No official price data for recipes or ingredients | `referenceCostPenIsEstimate: true` / `costo_referencial_es_estimado: true` on every row; asserted by test |
| No official region assignment for recipes | `region: null` on all 23 recipes |
| No official region classification for ingredients | Documented in the file's `notes` as editorial |
| No MINSA/INS dietary iron requirement table in mg/day | FAO/WHO used instead; the substitution is recorded in the file's `notes` |
| `queso fresco` has no located row in the composition tables | Omitted from the ingredient checklist rather than given a guessed value |

## Re-checking a value

Every nutrient row is traceable without repeating this research:

- **A recipe's iron** — open the `source` URL on the recipe and read the "Aporte nutricional por
  ración" panel on that recipe's card.
- **An ingredient's iron** — look up `tpca_codigo` (e.g. `F-29`) and `tpca_nombre` in the Tablas
  Peruanas de Composición de Alimentos; the iron column is `<FE>`, in mg per 100 g.
- **A requirement** — FAO/WHO Table 40, row `sourceAgeGroup`, column = the bio-availability level.

The INS PDFs are scanned images with no text layer, so the recipe values were read visually from the
printed cards. Where a dish appears in both published editions, the two printed iron figures were
compared and agreed — that cross-check is the main guard against a transcription slip.
