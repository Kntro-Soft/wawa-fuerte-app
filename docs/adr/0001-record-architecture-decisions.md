# 0001. Record architecture decisions

- Status: Accepted
- Date: 2026-07-25
- Deciders: Kntro-Soft team

## Context

This project is built during a 6-hour hackathon sprint by four developers working in parallel,
three of them remote from the machine that owns the demo device. Decisions taken verbally in the
first hour are the ones most likely to be forgotten, re-litigated, or silently contradicted at
hour four — exactly when there is no time to recover.

The team already uses ADRs in `reqsai-api`, so the format is familiar and needs no ramp-up.

## Decision

Record every significant architectural decision as an ADR in `docs/adr/`, using Michael Nygard's
format. ADRs are immutable once accepted; to reverse a decision, add a new ADR that supersedes the
previous one.

Scope discipline for a short sprint: only decisions that would cost real rework to reverse get an
ADR. Library-level trivia does not.

## Consequences

- The Kaggle Writeup can cite the ADRs directly — the judging criteria reward a clear explanation
  of why technical decisions were made, and this is that explanation, written while it was fresh.
- A developer blocked at hour three can read why something is the way it is without interrupting
  the person who decided it.
- Writing ADRs costs time during the sprint. Kept short (under a screen each), the cost is minutes
  and it is paid back the first time a decision is questioned.
