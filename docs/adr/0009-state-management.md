# 0009. State management library

- Status: Proposed
- Date: 2026-07-25
- Deciders: Kntro-Soft team

> **This is the one decision that must be closed in the first minutes of the sprint.** Four
> developers building screens against different state idioms will produce code that cannot be
> merged. Pick one, mark this ADR Accepted, and stop discussing it.

## Context

Four developers work in parallel on separate feature folders that must compose into one app at the
hour-4 integration checkpoint. State management is the decision with the widest blast radius: it
shapes every widget, every service lookup, and every test.

The candidates:

- **Provider** — smallest API surface, ships in most Flutter tutorials, minimal boilerplate. Least
  to learn under time pressure.
- **Riverpod** — compile-safe, testable without a widget tree, no `BuildContext` dependency for
  reads. More robust, slightly more ceremony.
- **Bloc** — the most structured and the most boilerplate per feature. Its benefits accrue over
  months, not hours.

## Decision

_To be filled in at sprint start._

Recommendation: **Provider**, on the grounds that the deciding factor over six hours is how quickly
four people converge on one idiom, not how well the architecture ages.

## Consequences

_To be filled in once decided._

Whatever is chosen, one reference implementation is written first by the `core` owner and every
other feature copies its shape, per the working agreement in `AGENTS.md`.
