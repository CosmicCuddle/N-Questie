#!/usr/bin/env bash
# Self-test for tests/check_no_tracked_private.sh using throwaway git repos.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
script="$here/check_no_tracked_private.sh"
fails=0
run() { # name expected_exit setup...
    local name="$1" want="$2"; shift 2
    local d; d="$(mktemp -d)"
    ( cd "$d" && git init -q && git config user.email t@t && git config user.name t && eval "$*" ) >/dev/null 2>&1
    ( cd "$d" && bash "$script" ) >/dev/null 2>&1; local got=$?
    rm -rf "$d"
    if [ "$got" = "$want" ]; then echo "PASS: $name"; else echo "FAIL: $name (exit $got, want $want)"; fails=$((fails+1)); fi
}
run "clean repo with private/ ignored" 0 'echo private/ > .gitignore; mkdir private; echo x > private/a; git add .gitignore; git commit -qm i'
run "tracked file under private/" 1 'echo private/ > .gitignore; mkdir private; echo x > private/a; git add .gitignore; git add -f private/a; git commit -qm i'
run "private/ not gitignored" 1 'echo > .gitignore; git add .gitignore; git commit -qm i'
[ "$fails" = 0 ] && echo "PASS: private/ guard self-test (3 cases)" || exit 1
