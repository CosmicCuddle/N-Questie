#!/usr/bin/env python3
"""Offline synthetic self-test for tools/check_nq_335_local_stage.py.

Uses only invented files in disposable temporary directories; never touches
a WoW install, user data, private/server data or the repository tree.
Deliberately not named test_*.py so pinned CI discovery is unchanged.
Run: python tools/qa_nq_335_local_stage_selftest.py
"""
import sys

sys.dont_write_bytecode = True

import hashlib  # noqa: E402
import importlib.util  # noqa: E402
import os  # noqa: E402
import tempfile  # noqa: E402
import unittest  # noqa: E402
from pathlib import Path  # noqa: E402

HERE = Path(__file__).resolve().parent


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
    "Icons/LICENSE.md": "synthetic notice\n",
    "Libs/LibStub.lua": "-- synthetic\n",
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


class StageCheckerSelfTest(unittest.TestCase):
    def check(self, root):
        lines = []
        before = snapshot(root.parent)
        code = CHECKER.run(str(root), out=lines.append)
        self.assertEqual(before, snapshot(root.parent), "checker mutated tree")
        return code, "\n".join(lines)

    def test_valid_pass_with_case_warning_and_inactive_ignored(self):
        with tempfile.TemporaryDirectory() as tmp:
            code, out = self.check(build(tmp))
            self.assertEqual(code, 0, out)
            self.assertIn("RESULT: PASS", out)
            self.assertIn("Case-only texture mismatch Icons\\\\Checkmark", out)
            self.assertNotIn("absent.blp", out)
            self.assertNotIn("commented_out", out)
            self.assertIn("NOT TESTED", out)

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

    @unittest.skipUnless(hasattr(os, "symlink"), "no symlink support")
    def test_symlink_escape_fails(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = build(tmp)
            outside = Path(tmp) / "outside"
            outside.mkdir()
            try:
                os.symlink(outside, root / "Libs" / "escape")
            except (OSError, NotImplementedError):
                self.skipTest("symlink creation not permitted")
            code, out = self.check(root)
            self.assertEqual(code, 1, out)
            self.assertIn("Link escapes staged folder", out)

    def test_no_bytecode_written_next_to_tools(self):
        self.assertFalse((HERE / "__pycache__").exists())


if __name__ == "__main__":
    unittest.main(verbosity=2)
