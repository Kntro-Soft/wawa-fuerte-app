# 0011. INS recipe data provenance

- Status: Accepted
- Date: 2026-07-25
- Deciders: Kntro-Soft team

## Context

ADR-0005 decided that the app is grounded in the INS recipe book rather than in anything the model
produces. That decision is only worth as much as the corpus behind it. A JSON file of plausible
Peruvian recipes with plausible iron figures would satisfy every test we could write and would still
be exactly the failure mode ADR-0005 exists to prevent — the fabrication would simply have moved
from inference time to build time.

Three datasets feed the app, and they carry different risks:

- The **recipes** drive what the app tells a caregiver to cook.
- The **iron per serving** drives the coverage percentage, which is the number a caregiver acts on.
- The **age requirement table** is the denominator of that percentage.

A wrong figure in any of them is a clinical defect, not a data-quality nit. Meanwhile the corpus also
has to be assembled inside a 6-hour sprint, so "we will verify it later" is not an available plan.

The Instituto Nacional de Salud publishes the primary material openly: a recipe book for preventing
anemia in children aged 6 to 23 months, and the Tablas Peruanas de Composición de Alimentos. Both are
Ministry-of-Health publications, which is the strongest provenance available for this problem.

## Decision

Every nutritional number shipped in `assets/data/` is **transcribed from a published official
source, and carries a `source` URL identifying where it came from**. Nothing is computed from a
model, inferred from a similar food, or filled in to make a row look complete.

Concretely:

- `recetario_ins.json` — 23 recipes from the INS/CENAN *Recetario para prevenir la anemia en niños
  de 6 a 23 meses* (`anemia.ins.gob.pe`). `ironMg` is copied verbatim from the "Aporte nutricional
  por ración" panel printed on each recipe card. The book is published in two editions — a set of
  per-age cards and a combined volume — and where a dish appears in both, the two printed iron
  figures were compared and agreed. Near-duplicate variants of the same dish were collapsed to one
  entry rather than counted twice to pad the corpus.
- `ingredientes_regionales.json` — `hierro_mg_por_100g` from the *Tablas Peruanas de Composición de
  Alimentos* (INS/CENAN). Each row records the table's own food code and food name, so any value can
  be re-checked against the published table without re-tracing this research.
- `requerimientos_hierro.json` — FAO/WHO *Vitamin and mineral requirements in human nutrition*
  (2004), Table 40, at all four bio-availability levels.

**Where an official value could not be found, the field is flagged rather than filled.** A gap that
is visible is a task; a gap that has been papered over is a liability.

## Consequences

### What this buys us

- The headline iron coverage traces to a Ministry of Health document. That is a materially stronger
  claim in the writeup than "the model suggested it", and it is verifiable by a judge.
- Errors are findable. Because every row names its source — and the ingredient rows name their exact
  table code — a reviewer can check a suspicious value in minutes.
- The corpus is small enough to have been read end to end, which is not true of a scraped one.

### What we could not source, and how it is marked

- **Cost.** The INS recipe book publishes no prices, and no official per-ingredient price table was
  obtained in the sprint. MIDAGRI's SISAP publishes market prices but only through an interactive
  query app, and deriving a per-serving cost from it would need household-measure-to-gram conversion
  on top — more derivation than the number is worth. `referenceCostPen` and `costo_referencial_pen`
  are therefore **estimates**, and every affected row carries an explicit flag
  (`referenceCostPenIsEstimate` / `costo_referencial_es_estimado`) so no consumer can mistake them
  for sourced data. A test asserts the flag is present. The budget filter in Flow B is consequently
  an approximate sort, and the UI must not present a cost as authoritative.
- **Region per recipe.** The INS book is a national publication and does not assign recipes to
  Coast, Highlands or Jungle. `region` is therefore `null` for all 23 recipes. Inferring a region
  from the ingredients would have been invention dressed as data.
- **Region per ingredient.** The Coast/Highlands/Jungle grouping in
  `ingredientes_regionales.json` is **editorial**, is labelled as such in the file, and reflects
  habitual availability. It only decides which checklist a caregiver is shown; it never changes a
  nutrient value.
- **A Peruvian dietary iron requirement table.** No MINSA or INS document publishing a dietary iron
  requirement in mg/day by age was located. MINSA's anemia norms specify *supplementation* doses,
  which are a different quantity, and using them as a dietary requirement would have produced a
  wrong denominator for every coverage figure in the app. FAO/WHO is used instead, and the
  substitution is recorded in the file itself.
- **`queso fresco`.** It appears in the INS recipes but no matching row was located in the Tablas
  Peruanas de Composición de Alimentos, so it is absent from the ingredient checklist rather than
  carrying a guessed iron value.

### Licensing and attribution

The INS material is published by a Peruvian state body for free public distribution and carries no
explicit open licence. We therefore treat it as **attribution-required, non-appropriated**: the
recipe content is reproduced for the purpose it was published for, the app credits the Instituto
Nacional de Salud and CENAN as the source of the recipe book and of the composition tables, and no
part of it is presented as the team's own nutritional guidance. The same attribution appears in the
README and in `assets/data/SOURCES.md`. Should the project continue past the hackathon, formal
permission from INS should be requested before any distribution.

### The cost we are accepting

- **The corpus bounds the product.** 23 recipes is the whole world the app can recommend from. It
  cannot suggest a dish outside the book, and it skews to the organ meats and blood-based
  preparations the INS book is built around. That is the intended trade-off of ADR-0005, now made
  concrete: we would rather refuse to answer than answer from an unverified recipe.
- The 23 recipes fall short of the 25–40 we aimed for. Padding the count with near-duplicate
  variants was available and was rejected; the shortfall is real and recorded here rather than
  hidden behind a larger number.
- Widening the corpus is not a matter of prompting differently. It requires finding another official
  publication, transcribing it, and extending `SOURCES.md` — which is the correct amount of friction
  for adding clinical content to a child-health app.
