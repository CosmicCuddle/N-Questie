#!/usr/bin/env python3
"""Regression guard for the N-Questie overlay QA packaging gate (stdlib only).

Assemble and Upload may build a test ZIP only when all of the following hold:

- the event is pull_request
- the pull request carries the exact label nq-qa-ingame-test
- git diff --name-only shows at least one changed path that is not documentation

Documentation paths are narrow and case-sensitive: docs/**, **/*.md, and a
repository-root LICENSE*. An empty or undeterminable changed-file list does
not package. The changed-path script embedded in the workflow is executed
against synthetic repositories; the YAML predicates are compared as text.
"""
import os
import pathlib
import re
import subprocess
import sys
import tempfile

LABEL = "nq-qa-ingame-test"
_EVENT = "github.event_name == 'pull_request'"
_LABEL = "contains(github.event.pull_request.labels.*.name, '%s')" % LABEL
_PATH = "steps.qa_changed_paths.outputs.package == 'true'"
LABEL_ONLY_IF = "${{ %s && %s }}" % (_EVENT, _LABEL)
FULL_IF = "${{ %s && %s && %s }}" % (_EVENT, _LABEL, _PATH)
ROOT = pathlib.Path(__file__).resolve().parents[2]
WF = ROOT / ".github" / "workflows" / "nquestie-overlay.yml"
DOC = ROOT / "docs" / "NQ-QA-PACKAGING-LABEL-GATE.md"
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


def extract_gate_script(text):
    """Return the changed-path shell script, dedented, including its markers."""
    lines = text.splitlines()
    begin = [i for i, line in enumerate(lines) if "NQ_QA_PATH_GATE_BEGIN" in line]
    end = [i for i, line in enumerate(lines) if "NQ_QA_PATH_GATE_END" in line]
    if len(begin) != 1 or len(end) != 1 or not (begin[0] < end[0]):
        return None
    block = lines[begin[0]:end[0] + 1]
    indent = None
    for line in block:
        if line.strip():
            indent = len(line) - len(line.lstrip(" "))
            break
    if not indent:
        return None
    out = []
    for line in block:
        if line.strip() == "":
            out.append("")
            continue
        if not line.startswith(" " * indent):
            return None
        out.append(line[indent:])
    return "\n".join(out) + "\n"


def packaging_allowed(event_name, labels, package_flag):
    """Mirror the Assemble/Upload predicate. Fail closed unless every part is true."""
    if event_name != "pull_request":
        return False
    if not isinstance(labels, (list, tuple)) or LABEL not in labels:
        return False
    return package_flag is True


def evaluate(cond, event_name, labels, package_flag=True):
    """Evaluate only the exact approved condition shape; anything else fails closed."""
    if cond != FULL_IF:
        raise ValueError("unexpected condition shape: %r" % cond)
    return packaging_allowed(event_name, labels, package_flag)


