#!/usr/bin/env python3
"""READ-ONLY checker for ONE locally staged WoW 3.3.5a `Questie-335` folder.

Usage:  python tools/check_nq_335_local_stage.py <path-to>/Questie-335

What it does (reads only, inside the folder you name):
  * pre-walks that folder without following links. A symlink, a junction,
    or a Windows reparse point (`os.lstat` `st_file_attributes` &
    `stat.FILE_ATTRIBUTE_REPARSE_POINT`, where that attribute exists)
    fails the run before any TOC, XML, Lua or texture read. Off Windows
    the reparse-attribute check is a no-op. Real Windows reparse points
    are NOT TESTED;
  * any other layout failure (forbidden or unexpected entry, missing
    required top-level entry) also skips those content reads;
  * reuses the reviewed `check_manifest` from
    tools/test_nquestie_335_manifest_preflight.py (Interface 30300, every
    active TOC entry and reachable XML Script/Include, exact path spelling);
  * checks the allowed top-level layout and rejects stray/unsafe content
    (private/, WTF/, SQL, archives, credential-like files, extra top-level
    .toc, any symlink, junction, or reparse-attribute hit);
  * checks presence (not contents) of notice files that belong to the
    agreed 557-file layout;
  * statically resolves addon-relative texture literals in ACTIVE Lua files
    (`QuestieLib.AddonPath.."Icons\\..."` and hard-coded
    `Interface\\AddOns\\Questie-335\\...`): exact match PASS, case-only
    mismatch WARN, absent FAIL. Inline `--` comments outside strings are
    ignored. This is not a Lua parser.

What it never does: copy, build, zip, install, delete, rename or modify any
file; write a report or Python bytecode; use the network; read WoW/WTF or
any default game path; enumerate or read through a symlink or junction;
read TOC, XML, Lua or texture bytes after a layout failure; print an
absolute path or an arbitrary exception string. Non-OSError results are
the exception type only. An OSError path is shown only after a lexical
in-root check, and an outside filename is not resolved just to format
that diagnostic.
It is NOT a game-client test, NOT rights/licence clearance and NOT a
source-commit attestation.

Static Lua scan limits (also printed on the NOT TESTED line): unbalanced
quotes, unclosed long brackets, texture-like text that only appears inside
a string, and loadstring/dynamic code. Windows junctions/reparse points,
PowerShell and Python on Windows are NOT TESTED. `os.path.isjunction` is
still consulted. `FILE_ATTRIBUTE_REPARSE_POINT` is consulted only where
`st_file_attributes` exists and is a no-op off Windows.
Exit status: 0 = PASS (warnings allowed), 1 = FAIL, 2 = usage/internal error.
"""
import sys

sys.dont_write_bytecode = True  # must precede the import below (no .pyc)

import importlib.util  # noqa: E402
import os  # noqa: E402
import re  # noqa: E402
import stat  # noqa: E402
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
# These four paths exist in the agreed 557-file layout. Confirmed with
# `git ls-tree -r 2be0f6f3001a20242c2fe81cb1915ff18602a4c8` and this head
# (same paths). ExternalScripts(...)/slpp/LICENSE is outside that layout
# and is intentionally not checked.
NOTICE_FILES = (
    "Icons/LICENSE.md",
    "Icons/MIT.txt",
    "Libs/LICENSE.txt",
)
KROWI_NOTICE_DIR = "Libs/Krowi_WorldMapButtons"
KROWI_NOTICE_FILE = "Libs/Krowi_WorldMapButtons/LICENSE.md"
# Drive, UNC, or a slash that starts a path. A slash inside a relative
# segment such as Modules/Tracker.lua does not match.
_EMBEDDED_ABS = re.compile(
    r"(?:[A-Za-z]:[\\/]|\\\\|(?<![A-Za-z0-9_.-])/(?:[A-Za-z0-9._+-]+))"
)


def _load_manifest_module():
    here = Path(__file__).resolve().parent
    src = here / "test_nquestie_335_manifest_preflight.py"
    spec = importlib.util.spec_from_file_location("_nq_manifest_preflight",
                                                  src)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _opening_long_bracket(text, index):
    """Return the `=` count if text[index:] is `[=*[`, else None."""
    if index >= len(text) or text[index] != "[":
        return None
    cursor = index + 1
    while cursor < len(text) and text[cursor] == "=":
        cursor += 1
    if cursor < len(text) and text[cursor] == "[":
        return cursor - index - 1
    return None


