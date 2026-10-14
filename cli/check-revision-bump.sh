#!/usr/bin/env bash
# N-Questie CI guard: if any N-Questie correction source changed between the
# merge base and HEAD, NQuestieCustomQuestData.revision must be strictly
# greater than at the merge base. Otherwise installed clients keep a stale
# compiled Questie database (QuestieInit only recompiles when
# Questie.db.global.nQuestieDataRevision differs from this revision).
#
# Usage: cli/check-revision-bump.sh [<base-ref>]   (default: origin/335)
# Exit:  0 = OK or nothing relevant changed, 1 = bump missing, 2 = usage/git error
# CI-only. Does not change the runtime revision mechanism.
set -euo pipefail

BASE_REF="${1:-origin/335}"
DATA_FILE="Compat/NQuestieCustomQuestData.lua"

if ! MERGE_BASE=$(git merge-base "$BASE_REF" HEAD 2>/dev/null); then
    echo "check-revision-bump: cannot find merge base of '$BASE_REF' and HEAD" >&2
    exit 2
fi

revision_at() {
    # Prints the revision number in DATA_FILE at the given commit, or nothing.
    { git show "$1:$DATA_FILE" 2>/dev/null || true; } |
        sed -n 's/^[[:space:]]*revision[[:space:]]*=[[:space:]]*\([0-9][0-9]*\)[[:space:]]*,.*$/\1/p' |
        head -n1 || true
}

changed_files=$(git diff --name-only "$MERGE_BASE" HEAD -- 'Compat/NQuestie*.lua')
toc_changes=$(git diff -U0 "$MERGE_BASE" HEAD -- Questie-335.toc |
    grep -E '^[+-][^+-]' | grep -F 'Compat\NQuestie' || true)

if [ -z "$changed_files" ] && [ -z "$toc_changes" ]; then
    echo "check-revision-bump: no N-Questie correction changes since ${MERGE_BASE:0:10}; OK"
    exit 0
fi

base_rev=$(revision_at "$MERGE_BASE")
head_rev=$(revision_at HEAD)
base_rev=${base_rev:-0}

echo "check-revision-bump: N-Questie correction sources changed since ${MERGE_BASE:0:10}:"
[ -n "$changed_files" ] && printf '  %s\n' $changed_files
[ -n "$toc_changes" ] && printf '  Questie-335.toc: %s\n' "$toc_changes"

if [ -z "$head_rev" ]; then
    echo "check-revision-bump: FAIL - no 'revision = <number>,' found in $DATA_FILE at HEAD" >&2
    exit 1
fi
if [ "$head_rev" -le "$base_rev" ]; then
    echo "check-revision-bump: FAIL - N-Questie corrections changed but $DATA_FILE revision is $head_rev (merge base: $base_rev)." >&2
    echo "Increase 'revision' above $base_rev so installed clients recompile the Questie database." >&2
    exit 1
fi
echo "check-revision-bump: OK - revision $base_rev -> $head_rev"
