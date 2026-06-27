# Backfill guide — mining decisions from an existing codebase

The aim is to surface decisions that were made but never written down, present
them for the user to curate, and only then write records. Breadth and speed come
from fanning out read-only subagents; quality comes from the user's curation
step. Do not skip the curation step.

## Where decisions hide (signal sources)

Point agents at these, in rough order of value:

- **Dependency and config manifests** — `package.json`, lockfiles, `tsconfig`,
  `Dockerfile`, CI config. Every non-trivial dependency is a decision: a chosen
  framework, ORM, test runner, protocol library.
- **Top-level structure** — the package/module layout, monorepo splits, the
  boundary between services. How the code is divided is itself a decision.
- **Existing prose** — `README.md`, `CLAUDE.md`, `docs/`, a wiki, design notes,
  PR descriptions, commit messages with rationale ("switched to X because …").
- **Data and persistence** — schema files, migrations, the choice of store.
- **Cross-cutting patterns** — how auth, error handling, config, logging, and
  the build are done. Conventions repeated across the code encode a decision.
- **Conspicuous absences** — no build step, no server framework, no test mocks:
  deliberate omissions are decisions too.

## The agent brief (use for each Explore subagent)

Give each agent one area and this shape of instruction:

> Explore <area> of this repository. Identify **architectural decisions** that
> appear to have been made — technology choices, structural splits, persistence
> choices, cross-cutting patterns, and deliberate omissions. For each, return:
> a one-line title naming the decision, a one-line rationale you can infer from
> the code/docs, and 1–3 file paths as evidence. Return a list only; do not
> propose fixes or tour the code. Aim for the genuinely significant — skip
> trivial style choices.

Run them in parallel, one per major area, so the sweep is fast.

## From candidates to a list

Collect every agent's candidates, then **deduplicate and merge** — the same
decision often surfaces from several areas. Drop the trivial. Produce a single
numbered list and show it to the user:

```
Proposed ADRs (please cull / merge / rename):
 1. Split into open-source agent vs. private dev-hub repositories — why: ...
 2. Use @openai/agents for tool/agent orchestration — why: ...
 3. Describe agents and skills in markdown (SKILL.md) — why: ...
 ...
```

Wait for the user to approve the list before writing anything.

## Writing retroactive records

- Status is `accepted` — these decisions are already in force.
- Date with the project's best-known date for the decision; if unknown, use the
  repo's start. Add a short note in Context that the record was written
  retroactively, so readers don't mistake it for a contemporaneous one.
- Keep the discipline of Context / Decision / Consequences. For consequences,
  describe what the codebase actually lives with today.
- Number lowest-first and update the index as you go.
