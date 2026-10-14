#!/usr/bin/env bash
# Synthetic tests for cli/check-revision-bump.sh. Builds throwaway git repos in
# a temporary directory; never touches the working repository.
set -u
SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/cli/check-revision-bump.sh"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
status=0

new_repo() {
    local dir="$TMP/$1"
    mkdir -p "$dir/Compat" && cd "$dir"
    git init -q -b base
    git config user.email test@example.invalid
    git config user.name test
    printf 'NQuestieCustomQuestData = {\n    revision = 3,\n    quests = {},\n}\n' > Compat/NQuestieCustomQuestData.lua
    printf 'return {[1203] = 3853}\n' > Compat/NQuestieExistingQuestCorrections.lua
    printf '## Interface: 30300\nCompat\\NQuestieCustomQuestData.lua\nCompat\\NQuestieExistingQuestCorrections.lua\n' > Questie-335.toc
    printf 'readme\n' > README.md
    git add -A && git commit -qm base
    git checkout -q -b head
}

expect() { # expect <name> <expected exit> 
    local name=$1 want=$2 got
    "$SCRIPT" base >"$TMP/$name.log" 2>&1; got=$?
    if [ "$got" -eq "$want" ]; then
        echo "PASS: $name (exit $got)"
    else
        echo "FAIL: $name expected exit $want, got $got"; cat "$TMP/$name.log"; status=1
    fi
}

# 1. Correction changed without a revision bump -> must fail.
new_repo no-bump
printf 'return {[1203] = 3854}\n' > Compat/NQuestieExistingQuestCorrections.lua
git commit -qam "change correction"
expect correction-without-bump 1

# 2. Correction changed with a bump -> must pass.
new_repo with-bump
printf 'return {[1203] = 3854}\n' > Compat/NQuestieExistingQuestCorrections.lua
sed -i 's/revision = 3,/revision = 4,/' Compat/NQuestieCustomQuestData.lua
git commit -qam "change correction and bump"
expect correction-with-bump 0

# 3. Unrelated change only -> must pass.
new_repo unrelated
printf 'changed\n' > README.md
git commit -qam "docs"
expect unrelated-change 0

# 4. New correction module added to the TOC without a bump -> must fail.
new_repo toc-only
printf 'Compat\\NQuestieNewModule.lua\n' >> Questie-335.toc
git commit -qam "toc"
expect toc-change-without-bump 1

# 5. Revision decreased -> must fail.
new_repo decreased
printf 'return {[1203] = 3854}\n' > Compat/NQuestieExistingQuestCorrections.lua
sed -i 's/revision = 3,/revision = 2,/' Compat/NQuestieCustomQuestData.lua
git commit -qam "lower revision"
expect revision-decreased 1

# 6. Revision line removed -> must fail.
new_repo removed
sed -i '/revision = 3,/d' Compat/NQuestieCustomQuestData.lua
git commit -qam "drop revision"
expect revision-missing 1

# 7. Data file absent at the merge base (first introduction) -> base revision
#    counts as 0, so revision 1 passes.
mkdir -p "$TMP/first" && cd "$TMP/first"
git init -q -b base; git config user.email test@example.invalid; git config user.name test
printf 'readme\n' > README.md; git add -A; git commit -qm base; git checkout -q -b head
mkdir Compat
printf 'NQuestieCustomQuestData = {\n    revision = 1,\n}\n' > Compat/NQuestieCustomQuestData.lua
git add -A; git commit -qm "introduce overlay"
expect first-introduction 0

exit $status
