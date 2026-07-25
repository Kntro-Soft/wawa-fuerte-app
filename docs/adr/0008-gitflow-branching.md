# 0008. Gitflow branching model

- Status: Accepted
- Date: 2026-07-25
- Deciders: Kntro-Soft team

## Context

Four developers work in parallel on separate areas of the same codebase and must converge on a
single working build for the demo. Uncoordinated merges into a single branch would leave the demo
branch in an unknown state at the moment it matters most.

The team already runs Gitflow in `reqsai-api`. Reusing a branching model the team knows costs no
ramp-up time, and consistency across the organisation's repositories has value beyond this sprint.

A trunk-based alternative was considered on the grounds that the project lives for six hours, but
the team decided that a known model applied consistently is worth more than a marginally shorter
merge path.

## Decision

Use **Gitflow**:

- `main` — release branch. Holds the demo build. Never receives direct commits.
- `develop` — integration branch. All completed work lands here first.
- `feature/*` — new functionality, branched from `develop`, merged back into `develop`.
- `bugfix/*` — defect fixes on `develop`, branched from and merged back into `develop`.
- `hotfix/*` — urgent fixes branched from `main`, merged into both `main` and `develop`.

Branch names use only these prefixes. **Conventional Commits types (`chore`, `docs`, `ci`, `refactor`)
are commit-message types, not branch prefixes** — they never appear in a branch name.

Commit messages follow Conventional Commits: `<type>(<scope>): <description>`, where scope is the
area (`inference`, `rag`, `nutrition`, `storage`, `onboarding`, `home`, `plan`, `ci`, `docs`).

Commits are **atomic**: one logical change per commit. Large commits bundling unrelated changes are
not acceptable, because they cannot be reviewed or reverted independently.

Given the sprint duration, CODEOWNERS notifies the area owner but branch protection does not require
approval — a red CI is the merge gate, not a human. Everything else in Gitflow applies as written.

## Consequences

- `main` always holds a known-good build, so the demo can be cut from it at any moment without
  auditing what landed.
- Integration problems surface on `develop` where they can be fixed, rather than on the branch the
  demo comes from.
- Every change traverses two merges instead of one. This is the accepted cost of the model.
- Atomic commits make `git revert` a precise tool: a single bad change can be removed without
  unpicking unrelated work from the same commit.
- Consistency with `reqsai-api` means no developer has to hold two branching models in their head.