def _closing_long_bracket(text, index, level):
    close = "]" + ("=" * level) + "]"
    found = text.find(close, index)
    if found < 0:
        return len(text)
    return found + len(close)


def _strip_lua_comments(text):
    """Drop Lua comments that sit outside string literals.

    Handles whole-line and inline `--` comments, and long comments
    (`--[[ ]]`, `--[=[ ]=]`). A quoted `"--"` or `'--'` is not a comment.
    Not a Lua parser: unbalanced quotes, unclosed long brackets, and
    texture-like text inside strings remain static-scan limits.
    """
    if "--" not in text:
        return text
    parts = []
    index = 0
    plain = 0
    length = len(text)
    while index < length:
        char = text[index]
        if char in ("'", '"'):
            if plain < index:
                parts.append(text[plain:index])
            cursor = index + 1
            while cursor < length:
                if text[cursor] == "\\":
                    cursor += 2
                    continue
                if text[cursor] == char:
                    cursor += 1
                    break
                if text[cursor] == "\n":
                    break
                cursor += 1
            if cursor < index:
                cursor = index + 1
            parts.append(text[index:cursor])
            index = cursor
            plain = index
            continue
        if char == "[":
            level = _opening_long_bracket(text, index)
            if level is not None:
                if plain < index:
                    parts.append(text[plain:index])
                cursor = _closing_long_bracket(text, index + 2 + level, level)
                if cursor <= index:
                    cursor = index + 1
                parts.append(text[index:cursor])
                index = cursor
                plain = index
                continue
        if char == "-" and index + 1 < length and text[index + 1] == "-":
            if plain < index:
                parts.append(text[plain:index])
            level = _opening_long_bracket(text, index + 2)
            if level is not None:
                cursor = _closing_long_bracket(text, index + 4 + level, level)
                if cursor <= index:
                    cursor = index + 1
                newlines = text.count("\n", index, cursor)
                if newlines:
                    parts.append("\n" * newlines)
                index = cursor
            else:
                cursor = text.find("\n", index)
                index = length if cursor < 0 else cursor
            plain = index
            continue
        index += 1
    if plain < length:
        parts.append(text[plain:length])
    return "".join(parts)


def _reparse_point(path):
    """True when lstat reports FILE_ATTRIBUTE_REPARSE_POINT.

    The flag is only meaningful together with `st_file_attributes`, which
    Windows fills in. Off Windows that field is absent, so this returns
    False and is a no-op. Real Windows reparse points are NOT TESTED.
    """
    flag = getattr(stat, "FILE_ATTRIBUTE_REPARSE_POINT", None)
    if flag is None:
        return False
    try:
        attrs = getattr(os.lstat(path), "st_file_attributes", None)
    except OSError:
        return False
    if not isinstance(attrs, int):
        return False
    return bool(attrs & flag)


def _is_link(path):
    """True for a symlink, a junction, or a Windows reparse point.

    Junctions use `os.path.isjunction` where that function exists. Other
    reparse points use `st_file_attributes & FILE_ATTRIBUTE_REPARSE_POINT`
    when the attribute exists; that check is a no-op off Windows. Real
    Windows junction and reparse-point behaviour is NOT TESTED.
    """
    try:
        if Path(path).is_symlink():
            return True
    except OSError:
        return False
    if _reparse_point(path):
        return True
    is_junction = getattr(os.path, "isjunction", None)
    if is_junction is None:
        return False
    try:
        return bool(is_junction(os.fspath(path)))
    except (OSError, ValueError, TypeError):
        return False


def _link_message(root, path, rel):
    """FAIL text for a link. Uses readlink + normpath, never lists the target."""
    try:
        raw = os.readlink(path)
    except OSError:
        return "Link/junction/reparse point is not allowed: " + rel
    if not os.path.isabs(raw):
        raw = os.path.join(os.path.dirname(os.path.abspath(os.fspath(path))),
                           raw)
    norm = os.path.normpath(raw)
    root_abs = os.path.normpath(os.path.abspath(os.fspath(root)))
    try:
        Path(norm).relative_to(root_abs)
    except ValueError:
        return "Link escapes staged folder: " + rel
    return "Link/junction/reparse point is not allowed: " + rel


