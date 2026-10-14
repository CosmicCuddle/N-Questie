#!/usr/bin/env bash
# Fail if any file under private/ is tracked by git. private/ holds local-only
# server exports and reports and must never be committed.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
tracked="$(git ls-files -- private/)"
if [ -n "$tracked" ]; then
    echo "FAIL: files under private/ are tracked by git:" >&2
    echo "$tracked" >&2
    exit 1
fi
if ! git check-ignore -q private/probe-file; then
    echo "FAIL: private/ is not gitignored" >&2
    exit 1
fi
echo "PASS: nothing under private/ is tracked, and private/ is gitignored"
