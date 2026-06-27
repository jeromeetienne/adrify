---
name: adrify
description: >-
  Record and maintain Architecture Decision Records (ADRs) in Nygard format
  under docs/ADRs. Use this whenever the user wants to document an architecture
  or design decision, asks to "write an ADR", "record a decision", "document why
  we chose X", set up an ADR log, or backfill/catalog the decisions already baked
  into an existing codebase. Also use it when reusing this mechanism in another
  project. Three modes: scaffold the docs/ADRs directory, "new" (interview the
  user to capture one fresh decision), and "backfill" (mine existing docs and
  code to reconstruct past decisions). Prefer this skill over writing ad-hoc
  markdown so numbering, the index, and the Nygard structure stay consistent.
---

# Architecture Decision Records

An ADR captures one architecturally significant decision: the context that
forced it, the decision itself, and the consequences. The format is Michael
Nygard's (https://www.cognitect.com/blog_posts/2011/11/15/documenting-architecture-decisions).
Records are immutable — when a decision changes, write a new record that
supersedes the old one rather than editing the old one.

This skill keeps three things consistent so the user can focus on the reasoning:
sequential numbering, the index in `docs/ADRs/README.md`, and the Nygard
structure. A bundled script owns the mechanics; you own the prose.

## Pick the mode from what the user asked

- **"new", "record this decision", "write an ADR for X"** → Interview mode.
- **"backfill", "catalog our decisions", "document what we've already built"** →
  Backfill mode.
- **"set up ADRs", first use in a repo, or any mode when `docs/ADRs` is missing**
  → Scaffold first, then continue.

The helper script lives next to this file. Resolve its directory from the skill
location and always call it with the project root as the working directory:

```bash
ADR="$CLAUDE_PROJECT_DIR/.claude/skills/adrify/scripts/adrify.sh"   # adjust if reused elsewhere
```

## Scaffold (run once per repo)

If `docs/ADRs` has no `README.md`, create the structure before doing anything
else:

```bash
bash "$ADR" scaffold        # creates docs/ADRs/{README.md, template.md, 0000-record-architecture-decisions.md}
```

This is idempotent — it never overwrites existing files. After scaffolding, fill
in the `<YYYY-MM-DD>` placeholders in `0000-…` and the index with the current
date. The `0000` meta-ADR records the decision to use ADRs at all; leave it in
place.

## Interview mode — capture one fresh decision

The goal is a record someone can understand in a year. Do not interrogate the
user with a long form; have a short, focused conversation, then write the file.

1. **Get the decision in one sentence.** If the user already stated it, confirm
   your phrasing. A good title names the decision, not the problem:
   "Use SQLite for the job board", not "Database choice".
2. **Draw out the three Nygard sections** with at most a few questions each. You
   usually have most of this from the surrounding conversation or the code —
   propose a draft and ask the user to correct it rather than asking cold:
   - **Context** — what forces made this necessary now? Constraints, scale,
     team, prior art. State facts neutrally.
   - **Decision** — what are we doing, in active voice ("We will …")? Include
     the alternatives considered and *why they lost* — that is the part future
     readers most need.
   - **Consequences** — what gets easier, what gets harder, what new work or
     risk this creates. Honest trade-offs, not just upsides.
3. **Create the file and write it in:**
   ```bash
   path=$(bash "$ADR" create "<title>")   # prints docs/ADRs/NNNN-slug.md
   ```
   Then edit `$path`: set Status (usually `accepted` for a decision being made
   now, `proposed` if still under discussion), today's date, deciders, and the
   three sections.
4. **Rebuild the index** so `docs/ADRs/README.md` lists the new record:
   ```bash
   bash "$ADR" reindex      # regenerates the index block from the files
   ```
5. **Show the user the finished record** and confirm.

See `references/nygard_format.md` for section-by-section guidance and worked
examples of strong vs. weak writing.

## Backfill mode — reconstruct decisions already made

Existing codebases are full of decisions that were never written down. The job
is to surface them, let the user choose which are worth recording, then write
them. **Do not write a pile of ADRs without the user's sign-off on the list** —
curation is the point.

1. **Scaffold** if needed (above).
2. **Mine the codebase for decisions.** Fan out parallel `Explore` subagents
   (one per major area — package, subsystem, or doc source) so this is fast and
   broad. Tell each agent to return *candidate decisions*, not a code tour. Good
   signal sources and the exact agent brief are in
   `references/backfill_guide.md` — read it before launching.
3. **Propose a numbered candidate list** to the user: for each candidate, a
   one-line title and a one-line "why it's a decision". Let the user cull, merge,
   rename, and reorder. This list is the deliverable of this step.
4. **Write the approved ones**, lowest number first, each via
   `bash "$ADR" create "<title>"` then editing the file. Use Status `accepted`
   (these are decisions already in force) and date them with the project's start
   or the decision's best-known date, noting in Context that the record was
   written retroactively.
5. **Rebuild the index** once all records are written: `bash "$ADR" reindex`.

## Conventions (keep these stable so the log stays trustworthy)

- Files: `NNNN-kebab-title.md`, four-digit zero-padded, `0000` reserved for the
  meta-ADR. The script computes the next number — do not hand-number.
- Records are immutable. To reverse a decision, write a new ADR and set the old
  one's Status to `superseded by NNNN`; add `supersedes NNNN` on the new one.
- Statuses: `proposed`, `accepted`, `deprecated`, `superseded by NNNN`.
- One decision per record. If you find yourself writing "and also", split it.

## Reusing this skill in another project

The skill is self-contained: copy `.claude/skills/adrify/` and, for automatic
nudges, `.claude/hooks/adrify-nudge.sh` plus its `Stop` hook entry in
`.claude/settings.json`. The only project-specific part worth editing is the
SIGNALS section of the hook. See `references/reuse.md`.
