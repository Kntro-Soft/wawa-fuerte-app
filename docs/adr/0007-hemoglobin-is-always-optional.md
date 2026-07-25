# 0007. Hemoglobin is always optional

- Status: Accepted
- Date: 2026-07-25
- Deciders: Kntro-Soft team

## Context

Peru's MINSA issues every child a physical *Carné de Crecimiento y Desarrollo* (CRED) from their
first check-up. It is a paper booklet held by the family, recording weight, height, vaccinations and
periodic hemoglobin readings. It is universal by policy — it is not issued only to children already
diagnosed with anemia.

Coverage is nonetheless imperfect in practice: the booklet may not be at hand, the family may live
far from a health post, or the last hemoglobin reading may be months old.

Critically, **iron requirements do not depend on hemoglobin**. They are fixed nutritional values per
age band published by INS/WHO. A hemoglobin reading indicates *severity*, letting us prioritise
iron-dense recipes — it is not an input to the requirement calculation.

Designing the app around a mandatory hemoglobin field would therefore exclude families for a reason
that is not technically necessary.

## Decision

Hemoglobin is **optional everywhere** and must never block a flow.

- Onboarding asks "do you have the CRED booklet at hand?" with a third answer, "I don't know what
  that is". Answering no or unsure skips straight to saving the profile.
- The domain model carries hemoglobin as **nullable**. No code may assume it is present.
- With no reading, the app produces a standard preventive plan from the age-based requirement table.
- With a reading, the prompt additionally asks the model to prioritise iron-dense recipes, and the
  UI reports coverage against the child's specific deficit.
- When absent, the result screen invites the user to add it later, framed as improving precision —
  never as an error or a missing requirement.

## Consequences

- The app is usable by families without the booklet, which is a meaningful share of the target
  population and a stronger inclusion story for the writeup.
- Coverage percentage works in both modes, because it is computed against the age-based requirement
  either way.
- Every consumer of the profile must handle the null case; this is enforced by making the field
  nullable in the model rather than defaulting it to a sentinel value.
- Two prompt variants must be maintained and both must be tested before the demo.
