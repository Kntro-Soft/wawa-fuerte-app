# 0009. State management library

- Status: Accepted
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

**Provider.**

The deciding factor over a six-hour sprint is not how well an architecture ages — it is how quickly
four people converge on one idiom. Provider has the smallest API surface of the three, it is what
every Flutter tutorial the team has already read uses, and a developer who has never seen it can
read an existing screen and copy its shape without a detour into documentation. Riverpod's
compile-time safety and Bloc's structure are real advantages that accrue over months; this project
has hours.

Concretely, the app uses:

- `MultiProvider` at the root of `main.dart` for the dependency graph. Stateless collaborators
  (`RecipeRetriever`, `InferenceService`, `IronCalculator`, the repositories, `GenerateWeeklyPlan`)
  are exposed as plain `Provider` values, constructed once at startup.
- One `ChangeNotifier` per feature, held by a `ChangeNotifierProvider` and named `<Feature>Controller`
  (`OnboardingController`, `HomeController`, `PlanController`). The controller owns the screen's
  mutable state and calls into `core`; widgets never call `core` directly.
- `context.watch<T>()` inside `build`, `context.read<T>()` inside callbacks. No `Consumer` builders
  unless a rebuild needs to be scoped for performance — one convention, not two.

Controllers expose an explicit status enum rather than a set of loose booleans, because the plan
screen has a long-running generation state that must be distinguishable from both "idle" and
"failed" (see the loading requirement in `docs/FLOWS.md`).

## Consequences

- Every feature folder has the same three-file shape — controller, screen, widgets — so a developer
  moving between folders is never surprised. `PlanController` is the reference implementation; the
  others copy it.
- Controllers are plain `ChangeNotifier`s with their dependencies injected through the constructor,
  so they can be unit-tested with fakes and without a widget tree, which is the main thing Riverpod
  would otherwise have bought us.
- Provider resolves by runtime type, so registering two providers of the same type silently shadows
  one. The dependency graph is therefore assembled in exactly one place (`lib/app/providers.dart`)
  and nowhere else.
- `context.read` inside `build` is the classic Provider footgun. The convention above is the
  mitigation; there is no compiler to enforce it, so it is a review item.
- If the app outlives the sprint, migrating to Riverpod is mechanical precisely because the state
  lives in constructor-injected `ChangeNotifier`s rather than in widgets.
