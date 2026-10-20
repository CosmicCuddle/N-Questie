#!/usr/bin/env python3
"""READ-ONLY checker for ONE locally staged WoW 3.3.5a `Questie-335` folder.

Usage:  python tools/check_nq_335_local_stage.py <path-to>/Questie-335

What it does (reads only, inside the folder you name):
  * reuses the reviewed `check_manifest` from
    tools/test_nquestie_335_manifest_preflight.py (Interface 30300, every
    active TOC entry and reachable XML Script/Include, exact path spelling);
  * checks the allowed top-level layout and rejects stray/unsafe content
    (private/, WTF/, SQL, archives, credential-like files, extra top-level
    .toc, symlinks or junctions that escape the folder);
  * statically resolves addon-relative texture literals in ACTIVE Lua files
    (`QuestieLib.AddonPath.."Icons\\..."` and hard-coded
    `Interface\\AddOns\\Questie-335\\...`): exact match PASS, case-only
    mismatch WARN, absent FAIL.

What it never does: copy, build, zip, install, delete, rename or modify any
file; write a report or Python bytecode; use the network; read WoW/WTF or
any default game path. It is NOT a game-client test, NOT rights/licence
clearance and NOT a source-commit attestation.
Exit status: 0 = PASS (warnings allowed), 1 = FAIL, 2 = usage/internal error.
"""
import sys

sys.dont_write_bytecode = True  # must precede the import below (no .pyc)

import importlib.util  # noqa: E402
import os  # noqa: E402
import re  # noqa: E402
from pathlib import Path  # noqa: E402

STAGED_NAME = "Questie-335"
TOP_FILES_REQUIRED = {"Questie.lua", "Questie-335.toc"}
TOP_FILES_OPTIONAL = {"embeds.xml"}
TOP_DIRS_REQUIRED = {"Compat", "Database", "Icons", "Libs", "Localization",
                     "Modules"}
FORBIDDEN_DIR_NAMES = {"private", "wtf", ".git", "savedvariables"}
FORBIDDEN_SUFFIXES = {".sql", ".zip", ".7z", ".rar", ".tar", ".gz", ".tgz",
                      ".bz2", ".xz", ".pem", ".key", ".p12", ".pfx", ".bak",
                      ".env"}
FORBIDDEN_NAME_RE = re.compile(
    r"^(?:\.env.*|id_rsa.*|id_ed25519.*|credentials.*|.*\.secret.*|"
    r"addons\.txt|config-cache\.wtf|config\.wtf)$", re.I)
TEXTURE_EXTS = (".blp", ".tga")
ADDON_PATH_LITERAL = re.compile(
    r"""QuestieLib\.AddonPath\s*\.\.\s*(?:"([^"\n]*)"|'([^'\n]*)')""")
ADDON_PATH_DYNAMIC = re.compile(
    r"""QuestieLib\.AddonPath\s*\.\.\s*(?=[A-Za-z_(\[])""")
HARDCODED = re.compile(
    r"""["']Interface\\\\AddOns\\\\([^\\"'\n]+)\\\\([^"'\n]+)["']""", re.I)
LONG_COMMENT = re.compile(r"--\[(=*)\[.*?\]\1\]", re.DOTALL)


def _load_manifest_module():
    here = Path(__file__).resolve().parent
    src = here / "test_nquestie_335_manifest_preflight.py"
    spec = importlib.util.spec_from_file_location("_nq_manifest_preflight",
                                                  src)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _strip_lua_comments(text):
    """Conservative: drop --[[ ]] blocks and whole-line `--` comments."""
    text = LONG_COMMENT.sub("", text)
    return "\n".join("" if line.lstrip().startswith("--") else line
                     for line in text.splitlines())


def _is_link(path):
    is_junction = getattr(os.path, "isjunction", None)
    return path.is_symlink() or bool(is_junction and is_junction(path))


def check_layout(root):
    """Return (fails, warns). Walks without following links."""
    fails, warns = [], []
    entries = {e.name: e for e in root.iterdir()}
    for name in sorted(TOP_FILES_REQUIRED | TOP_DIRS_REQUIRED):
        if name not in entries:
            fails.append("Missing required top-level entry: " + name)
    for name, entry in sorted(entries.items()):
        if _is_link(entry):
            continue  # reported by the walk below
        if entry.is_dir():
            if name not in TOP_DIRS_REQUIRED:
                fails.append("Unexpected top-level directory: " + name)
        elif name not in TOP_FILES_REQUIRED | TOP_FILES_OPTIONAL:
            fails.append("Unexpected top-level file: " + name)
    root_real = root.resolve()
    for current, dirs, files in os.walk(root, followlinks=False):
        here = Path(current)
        for name in list(dirs) + files:
            path = here / name
            rel = path.relative_to(root).as_posix()
            if _is_link(path):
                try:
                    path.resolve().relative_to(root_real)
                    warns.append("Link inside folder (not followed): " + rel)
                except (ValueError, OSError):
                    fails.append("Link escapes staged folder: " + rel)
                if name in dirs:
                    dirs.remove(name)
                continue
            if name in dirs and name.lower() in FORBIDDEN_DIR_NAMES:
                fails.append("Forbidden directory: " + rel)
                dirs.remove(name)
            elif name in files and (Path(name).suffix.lower()
                                    in FORBIDDEN_SUFFIXES
                                    or FORBIDDEN_NAME_RE.match(name)):
                fails.append("Forbidden/unsafe file: " + rel)
    return fails, warns