def _scan_tree(root):
    """Inventory `root` without following links or reading file bytes.

    Returns (files, dirs, links, fails). `files` and `dirs` hold relative
    posix paths of real (non-link) entries only.
    """
    files, dirs, links, fails = set(), set(), [], []
    stack = [root]
    while stack:
        current = stack.pop()
        try:
            with os.scandir(current) as iterator:
                entries = sorted(iterator, key=lambda entry: entry.name)
        except OSError as exc:
            try:
                rel = "." if current == root else Path(current).relative_to(
                    root).as_posix()
            except ValueError:
                rel = "."
            fails.append("Cannot list staged directory %s: %s"
                         % (rel, type(exc).__name__))
            continue
        children = []
        for entry in entries:
            path = Path(entry.path)
            rel = path.relative_to(root).as_posix()
            if _is_link(path):
                links.append(rel)
                fails.append(_link_message(root, path, rel))
                continue
            try:
                is_dir = entry.is_dir(follow_symlinks=False)
            except OSError:
                is_dir = False
            if is_dir:
                dirs.add(rel)
                if path.name.lower() in FORBIDDEN_DIR_NAMES:
                    fails.append("Forbidden directory: " + rel)
                    continue
                children.append(path)
            else:
                files.add(rel)
                if (path.suffix.lower() in FORBIDDEN_SUFFIXES
                        or FORBIDDEN_NAME_RE.match(path.name)):
                    fails.append("Forbidden/unsafe file: " + rel)
        stack.extend(reversed(children))
    return files, dirs, links, fails


def check_layout(root):
    """Return (fails, links, files, dirs). Does not follow links or read bytes."""
    files, dirs, links, fails = _scan_tree(root)
    top_links = {name for name in links if "/" not in name}
    top_dirs = {name for name in dirs if "/" not in name}
    top_files = {name for name in files if "/" not in name}
    top_names = top_links | top_dirs | top_files
    for name in sorted(TOP_FILES_REQUIRED | TOP_DIRS_REQUIRED):
        if name not in top_names:
            fails.append("Missing required top-level entry: " + name)
    for name in sorted(top_dirs):
        if name not in TOP_DIRS_REQUIRED:
            fails.append("Unexpected top-level directory: " + name)
    for name in sorted(top_files):
        if name not in TOP_FILES_REQUIRED | TOP_FILES_OPTIONAL:
            fails.append("Unexpected top-level file: " + name)
    return fails, links, files, dirs


def check_notices(files, dirs):
    """Presence only. Does not read notice bytes."""
    fails = []
    for rel in NOTICE_FILES:
        if rel not in files:
            fails.append("Missing required notice: " + rel)
    if KROWI_NOTICE_DIR in dirs and KROWI_NOTICE_FILE not in files:
        fails.append("Missing required notice: " + KROWI_NOTICE_FILE)
    return fails


def _cursor_inside(root_real, cursor):
    """False if `cursor` is a link or resolves outside `root_real`."""
    if _is_link(cursor):
        return False
    try:
        cursor.resolve().relative_to(root_real)
    except (ValueError, OSError):
        return False
    return True


def _resolve_case(root, parts):
    """Return 'exact', 'case' or None for addon-relative path parts.

    Refuses any component that is a link, or a cursor that resolves outside
    `root`, before calling iterdir.
    """
    if not parts or any(part in ("", ".", "..") for part in parts):
        return None
    try:
        root_real = root.resolve()
    except OSError:
        return None
    cursor, exact = root, True
    for index, part in enumerate(parts):
        if not _cursor_inside(root_real, cursor):
            return None
        try:
            names = {entry.name: entry for entry in cursor.iterdir()}
        except OSError:
            return None
        last = index == len(parts) - 1
        candidates = [part]
        if last and not part.lower().endswith(TEXTURE_EXTS):
            candidates = [part + ext for ext in TEXTURE_EXTS]
        hit = next((cand for cand in candidates if cand in names), None)
        if hit is None:
            folded = {name.lower(): name for name in names}
            hit = next((folded[cand.lower()] for cand in candidates
                        if cand.lower() in folded), None)
            if hit is None:
                return None
            exact = False
        if _is_link(names[hit]):
            return None
        cursor = cursor / hit
        if not _cursor_inside(root_real, cursor):
            return None
    if not _cursor_inside(root_real, cursor):
        return None
    try:
        if not cursor.is_file():
            return None
    except OSError:
        return None
    return "exact" if exact else "case"


