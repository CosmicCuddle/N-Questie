#!/usr/bin/env python3
"""Test-only source/package manifest preflight for WoW 3.3.5a N-Questie.

Reads files; NEVER creates a package, writes a report, changes the addon,
runs build.py/release.py, or publishes anything. This is NOT licence clearance.
"""
import os
import re
import tempfile
import unittest
from pathlib import Path


XML_COMMENTS = re.compile(r"<!--.*?-->", re.DOTALL)
LOAD_TAG = re.compile(r"<\s*(?:Script|Include)\b([^>]*)>", re.I | re.DOTALL)
FILE_ATTR = re.compile(r"""\bfile\s*=\s*(["'])(.*?)\1""", re.I | re.DOTALL)


def _checked_path(root, parent, supplied):
    """Resolve WoW slashes exactly and reject escape or missing source paths."""
    if not supplied or supplied[0] in ("/", "\\") or ":" in supplied:
        raise ValueError("Unsafe absolute/drive/empty file reference")
    parent_parts = list(parent.relative_to(root).parts[:-1])
    for part in supplied.replace("\\", "/").split("/"):
        if part in ("", "."):
            if part == "":
                raise ValueError("Empty path component")
            continue
        if part == "..":
            if not parent_parts:
                raise ValueError("Reference escapes addon root")
            parent_parts.pop()
        else:
            parent_parts.append(part)
    relative = Path(*parent_parts)
    if not parent_parts:
        raise ValueError("Reference names no file")
    target = root / relative
    try:
        target.resolve().relative_to(root.resolve())
    except ValueError as exc:
        raise ValueError("Reference escapes addon root (symlink)") from exc
    if not target.is_file():
        raise ValueError("Missing or wrong-case referenced file: " +
                         relative.as_posix())
    return relative.as_posix()


def check_manifest(root, require_staged_name=True):
    """Read one 30300 TOC plus reachable XML. No disk writes or packaging."""
    root = Path(root).resolve()
    if require_staged_name and root.name != "Questie-335":
        raise ValueError("Expected staged folder named Questie-335")
    toc_path = root / "Questie-335.toc"
    if not toc_path.is_file():
        raise ValueError("Required Questie-335.toc is missing")
    try:
        toc_path.resolve().relative_to(root)
    except ValueError as exc:
        raise ValueError("TOC escapes addon root (symlink)") from exc
    raw = toc_path.read_text(encoding="utf-8-sig")
    interfaces = re.findall(r"(?m)^## Interface:\s*(\d+)\s*$", raw)
    if interfaces != ["30300"]:
        raise ValueError("Not an unambiguous WoW 3.3.5a Interface 30300 TOC")
    tocs = [line.strip() for line in raw.splitlines()
            if line.strip() and not line.lstrip().startswith("#")]
    if not tocs:
        raise ValueError("Empty active TOC manifest")

    visited = set()
    processing = set()
    references = []

    def visit_xml(path):
        if path in processing:
            raise ValueError("Cyclic XML Include: " + path)
        if path in visited:
            return
        processing.add(path)
        xml = (root / path).read_text(encoding="utf-8-sig")
        xml = XML_COMMENTS.sub("", xml)
        if "<!--" in xml or "-->" in xml:
            raise ValueError("Unterminated or malformed XML comment")
        for match in LOAD_TAG.finditer(xml):
            file_attrs = FILE_ATTR.findall(match.group(1))
            if len(file_attrs) != 1:
                raise ValueError("XML Script/Include without one file attribute")
            target = _checked_path(root, root / path, file_attrs[0][1])
            references.append(target)
            if target.lower().endswith(".xml"):
                visit_xml(target)
        processing.remove(path)
        visited.add(path)

    for source in tocs:
        target = _checked_path(root, toc_path, source)
        references.append(target)
        if target.lower().endswith(".xml"):
            visit_xml(target)
    return {
        "toc_paths": len(tocs),
        "xml_paths": len(references) - len(tocs),
        "total_references": len(references),
        "xml_documents": len(visited),
    }


def synthetic_package(base):
    """Invented small tree; no proprietary/private or live-world quest files."""
    root = Path(base) / "Questie-335"
    files = {
        "Questie-335.toc":
            "## Interface: 30300\nModules\\Entry.lua\nCompat\\embeds.xml\n",
        "Modules/Entry.lua": "-- synthetic entry\n",
        "Modules/Helper.lua": "-- synthetic helper\n",
        "Compat/Impl.lua": "-- synthetic implementation\n",
        "Compat/embeds.xml":
            '<Ui><Script file="..\\Modules\\Helper.lua"/>'
            '<Include file="Libs\\inner.xml"/>'
            '<!-- <Script file="..\\Libs\\Krowi_WorldMapButtons\\ignored.lua"/> -->'
            '</Ui>\n',
        "Compat/Libs/inner.xml":
            '<Ui><Script file="..\\Impl.lua"/></Ui>\n',
    }
    for name, data in files.items():
        target = root / name
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(data, encoding="utf-8")
    return root


