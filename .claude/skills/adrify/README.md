# adrify — Architecture Decision Records skill

A Claude Code skill for recording and maintaining Architecture Decision Records
(ADRs) in Michael Nygard's format:
https://www.cognitect.com/blog_posts/2011/11/15/documenting-architecture-decisions

An ADR is one short markdown file capturing a single architecturally significant
decision: the **context** that forced it, the **decision** itself, and its
**consequences**. Records are immutable — when a decision changes, a new record
supersedes the old one rather than editing it.

This directory holds the skill. `SKILL.md` is the instruction file Claude loads;
this README is for humans browsing the repository.

## What it does

The skill keeps the parts that are easy to get inconsistent — sequential
numbering, the index, and the Nygard structure — uniform, so you can focus on the
reasoning. It has three modes, chosen from how you ask:

| You say | Mode | What happens |
|---|---|---|
| "set up ADRs", first use in a repo | **scaffold** | Creates the ADR directory with an index, a template, and the `0000` meta-ADR. |
| "record this decision", "write an ADR for X", `/adrify new` | **interview** | A short, focused Q&A, then writes one record. |
| "catalog our decisions", "document what we've built", `/adrify backfill` | **backfill** | Fans out subagents to mine existing docs and code, proposes a candidate list for you to curate, then writes the approved records. |

Invoke it by asking Claude in plain language, or with `/adrify`, `/adrify new`,
`/adrify backfill`.

## Automatic capture going forward

A companion `Stop` hook, `.claude/hooks/adrify-nudge.sh` (registered in
`.claude/settings.json`), reminds you to record an ADR when a session produces a
"decision signal" — a new dependency, a new package or top-level area, or an
infrastructure / schema file. It is deliberately gentle: non-blocking, at most
once per session, and silent if you already touched an ADR that session.

## Where records live

By default records go in `docs/ADRs`. The target directory is configurable, so a
project can keep one log at the root or distribute logs per package. In this
repository the records are distributed: cross-cutting decisions in `docs/ADRs`,
and per-package decisions under `packages/<name>/docs/ADRs`.

## The `adr.sh` helper

`scripts/adr.sh` owns the deterministic mechanics. The model writes the prose; the
script handles numbering, scaffolding, file creation, and index rebuilds. Each
command takes the ADR directory as an optional trailing argument (default
`docs/ADRs`).

| Command | Purpose |
|---|---|
| `adr.sh scaffold [<dir>]` | Create the directory, index, meta-ADR, and template (idempotent). |
| `adr.sh next "<title>" [<dir>]` | Print the next numbered file path without creating it. |
| `adr.sh create "<title>" [<dir>]` | Create the next record from the template and print its path. |
| `adr.sh list [<dir>]` | List existing records. |
| `adr.sh reindex [<dir>]` | Rebuild the index block in `README.md` from the records. |

## Layout

```
.claude/skills/adrify/
├── SKILL.md                     instructions Claude loads
├── README.md                    this file
├── scripts/
│   └── adr.sh                   numbering, scaffold, create, list, reindex
└── references/
    ├── nygard_format.md         section-by-section writing guidance + examples
    ├── backfill_guide.md        where decisions hide; the subagent brief
    └── reuse.md                 dropping the mechanism into another project
```

## Conventions

- Files are named `NNNN-kebab-title.md`, four-digit zero-padded; `0000` is the
  meta-ADR. The script assigns numbers — do not hand-number.
- One decision per record. Records are immutable; to reverse a decision, write a
  new ADR and mark the old one `superseded by NNNN`.
- Statuses: `proposed`, `accepted`, `deprecated`, `superseded by NNNN`.

## Reusing this in another project

The skill and its hook are self-contained. Copy `.claude/skills/adrify/` and
`.claude/hooks/adrify-nudge.sh`, register the `Stop` hook, and tune the hook's
SIGNALS block for the project's stack. Full instructions are in
[`references/reuse.md`](references/reuse.md).