def _display_rel(rel):
    if not isinstance(rel, str) or not rel:
        return None
    text = rel.replace("\\", "/")
    if os.path.isabs(text) or text.startswith("../") or "/../" in text:
        return None
    return text


def check_textures(root, lua_paths):
    fails, warns, notes = [], [], []
    seen = {}
    dynamic = 0
    try:
        root_real = root.resolve()
    except OSError:
        fails.append("Cannot resolve staged folder: OSError")
        return fails, warns, notes
    for rel in lua_paths:
        shown = _display_rel(rel)
        target = None if shown is None else root.joinpath(*shown.split("/"))
        if target is None or not _cursor_inside(root_real, target):
            fails.append("Cannot read active Lua: UnsafePath")
            continue
        try:
            text = target.read_text(encoding="utf-8-sig", errors="replace")
        except OSError as exc:
            fails.append("Cannot read active Lua %s: %s"
                         % (shown, type(exc).__name__))
            continue
        text = _strip_lua_comments(text)
        dynamic += len(ADDON_PATH_DYNAMIC.findall(text))
        for match in ADDON_PATH_LITERAL.finditer(text):
            value = match.group(1) if match.group(1) is not None \
                else match.group(2)
            seen.setdefault(value, shown)
        for match in HARDCODED.finditer(text):
            folder, rest = match.group(1), match.group(2)
            if folder == STAGED_NAME:
                seen.setdefault(rest, shown)
            elif folder.lower().startswith("questie"):
                warns.append("Active %s hard-codes another addon folder "
                             "'%s' (not %s)" % (shown, folder, STAGED_NAME))
    textures = 0
    for value, rel in sorted(seen.items()):
        parts = [part for part in value.replace("\\\\", "\\").split("\\")
                 if part]
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


def _drive_prefix(text):
    """`C:` style prefix, or None. Does not touch the filesystem."""
    if len(text) >= 2 and text[0].isalpha() and text[1] == ":":
        return text[0].upper() + ":"
    return None


def _collapse_lexical(text):
    """Return `(absolute, parts)` or None when `..` escapes.

    Understands `/` and `\\` only. No resolve, stat, or read.
    """
    if not isinstance(text, str) or not text or "\x00" in text:
        return None
    drive = _drive_prefix(text)
    absolute = bool(drive) or text.startswith(("/", "\\"))
    body = text[2:] if drive else text
    collapsed = [drive] if drive else []
    for piece in body.replace("\\", "/").split("/"):
        if piece in ("", "."):
            continue
        if piece == "..":
            if drive and len(collapsed) == 1:
                return None
            if not collapsed:
                return None
            collapsed.pop()
            continue
        collapsed.append(piece)
    return absolute, collapsed


def _plain_component(part):
    if not part or part in (".", ".."):
        return False
    if ":" in part or "/" in part or "\\" in part:
        return False
    return True


def _lexical_in_root(root, filename):
    """Relative posix path if `filename` is lexically inside `root`.

    Absolute paths are compared as strings. An outside path, a drive or
    UNC path, or a `..` escape returns None and is never resolved.
    """
    if isinstance(filename, bytes):
        try:
            filename = os.fsdecode(filename)
        except (UnicodeError, ValueError):
            return None
    elif isinstance(filename, os.PathLike):
        try:
            filename = os.fspath(filename)
        except (TypeError, ValueError):
            return None
    if not isinstance(filename, str):
        return None
    try:
        root_text = os.fspath(root)
    except (TypeError, ValueError):
        return None
    file_norm = _collapse_lexical(filename)
    root_norm = _collapse_lexical(root_text)
    if file_norm is None or root_norm is None:
        return None
    file_abs, file_parts = file_norm
    root_abs, root_parts = root_norm
    if file_abs:
        if not root_abs or not root_parts:
            return None
        if file_parts[:len(root_parts)] != root_parts:
            return None
        if len(file_parts) <= len(root_parts):
            return None
        rel_parts = file_parts[len(root_parts):]
    else:
        rel_parts = file_parts
    if not rel_parts or any(not _plain_component(part) for part in rel_parts):
        return None
    shown = "/".join(rel_parts)
    if _EMBEDDED_ABS.search(shown):
        return None
    return shown


