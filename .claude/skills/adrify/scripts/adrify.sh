#!/usr/bin/env bash
#
# adrify.sh — deterministic helpers for the `adrify` skill.
#
# The model writes the prose of each Architecture Decision Record; this script
# owns the fiddly, error-prone mechanics (next number, zero-padding, slugifying,
# scaffolding) so they are done the same way every time.
#
# Usage:
#   adrify.sh scaffold [<dir>]          Create the ADR directory, index, meta-ADR
#                                    and template if they do not exist.
#   adrify.sh next "<title>" [<dir>]    Print the path of the next ADR file
#                                    (NNNN-slug.md) WITHOUT creating it.
#   adrify.sh create "<title>" [<dir>]  Create the next ADR file from the template
#                                    and print its path.
#   adrify.sh list [<dir>]              List existing ADRs, one per line.
#   adrify.sh reindex [<dir>]           Rebuild the index block in README.md from
#                                    the ADR files (title + status of each).
#
# <dir> defaults to docs/ADRs relative to the current working directory.

set -euo pipefail

ADR_DIR="${2:-docs/ADRs}"
# For `next`/`create` the title is $2, so the directory shifts to $3.
case "${1:-}" in
	next|create)
		ADR_DIR="${3:-docs/ADRs}"
		;;
esac

slugify() {
	printf '%s' "$1" \
		| tr '[:upper:]' '[:lower:]' \
		| sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//'
}

next_number() {
	local max=0 n
	shopt -s nullglob
	for f in "$ADR_DIR"/[0-9][0-9][0-9][0-9]-*.md; do
		n=$(basename "$f" | cut -c1-4)
		n=$((10#$n))
		(( n > max )) && max=$n
	done
	printf '%04d' $(( max + 1 ))
}

cmd_scaffold() {
	mkdir -p "$ADR_DIR"

	if [ ! -f "$ADR_DIR/template.md" ]; then
		cat > "$ADR_DIR/template.md" <<'EOF'
# NNNN. <Short title of the decision>

- Status: proposed
- Date: <YYYY-MM-DD>
- Deciders: <people / roles involved>

## Context

<The forces at play: the situation, constraints, and problem that make a
decision necessary. State the facts neutrally — this is the "why now".>

## Decision

<The change we are making, stated in active voice: "We will …".>

## Consequences

<What becomes easier and what becomes harder as a result. Include the
trade-offs we accept, the risks, and any follow-up work the decision creates.>
EOF
	fi

	if [ ! -f "$ADR_DIR/0000-record-architecture-decisions.md" ]; then
		cat > "$ADR_DIR/0000-record-architecture-decisions.md" <<'EOF'
# 0000. Record architecture decisions

- Status: accepted
- Date: <YYYY-MM-DD>
- Deciders: <team>

## Context

We want to capture the significant architectural decisions made on this project,
together with their context and consequences, so that newcomers and our future
selves can understand why the system is the way it is.

## Decision

We will use Architecture Decision Records, as described by Michael Nygard in
https://www.cognitect.com/blog_posts/2011/11/15/documenting-architecture-decisions

Each record is a short markdown file in `docs/ADRs`, numbered sequentially and
never deleted. When a decision is reversed, we add a new record that supersedes
the old one rather than editing history.

## Consequences

The reasoning behind the architecture is preserved and reviewable. The cost is
the small, ongoing discipline of writing a record when a real decision is made.
EOF
	fi

	if [ ! -f "$ADR_DIR/README.md" ]; then
		cat > "$ADR_DIR/README.md" <<'EOF'
# Architecture Decision Records

This directory records the significant architecture decisions for this project,
in the format described by Michael Nygard. Each file is one decision; records
are immutable — supersede rather than rewrite.

See `0000-record-architecture-decisions.md` for why we do this, and
`template.md` for the shape of a new record.

## Index

<!-- adr-index:start -->
- [0000. Record architecture decisions](0000-record-architecture-decisions.md) — accepted
<!-- adr-index:end -->
EOF
	fi

	echo "$ADR_DIR"
}

cmd_next() {
	local title="${2:-}"
	[ -n "$title" ] || { echo "error: title required" >&2; exit 1; }
	echo "$ADR_DIR/$(next_number)-$(slugify "$title").md"
}

cmd_create() {
	local title="${2:-}"
	[ -n "$title" ] || { echo "error: title required" >&2; exit 1; }
	mkdir -p "$ADR_DIR"
	local num path
	num=$(next_number)
	path="$ADR_DIR/$num-$(slugify "$title").md"
	if [ -f "$ADR_DIR/template.md" ]; then
		sed "s/^# NNNN\. .*/# $num. $title/" "$ADR_DIR/template.md" > "$path"
	else
		printf '# %s. %s\n\n- Status: proposed\n- Date: \n\n## Context\n\n## Decision\n\n## Consequences\n' "$num" "$title" > "$path"
	fi
	echo "$path"
}

cmd_list() {
	shopt -s nullglob
	for f in "$ADR_DIR"/[0-9][0-9][0-9][0-9]-*.md; do
		echo "$f"
	done
}

cmd_reindex() {
	local readme="$ADR_DIR/README.md"
	[ -f "$readme" ] || { echo "error: no README.md in $ADR_DIR" >&2; exit 1; }
	local tmplist base title status
	tmplist=$(mktemp)
	shopt -s nullglob
	for f in "$ADR_DIR"/[0-9][0-9][0-9][0-9]-*.md; do
		base=$(basename "$f")
		title=$(sed -n '1s/^#[[:space:]]*//p' "$f")
		status=$(sed -n 's/^-[[:space:]]*Status:[[:space:]]*//p' "$f" | head -1)
		[ -n "$title" ] || title="$base"
		[ -n "$status" ] || status="?"
		printf -- '- [%s](%s) — %s\n' "$title" "$base" "$status" >> "$tmplist"
	done
	# Read the generated lines from a file (awk -v cannot carry newlines).
	awk -v listfile="$tmplist" '
		/<!-- adr-index:start -->/ {
			print
			while ((getline line < listfile) > 0) print line
			close(listfile)
			skip=1
			next
		}
		/<!-- adr-index:end -->/ { skip=0 }
		skip != 1 { print }
	' "$readme" > "$readme.tmp" && mv "$readme.tmp" "$readme"
	rm -f "$tmplist"
	echo "$readme"
}

case "${1:-}" in
	scaffold) cmd_scaffold ;;
	next)     cmd_next "$@" ;;
	create)   cmd_create "$@" ;;
	list)     cmd_list ;;
	reindex)  cmd_reindex ;;
	*)
		echo "usage: adrify.sh {scaffold|next|create|list|reindex} [args]" >&2
		exit 1
		;;
esac
