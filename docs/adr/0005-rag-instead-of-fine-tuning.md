# 0005. RAG over the INS recipe book instead of fine-tuning

- Status: Accepted
- Date: 2026-07-25
- Deciders: Kntro-Soft team

## Context

The app gives nutritional guidance for infants with anemia. A general-purpose language model asked
to invent recipes and iron figures will produce plausible, confidently-worded, and occasionally
wrong clinical content. In this domain that is not a cosmetic defect.

Peru's Instituto Nacional de Salud publishes an official recipe book for preventing anemia in
children, which is exactly the authoritative corpus this problem needs.

Specialising a model could be done by fine-tuning or by retrieval. Fine-tuning requires a labelled
dataset, GPU time, and hours-to-days of training — none of which exist in a 6-hour sprint.

## Decision

Do **not** train or fine-tune anything. Use the pre-trained Gemma checkpoint as-is and specialise
it at runtime through **prompting plus retrieval-augmented generation** grounded in the INS recipe
book.

- `recetario_ins.json` is the knowledge base, bundled as an app asset.
- Retrieval selects the recipes relevant to the ingredients, budget, region, and child's age.
- Those recipes are injected into the prompt as context; the model composes and sequences a weekly
  plan from them rather than inventing dishes.
- Iron totals are **not** produced by the model. They are computed in Dart from the nutrient data
  attached to each recipe (see ADR-0006), so the headline number is arithmetic, not generation.

## Consequences

- Nutritional content traces back to an official Ministry-of-Health source, which is a far stronger
  claim in the writeup than "the model suggested it".
- The most safety-critical number in the UI — iron coverage — cannot be hallucinated, because no
  model produces it.
- Answer quality is bounded by the corpus: if a recipe is not in the INS book, it will not appear.
  This is the intended trade-off.
- The corpus must be cited as INS in the README and the writeup.
- Prompt wording becomes load-bearing and belongs under version control alongside the code.