def _resolve_case(root, parts):
    """Return 'exact', 'case' or None for addon-relative path parts."""
    cursor, exact = root, True
    for index, part in enumerate(parts):
        try:
            names = {e.name: e for e in cursor.iterdir()}
        except OSError:
            return None
        last = index == len(parts) - 1
        candidates = [part]
        if last and not part.lower().endswith(TEXTURE_EXTS):
            candidates = [part + ext for ext in TEXTURE_EXTS]
        hit = next((c for c in candidates if c in names), None)
        if hit is None:
            folded = {n.lower(): n for n in names}
            hit = next((folded[c.lower()] for c in candidates
                        if c.lower() in folded), None)
            if hit is None:
                return None
            exact = False
        cursor = cursor / hit
    if not cursor.is_file():
        return None
    return "exact" if exact else "case"


def check_textures(root, lua_paths):
    fails, warns, notes = [], [], []
    seen = {}
    dynamic = 0
    for rel in lua_paths:
        try:
            text = (root / rel).read_text(encoding="utf-8-sig",
                                          errors="replace")
        except OSError as exc:
            fails.append("Cannot read active Lua %s: %s" % (rel, exc))
            continue
        text = _strip_lua_comments(text)
        dynamic += len(ADDON_PATH_DYNAMIC.findall(text))
        for match in ADDON_PATH_LITERAL.finditer(text):
            value = match.group(1) if match.group(1) is not None \
                else match.group(2)
            seen.setdefault(value, rel)
        for match in HARDCODED.finditer(text):
            folder, rest = match.group(1), match.group(2)
            if folder == STAGED_NAME:
                seen.setdefault(rest, rel)
            elif folder.lower().startswith("questie"):
                warns.append("Active %s hard-codes another addon folder "
                             "'%s' (not %s)" % (rel, folder, STAGED_NAME))
    textures = 0
    for value, rel in sorted(seen.items()):
        parts = [p for p in value.replace("\\\\", "\\").split("\\") if p]
        if not parts or ".." in parts:
            warns.append("Unresolvable addon path literal in %s: %r"
                         % (rel, value))
            continue
        last = parts[-1].lower()
        if "." in last and not last.endswith(TEXTURE_EXTS):
            continue  # not a texture (e.g. sound/font): out of scope
        textures += 1
        state = _resolve_case(root, parts)
        if state is None:
            fails.append("Missing runtime texture %s (from %s)" % (value, rel))
        elif state == "case":
            warns.append("Case-only texture mismatch %s (from %s): loads on "
                         "Windows, would fail on case-sensitive filesystems"
                         % (value, rel))
    notes.append("%d distinct static addon texture paths checked" % textures)
    notes.append("%d dynamic AddonPath concatenations: NOT TESTED" % dynamic)
    return fails, warns, notes


def run(path, manifest_module=None, out=print):
    root = Path(path)
    if root.name != STAGED_NAME or not root.is_dir() or _is_link(root):
        out("FAIL: argument must be an existing real directory named "
            + STAGED_NAME)
        return 1
    root = root.resolve()
    module = manifest_module or _load_manifest_module()
    fails, warns, notes = [], [], []
    lua_paths = []
    try:
        result = module.check_manifest(root, require_staged_name=True)
        notes.append("TOC/XML graph: %(toc_paths)d TOC, %(xml_paths)d XML "
                     "refs, %(total_references)d total, %(xml_documents)d "
                     "XML docs" % result)
        lua_paths = _active_lua(module, root)
    except (ValueError, OSError) as exc:
        fails.append("Manifest: " + str(exc))
    lf, lw = check_layout(root)
    fails += lf
    warns += lw
    if lua_paths:
        tf, tw, tn = check_textures(root, lua_paths)
        fails += tf
        warns += tw
        notes += tn
    for line in fails:
        out("FAIL: " + line)
    for line in warns:
        out("WARN: " + line)
    for line in notes:
        out("INFO: " + line)
    out("NOT TESTED: game-client loading/rendering, Lua runtime errors, "
        "SavedVariables, rights/licence clearance, source-SHA attestation")
    out("RESULT: " + ("FAIL" if fails else "PASS") +
        " (%d fail, %d warn)" % (len(fails), len(warns)))
    return 1 if fails else 0


def _active_lua(module, root):
    """Active Lua files = TOC + reachable XML refs, via the reviewed parser."""
    collected = []
    original = module._checked_path

    def recording(r, parent, supplied):
        rel = original(r, parent, supplied)
        if rel.lower().endswith(".lua"):
            collected.append(rel)
        return rel

    module._checked_path = recording
    try:
        module.check_manifest(root, require_staged_name=True)
    finally:
        module._checked_path = original
    return list(dict.fromkeys(collected))


def main(argv):
    if len(argv) != 2 or argv[1] in ("-h", "--help"):
        print(__doc__)
        return 2
    try:
        return run(argv[1])
    except Exception as exc:  # fail closed, no traceback paths
        print("FAIL: internal error (%s)" % type(exc).__name__)
        return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))
