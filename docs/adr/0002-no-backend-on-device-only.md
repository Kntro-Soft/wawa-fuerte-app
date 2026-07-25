# 0002. No backend, on-device only

- Status: Accepted, amended by [ADR-0015](0015-hosted-nutrition-agent.md)
- Date: 2026-07-25
- Deciders: Kntro-Soft team

> **Amendment (ADR-0015).** Plan generation may now optionally run against a
> hosted nutrition agent when a channel API key is compiled in. Everything below
> still describes the default build, which compiles in no key, opens no socket
> and keeps all data on the device. Read ADR-0015 for what changes when a key is
> present — in particular, that hemoglobin readings then leave the handset.

## Context

The problem we target is childhood anemia in rural and peri-urban Peru, where connectivity is
intermittent or absent. A conventional client/server design would make the app useless in exactly
the places that need it most.

A backend would also cost sprint time we do not have: hosting, authentication, deployment, and a
network error path in every screen.

The data involved is health data about minors (age, hemoglobin readings). Any transmission or
remote storage of it raises a privacy burden we have neither the time nor the mandate to discharge
properly.

## Decision

Ship a single Flutter application with **no server component of any kind**. The Gemma model, the
INS recipe book, the precomputed embeddings, and the user's data all live on the device.

- No HTTP client, no API keys, no authentication.
- "Login" is a local profile name for personalisation only — there is nobody to authenticate against.
- Photos captured for ingredient recognition are processed in memory and discarded, never written
  to disk and never uploaded.

## Consequences

- The offline claim in the pitch is literally true and can be demonstrated in airplane mode, which
  is far more convincing to judges than an architecture diagram.
- Health data never leaves the handset, so there is no data-protection surface to defend.
- No repository split (api/web/infra) is warranted — a single repo is the correct shape here, unlike
  `reqsai-api`.
- The model file is large (>1 GB) and must be distributed out-of-band rather than bundled in git.
- Any future feature that inherently needs a server (sync across devices, clinician dashboards) is
  out of scope and would require superseding this ADR.
