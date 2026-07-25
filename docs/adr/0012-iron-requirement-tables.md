# 0012. Iron requirement tables from INS/FAO-WHO, applied in Dart

- Status: Accepted
- Date: 2026-07-25
- Deciders: Kntro-Soft team

## Context

The weekly iron coverage percentage is the one number in this app a caregiver actually acts on. It
answers "did this week's food give my child enough iron?", and a family may change what they cook —
or stop worrying — because of it. A wrong figure here is a clinical defect, not a display bug.

That number is a ratio, and it needs a denominator: how much iron a child of a given age should be
getting in a week. Two things had to be settled to produce it.

**Where the requirement comes from.** ADR-0007 already established that the requirement keys on
**age**, not on hemoglobin — hemoglobin indicates severity, it is not an input to the requirement.
So the app needs an age-banded table. It must be an official published one; nothing in this table
may be estimated, interpolated, or filled in from memory.

Peru's Instituto Nacional de Salud publishes exactly such a table for children aged 0–11 years:
*"Recomendaciones para el consumo de Minerales para la Población Infantil de 0 a 11 años"*, whose
iron column is split into three dietary-bioavailability sub-columns — 15% (Alta), 10% (Moderada) and
5% (Baja). Those Peruvian figures are a reprint of the FAO/WHO expert consultation values, which
publish the same requirement at four bioavailability levels and additionally give the mean body
weight and the exact age boundary of each band.

**Bioavailability then has to be chosen**, because the recipe corpus reports the iron *contained* in
a serving, not the iron *absorbed* from it. FAO/WHO states plainly: "For developing countries, it may
be realistic to use the figures of 5 percent and 10 percent."

**Who computes the ratio.** The app has a language model on board and it would be trivial to ask it
for the total. ADR-0005 already rules that out for generated nutritional content; this ADR records
that the rule binds the arithmetic too.

## Decision

Implement `TableIronCalculator` against the **INS mineral table, 10% (Moderada) bioavailability
column**, with the FAO/WHO consultation as the upstream source of record for band boundaries.

Sources, in the priority order the team agreed on (Peruvian first, international to fill gaps):

1. **INS (Peru)** — «Requerimientos nutricionales», Alimentación Saludable.
   <https://alimentacionsaludable.ins.gob.pe/ninos-y-ninas/requerimientos-nutricionales>
   Cited on the page as *Informe Técnico: Requerimiento de Energía para la población peruana, 2015*.
2. **FAO/WHO** — *Vitamin and mineral requirements in human nutrition*, 2nd ed., chapter 13 "Iron",
   Table 40, p. 197. <https://www.fao.org/4/y2809e/y2809e13.pdf>
3. **INS (Peru)** — «Suplementación con micronutrientes para niños de 6 a 35 meses de edad», used
   only to justify the 6-month lower boundary.
   <https://anemia.ins.gob.pe/suplementacion-con-micronutrientes-para-ninos-de-6-35-meses-de-edad>

The two tables agree digit for digit; the INS values *are* the FAO/WHO values. The implemented table
(mg/day, at 10% bioavailability, multiplied by 7 for the weekly figure):

| Age band            | FAO/WHO row | 15%  | **10% (used)** | 5%   |
|---------------------|-------------|------|----------------|------|
| 6–11 months         | 0.5–1 yr    | 6.2  | **9.3**        | 18.6 |
| 12–47 months        | 1–3 yr      | 3.9  | **5.8**        | 11.6 |
| 48–83 months        | 4–6 yr      | 4.2  | **6.3**        | 12.6 |
| 84–131 months       | 7–10 yr     | 5.9  | **8.9**        | 17.8 |

**Why 10% and not 5%.** FAO/WHO endorses both for developing countries. We take the more optimistic
of the two because the corpus this app plans from is the INS anti-anemia recipe book, which is built
around heme iron — sangrecita, hígado, bazo — served with ascorbic-acid-rich accompaniments, the
exact combination FAO/WHO names as lifting absorption above the 5% floor. Choosing 5% instead would
roughly double every requirement and make almost every honest plan read as a failure. The constant
is named `assumedBioavailability` and the 5% column is recorded beside every band, so the decision
can be reversed by editing four numbers.

**Age ranges with no official figure are left empty, not guessed.**

- **Below 6 months**: no dietary iron requirement is published at all — neither INS nor FAO/WHO —
  because the term infant's needs are met by fetal iron stores and breast milk. `hasOfficialRequirement`
  returns false and the requirement is 0, meaning *"not published"*, never *"needs no iron"*.
- **The 6-month boundary itself**: the INS page renders the first band as «7 a 11 meses», while
  FAO/WHO Table 40 gives it as "0.5–1" years, i.e. starting at 6 months. We follow the upstream
  FAO/WHO boundary. This is not a made-up number — it is the same 9.3 mg/day, applied from the age
  at which Peru begins complementary feeding and preventive supplementation, which is also the floor
  of this app's 6–59 month target population.
- **Above 10 years (132+ months)**: FAO/WHO splits by sex *and* by menarche status from 11 years
  (11–14 yr females: 14.0 mg/day non-menstruating vs 32.7 mg/day menstruating, at 10%). The app
  cannot know menarche status and has no reason to ask a mother about it. Rather than pick one, the
  calculator reports no requirement above 131 months.
- **Sex is accepted and ignored.** Neither table splits iron requirements by sex before 11 years.
  The `sex` parameter stays in the interface because the profile carries it and because a future
  adolescent band would need it, but honouring it today would mean fabricating an adjustment.

**Coverage stays in Dart.** `coverageOf` sums the `ironMg` bundled with each INS recipe and divides
by the weekly requirement. No model call, no network, no floating estimate — the same inputs always
produce the same percentage, and it can be unit-tested against the published table.

## Consequences

- Every constant in `table_iron_calculator.dart` carries its source and URL on the line above it.
  A reviewer can check the whole table against two web pages in a couple of minutes, and the writeup
  can claim a Peruvian Ministry-of-Health source rather than "the model suggested it".
- The headline number cannot be hallucinated, because no model produces it (ADR-0005 extended to
  arithmetic).
- Coverage works identically with and without a CRED hemoglobin reading, since the denominator never
  depended on hemoglobin (ADR-0007).
- The bioavailability choice is a genuine judgement call and is the most likely thing to be
  challenged by a nutritionist. It is isolated in one named constant with the alternative column
  recorded next to it, so revising it is a four-number edit plus a superseding ADR — not a rewrite.
- Two age ranges return a requirement of zero. `IronCoverage.percent` already returns 0 when
  `requiredMg <= 0`, so nothing divides by zero, but `meetsTarget` degenerates to true. **The UI must
  call `hasOfficialRequirement` before showing a coverage figure** and hide the percentage rather
  than print a misleading one. This is the sharpest edge this decision leaves behind.
- The table is a *dietary intake* target, not an absorbed-iron target and not a supplementation dose.
  It does not replace the ferrous-sulphate / micronutrient-sachet regimen MINSA prescribes; the app
  covers food, and the plan screen should not be read as a substitute for the CRED check-up.
- Requirements are stored per day and multiplied by seven. Real intake is not uniform across a week,
  but the plan is weekly and the caregiver's question is weekly, so the weekly aggregate is the right
  granularity to report.
