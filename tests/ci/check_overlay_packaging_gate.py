#!/usr/bin/env python3
"""Regression guard for the N-Questie overlay QA packaging gate (stdlib only).

Asserts that .github/workflows/nquestie-overlay.yml only assembles/uploads a
test ZIP for pull_request events carrying the explicit `nq-qa-ingame-test`
label, never on push, with a read-only token and short artifact retention.
Also evaluates the gate condition against synthetic events.
"""
import pathlib
import re
import sys

LABEL = "nq-qa-ingame-test"
EXPECTED_IF = ("${{ github.event_name == 'pull_request' && "
               "contains(github.event.pull_request.labels.*.name, '%s') }}" % LABEL)
ROOT = pathlib.Path(__file__).resolve().parents[2]
WF = ROOT / ".github" / "workflows" / "nquestie-overlay.yml"
failures = []


def check(cond, msg):
    print(("PASS " if cond else "FAIL ") + msg)
    if not cond:
        failures.append(msg)


def steps(text):
    """Split the steps list into (name, body) blocks."""
    out = []
    for block in re.split(r"\n      - ", text)[1:]:
        m = re.match(r"name:\s*(.+)", block)
        out.append(((m.group(1).strip() if m else ""), block))
    return out


def step_if(body):
    m = re.search(r"^\s+if:\s*(.+)$", body, re.M)
    return m.group(1).strip() if m else None


def evaluate(cond, event_name, labels):
    """Evaluate only the exact approved condition shape; anything else fails closed."""
    if cond != EXPECTED_IF:
        raise ValueError("unexpected condition shape: %r" % cond)
    return event_name == "pull_request" and LABEL in labels


def main():
    text = WF.read_text(encoding="utf-8")
    all_steps = steps(text)
    pkg = [(n, b) for n, b in all_steps
           if "upload-artifact" in b or "qa-package" in b]
    check(len(pkg) == 2, "exactly two packaging steps (assemble + upload), found %d" % len(pkg))
    for name, body in pkg:
        check(step_if(body) == EXPECTED_IF, "label gate on step: %s" % name)
    upload = [b for _, b in pkg if "upload-artifact" in b]
    check(len(upload) == 1, "single upload-artifact step")
    if upload:
        m = re.search(r"retention-days:\s*(\d+)", upload[0])
        check(bool(m) and 1 <= int(m.group(1)) <= 7, "retention-days set and <= 7")
    # Top-level permissions must exist and be read-only.
    m = re.search(r"^permissions:\s*\n((?:  .+\n)+)", text, re.M)
    check(bool(m), "top-level permissions block present")
    if m:
        perms = dict(re.findall(r"^\s+([\w-]+):\s*(\S+)", m.group(1), re.M))
        check(perms.get("contents") == "read", "contents: read")
        check(all(v in ("read", "none") for v in perms.values()), "all permissions read/none: %s" % perms)
    check(not re.search(r"write", (m.group(1) if m else "")), "no write permission")
    check("pull_request_target" not in text, "no pull_request_target trigger")
    m = re.search(r"pull_request:\s*\n\s+types:\s*\[([^\]]*)\]", text)
    types = [t.strip() for t in m.group(1).split(",")] if m else []
    check("labeled" in types and "unlabeled" in types, "labeled/unlabeled PR types present")

    # Synthetic cases on the actual condition text.
    cond = step_if(pkg[0][1]) if pkg else None
    cases = [
        ("docs-only PR, no label", "pull_request", [], False),
        ("docs PR with unrelated label", "pull_request", ["documentation"], False),
        ("approved PR labelled for in-game test", "pull_request", [LABEL, "docs"], True),
        ("push to 335", "push", [], False),
        ("push carrying label-like data", "push", [LABEL], False),
        ("similar but wrong label", "pull_request", ["nq-qa-ingame-test-old"], False),
    ]
    for desc, ev, labels, want in cases:
        try:
            got = evaluate(cond, ev, labels)
        except ValueError as e:
            got = "error: %s" % e
        check(got == want, "synthetic: %s -> %s" % (desc, "build" if want else "skip"))
    # Fail-closed self-test: the old deny-list condition must be rejected.
    try:
        evaluate("github.event_name == 'pull_request'", "pull_request", [])
        check(False, "old ungated condition rejected")
    except ValueError:
        check(True, "old ungated condition rejected")

    print("\n%d failure(s)" % len(failures))
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
