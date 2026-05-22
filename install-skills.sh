#!/usr/bin/env bash
# install-skills.sh — install all skills from this market into ~/.claude/skills/
#
# Usage:  ./install-skills.sh
#         bash /path/to/steve-skill-market/install-skills.sh
#
# Safe to re-run: files that haven't changed are skipped.
# Installs each SKILL.md under ~/.claude/skills/<skill-name>/SKILL.md.
# Any RULES.md sitting alongside a SKILL.md is also installed.

set -euo pipefail

MARKET_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="$MARKET_DIR/skills"
SKILLS_DST="${HOME}/.claude/skills"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# extract_name <skill_md_path>
# Reads the skill name from the frontmatter, trying two formats:
#
#   Format A — YAML block (standard market format):
#     ---
#     name: my-skill
#     description: ...
#     ---
#
#   Format B — inline header (older format used in some skills):
#     ## name: my-skill description: ... allowed-tools: ...
#
# Falls back to the directory path relative to skills/, with / replaced by -.
extract_name() {
    local skill_md="$1"
    local skill_dir
    skill_dir="$(dirname "$skill_md")"
    local name=""

    # Format A: first bare "name: <value>" line (inside YAML frontmatter)
    name="$(grep -m1 '^name: ' "$skill_md" 2>/dev/null \
            | sed 's/^name: *//' \
            | tr -d '[:space:]' \
            || true)"

    # Format B: "## name: <value> ..."
    if [[ -z "$name" ]]; then
        name="$(grep -m1 '^## name:' "$skill_md" 2>/dev/null \
                | sed 's/^## name: \([^ ]*\).*/\1/' \
                || true)"
    fi

    # Fallback: relative path with slashes replaced by dashes
    if [[ -z "$name" ]]; then
        local rel="${skill_dir#"$SKILLS_SRC/"}"
        name="${rel//\//-}"
    fi

    printf '%s' "$name"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

if [[ ! -d "$SKILLS_SRC" ]]; then
    echo "error: skills directory not found: $SKILLS_SRC" >&2
    exit 1
fi

mkdir -p "$SKILLS_DST"

installed=0
updated=0
current=0

while IFS= read -r skill_md; do
    skill_dir="$(dirname "$skill_md")"
    name="$(extract_name "$skill_md")"

    if [[ -z "$name" ]]; then
        echo "  skip     (no name found) $skill_md" >&2
        continue
    fi

    dst_dir="$SKILLS_DST/$name"
    mkdir -p "$dst_dir"

    # ---- SKILL.md ----
    if [[ ! -f "$dst_dir/SKILL.md" ]]; then
        cp "$skill_md" "$dst_dir/SKILL.md"
        printf '  install  %s\n' "$name"
        installed=$((installed + 1))
    elif cmp -s "$skill_md" "$dst_dir/SKILL.md"; then
        current=$((current + 1))
    else
        cp "$skill_md" "$dst_dir/SKILL.md"
        printf '  update   %s\n' "$name"
        updated=$((updated + 1))
    fi

    # ---- companion RULES.md (if present alongside SKILL.md) ----
    if [[ -f "$skill_dir/RULES.md" ]]; then
        if [[ ! -f "$dst_dir/RULES.md" ]] \
           || ! cmp -s "$skill_dir/RULES.md" "$dst_dir/RULES.md"; then
            cp "$skill_dir/RULES.md" "$dst_dir/RULES.md"
        fi
    fi

done < <(find "$SKILLS_SRC" -name "SKILL.md" | sort)

total=$((installed + updated + current))
echo ""
echo "Installed to: $SKILLS_DST"
printf '%d skills: %d installed, %d updated, %d already current\n' \
    "$total" "$installed" "$updated" "$current"
