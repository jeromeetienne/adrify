# adrjournal — Architecture Decision Records skill

A Claude Code skill for recording and maintaining Architecture Decision Records
(ADRs) in Michael Nygard's format:
https://www.cognitect.com/blog_posts/2011/11/15/documenting-architecture-decisions

An ADR is one short markdown file capturing a single architecturally significant
decision: the **context** that forced it, the **decision** itself, and its
**consequences**. Records are immutable — when a decision changes, a new record
supersedes the old one rather than editing it.

The skill prose lives in
[`dotclaude_folder/skills/adrjournal/`](dotclaude_folder/skills/adrjournal); its
deterministic mechanics live in [`src/`](src) as a small TypeScript CLI.

[![npm version](https://img.shields.io/npm/v/adrjournal.svg)](https://www.npmjs.com/package/adrjournal)
[![downloads](https://img.shields.io/npm/dm/adrjournal.svg)](https://www.npmjs.com/package/adrjournal)
[![License](https://img.shields.io/github/license/jeromeetienne/adrjou)](LICENSE)

## How to install

Run `npx adrjournal install <target>/.claude` to drop the skill prose into the
target and auto-register `npx adrjournal nudge` as a `Stop` hook — no source
checkout needed. Full instructions are in
[`references/reuse.md`](dotclaude_folder/skills/adrjournal/references/reuse.md).

## Blog

A short series on why adrjournal exists and how it's designed:

1. [adrjournal: Your Codebase Is Full of Decisions Nobody Wrote Down](docs/blog_posts/part-1-decisions-nobody-wrote-down.md)
2. [adrjournal: Stop Asking the Model to Count (The Code-vs-Model Split)](docs/blog_posts/part-2-stop-asking-the-model-to-count.md)
3. [adrjournal: Designing a Nudge That Helps Without Nagging](docs/blog_posts/part-3-a-nudge-that-helps-without-nagging.md)

## What it does

The skill keeps the parts that are easy to get inconsistent — sequential
numbering, the index, and the Nygard structure — uniform, so you can focus on the
reasoning. It has three modes, chosen from how you ask:

| You say | Mode | What happens |
|---|---|---|
| "set up ADRs", first use in a repo | **scaffold** | Creates the ADR directory with an index, a template, and the `0000` meta-ADR. |
| "record this decision", "write an ADR for X", `/adrjournal new` | **interview** | A short, focused Q&A, then writes one record. |
| "catalog our decisions", "document what we've built", `/adrjournal backfill` | **backfill** | Fans out subagents to mine existing docs and code, proposes a candidate list for you to curate, then writes the approved records. |

Invoke it by asking Claude in plain language, or with `/adrjournal`, `/adrjournal new`,
`/adrjournal backfill`.

## Automatic capture going forward

A companion `Stop` hook — `npx adrjournal nudge`, registered in the consuming
project's `.claude/settings.json` — reminds you to record an ADR when a session
produces a "decision signal": a new dependency, a new package or top-level area,
or an infrastructure / schema file. It is deliberately gentle: non-blocking, at
most once per session, and silent if you already touched an ADR that session. See
[`references/reuse.md`](dotclaude_folder/skills/adrjournal/references/reuse.md) to
register it.

## Where records live

By default records go in `docs/ADRs`. The target directory is configurable, so a
project can keep one log at the root or distribute logs per package. The CLI
takes the directory as an optional trailing argument; the hook honours an
`ADR_DIR` environment variable.

## The `adrjournal` CLI

The published [`adrjournal`](https://www.npmjs.com/package/adrjournal) CLI owns
the deterministic mechanics, run with `npx` (Node ≥20.12). The model writes the
prose; the CLI handles numbering, scaffolding, file creation, and index rebuilds.
Each record command takes the ADR directory as an optional trailing argument
(default `docs/ADRs`).

| Command | Purpose |
|---|---|
| `adrjournal scaffold [<dir>]` | Create the directory, index, meta-ADR, and template (idempotent). |
| `adrjournal next "<title>" [<dir>]` | Print the next numbered file path without creating it. |
| `adrjournal create "<title>" [<dir>]` | Create the next record from the template and print its path. |
| `adrjournal list [<dir>]` | List existing records. |
| `adrjournal reindex [<dir>]` | Rebuild the index block in the ADR directory's `README.md` from the records. |
| `adrjournal nudge` | Stop-hook entry: read the hook payload on stdin and maybe remind. |
| `adrjournal install [<agent_folder>]` | Copy the bundled agent files into the agent folder (default `.`, e.g. `.claude`); when the target is a `.claude` folder, also register the `npx adrjournal nudge` Stop hook in its `settings.json` (idempotent, non-destructive). |

Run any command with `npx adrjournal <command>`. When developing in this repo you
can also run the source directly with `npx tsx src/cli.ts <command>`, or via the
npm script `npm run adrjournal -- <command>`.

## Layout

```
src/
├── cli.ts                       Commander entry; parses the subcommands below
├── misc/
│   └── adr_store.ts             shared mechanics: numbering, slugging, indexing
└── commands/
    ├── scaffold_command.ts      create the directory, template, meta-ADR, index
    ├── next_command.ts          print the next record path
    ├── create_command.ts        create the next record from the template
    ├── list_command.ts          list existing records
    ├── reindex_command.ts       rebuild the index block in README.md
    ├── nudge_command.ts         the Stop-hook nudge
    └── install_command.ts       copy the agent files into a target agent folder
dotclaude_folder/skills/adrjournal/
├── SKILL.md                     instructions Claude loads
└── references/
    ├── nygard_format.md         section-by-section writing guidance + examples
    ├── backfill_guide.md        where decisions hide; the subagent brief
    └── reuse.md                 dropping the mechanism into another project
```

## Conventions

- Files are named `NNNN-kebab-title.md`, four-digit zero-padded; `0000` is the
  meta-ADR. The CLI assigns numbers — do not hand-number.
- Every record needs a title. `create` and `next` reject an empty or
  symbol-only title (`error: title required`, exit 1) rather than writing a
  malformed `NNNN-.md` file.
- One decision per record. Records are immutable; to reverse a decision, write a
  new ADR and mark the old one `superseded by NNNN`.
- Statuses: `proposed`, `accepted`, `deprecated`, `superseded by NNNN`.