class ManifestPreflightTests(unittest.TestCase):
    def test_synthetic_valid_nested_xml_and_commented_script(self):
        with tempfile.TemporaryDirectory() as temp:
            root = synthetic_package(temp)
            result = check_manifest(root)
            self.assertEqual(result, {
                "toc_paths": 2, "xml_paths": 3,
                "total_references": 5, "xml_documents": 2,
            })
            self.assertFalse((root / "Libs").exists())

    def test_missing_compat_after_legacy_style_copy_is_refused(self):
        with tempfile.TemporaryDirectory() as temp:
            root = synthetic_package(temp)
            (root / "Compat/embeds.xml").unlink()
            with self.assertRaisesRegex(ValueError, "Missing or wrong-case"):
                check_manifest(root)

    def test_retail_wotlk_toc_is_not_a_335_toc(self):
        with tempfile.TemporaryDirectory() as temp:
            root = synthetic_package(temp)
            (root / "Questie-335.toc").unlink()
            (root / "Questie-WOTLKC.toc").write_text(
                "## Interface: 30403\n", encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "Required Questie-335.toc"):
                check_manifest(root)

    def test_wrong_interface_and_wrong_package_folder_refused(self):
        with tempfile.TemporaryDirectory() as temp:
            root = synthetic_package(temp)
            (root / "Questie-335.toc").write_text(
                "## Interface: 30403\nModules\\Entry.lua\n",
                encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "30300"):
                check_manifest(root)
            with self.assertRaisesRegex(ValueError, "folder named Questie-335"):
                check_manifest(Path(temp), require_staged_name=True)

    def test_missing_nested_script_and_exact_case_guard(self):
        with tempfile.TemporaryDirectory() as temp:
            root = synthetic_package(temp)
            (root / "Compat/Impl.lua").unlink()
            with self.assertRaisesRegex(ValueError, "Missing or wrong-case"):
                check_manifest(root)
            synthetic_package(temp)
            (root / "Compat/Libs/inner.xml").rename(
                root / "Compat/Libs/Inner.xml")
            with self.assertRaisesRegex(ValueError, "Missing or wrong-case"):
                check_manifest(root)

    def test_path_traversal_and_absolute_path_refused(self):
        with tempfile.TemporaryDirectory() as temp:
            root = synthetic_package(temp)
            (root / "Compat/Libs/inner.xml").write_text(
                '<Ui><Script file="../../../outside.lua"/></Ui>\n',
                encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "escapes addon root"):
                check_manifest(root)
            (root / "Compat/Libs/inner.xml").write_text(
                '<Ui><Script file="/etc/passwd"/></Ui>\n',
                encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "Unsafe absolute"):
                check_manifest(root)

    def test_recursive_xml_include_cycle_refused(self):
        with tempfile.TemporaryDirectory() as temp:
            root = synthetic_package(temp)
            (root / "Compat/Libs/inner.xml").write_text(
                '<Ui><Include file="../embeds.xml"/></Ui>\n',
                encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "Cyclic XML Include"):
                check_manifest(root)

    def test_symlink_outside_staging_root_refused(self):
        with tempfile.TemporaryDirectory() as temp:
            root = synthetic_package(temp)
            outside = Path(temp) / "external.lua"
            outside.write_text("-- outside staging\n", encoding="utf-8")
            (root / "Modules/Helper.lua").unlink()
            os.symlink(outside, root / "Modules/Helper.lua")
            with self.assertRaisesRegex(ValueError, "symlink"):
                check_manifest(root)

    def test_external_toc_symlink_cannot_supply_managed_manifest(self):
        with tempfile.TemporaryDirectory() as temp:
            root = synthetic_package(temp)
            original = (root / "Questie-335.toc").read_text(encoding="utf-8")
            external = Path(temp) / "untrusted-toc.txt"
            external.write_text(original, encoding="utf-8")
            (root / "Questie-335.toc").unlink()
            os.symlink(external, root / "Questie-335.toc")
            with self.assertRaisesRegex(ValueError, "TOC escapes"):
                check_manifest(root)

    def test_unterminated_xml_comment_cannot_hide_references(self):
        with tempfile.TemporaryDirectory() as temp:
            root = synthetic_package(temp)
            (root / "Compat/embeds.xml").write_text(
                '<Ui><!-- comment was never closed '
                '<Script file="..\\Modules\\Helper.lua"/></Ui>\\n',
                encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "XML comment"):
                check_manifest(root)

    def test_real_public_335_source_references_without_writes(self):
        # This source graph is publicly tracked; it is NOT a staged ZIP and
        # contains no offline world SQL, private report or SavedVariables.
        root = Path(__file__).resolve().parents[1]
        before = (root / "Questie-335.toc").read_bytes()
        result = check_manifest(root, require_staged_name=False)
        self.assertEqual(result, {
            "toc_paths": 143,
            "xml_paths": 149,
            "total_references": 292,
            "xml_documents": 21,
        })
        self.assertEqual((root / "Questie-335.toc").read_bytes(), before)


if __name__ == "__main__":
    unittest.main()
