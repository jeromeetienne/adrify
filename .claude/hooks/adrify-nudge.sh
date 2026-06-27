#!/usr/bin/env bash
#
# adrify-nudge.sh — Stop hook companion to the `adrify` skill.
#
# When a working session has produced "decision signals" — the kind of change
# that usually reflects an architectural decision — this reminds the user to
# record an ADR. It is deliberately gentle:
#   * non-blocking (exit 0, prints a `systemMessage`, never `decision: block`),
#   * fires at most once per session (a marker file guards re-nudging),
#   * stays quiet if an ADR was already touched this session.
#
# Tune SIGNALS for your project — that is the part worth editing when you reuse
# this hook elsewhere.

set -euo pipefail

input=$(cat)

# Minimal, dependency-free extraction of the flat fields we need so this hook
# works on machines without jq.
json_str() { printf '%s' "$input" | sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" | head -1; }

# Print the dependency names declared in a package.json read from stdin. Tracks
# the standard *Dependencies blocks (the multi-line shape every package manager
# writes). Comparing the resulting sets is far more reliable than reading diff
# lines, which cannot tell a dependency from a version bump or a new script.
deps_of() {
	awk '
		/"(dependencies|devDependencies|peerDependencies|optionalDependencies)"[[:space:]]*:[[:space:]]*\{/ { indep=1; next }
		indep && /}/ { indep=0; next }
		indep && match($0, /"[^"]+"[[:space:]]*:/) {
			key=substr($0, RSTART+1)
			sub(/".*/, "", key)
			print key
		}
	'
}

session_id=$(json_str session_id)
cwd=$(json_str cwd)
[ -n "$cwd" ] || cwd="$PWD"
[ -n "$session_id" ] || session_id="nosession"

ADR_DIR="${ADR_DIR:-docs/ADRs}"
marker="${TMPDIR:-/tmp}/claude-adrify-nudge-${session_id}"

# Already nudged this session, or not a git repo — stay silent.
[ -f "$marker" ] && exit 0
git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1 || exit 0

# If the user is already recording a decision, there is nothing to nudge about.
if [ -n "$(git -C "$cwd" status --porcelain -- "$ADR_DIR" 2>/dev/null)" ]; then
	exit 0
fi

# All changes since HEAD, tracked and untracked, as plain paths.
changed=$(
	{
		git -C "$cwd" diff --name-only HEAD 2>/dev/null
		git -C "$cwd" ls-files --others --exclude-standard 2>/dev/null
	} | sort -u
)
[ -n "$changed" ] || exit 0

reason=""

# --- SIGNALS -------------------------------------------------------------
# A dependency was added: a name now present in some package.json *Dependencies
# block that was not present at HEAD.
pkg_jsons=$(printf '%s\n' "$changed" | grep 'package\.json$' || true)
if [ -n "$pkg_jsons" ]; then
	while IFS= read -r pj; do
		[ -n "$pj" ] && [ -f "$cwd/$pj" ] || continue
		added=$(comm -13 \
			<(git -C "$cwd" show "HEAD:$pj" 2>/dev/null | deps_of | sort -u) \
			<(deps_of < "$cwd/$pj" | sort -u))
		[ -n "$added" ] && { reason="a dependency was added"; break; }
	done <<< "$pkg_jsons"
fi

# A new top-level area or package appeared.
if [ -z "$reason" ]; then
	# Candidate new directories: a brand-new top-level dir, or a new package
	# directly under a monorepo container. A lone new file at the root is not an
	# "area" and must not trigger this.
	new_top=$(printf '%s\n' "$changed" | awk -F/ '
		NF>1 { print $1 }
		NF>2 && ($1=="packages"||$1=="apps"||$1=="services"||$1=="crates"||$1=="modules") { print $1"/"$2 }
	' | sort -u)
	while IFS= read -r p; do
		[ -n "$p" ] || continue
		if [ -z "$(git -C "$cwd" ls-tree HEAD -- "$p" 2>/dev/null)" ] \
			&& [ -n "$(git -C "$cwd" status --porcelain -- "$p" 2>/dev/null)" ]; then
			reason="a new package or top-level area was added ($p)"
			break
		fi
	done <<< "$new_top"
fi

# Infrastructure / boundary files that usually encode a decision.
if [ -z "$reason" ]; then
	if printf '%s\n' "$changed" | grep -qiE '(^|/)(dockerfile|docker-compose\.ya?ml|.*\.tf|.*\.proto)$|(^|/)(migrations|schema)(/|$)'; then
		reason="an infrastructure or schema/boundary file changed"
	fi
fi
# -------------------------------------------------------------------------

[ -n "$reason" ] || exit 0

touch "$marker"
msg="This session looks like it made an architectural decision ($reason). Consider running /adrify new to record it."
printf '{"systemMessage": "%s"}\n' "$msg"
exit 0