def _public_error(root, exc):
    """Exception type, plus a lexical in-root OSError filename.

    Non-OSError failures contribute only the exception type. Arbitrary
    exception strings are never echoed. An OSError filename is included
    only when `_lexical_in_root` accepts it; outside or unknown paths are
    omitted and are not resolved.
    """
    kind = type(exc).__name__
    if not isinstance(exc, OSError):
        return kind
    rel = _lexical_in_root(root, getattr(exc, "filename", None))
    if rel is None:
        rel = _lexical_in_root(root, getattr(exc, "filename2", None))
    if rel is None:
        return kind
    return "%s: %s" % (kind, rel)


def _reject_root(out):
    out("FAIL: argument must be an existing real directory named "
        + STAGED_NAME)
    return 1


def run(path, manifest_module=None, out=print):
    root = Path(path)
    if root.name != STAGED_NAME or _is_link(root):
        return _reject_root(out)
    try:
        if not root.is_dir():
            return _reject_root(out)
        root = root.resolve()
    except OSError:
        return _reject_root(out)
    fails, warns, notes = [], [], []
    layout_fails, links, files, dirs = check_layout(root)
    fails.extend(layout_fails)
    # Any layout failure, including a symlink, junction or reparse point,
    # fails closed BEFORE manifest, XML, Lua or texture reads.
    if layout_fails:
        if links:
            notes.append("Skipped TOC/XML, Lua and texture reads because a "
                         "symlink, junction or reparse point is present")
        else:
            notes.append("Skipped TOC/XML, Lua and texture reads because "
                         "the staged layout failed")
    else:
        fails.extend(check_notices(files, dirs))
        module = manifest_module or _load_manifest_module()
        lua_paths = []
        try:
            result = module.check_manifest(root, require_staged_name=True)
            notes.append("TOC/XML graph: %(toc_paths)d TOC, %(xml_paths)d XML "
                         "refs, %(total_references)d total, %(xml_documents)d "
                         "XML docs" % result)
            lua_paths = _active_lua(module, root)
        except (ValueError, OSError) as exc:
            fails.append("Manifest: " + _public_error(root, exc))
        if lua_paths:
            texture_fails, texture_warns, texture_notes = check_textures(
                root, lua_paths)
            fails.extend(texture_fails)
            warns.extend(texture_warns)
            notes.extend(texture_notes)
    for line in fails:
        out("FAIL: " + line)
    for line in warns:
        out("WARN: " + line)
    for line in notes:
        out("INFO: " + line)
    out("NOT TESTED: game-client loading/rendering, Lua runtime errors, "
        "SavedVariables, rights/licence clearance, source-SHA attestation, "
        "Windows junctions/reparse points (os.path.isjunction is consulted; "
        "st_file_attributes & FILE_ATTRIBUTE_REPARSE_POINT is consulted "
        "where that attribute exists and is a no-op off Windows; "
        "real junction coverage is NOT TESTED; real Windows reparse points "
        "are NOT TESTED), Python on Windows, PowerShell, "
        "static Lua scan limits (not a Lua parser: unbalanced quotes, "
        "unclosed long brackets, texture text inside strings, "
        "loadstring/dynamic code)")
    out("RESULT: " + ("FAIL" if fails else "PASS") +
        " (%d fail, %d warn)" % (len(fails), len(warns)))
    return 1 if fails else 0


def _active_lua(module, root):
    """Active Lua files = TOC + reachable XML refs, via the reviewed parser."""
    collected = []
    original = module._checked_path

    def recording(checked_root, parent, supplied):
        rel = original(checked_root, parent, supplied)
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
