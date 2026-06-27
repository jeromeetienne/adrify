# Nygard ADR format — writing guidance

An ADR is short on purpose: one page, one decision. Its value is the reasoning,
not ceremony. Below is what each section is for and how to tell a strong record
from a weak one.

## The template

```
# NNNN. <Short title naming the decision>

- Status: proposed | accepted | deprecated | superseded by NNNN
- Date: YYYY-MM-DD
- Deciders: <people or roles>

## Context
## Decision
## Consequences
```

## Title

Name the **decision**, in a form that reads as a claim. The reader should know
what was decided without opening the file.

- Weak: "Database", "Auth", "Frontend framework"
- Strong: "Use SQLite as the job-board store", "Authenticate with short-lived
  JWTs", "Render the web client with no build step"

## Context

The forces at play — stated as neutral facts, not as the answer. A good Context
section would be agreed to by someone who would have chosen differently. Include:
constraints (team size, deadlines, existing stack), the scale or load that
matters, and the prior art or trigger that made a decision necessary *now*.

- Weak: "We need a database. SQLite is great because it's simple." (smuggles the
  decision into the context; editorializes)
- Strong: "The job board runs as a single-process dispatcher on one host. Jobs
  are low-volume (hundreds/day) and must survive restarts. We have no ops team
  to run a separate database server."

## Decision

The decision in active voice — "We will …" — plus the alternatives considered
and **why they lost**. The rejected options are the most valuable part: they stop
the team from re-litigating the same choice in six months.

- Weak: "We'll use SQLite."
- Strong: "We will store the job board in a single SQLite file. We considered
  Postgres (rejected: needs a server and ops we don't have) and an in-memory
  queue (rejected: loses jobs on restart). SQLite gives durability with zero
  operational overhead at our volume."

## Consequences

What becomes easier *and* harder. Be honest about the costs — a record that only
lists upsides is not trusted.

- Weak: "Now we have a database."
- Strong: "Deployment stays a single binary plus a file; backups are a file
  copy. We accept that horizontal scaling and concurrent writers are limited;
  if volume grows past one host we will need a new ADR superseding this one."

## Status lifecycle

- `proposed` — under discussion, not yet in force.
- `accepted` — in force. Most records written for decisions already made.
- `deprecated` — no longer recommended but not replaced.
- `superseded by NNNN` — replaced by a later record. Set this on the old file;
  put `supersedes NNNN` near the top of the new one. Never delete the old file.

## A complete short example

```
# 0007. Use SQLite as the job-board store

- Status: accepted
- Date: 2026-02-10
- Deciders: core team

## Context
The job board runs as a single-process dispatcher on one host. Jobs are
low-volume and must survive process restarts. There is no ops team to operate a
separate database service.

## Decision
We will persist the job board in one SQLite file. Alternatives: Postgres
(rejected — requires a server and operations we cannot staff) and an in-memory
queue (rejected — does not survive restarts).

## Consequences
Deployment remains a single process plus a file; backup is a file copy. Write
concurrency and multi-host scaling are limited; exceeding one host will require a
superseding ADR.
```