def _git(repo, *args):
    cmd = [
        "git",
        "-c", "commit.gpgsign=false",
        "-c", "user.email=nq-ci@example.com",
        "-c", "user.name=nq-ci",
        "-c", "core.autocrlf=false",
    ] + list(args)
    proc = subprocess.run(
        cmd, cwd=repo, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if proc.returncode != 0:
        detail = proc.stderr.decode("utf-8", "replace")
        raise RuntimeError("%s\n%s" % (" ".join(cmd), detail))
    return proc.stdout.decode("utf-8", "replace").strip()


def _write(repo, rel, content):
    path = os.path.join(repo, rel)
    parent = os.path.dirname(path)
    if parent and not os.path.isdir(parent):
        os.makedirs(parent)
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(content)


def _commit(repo, message):
    _git(repo, "add", "-A")
    _git(repo, "commit", "-m", message)
    return _git(repo, "rev-parse", "HEAD")


def _init_origin(path):
    os.makedirs(path)
    _git(path, "init", "-b", "main")
    _write(path, "Modules/a.lua", "a\n")
    return _commit(path, "A")


def _run_gate(repo, script, base, head):
    """Execute the workflow script. Returns (flag, reason, stderr). flag is True/False/None."""
    script_file = tempfile.NamedTemporaryFile("w", suffix="-nq-qa-gate.sh", delete=False)
    out_file = tempfile.NamedTemporaryFile("w", suffix="-nq-qa-out.txt", delete=False)
    script_file.write(script)
    script_file.close()
    out_file.close()
    env = os.environ.copy()
    env["GIT_TERMINAL_PROMPT"] = "0"
    env["GCM_INTERACTIVE"] = "Never"
    env.pop("GITHUB_STEP_SUMMARY", None)
    env["GITHUB_OUTPUT"] = out_file.name
    if base is None:
        env.pop("NQ_BASE_SHA", None)
    else:
        env["NQ_BASE_SHA"] = base
    if head is None:
        env.pop("NQ_HEAD_SHA", None)
    else:
        env["NQ_HEAD_SHA"] = head
    try:
        proc = subprocess.run(
            ["bash", "-eo", "pipefail", script_file.name],
            cwd=repo,
            env=env,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=60,
        )
        output = open(out_file.name, encoding="utf-8").read()
    finally:
        os.unlink(script_file.name)
        os.unlink(out_file.name)
    stdout = proc.stdout.decode("utf-8", "replace")
    stderr = proc.stderr.decode("utf-8", "replace")
    if proc.returncode != 0:
        return None, "exit %s" % proc.returncode, stderr
    out_vals = re.findall(r"(?m)^package=(true|false)$", output)
    out_stdout = re.findall(r"(?m)^package=(true|false)$", stdout)
    if out_vals != out_stdout or len(out_vals) != 1:
        return None, "package lines output=%r stdout=%r" % (out_vals, out_stdout), stderr
    reason_match = re.search(r"(?m)^reason=(.*)$", stdout)
    reason = reason_match.group(1) if reason_match else ""
    return out_vals[0] == "true", reason, stderr


def _expect(script, repo, base, head, event, labels, want, desc):
    flag, reason, stderr = _run_gate(repo, script, base, head)
    if flag is None:
        tail = stderr.strip().splitlines()[-1] if stderr.strip() else ""
        check(False, "synthetic: %s runner failed (%s) %s" % (desc, reason, tail))
        return
    got = packaging_allowed(event, labels, flag)
    check(got == want, "synthetic: %s got %s want %s [%s]" % (
        desc,
        "build" if got else "skip",
        "build" if want else "skip",
        reason))


def _build(root):
    origin = os.path.join(root, "origin")
    base_a = _init_origin(origin)
    _git(origin, "checkout", "-b", "prdocs", base_a)
    _write(origin, "docs/only.md", "doc\n")
    _write(origin, "README.md", "readme\n")
    _write(origin, "LICENSE", "license\n")
    docs_head = _commit(origin, "docs only")
    _git(origin, "checkout", "-b", "prdocslua", base_a)
    _write(origin, "docs/foo.lua", "lua under docs\n")
    docs_lua = _commit(origin, "docs lua")
    _git(origin, "checkout", "main")
    _write(origin, "Modules/b.lua", "b\n")
    moved_base = _commit(origin, "base moves")
    _git(origin, "checkout", "-b", "prmixed", docs_head)
    _write(origin, "Modules/QuestieInit.lua", "init\n")
    mixed = _commit(origin, "mixed")
    _git(origin, "checkout", "-b", "prcode", base_a)
    _write(origin, "Modules/QuestieInit.lua", "init\n")
    code = _commit(origin, "code")
    _git(origin, "checkout", "-b", "pryml", base_a)
    _write(origin, ".github/workflows/nquestie-overlay.yml", "name: x\n")
    workflow = _commit(origin, "workflow")
    _git(origin, "checkout", "-b", "prvendor", base_a)
    _write(origin, "vendor/LICENSE", "license\n")
    vendor = _commit(origin, "vendor license")
    _git(origin, "checkout", "-b", "prempty", base_a)
    _git(origin, "commit", "--allow-empty", "-m", "empty")
    empty = _git(origin, "rev-parse", "HEAD")
    _git(origin, "checkout", "main")
    _git(origin, "merge", "--no-ff", "prdocs", "-m", "merge docs")
    _git(origin, "checkout", "--orphan", "orphan")
    _write(origin, "Modules/z.lua", "z\n")
    orphan = _commit(origin, "orphan")
    return {
        "origin": origin,
        "base_a": base_a,
        "moved_base": moved_base,
        "docs_head": docs_head,
        "docs_lua": docs_lua,
        "mixed": mixed,
        "code": code,
        "workflow": workflow,
        "vendor": vendor,
        "empty": empty,
        "orphan": orphan,
    }


def run_path_cases(script):
    if not script:
        check(False, "extracted changed-path script")
        return
    syntax = subprocess.run(
        ["bash", "-n"], input=script.encode(), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    check(syntax.returncode == 0, "changed-path script passes bash -n")
    check("git diff --name-only --no-renames -z" in script,
          "changed paths come from git diff --name-only")
    check("docs/*|*.md|LICENSE*) return 0" in script,
          "documentation patterns are docs/*, *.md, and root LICENSE*")
    check(script.count("finish true") == 1, "package=true is emitted from one path")
    check('finish false "changed-file list empty"' in script,
          "empty changed-file list is fail closed")
    check("pull_request_target" not in script, "path script does not use pull_request_target")
    if syntax.returncode != 0:
        return
    try:
        with tempfile.TemporaryDirectory(prefix="nq-qa-gate-") as root:
            hist = _build(root)
            origin = hist["origin"]
            labelled = ("pull_request", [LABEL])
            _expect(script, origin, hist["moved_base"], hist["docs_head"],
                    labelled[0], labelled[1], False,
                    "labelled docs-only (behind base; md, README.md, LICENSE)")
            _expect(script, origin, hist["base_a"], hist["docs_lua"],
                    labelled[0], labelled[1], False,
                    "labelled docs-only (docs/** lua is still documentation)")
            _expect(script, origin, hist["moved_base"], hist["mixed"],
                    labelled[0], labelled[1], True,
                    "labelled mixed docs and code")
            _expect(script, origin, hist["base_a"], hist["code"],
                    labelled[0], labelled[1], True,
                    "labelled code-only lua")
            _expect(script, origin, hist["base_a"], hist["workflow"],
                    labelled[0], labelled[1], True,
                    "labelled workflow-only")
            _expect(script, origin, hist["base_a"], hist["vendor"],
                    labelled[0], labelled[1], True,
                    "labelled vendor/LICENSE is not root LICENSE*")
            _expect(script, origin, hist["base_a"], hist["empty"],
                    labelled[0], labelled[1], False,
                    "labelled empty changed-file list")
            _expect(script, origin, hist["base_a"], hist["base_a"],
                    labelled[0], labelled[1], False,
                    "labelled identical SHAs (empty diff)")
            _expect(script, origin, "not-a-sha", hist["base_a"],
                    labelled[0], labelled[1], False,
                    "labelled undeterminable SHA")
            _expect(script, origin, "0000000000000000000000000000000000000000", hist["base_a"],
                    labelled[0], labelled[1], False,
                    "labelled missing commit")
            _expect(script, origin, "", "",
                    labelled[0], labelled[1], False,
                    "labelled missing base and head")
            _expect(script, origin, None, None,
                    labelled[0], labelled[1], False,
                    "labelled unset base and head")
            _expect(script, origin, hist["base_a"], hist["orphan"],
                    labelled[0], labelled[1], False,
                    "labelled merge base undeterminable")
            # Shell would allow packaging; the label/event half must still refuse.
            _expect(script, origin, hist["base_a"], hist["code"],
                    "pull_request", [], False,
                    "unlabelled code-only")
            _expect(script, origin, hist["base_a"], hist["code"],
                    "pull_request", [], False,
                    "label removed, code-only")
            _expect(script, origin, hist["base_a"], hist["code"],
                    "pull_request", ["nq-qa-ingame-test-old"], False,
                    "wrong label, code-only")
            _expect(script, origin, hist["base_a"], hist["code"],
                    "push", [LABEL], False,
                    "push with the label and a code change")
            shallow = os.path.join(root, "shallow")
            _git(root, "clone", "--depth", "1", "--branch", "main",
                 "file://" + origin, shallow)
            _expect(script, shallow, hist["moved_base"], hist["docs_head"],
                    labelled[0], labelled[1], False,
                    "labelled docs-only from a depth-1 checkout")
            shallow_head = os.path.join(root, "shallow-head")
            _git(root, "clone", "--depth", "1", "--branch", "prdocs",
                 "file://" + origin, shallow_head)
            _expect(script, shallow_head, hist["moved_base"], hist["docs_head"],
                    labelled[0], labelled[1], False,
                    "labelled docs-only when the base SHA must be fetched")
    except Exception as exc:
        check(False, "path scenarios raised %s: %s" % (type(exc).__name__, exc))


def main():
    text = WF.read_text(encoding="utf-8")
    all_steps = steps(text)
    pkg = [(n, b) for n, b in all_steps
           if "upload-artifact" in b or "qa-package" in b]
    check(len(pkg) == 2, "exactly two packaging steps (assemble + upload), found %d" % len(pkg))
    ifs = [step_if(body) for _, body in pkg]
    check(len(ifs) == 2 and ifs[0] == ifs[1] and ifs[0] is not None,
          "Assemble and Upload predicates are identical")
    for name, body in pkg:
        check(step_if(body) == FULL_IF, "full gate on step: %s" % name)
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
    uses = re.findall(r"^\s+uses:\s*(\S+)", text, re.M)
    check(uses == ["actions/checkout@v4", "actions/upload-artifact@v4"],
          "no new third-party actions: %s" % uses)
    check(text.count(FULL_IF) == 2, "full predicate on exactly Assemble and Upload")
    check(text.count(LABEL_ONLY_IF) == 1, "changed-path step keeps the label-only guard")
    check("NQ_BASE_SHA: ${{ github.event.pull_request.base.sha }}" in text,
          "base SHA comes from the pull_request event")
    check("NQ_HEAD_SHA: ${{ github.event.pull_request.head.sha }}" in text,
          "head SHA comes from the pull_request event")
    det = [b for n, b in all_steps if "id: qa_changed_paths" in b]
    check(len(det) == 1, "single changed-path step")
    if det:
        check(step_if(det[0]) == LABEL_ONLY_IF, "changed-path step runs only for a labelled pull_request")

    doc = " ".join(DOC.read_text(encoding="utf-8").split())
    for phrase in (
        "docs/**",
        "**/*.md",
        "LICENSE*",
        "same predicate",
        "fail closed",
        "technical trigger",
        "not proof of owner consent",
        "authorised maintainer",
        "intentionally approved",
    ):
        check(phrase in doc, "doc states: %s" % phrase)

    # Synthetic label/event cases. package_flag True holds the path half open so
    # these stay focused on event and label; path cases below run the real script.
    cond = step_if(pkg[0][1]) if pkg else None
    cases = [
        ("docs-only PR, no label", "pull_request", [], True, False),
        ("docs PR with unrelated label", "pull_request", ["documentation"], True, False),
        ("labelled pull_request with a confirmed non-doc change", "pull_request", [LABEL, "docs"], True, True),
        ("push to 335", "push", [], True, False),
        ("push carrying label-like data", "push", [LABEL], True, False),
        ("similar but wrong label", "pull_request", ["nq-qa-ingame-test-old"], True, False),
        ("label removed", "pull_request", [], True, False),
    ]
    for desc, ev, labels, package_flag, want in cases:
        try:
            got = evaluate(cond, ev, labels, package_flag)
        except ValueError as exc:
            got = "error: %s" % exc
        check(got == want, "synthetic: %s -> %s" % (desc, "build" if want else "skip"))
    # Fail-closed self-test: the old deny-list / label-only conditions must be rejected.
    try:
        evaluate("github.event_name == 'pull_request'", "pull_request", [])
        check(False, "old ungated condition rejected")
    except ValueError:
        check(True, "old ungated condition rejected")
    try:
        evaluate(LABEL_ONLY_IF, "pull_request", [LABEL], True)
        check(False, "label-only condition rejected")
    except ValueError:
        check(True, "label-only condition rejected")

    run_path_cases(extract_gate_script(text))

    print("\n%d failure(s)" % len(failures))
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
