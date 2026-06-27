# Reusing the ADR mechanism in another project

The skill and its hook are self-contained. To add them to a different repository:

## 1. Copy the files

```bash
# from this repo into the target repo
cp -r .claude/skills/adrify           <target>/.claude/skills/adrify
cp    .claude/hooks/adrify-nudge.sh   <target>/.claude/hooks/adrify-nudge.sh
chmod +x <target>/.claude/skills/adrify/scripts/adr.sh <target>/.claude/hooks/adrify-nudge.sh
```

## 2. Register the Stop hook

Merge this into the target's `.claude/settings.json` (create the file if absent;
keep any existing hooks):

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/adrify-nudge.sh"
          }
        ]
      }
    ]
  }
}
```

## 3. Tune the SIGNALS section of the hook

`adrify-nudge.sh` decides when to nudge from a small, clearly marked SIGNALS block.
The defaults assume a Node/TypeScript project (added dependency in a
`package.json`, a new top-level package, infra/schema/boundary files). For other
stacks, edit that block:

- **Python** — watch `pyproject.toml` / `requirements.txt` additions, new
  top-level packages, `alembic/` migrations.
- **Go** — watch `go.mod` `require` additions, new top-level modules.
- **Rust** — watch `Cargo.toml` `[dependencies]` additions.

The rest of the hook (once-per-session marker, "skip if an ADR was already
touched", non-blocking `systemMessage`) is project-agnostic and needs no change.

## 4. Optional: change where records live

The skill and hook both default to `docs/ADRs`. The hook honours an `ADR_DIR`
environment variable; the skill script takes the directory as a trailing
argument. If a project keeps records elsewhere, set `ADR_DIR` in the hook entry
and pass the directory to `adr.sh`.

## What is and is not portable

- **Portable as-is:** the Nygard format, numbering, index maintenance, the
  interview and backfill workflows, the once-per-session non-blocking nudge.
- **Worth reviewing per project:** the SIGNALS block, the records directory, and
  whether `$CLAUDE_PROJECT_DIR` resolves (it is set by Claude Code; if you invoke
  the hook another way, pass an absolute path).
