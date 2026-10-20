#!/usr/bin/env python3
"""Offline synthetic self-test for tools/check_nq_335_local_stage.py.

Uses only invented files in disposable temporary directories; never touches
a WoW install, user data, private/server data or the repository tree.
Notice fixtures are invented sentences, not copies of third-party licenses.
Deliberately not named test_*.py so pinned CI discovery is unchanged.
Run: python tools/qa_nq_335_local_stage_selftest.py

Real Windows junctions and reparse points cannot be created here. The
checker still calls os.path.isjunction and, where st_file_attributes
exists, FILE_ATTRIBUTE_REPARSE_POINT, including on ancestors of the
named folder. A monkeypatched junction and a monkeypatched reparse bit
are covered. A real junction in an ancestor is NOT TESTED on Linux.
Real Windows junction/reparse coverage, PowerShell and the game client
are NOT TESTED. Python on Windows is NOT TESTED.
"""
import sys

sys.dont_write_bytecode = True

import contextlib  # noqa: E402
import hashlib  # noqa: E402
import importlib.util  # noqa: E402
import io  # noqa: E402
import os  # noqa: E402
import re  # noqa: E402
import shutil  # noqa: E402
import stat  # noqa: E402
import subprocess  # noqa: E402
import tempfile  # noqa: E402
import unittest  # noqa: E402
from pathlib import Path  # noqa: E402
from unittest import mock  # noqa: E402

HERE = Path(__file__).resolve().parent
CANARY = "NQ335_EXTERNAL_CANARY_SENTINEL"
PRIVATE = "NQ335_PRIVATE_OWNER_PATH_do_not_print"
LAYOUT_CANARY = "NQ335_LAYOUT_FORBIDDEN_CANARY"
OWNER_MARKER = "OWNER_STAGING_ROOT"
# Drive, UNC, or a slash that starts a path. A slash inside a word
# (loading/rendering, Icons/LICENSE) is not an absolute path.
_EMITTED_ABSOLUTE = re.compile(
    r"(?:[A-Za-z]:[\\/]|\\\\|(?<![A-Za-z0-9_])/(?:[A-Za-z0-9._+-]+))"
)


def _load(name, filename):
    spec = importlib.util.spec_from_file_location(name, HERE / filename)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


CHECKER = _load("_nq_stage_checker", "check_nq_335_local_stage.py")

TOC = ("## Interface: 30300\n## Version: 9.5.1.1\n"
       "Modules\\Libs\\QuestieLib.lua\nCompat\\embeds.xml\n"
       "#Modules\\Inactive.lua\nModules\\Tracker.lua\n")
FILES = {
    "Questie-335.toc": TOC,
    "Questie.lua": "-- synthetic root\n",
    "embeds.xml": "<Ui></Ui>\n",
    "Modules/Libs/QuestieLib.lua":
        'QuestieLib.AddonPath = "Interface\\\\Addons\\\\"..n.."\\\\"\n'
        'local a = QuestieLib.AddonPath.."Icons\\\\available.blp"\n'
        '-- QuestieLib.AddonPath.."Icons\\\\commented_out.blp"\n',
    "Modules/Tracker.lua":
        'x:SetTexture(QuestieLib.AddonPath.."Icons\\\\Checkmark")\n',
    "Modules/Inactive.lua":
        'x:SetTexture(QuestieLib.AddonPath.."Icons\\\\absent.blp")\n',
    "Compat/embeds.xml":
        '<Ui><Script file="Compat.lua"/><Include file="Libs\\lib.xml"/>'
        '</Ui>\n',
    "Compat/Compat.lua":
        'l:SetTexture(QuestieLib.AddonPath.."Compat\\\\Icons\\\\Line.blp")\n',
    "Compat/Icons/Line.blp": "synthetic",
    "Compat/Libs/lib.xml": '<Ui><Script file="lib.lua"/></Ui>\n',
    "Compat/Libs/lib.lua": "-- synthetic lib\n",
    "Compat/Libs/Nested/Nested.toc": "## Interface: 30300\n",
    "Database/db.lua": "-- synthetic db\n",
    "Icons/available.blp": "synthetic",
    "Icons/checkmark.tga": "synthetic",
    "Icons/LICENSE.md": "synthetic notice invented for this fixture\n",
    "Icons/MIT.txt": "synthetic mit notice invented for this fixture\n",
    "Libs/LibStub.lua": "-- synthetic\n",
    "Libs/LICENSE.txt": "synthetic libs notice invented for this fixture\n",
    "Localization/enUS.lua": "-- synthetic\n",
}


def build(base, overrides=None, remove=()):
    root = Path(base) / "Questie-335"
    data = dict(FILES)
    data.update(overrides or {})
    for name, text in data.items():
        if name in remove:
            continue
        target = root / name
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(text, encoding="utf-8")
    return root


def snapshot(root):
    digest = {}
    for current, dirs, files in os.walk(root, followlinks=False):
        for name in dirs + files:
            path = Path(current) / name
            key = path.relative_to(root).as_posix()
            if path.is_symlink():
                digest[key] = "link:" + os.readlink(path)
            elif path.is_file():
                digest[key] = hashlib.sha256(path.read_bytes()).hexdigest()
            else:
                digest[key] = "dir"
    return digest


def _plant_canary(parent):
    """Readable files outside the staged root. Invented bytes only."""
    outside = Path(parent) / "OUTSIDE"
    outside.mkdir()
    (outside / "NQ335_EXTERNAL_CANARY_DIR").mkdir()
    (outside / "NQ335_EXTERNAL_CANARY_DIR" / "secret.blp").write_text(
        CANARY + "\n", encoding="utf-8")
    (outside / "available.blp").write_text(CANARY + "\n", encoding="utf-8")
    (outside / "Tracker.lua").write_text(
        'local t = QuestieLib.AddonPath.."Icons\\\\' + CANARY + '.blp"\n'
        + CANARY + "\n", encoding="utf-8")
    return outside


class _OutsideAccessWatch:
    """Record scandir/iterdir/open/read_text/resolve that land outside."""

    def __init__(self, outside):
        self.outside = os.path.realpath(outside)
        self.seen = []

    def _flag(self, path):
        if isinstance(path, int):
            return
        try:
            text = os.fspath(path)
        except TypeError:
            return
        try:
            followed = os.path.realpath(text)
        except (OSError, ValueError):
            return
        outside = self.outside
        if followed == outside or followed.startswith(outside + os.sep):
            self.seen.append(followed)

    def __enter__(self):
        real_scandir = os.scandir
        real_iterdir = Path.iterdir
        real_read_text = Path.read_text
        real_resolve = Path.resolve
        real_open = open
        real_io_open = io.open
        watch = self

        def scandir_wrap(path, *args, **kwargs):
            watch._flag(path)
            return real_scandir(path, *args, **kwargs)

        def iterdir_wrap(pathobj):
            watch._flag(pathobj)
            return real_iterdir(pathobj)

        def read_text_wrap(pathobj, *args, **kwargs):
            watch._flag(pathobj)
            return real_read_text(pathobj, *args, **kwargs)

        def resolve_wrap(pathobj, *args, **kwargs):
            result = real_resolve(pathobj, *args, **kwargs)
            watch._flag(result)
            return result

        def open_wrap(file, *args, **kwargs):
            watch._flag(file)
            return real_open(file, *args, **kwargs)

        def io_open_wrap(file, *args, **kwargs):
            watch._flag(file)
            return real_io_open(file, *args, **kwargs)

        self._stack = contextlib.ExitStack()
        self._stack.enter_context(mock.patch("os.scandir", new=scandir_wrap))
        self._stack.enter_context(
            mock.patch.object(Path, "iterdir", iterdir_wrap))
        self._stack.enter_context(
            mock.patch.object(Path, "read_text", read_text_wrap))
        self._stack.enter_context(
            mock.patch.object(Path, "resolve", resolve_wrap))
        self._stack.enter_context(
            mock.patch("builtins.open", new=open_wrap))
        self._stack.enter_context(mock.patch("io.open", new=io_open_wrap))
        return self

    def __exit__(self, exc_type, exc, tb):
        self._stack.close()
        return False


def _bytecode_snapshot(directory):
    found = {}

    def record(path):
        if path.is_file() and path.suffix == ".pyc":
            stat = path.stat()
            found[path.relative_to(directory).as_posix()] = (
                stat.st_size, stat.st_mtime_ns)

    for path in directory.glob("*.pyc"):
        record(path)
    cache = directory / "__pycache__"
    if cache.is_dir() and not cache.is_symlink():
        for path in cache.iterdir():
            record(path)
    return found


class StageCheckerSelfTest(unittest.TestCase):
    def check(self, root):
        lines = []
        before = snapshot(root.parent)
        code = CHECKER.run(str(root), out=lines.append)
        self.assertEqual(before, snapshot(root.parent), "checker mutated tree")
        return code, "\n".join(lines)

    def _assert_outside_unread(self, root, outside):
        lines = []
        before = snapshot(root.parent)
        with _OutsideAccessWatch(outside) as watch:
            code = CHECKER.run(str(root), out=lines.append)
        text = "\n".join(lines)
        self.assertEqual(before, snapshot(root.parent), "checker mutated tree")
        self.assertEqual(watch.seen, [],
                         "outside path was enumerated or read: %r\n%s"
                         % (watch.seen, text))
        self.assertNotIn(CANARY, text)
        self.assertNotIn("NQ335_EXTERNAL_CANARY_DIR", text)
        return code, text

    def test_valid_pass_with_case_warning_and_inactive_ignored(self):
        with tempfile.TemporaryDirectory() as tmp:
            code, out = self.check(build(tmp))
            self.assertEqual(code, 0, out)
            self.assertIn("RESULT: PASS", out)
            self.assertIn("Case-only texture mismatch Icons\\\\Checkmark", out)
            self.assertNotIn("absent.blp", out)
            self.assertNotIn("commented_out", out)
            self.assertIn("NOT TESTED", out)
            self.assertIn("real junction coverage is NOT TESTED", out)
            self.assertIn("real Windows reparse points are NOT TESTED", out)
            self.assertIn("no-op off Windows", out)
            self.assertIn("Python on Windows", out)
            self.assertIn("PowerShell", out)
            self.assertIn("static Lua scan limits", out)

    def test_missing_toc_entry_fails(self):
        with tempfile.TemporaryDirectory() as tmp:
            code, out = self.check(build(tmp, remove={"Modules/Tracker.lua"}))
            self.assertEqual(code, 1, out)
            self.assertIn("Manifest:", out)

    def test_missing_xml_include_fails(self):
        with tempfile.TemporaryDirectory() as tmp:
            code, out = self.check(build(tmp, remove={"Compat/Libs/lib.lua"}))
            self.assertEqual(code, 1, out)

    def test_wrong_case_toc_reference_fails(self):
        with tempfile.TemporaryDirectory() as tmp:
            toc = TOC.replace("Modules\\Tracker.lua", "Modules\\tracker.lua")
            code, out = self.check(build(tmp, {"Questie-335.toc": toc}))
            self.assertEqual(code, 1, out)

    def test_wrong_interface_fails(self):
        with tempfile.TemporaryDirectory() as tmp:
            toc = TOC.replace("30300", "11507")
            code, out = self.check(build(tmp, {"Questie-335.toc": toc}))
            self.assertEqual(code, 1, out)

    def test_missing_runtime_icon_fails(self):
        with tempfile.TemporaryDirectory() as tmp:
            code, out = self.check(build(tmp, remove={"Icons/available.blp"}))
            self.assertEqual(code, 1, out)
            self.assertIn("Missing runtime texture", out)

    def test_missing_compat_icon_fails(self):
        with tempfile.TemporaryDirectory() as tmp:
            code, out = self.check(build(tmp,
                                         remove={"Compat/Icons/Line.blp"}))
            self.assertEqual(code, 1, out)

    def test_forbidden_content_fails(self):
        cases = {"private/q.lua": "x", "Database/dump.sql": "x",
                 "Libs/pkg.zip": "x", "Extra.toc": "## Interface: 30300\n",
                 "README.md": "x", "WTF/Config.wtf": "x",
                 "Modules/.env": "x", "tools/x.py": "x"}
        for name, text in cases.items():
            with self.subTest(name=name), \
                    tempfile.TemporaryDirectory() as tmp:
                code, out = self.check(build(tmp, {name: text}))
                self.assertEqual(code, 1, out)

    def test_nested_library_toc_allowed(self):
        with tempfile.TemporaryDirectory() as tmp:
            code, out = self.check(build(tmp))
            self.assertNotIn("Nested.toc", out)
            self.assertEqual(code, 0, out)

    def test_missing_required_directory_fails(self):
        with tempfile.TemporaryDirectory() as tmp:
            code, out = self.check(build(tmp, remove={"Localization/enUS.lua"}))
            self.assertEqual(code, 1, out)

    def test_wrong_folder_name_fails(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = build(tmp)
            other = root.with_name("Questie")
            root.rename(other)
            lines = []
            self.assertEqual(CHECKER.run(str(other), out=lines.append), 1)

    def test_ordinary_file_named_icons_fails(self):
        remove = [name for name in FILES
                  if name == "Icons" or name.startswith("Icons/")]
        with tempfile.TemporaryDirectory() as tmp:
            root = build(tmp, {"Icons": "not a directory\n"}, remove=remove)
            self.assertTrue((root / "Icons").is_file())
            code, out = self.check(root)
            self.assertEqual(code, 1, out)
            self.assertIn("Unexpected top-level file: Icons", out)

    def test_ordinary_directory_named_questie_lua_fails(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = build(tmp, remove={"Questie.lua"})
            (root / "Questie.lua").mkdir()
            self.assertTrue((root / "Questie.lua").is_dir())
            code, out = self.check(root)
            self.assertEqual(code, 1, out)
            self.assertIn("Unexpected top-level directory: Questie.lua", out)

    def _assert_linked_input_rejected(self, path, outside, forbidden):
        """run() returns 1 before is_dir, resolve, scandir or read_text.

        `forbidden` strings (canaries, absolute paths) must be absent.
        A real Windows junction path is NOT TESTED on Linux.
        """
        is_dir_calls = []
        real_is_dir = Path.is_dir

        def is_dir_wrap(pathobj, *args, **kwargs):
            is_dir_calls.append(os.fspath(pathobj))
            return real_is_dir(pathobj, *args, **kwargs)

        lines = []
        with mock.patch.object(Path, "is_dir", is_dir_wrap), \
                _OutsideAccessWatch(outside) as watch:
            code = CHECKER.run(os.fspath(path), out=lines.append)
        text = "\n".join(lines)
        self.assertEqual(code, 1, text)
        self.assertEqual(is_dir_calls, [],
                         "is_dir ran before the link check:\n" + text)
        self.assertEqual(watch.seen, [],
                         "outside path was enumerated or read: %r\n%s"
                         % (watch.seen, text))
        self.assertEqual(lines, [
            "FAIL: symlink, junction or reparse point in the path to "
            "Questie-335",
        ], text)
        for secret in forbidden:
            self.assertNotIn(secret, text)
        for line in lines:
            self.assertIsNone(_EMITTED_ABSOLUTE.search(line), line)
        return text

    @unittest.skipUnless(hasattr(os, "symlink"), "no symlink support")
    def test_symlink_escape_fails(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = build(tmp)
            outside = _plant_canary(tmp)
            shutil.rmtree(root / "Icons")
            try:
                os.symlink(os.path.join("..", "OUTSIDE"), root / "Icons",
                           target_is_directory=True)
            except (OSError, NotImplementedError):
                self.skipTest("symlink creation not permitted")
            code, out = self._assert_outside_unread(root, outside)
            self.assertEqual(code, 1, out)
            self.assertIn("Link escapes staged folder: Icons", out)
            self.assertIn("Skipped TOC/XML", out)

    @unittest.skipUnless(hasattr(os, "symlink"), "no symlink support")
    def test_active_toc_symlink_is_not_read(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = build(tmp)
            outside = _plant_canary(tmp)
            tracker = root / "Modules" / "Tracker.lua"
            tracker.unlink()
            try:
                os.symlink(os.path.join("..", "..", "OUTSIDE", "Tracker.lua"),
                           tracker)
            except (OSError, NotImplementedError):
                self.skipTest("symlink creation not permitted")
            code, out = self._assert_outside_unread(root, outside)
            self.assertEqual(code, 1, out)
            self.assertIn("Link escapes staged folder: Modules/Tracker.lua",
                          out)
            self.assertIn("Skipped TOC/XML", out)

    @unittest.skipUnless(hasattr(os, "symlink"), "no symlink support")
    def test_internal_symlink_fails(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = build(tmp)
            try:
                os.symlink("available.blp", root / "Icons" / "alias.blp")
            except (OSError, NotImplementedError):
                self.skipTest("symlink creation not permitted")
            code, out = self.check(root)
            self.assertEqual(code, 1, out)
            self.assertIn("Link/junction/reparse point is not allowed: "
                          "Icons/alias.blp", out)
            self.assertIn("Skipped TOC/XML", out)

    @unittest.skipUnless(hasattr(os, "symlink"), "no symlink support")
    def test_symlinked_parent_does_not_read_outside(self):
        """An ordinary Questie-335 under a linked parent must not be scanned.

        Shape: INTENDED/LinkedParent/Questie-335 where LinkedParent points
        at OUTSIDE, and OUTSIDE/Questie-335 is a real directory. The child
        itself is not a symlink. run() must return nonzero without reading
        or enumerating OUTSIDE.

        A junction in that ancestor position is NOT TESTED on Linux.
        """
        canary = "NQ335_ANCESTOR_LINK_CANARY"
        with tempfile.TemporaryDirectory() as tmp:
            outside = Path(tmp) / "OUTSIDE"
            intended = Path(tmp) / "INTENDED"
            outside.mkdir()
            intended.mkdir()
            root_real = build(outside, {
                "Modules/Tracker.lua":
                    'x:SetTexture(QuestieLib.AddonPath.."Icons\\\\'
                    + canary + '.blp")\n',
                "Icons/" + canary + ".blp": canary + "\n",
            })
            (outside / "NQ335_EXTERNAL_CANARY_DIR").mkdir()
            (outside / "NQ335_EXTERNAL_CANARY_DIR" / "secret.blp").write_text(
                CANARY + "\n", encoding="utf-8")
            link = intended / "LinkedParent"
            try:
                os.symlink(outside, link, target_is_directory=True)
            except (OSError, NotImplementedError):
                self.skipTest("symlink creation not permitted")
            lexical = link / "Questie-335"
            self.assertFalse(lexical.is_symlink())
            self.assertTrue(link.is_symlink())
            self.assertTrue(lexical.is_dir())
            self.assertEqual(lexical.resolve(), root_real.resolve())

            def explode(*args, **kwargs):
                raise AssertionError("resolve called while building chain")

            with mock.patch.object(Path, "resolve", explode):
                chain = CHECKER._lexical_chain(str(lexical))
            self.assertIsNotNone(chain)
            self.assertEqual(chain[0], os.sep)
            self.assertTrue(any(part.endswith(os.sep + "LinkedParent")
                                for part in chain))
            self.assertTrue(chain[-1].endswith(os.sep + "Questie-335"))
            self.assertNotIn(str(outside), "\n".join(chain))
            self.assertNotIn(str(root_real), chain)
            before = snapshot(outside)
            forbidden = (canary, CANARY, "NQ335_EXTERNAL_CANARY_DIR",
                         str(outside), str(lexical), str(root_real),
                         str(link), str(intended))
            self._assert_linked_input_rejected(str(lexical), outside,
                                               forbidden)
            self.assertEqual(before, snapshot(outside),
                             "checker mutated the outside tree")

            cwd = os.getcwd()
            try:
                os.chdir(intended)
                relative = os.path.join("LinkedParent", "Questie-335")
                self.assertFalse(os.path.isabs(relative))
                with mock.patch.object(Path, "resolve", explode):
                    relative_chain = CHECKER._lexical_chain(relative)
                self.assertNotIn(str(outside), "\n".join(relative_chain))
                self.assertTrue(any(
                    part.endswith(os.sep + "LinkedParent")
                    for part in relative_chain))
                self._assert_linked_input_rejected(relative, outside,
                                                   forbidden)
            finally:
                os.chdir(cwd)
            self.assertEqual(before, snapshot(outside),
                             "checker mutated the outside tree")

    @unittest.skipUnless(hasattr(os, "symlink"), "no symlink support")
    def test_parent_dotdot_cannot_bypass_ancestor_guard(self):
        """Raw linked-parent/.. must fail before any staged-tree read.

        Normalised spelling points at INTENDED/Questie-335, but filesystem
        traversal via LinkedParent -> OUTSIDE/NEST reaches OUTSIDE/Questie-335.
        Both targets are valid invented stages: missing files cannot make
        this negative test pass accidentally.
        """
        with tempfile.TemporaryDirectory() as tmp:
            intended = Path(tmp) / "INTENDED"
            outside = Path(tmp) / "OUTSIDE"
            intended.mkdir()
            (outside / "NEST").mkdir(parents=True)
            normal = build(intended)
            external = build(outside, {
                "Modules/Tracker.lua": "-- invented outside canary\n",
                "Icons/external-canary.blp": CANARY + "\n",
            })
            (outside / "NQ335_EXTERNAL_CANARY_DIR").mkdir()
            (outside / "NQ335_EXTERNAL_CANARY_DIR" / "private.txt").write_text(
                CANARY + "\n", encoding="utf-8")
            link = intended / "LinkedParent"
            try:
                os.symlink(outside / "NEST", link, target_is_directory=True)
            except (OSError, NotImplementedError):
                self.skipTest("symlink creation not permitted")

            lexical = link / ".." / "Questie-335"
            self.assertEqual(Path(os.path.abspath(str(lexical))), normal)
            self.assertEqual(lexical.resolve(), external.resolve())
            self.assertTrue(lexical.is_dir())
            self.assertTrue(normal.is_dir())
            self.assertIsNone(CHECKER._lexical_chain(str(lexical)))
            self.assertIsNone(
                CHECKER._lexical_chain(r"LinkedParent\..\Questie-335"))
            before = snapshot(outside)

            def reject_candidate(candidate):
                lines = []
                with mock.patch.object(
                        Path, "is_dir",
                        side_effect=AssertionError("pre-read is_dir called")
                ), _OutsideAccessWatch(outside) as watch:
                    code = CHECKER.run(candidate, out=lines.append)
                output = "\n".join(lines)
                self.assertEqual(code, 1, output)
                self.assertEqual(watch.seen, [],
                                 "outside access: %r" % watch.seen)
                self.assertEqual(lines, [
                    "FAIL: argument must be an existing real directory "
                    "named Questie-335",
                ], output)
                self.assertNotIn(CANARY, output)
                self.assertNotIn(str(outside), output)
                for line in lines:
                    self.assertIsNone(_EMITTED_ABSOLUTE.search(line), line)

            reject_candidate(str(lexical))
            cwd = os.getcwd()
            try:
                os.chdir(intended)
                reject_candidate(
                    os.path.join("LinkedParent", "..", "Questie-335"))
            finally:
                os.chdir(cwd)
            self.assertEqual(before, snapshot(outside),
                             "outside fixture was mutated")
            code, output = self.check(normal)
            self.assertEqual(code, 0, output)

    @unittest.skipUnless(hasattr(os, "symlink"), "no symlink support")
    def test_root_symlink_is_not_followed(self):
        """The named Questie-335 itself being a symlink still fails closed."""
        with tempfile.TemporaryDirectory() as tmp:
            outside = _plant_canary(tmp)
            real = build(outside)
            intended = Path(tmp) / "INTENDED"
            intended.mkdir()
            link = intended / "Questie-335"
            try:
                os.symlink(real, link, target_is_directory=True)
            except (OSError, NotImplementedError):
                self.skipTest("symlink creation not permitted")
            self.assertTrue(link.is_symlink())
            forbidden = (CANARY, "NQ335_EXTERNAL_CANARY_DIR", str(outside),
                         str(real), str(link), str(intended))
            self._assert_linked_input_rejected(str(link), outside, forbidden)

    def test_simulated_ancestor_junction_rejects_before_isdir(self):
        """os.path.isjunction on an ancestor fails closed before is_dir.

        Real Windows junctions and reparse points are NOT TESTED. This
        only monkeypatches the predicate.
        """
        if not hasattr(os.path, "isjunction"):
            self.skipTest("os.path.isjunction is not available")
        with tempfile.TemporaryDirectory() as tmp:
            root = build(tmp)
            parent_name = Path(tmp).name
            real_isjunction = os.path.isjunction
            real_is_dir = Path.is_dir
            real_resolve = Path.resolve
            real_scandir = os.scandir
            real_read = Path.read_text
            seen = {"is_dir": [], "resolve": [], "scandir": [], "read": []}

            def fake_isjunction(path):
                if os.path.basename(os.fspath(path)) == parent_name:
                    return True
                return real_isjunction(path)

            def is_dir_wrap(pathobj, *args, **kwargs):
                seen["is_dir"].append(os.fspath(pathobj))
                return real_is_dir(pathobj, *args, **kwargs)

            def resolve_wrap(pathobj, *args, **kwargs):
                seen["resolve"].append(os.fspath(pathobj))
                return real_resolve(pathobj, *args, **kwargs)

            def scandir_wrap(path, *args, **kwargs):
                seen["scandir"].append(os.fspath(path))
                return real_scandir(path, *args, **kwargs)

            def read_wrap(pathobj, *args, **kwargs):
                seen["read"].append(os.fspath(pathobj))
                return real_read(pathobj, *args, **kwargs)

            lines = []
            before = snapshot(root.parent)
            with mock.patch("os.path.isjunction", new=fake_isjunction), \
                    mock.patch.object(Path, "is_dir", is_dir_wrap), \
                    mock.patch.object(Path, "resolve", resolve_wrap), \
                    mock.patch("os.scandir", scandir_wrap), \
                    mock.patch.object(Path, "read_text", read_wrap):
                code = CHECKER.run(str(root), out=lines.append)
            text = "\n".join(lines)
            self.assertEqual(before, snapshot(root.parent),
                             "checker mutated tree")
            self.assertEqual(code, 1, text)
            self.assertEqual(seen["is_dir"], [], text)
            self.assertEqual(seen["resolve"], [], text)
            self.assertEqual(seen["scandir"], [], text)
            self.assertEqual(seen["read"], [], text)
            self.assertEqual(lines, [
                "FAIL: symlink, junction or reparse point in the path to "
                "Questie-335",
            ], text)
            for line in lines:
                self.assertIsNone(_EMITTED_ABSOLUTE.search(line), line)
                self.assertNotIn(str(root), line)
                self.assertNotIn(tmp, line)

    def test_simulated_junction_skips_content_reads(self):
        """Real Windows junctions are NOT TESTED. A monkeypatched
        os.path.isjunction True must still fail closed before read_text.
        """
        if not hasattr(os.path, "isjunction"):
            self.skipTest("os.path.isjunction is not available")

        def fake_isjunction(path):
            candidate = Path(os.fspath(path))
            return candidate.parent.name == "Modules" and \
                candidate.name == "Tracker.lua"

        read_calls = []
        real_read = Path.read_text

        def read_wrap(pathobj, *args, **kwargs):
            read_calls.append(str(pathobj))
            return real_read(pathobj, *args, **kwargs)

        with tempfile.TemporaryDirectory() as tmp:
            root = build(tmp)
            lines = []
            before = snapshot(root.parent)
            with mock.patch("os.path.isjunction", new=fake_isjunction), \
                    mock.patch.object(Path, "read_text", read_wrap):
                code = CHECKER.run(str(root), out=lines.append)
            text = "\n".join(lines)
            self.assertEqual(before, snapshot(root.parent),
                             "checker mutated tree")
            self.assertEqual(code, 1, text)
            self.assertEqual(read_calls, [], text)
            self.assertIn("Link/junction/reparse point is not allowed: "
                          "Modules/Tracker.lua", text)
            self.assertIn("real junction coverage is NOT TESTED", text)

    def test_unreadable_active_file_omits_private_path(self):
        if getattr(os, "geteuid", lambda: 1)() == 0:
            self.skipTest("chmod 000 is ignored when running as root")
        cases = ("Modules/Tracker.lua", "Compat/embeds.xml")
        for rel in cases:
            with self.subTest(rel=rel), tempfile.TemporaryDirectory() as tmp:
                parent = Path(tmp) / PRIVATE
                parent.mkdir()
                root = build(parent)
                target = root.joinpath(*rel.split("/"))
                before = snapshot(root)
                target.chmod(0)
                lines = []
                try:
                    code = CHECKER.run(str(root), out=lines.append)
                finally:
                    target.chmod(0o644)
                text = "\n".join(lines)
                self.assertEqual(snapshot(root), before, "checker mutated tree")
                self.assertEqual(code, 1, text)
                for line in lines:
                    self.assertNotIn(PRIVATE, line)
                    self.assertNotIn(str(parent), line)
                self.assertIn("PermissionError", text)
                self.assertIn(rel, text)

    def test_missing_required_notice_fails(self):
        for rel in ("Icons/LICENSE.md", "Icons/MIT.txt", "Libs/LICENSE.txt"):
            with self.subTest(rel=rel), tempfile.TemporaryDirectory() as tmp:
                code, out = self.check(build(tmp, remove={rel}))
                self.assertEqual(code, 1, out)
                self.assertIn("Missing required notice: " + rel, out)

    def test_krowi_notice_required_only_when_directory_present(self):
        with self.subTest("absent directory"), \
                tempfile.TemporaryDirectory() as tmp:
            code, out = self.check(build(tmp))
            self.assertEqual(code, 0, out)
            self.assertNotIn("Krowi_WorldMapButtons", out)
        with self.subTest("present without notice"), \
                tempfile.TemporaryDirectory() as tmp:
            code, out = self.check(build(tmp, {
                "Libs/Krowi_WorldMapButtons/placeholder.txt":
                "synthetic placeholder\n",
            }))
            self.assertEqual(code, 1, out)
            self.assertIn(
                "Missing required notice: "
                "Libs/Krowi_WorldMapButtons/LICENSE.md", out)
        with self.subTest("present with invented notice"), \
                tempfile.TemporaryDirectory() as tmp:
            code, out = self.check(build(tmp, {
                "Libs/Krowi_WorldMapButtons/LICENSE.md":
                "synthetic krowi notice invented for this fixture\n",
            }))
            self.assertEqual(code, 0, out)

    def test_inline_lua_comment_and_quoted_dashes(self):
        lua = "\n".join((
            '--[[ QuestieLib.AddonPath.."Icons\\\\long_missing.blp" ]]',
            'local quoted = "--" local a = '
            'QuestieLib.AddonPath.."Icons\\\\after_quoted_dashes.blp"'
            ' -- QuestieLib.AddonPath.."Icons\\\\missing.blp"',
        )) + "\n"
        stripped = CHECKER._strip_lua_comments(lua)
        self.assertIn("after_quoted_dashes.blp", stripped)
        self.assertIn('"--"', stripped)
        self.assertNotIn("missing.blp", stripped)
        self.assertNotIn("long_missing", stripped)
        with tempfile.TemporaryDirectory() as tmp:
            root = build(tmp, {
                "Modules/Tracker.lua": lua,
                "Icons/after_quoted_dashes.blp": "synthetic\n",
            })
            code, out = self.check(root)
            self.assertEqual(code, 0, out)
            self.assertIn("RESULT: PASS", out)
            self.assertNotIn("missing.blp", out)
            self.assertNotIn("long_missing", out)
            self.assertIn(
                "3 distinct static addon texture paths checked", out)

    def _assert_emitted_paths_private(self, lines, root, message):
        text = "\n".join(lines)
        resolved = str(Path(root).resolve())
        owner = str(Path(root).resolve().parent)
        self.assertNotIn(message, text)
        self.assertNotIn("OTHER_PRIVATE", text)
        self.assertNotIn("sensitive.txt", text)
        self.assertNotIn(OWNER_MARKER, text)
        self.assertNotIn(resolved, text)
        self.assertNotIn(owner, text)
        for line in lines:
            match = _EMITTED_ABSOLUTE.search(line)
            self.assertIsNone(match, "absolute path in %r" % (line,))
        return text

    def test_injected_valueerror_never_echoes_exception_text(self):
        """Non-OSError text is never emitted, including paths the old
        absolute-path regex missed (after '=', ':', '[', ',').

        Invented paths only. Restoring `return kind + ': ' + str(exc)`
        makes this test fail.
        """
        messages = (
            "manifest returned source=/home/OTHER_PRIVATE/sensitive.txt",
            "path:/x/OTHER_PRIVATE/sensitive.txt",
            "[/x/OTHER_PRIVATE/sensitive.txt]",
            ",/x/OTHER_PRIVATE/sensitive.txt",
            "C:\\Users\\OTHER_PRIVATE\\sensitive.txt",
            "C:/Users/OTHER_PRIVATE/sensitive.txt",
        )

        class _Boom:
            def __init__(self, message):
                self._message = message

            def check_manifest(self, root, require_staged_name=True):
                raise ValueError(self._message)

        for message in messages:
            with self.subTest(message=message), \
                    tempfile.TemporaryDirectory() as tmp:
                parent = Path(tmp) / OWNER_MARKER
                parent.mkdir()
                root = build(parent)
                lines = []
                before = snapshot(root.parent)
                code = CHECKER.run(str(root), manifest_module=_Boom(message),
                                   out=lines.append)
                self.assertEqual(before, snapshot(root.parent),
                                 "checker mutated tree")
                text = self._assert_emitted_paths_private(lines, root, message)
                self.assertEqual(code, 1, text)
                self.assertIn("FAIL: Manifest: ValueError", text)
                self.assertNotIn("ValueError:", text)
                self.assertIn("RESULT: FAIL", text)

    def test_oserror_outside_filename_is_not_resolved(self):
        """An outside OSError filename is not resolved and not printed.

        An in-root filename is reduced lexically to a relative path.
        """
        with tempfile.TemporaryDirectory() as tmp:
            parent = Path(tmp) / OWNER_MARKER
            parent.mkdir()
            root = build(parent)
            root_real = root.resolve()
            inside = str(root_real / "Modules" / "Tracker.lua")
            outside = "/home/OTHER_PRIVATE/sensitive.txt"
            windows = "C:\\Users\\OTHER_PRIVATE\\sensitive.txt"
            real_resolve = Path.resolve

            def guarded_resolve(pathobj, *args, **kwargs):
                text = os.fspath(pathobj)
                folded = text.replace("\\", "/")
                if "OTHER_PRIVATE" in folded or "\\Users\\" in text \
                        or "/Users/" in folded:
                    raise AssertionError("resolved outside path " + text)
                return real_resolve(pathobj, *args, **kwargs)

            def run_case(filename, filename2=None):
                class Module:
                    def check_manifest(self, checked,
                                       require_staged_name=True):
                        err = OSError(13, "Permission denied")
                        err.filename = filename
                        if filename2 is not None:
                            err.filename2 = filename2
                        raise err

                lines = []
                before = snapshot(root.parent)
                with mock.patch.object(Path, "resolve", guarded_resolve):
                    code = CHECKER.run(str(root), manifest_module=Module(),
                                       out=lines.append)
                self.assertEqual(before, snapshot(root.parent),
                                 "checker mutated tree")
                return code, lines

            code, lines = run_case(inside)
            text = self._assert_emitted_paths_private(lines, root, inside)
            self.assertEqual(code, 1, text)
            # errno 13 is constructed as PermissionError, a subclass of OSError.
            self.assertIn(
                "FAIL: Manifest: PermissionError: Modules/Tracker.lua", text)

            for filename in (outside, windows,
                             "source=/home/OTHER_PRIVATE/sensitive.txt",
                             "path:/x/OTHER_PRIVATE/sensitive.txt",
                             "[/x/OTHER_PRIVATE/sensitive.txt]",
                             ",/x/OTHER_PRIVATE/sensitive.txt"):
                with self.subTest(filename=filename):
                    code, lines = run_case(filename)
                    text = self._assert_emitted_paths_private(
                        lines, root, filename)
                    self.assertEqual(code, 1, text)
                    self.assertIn("FAIL: Manifest: PermissionError", text)
                    self.assertNotIn("PermissionError:", text)

            code, lines = run_case(outside, inside)
            text = self._assert_emitted_paths_private(lines, root, outside)
            self.assertEqual(code, 1, text)
            self.assertIn(
                "FAIL: Manifest: PermissionError: Modules/Tracker.lua", text)
            self.assertNotIn(outside, text)

    def test_layout_failure_skips_content_reads(self):
        """Forbidden or unexpected layout must not read staged bytes.

        Invented canary only. check_manifest is not called.
        """
        cases = {
            "wtf-toc": (
                {"Questie-335.toc": TOC + "WTF\\Secret.lua\n",
                 "WTF/Secret.lua": LAYOUT_CANARY + "\n"},
                "Forbidden directory: WTF",
                "WTF/Secret.lua",
            ),
            "private-toc": (
                {"Questie-335.toc": TOC + "private\\Secret.lua\n",
                 "private/Secret.lua": LAYOUT_CANARY + "\n"},
                "Forbidden directory: private",
                "private/Secret.lua",
            ),
            "unexpected-dir": (
                {"Extra/note.txt": LAYOUT_CANARY + "\n"},
                "Unexpected top-level directory: Extra",
                "Extra/note.txt",
            ),
            "unexpected-file": (
                {"README.md": LAYOUT_CANARY + "\n"},
                "Unexpected top-level file: README.md",
                "README.md",
            ),
        }
        for name, (overrides, expect, forbidden) in cases.items():
            with self.subTest(name=name), \
                    tempfile.TemporaryDirectory() as tmp:
                root = build(tmp, overrides)
                module = CHECKER._load_manifest_module()
                calls = []
                original = module.check_manifest

                def wrapped(checked, require_staged_name=True,
                            _original=original, _calls=calls):
                    _calls.append(os.fspath(checked))
                    return _original(checked,
                                     require_staged_name=require_staged_name)

                module.check_manifest = wrapped
                read_calls = []
                real_read = Path.read_text

                def read_wrap(pathobj, *args, **kwargs):
                    read_calls.append(os.fspath(pathobj))
                    return real_read(pathobj, *args, **kwargs)

                lines = []
                before = snapshot(root.parent)
                with mock.patch.object(Path, "read_text", read_wrap):
                    code = CHECKER.run(str(root), manifest_module=module,
                                       out=lines.append)
                text = "\n".join(lines)
                self.assertEqual(before, snapshot(root.parent),
                                 "checker mutated tree")
                self.assertEqual(code, 1, text)
                self.assertIn(expect, text)
                self.assertNotIn(LAYOUT_CANARY, text)
                self.assertEqual(calls, [], "check_manifest ran:\n" + text)
                self.assertEqual(read_calls, [],
                                 "staged bytes were read:\n" + text)
                if forbidden.endswith("Secret.lua"):
                    self.assertNotIn(forbidden, text)
                self.assertIn("Skipped TOC/XML", text)
                self.assertIn("RESULT: FAIL", text)
                self.assertIn("NOT TESTED", text)

    def test_uninspectable_entry_is_layout_fail(self):
        """entry.is_dir(follow_symlinks=False) raising is a layout FAIL.

        It is not classed as a file, and the file is not read.
        """
        secret = "NQ335_INSPECT_OTHER_PRIVATE"
        real_scandir = os.scandir

        class _Entry:
            def __init__(self, inner):
                self._inner = inner
                self.name = inner.name
                self.path = inner.path

            def is_dir(self, *, follow_symlinks=True):
                if self.name == "Tracker.lua":
                    raise OSError(1, secret)
                return self._inner.is_dir(follow_symlinks=follow_symlinks)

        class _Scan:
            def __init__(self, inner):
                self._inner = inner

            def __enter__(self):
                self._inner.__enter__()
                return self

            def __exit__(self, exc_type, exc, tb):
                return self._inner.__exit__(exc_type, exc, tb)

            def __iter__(self):
                for entry in self._inner:
                    yield _Entry(entry)

        def scandir_wrap(path, *args, **kwargs):
            return _Scan(real_scandir(path, *args, **kwargs))

        with tempfile.TemporaryDirectory() as tmp:
            root = build(tmp)
            module = CHECKER._load_manifest_module()
            calls = []
            original = module.check_manifest

            def wrapped(checked, require_staged_name=True,
                        _original=original):
                calls.append(os.fspath(checked))
                return _original(checked,
                                 require_staged_name=require_staged_name)

            module.check_manifest = wrapped
            read_calls = []
            real_read = Path.read_text

            def read_wrap(pathobj, *args, **kwargs):
                read_calls.append(os.fspath(pathobj))
                return real_read(pathobj, *args, **kwargs)

            lines = []
            before = snapshot(root.parent)
            with mock.patch("os.scandir", new=scandir_wrap), \
                    mock.patch.object(Path, "read_text", read_wrap):
                code = CHECKER.run(str(root), manifest_module=module,
                                   out=lines.append)
            text = "\n".join(lines)
            self.assertEqual(before, snapshot(root.parent),
                             "checker mutated tree")
            self.assertEqual(code, 1, text)
            self.assertIn("Cannot inspect staged entry: Modules/Tracker.lua",
                          text)
            self.assertNotIn(secret, text)
            self.assertNotIn("Unexpected top-level file: Tracker.lua", text)
            self.assertEqual(calls, [], "check_manifest ran:\n" + text)
            self.assertEqual(read_calls, [],
                             "staged bytes were read:\n" + text)
            self.assertIn("Skipped TOC/XML", text)
            self.assertIn("RESULT: FAIL", text)
            for line in lines:
                self.assertNotIn(str(root), line)
                self.assertNotIn(tmp, line)
                self.assertIsNone(_EMITTED_ABSOLUTE.search(line), line)

    def test_reparse_attribute_is_noop_when_absent(self):
        """Off Windows st_file_attributes is missing. Real Windows reparse
        points are NOT TESTED.
        """
        self.assertIsNotNone(
            getattr(stat, "FILE_ATTRIBUTE_REPARSE_POINT", None))
        sample = HERE / "check_nq_335_local_stage.py"
        attrs = getattr(os.lstat(sample), "st_file_attributes", None)
        if attrs is not None:
            self.skipTest("st_file_attributes is present; real Windows "
                          "reparse points are NOT TESTED")
        self.assertFalse(CHECKER._reparse_point(sample))

    def test_injected_reparse_attribute_skips_reads(self):
        """A monkeypatched FILE_ATTRIBUTE_REPARSE_POINT bit fails closed.

        This is not a real Windows reparse point. Real Windows reparse
        points are NOT TESTED.
        """
        flag = stat.FILE_ATTRIBUTE_REPARSE_POINT
        real_lstat = os.lstat

        class _AttrStat:
            def __init__(self, inner, attrs):
                self._inner = inner
                self.st_file_attributes = attrs

            def __getattr__(self, name):
                return getattr(self._inner, name)

        def lstat_wrap(path, *args, **kwargs):
            result = real_lstat(path, *args, **kwargs)
            try:
                text = os.fspath(path).replace("\\", "/")
            except TypeError:
                return result
            if text.endswith("/Modules/Tracker.lua"):
                return _AttrStat(result, flag)
            return result

        read_calls = []
        real_read = Path.read_text

        def read_wrap(pathobj, *args, **kwargs):
            read_calls.append(os.fspath(pathobj))
            return real_read(pathobj, *args, **kwargs)

        with tempfile.TemporaryDirectory() as tmp:
            root = build(tmp)
            lines = []
            before = snapshot(root.parent)
            with mock.patch("os.lstat", new=lstat_wrap), \
                    mock.patch.object(Path, "read_text", read_wrap):
                code = CHECKER.run(str(root), out=lines.append)
            text = "\n".join(lines)
            self.assertEqual(before, snapshot(root.parent),
                             "checker mutated tree")
            self.assertEqual(code, 1, text)
            self.assertEqual(read_calls, [], text)
            self.assertIn("Link/junction/reparse point is not allowed: "
                          "Modules/Tracker.lua", text)
            self.assertIn("Skipped TOC/XML", text)
            self.assertIn("real Windows reparse points are NOT TESTED", text)

    def test_no_bytecode_written_next_to_tools(self):
        env = os.environ.copy()
        env.pop("PYTHONDONTWRITEBYTECODE", None)
        env.pop("PYTHONPYCACHEPREFIX", None)
        with tempfile.TemporaryDirectory() as tmp:
            root = build(tmp)
            before = _bytecode_snapshot(HERE)
            proc = subprocess.run(
                [sys.executable, str(HERE / "check_nq_335_local_stage.py"),
                 str(root)],
                cwd=tmp,
                env=env,
                capture_output=True,
                text=True,
                check=False,
            )
            after = _bytecode_snapshot(HERE)
            self.assertEqual(proc.returncode, 0, proc.stdout + proc.stderr)
            self.assertEqual(before, after,
                             "checker wrote or updated bytecode next to tools")
            self.assertFalse(list(root.rglob("__pycache__")))
            self.assertFalse(list(root.rglob("*.pyc")))


if __name__ == "__main__":
    unittest.main(verbosity=2)
