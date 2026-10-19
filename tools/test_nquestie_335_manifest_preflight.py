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
from unittest import mock


XML_COMMENTS = re.compile(r"<!--.*?-->", re.DOTALL)
# A quote-aware token boundary: a > inside a quoted attribute is not the tag end.
# Only an exact attribute name "file" may supply the target; never data-file,
# file-looking text inside another value, or an unquoted/malformed attribute.
LOAD_START = re.compile(r"<\s*(?:Script|Include)\b", re.I)
# Reject prefixed loader elements instead of overlooking a possible include.
PREFIXED_LOAD_START = re.compile(
    r"<\s*[^\s<>/!?=\"']+:(?:Script|Include)\b", re.I)
LOAD_TAG = re.compile(
    r"""<\s*(?:Script|Include)\b((?:[^>"']|"[^"]*"|'[^']*')*)>""",
    re.I | re.DOTALL)
ATTRIBUTE = re.compile(
    r"""[ \t\r\n]*([A-Za-z_][\w.:-]*)[ \t\r\n]*=[ \t\r\n]*(?:"([^"]*)"|'([^']*)')""",
    re.DOTALL)


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
    # Check each component using the directory's actual spelling, not
    # Path.is_file() alone. Case-insensitive filesystems can otherwise
    # silently accept a source path that fails on Linux/WoW deployments.
    cursor = root
    for component in relative.parts:
        try:
            actual_names = {entry.name for entry in cursor.iterdir()}
        except OSError as exc:
            raise ValueError("Missing or wrong-case referenced file: " +
                             relative.as_posix()) from exc
        if component not in actual_names:
            raise ValueError("Missing or wrong-case referenced file: " +
                             relative.as_posix())
        cursor = cursor / component
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
    # TOC name must be spelled exactly even on case-insensitive hosts.
    try:
        top_level_names = {entry.name for entry in root.iterdir()}
    except OSError as exc:
        raise ValueError("Cannot inspect staged addon root") from exc
    if "Questie-335.toc" not in top_level_names:
        raise ValueError("Required Questie-335.toc has wrong-case spelling")
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
        # This preflight deliberately does not expand XML entities or DTDs.
        # Fail closed rather than allow parser/runtime interpretation to differ.
        if re.search(r"<!\s*(?:DOCTYPE|ENTITY)\b", xml, re.I):
            raise ValueError("Unsupported XML DTD/entity declaration")
        if PREFIXED_LOAD_START.search(xml):
            raise ValueError("Unsupported prefixed XML Script/Include tag")
        load_tags = list(LOAD_TAG.finditer(xml))
        if len(load_tags) != len(LOAD_START.findall(xml)):
            raise ValueError("Malformed XML Script/Include tag")
        for match in load_tags:
            attributes = match.group(1).strip(" \t\r\n")
            if attributes.endswith("/"):
                attributes = attributes[:-1].rstrip(" \t\r\n")
            position = 0
            file_attrs = []
            while position < len(attributes):
                if position and attributes[position] not in " \t\r\n":
                    raise ValueError("XML attributes require separating whitespace")
                attribute = ATTRIBUTE.match(attributes, position)
                if attribute is None:
                    raise ValueError("Malformed XML Script/Include attribute")
                if attribute.group(1).lower() == "file":
                    value = (attribute.group(2) if attribute.group(2) is not None
                             else attribute.group(3))
                    file_attrs.append(value)
                position = attribute.end()
            if len(file_attrs) != 1:
                raise ValueError("XML Script/Include without one file attribute")
            target = _checked_path(root, root / path, file_attrs[0])
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

    def test_exact_case_refusal_when_is_file_claims_wrong_case_exists(self):
        # Simulate case-insensitive is_file() while preserving actual
        # directory entries. Without component-level spelling checks, every
        # wrong-case reference below would be incorrectly accepted.
        with tempfile.TemporaryDirectory() as temp:
            root = synthetic_package(temp)
            examples = (
                (root / "Questie-335.toc", "modules/Entry.lua",
                 root / "modules/Entry.lua"),
                (root / "Questie-335.toc", "Modules/entry.lua",
                 root / "Modules/entry.lua"),
                (root / "Compat/embeds.xml", "Libs/Inner.xml",
                 root / "Compat/Libs/Inner.xml"),
            )
            fake_targets = {target for _, _, target in examples}
            original_is_file = Path.is_file

            def simulated_case_insensitive_is_file(candidate):
                if candidate in fake_targets:
                    return True
                return original_is_file(candidate)

            with mock.patch.object(Path, "is_file",
                                   simulated_case_insensitive_is_file):
                for parent, supplied, _ in examples:
                    with self.subTest(supplied=supplied):
                        with self.assertRaisesRegex(
                                ValueError, "Missing or wrong-case"):
                            _checked_path(root, parent, supplied)
                self.assertEqual(
                    _checked_path(root, root / "Questie-335.toc",
                                  "Modules/Entry.lua"),
                    "Modules/Entry.lua")

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

    def test_wrong_case_intermediate_dir_refused_with_case_insensitive_listing(self):
        # Reproduce BOTH case-insensitive file lookup and directory listings.
        # A leaf-only filename check would wrongly accept "modules/Entry.lua".
        with tempfile.TemporaryDirectory() as temp:
            root = synthetic_package(temp)
            alias = {root / "modules": root / "Modules"}
            original_is_file = Path.is_file
            original_iterdir = Path.iterdir

            def simulated_is_file(candidate):
                if candidate == root / "modules/Entry.lua":
                    return True
                return original_is_file(candidate)

            def simulated_iterdir(candidate):
                return original_iterdir(alias.get(candidate, candidate))

            with mock.patch.object(Path, "is_file", simulated_is_file), \
                    mock.patch.object(Path, "iterdir", simulated_iterdir):
                with self.assertRaisesRegex(ValueError, "Missing or wrong-case"):
                    _checked_path(
                        root, root / "Questie-335.toc", "modules/Entry.lua")

    def test_windows_drive_and_unc_paths_refused_in_toc_and_xml(self):
        # Two distinct Windows-style escape attempts. These must be refused
        # by the drive/UNC guard, not merely because a file is missing.
        references = (
            r"C:\untrusted\module.lua",
            r"\\server\share\module.lua",
        )
        with tempfile.TemporaryDirectory() as temp:
            root = synthetic_package(temp)
            for reference in references:
                with self.subTest(source="toc", reference=reference):
                    (root / "Questie-335.toc").write_text(
                        "## Interface: 30300\n" + reference + "\n",
                        encoding="utf-8")
                    with self.assertRaisesRegex(
                            ValueError, "Unsafe absolute/drive"):
                        check_manifest(root)
                synthetic_package(temp)
                with self.subTest(source="xml", reference=reference):
                    (root / "Compat/Libs/inner.xml").write_text(
                        '<Ui><Script file="' + reference + '"/></Ui>\n',
                        encoding="utf-8")
                    with self.assertRaisesRegex(
                            ValueError, "Unsafe absolute/drive"):
                        check_manifest(root)
                synthetic_package(temp)

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

    def test_toc_name_case_refused_when_is_file_is_case_insensitive(self):
        with tempfile.TemporaryDirectory() as temp:
            root = synthetic_package(temp)
            correct_toc = root / "Questie-335.toc"
            wrong_toc = root / "questie-335.toc"
            correct_toc.rename(wrong_toc)
            original_is_file = Path.is_file

            def simulated_case_insensitive_is_file(candidate):
                if candidate == correct_toc:
                    return True
                return original_is_file(candidate)

            with mock.patch.object(Path, "is_file",
                                   simulated_case_insensitive_is_file):
                with self.assertRaisesRegex(
                        ValueError, "Required Questie-335.toc.*wrong-case"):
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

    def test_xml_missing_or_duplicate_file_attribute_refused(self):
        examples = (
            '<Ui><Script/></Ui>\n',
            '<Ui><Include/></Ui>\n',
            '<Ui><Script file="../Impl.lua" file="../Impl.lua"/></Ui>\n',
            '<Ui><Include file="../Impl.lua" file="../Impl.lua"/></Ui>\n',
        )
        with tempfile.TemporaryDirectory() as temp:
            root = synthetic_package(temp)
            for contents in examples:
                with self.subTest(xml=contents):
                    (root / "Compat/Libs/inner.xml").write_text(
                        contents, encoding="utf-8")
                    with self.assertRaisesRegex(
                            ValueError, "without one file attribute"):
                        check_manifest(root)

    def test_spoofed_xml_file_attribute_is_not_a_file_reference(self):
        examples = (
            ('<Ui><Script data-file="../Impl.lua"/></Ui>\n',
             "without one file attribute"),
            ('<Ui><Include meta-file="../Impl.lua"/></Ui>\n',
             "without one file attribute"),
            ('<Ui><Script note=\'file="../Impl.lua"\'/></Ui>\n',
             "without one file attribute"),
            ('<Ui><Script file=../Impl.lua/></Ui>\n',
             "Malformed XML Script/Include attribute"),
        )
        with tempfile.TemporaryDirectory() as temp:
            root = synthetic_package(temp)
            for xml, expected in examples:
                with self.subTest(xml=xml):
                    (root / "Compat/Libs/inner.xml").write_text(
                        xml, encoding="utf-8")
                    with self.assertRaisesRegex(ValueError, expected):
                        check_manifest(root)

    def test_quoted_attribute_contents_do_not_create_false_dependencies(self):
        with tempfile.TemporaryDirectory() as temp:
            root = synthetic_package(temp)
            (root / "Compat/Libs/inner.xml").write_text(
                '<Ui><Script note=\'file="../Unreviewed.lua" > ignored\' '
                'file="../Impl.lua"/></Ui>\n',
                encoding="utf-8")
            self.assertEqual(check_manifest(root), {
                "toc_paths": 2, "xml_paths": 3,
                "total_references": 5, "xml_documents": 2,
            })

    def test_prefixed_xml_loader_tags_fail_closed(self):
        # An unsupported namespace prefix must not hide an active dependency.
        with tempfile.TemporaryDirectory() as temp:
            root = synthetic_package(temp)
            target = root / "Compat/Libs/inner.xml"
            for kind in ("Script", "Include"):
                with self.subTest(kind=kind):
                    target.write_text(
                        '<Ui><ui:' + kind + ' file="../Impl.lua"/></Ui>\n',
                        encoding="utf-8")
                    with self.assertRaisesRegex(
                            ValueError, "Unsupported prefixed XML"):
                        check_manifest(root)
            target.write_text(
                '<Ui><!-- <ui:Script file="../Missing.lua"/> -->'
                '<Script file="../Impl.lua"/></Ui>\n',
                encoding="utf-8")
            self.assertEqual(check_manifest(root)["total_references"], 5)

    def test_adjacent_xml_attributes_without_whitespace_refused(self):
        # XML requires whitespace between consecutive attributes.
        with tempfile.TemporaryDirectory() as temp:
            root = synthetic_package(temp)
            target = root / "Compat/Libs/inner.xml"
            valid = '<Ui><Script note="safe" file="../Impl.lua"/></Ui>\n'
            target.write_text(valid, encoding="utf-8")
            self.assertEqual(check_manifest(root)["total_references"], 5)
            for inner in (
                    'note="safe"file="../Impl.lua"',
                    'file="../Impl.lua"note="safe"'):
                with self.subTest(attributes=inner):
                    target.write_text(
                        "<Ui><Script " + inner + "/></Ui>\n",
                        encoding="utf-8")
                    with self.assertRaisesRegex(
                            ValueError, "separating whitespace"):
                        check_manifest(root)


    def test_unusual_prefixed_loader_spellings_are_refused(self):
        # Refuse all active prefixed loaders, not only lowercase "ui".
        # Non-loader prefixed Frame elements remain outside this narrow guard.
        with tempfile.TemporaryDirectory() as temp:
            root = synthetic_package(temp)
            target = root / "Compat/Libs/inner.xml"
            for tag in (
                    "UI:script", "a.b-c:Include", "ü:Script",
                    "a:b:Script", "u·i:Include", " ui:Script"):
                with self.subTest(tag=tag):
                    target.write_text(
                        '<Ui><' + tag + ' file="../Impl.lua"/></Ui>\n',
                        encoding="utf-8")
                    with self.assertRaisesRegex(
                            ValueError, "Unsupported prefixed XML"):
                        check_manifest(root)
            target.write_text(
                '<Ui><ü:Frame/><Script file="../Impl.lua"/></Ui>\n',
                encoding="utf-8")
            self.assertEqual(check_manifest(root)["total_references"], 5)
            target.write_text(
                '<Ui><!-- <ü:Script file="../Missing.lua"/> -->'
                '<Script file="../Impl.lua"/></Ui>\n',
                encoding="utf-8")
            self.assertEqual(check_manifest(root)["total_references"], 5)

    def test_xml_s_whitespace_only_in_loader_attributes(self):
        # XML 1.0 S is only space, TAB, CR, LF. Python \s/isspace
        # also accepts NBSP, VT and EM SPACE, which XML must reject here.
        with tempfile.TemporaryDirectory() as temp:
            root = synthetic_package(temp)
            target = root / "Compat/Libs/inner.xml"
            for separator in (" ", "\t", "\r\n", "\n"):
                with self.subTest(valid_separator=repr(separator)):
                    target.write_text(
                        '<Ui><Script note="safe"' + separator
                        + 'file="../Impl.lua"/></Ui>\n', encoding="utf-8")
                    self.assertEqual(
                        check_manifest(root)["total_references"], 5)
            invalid = (
                'note="safe"\u00a0file="../Impl.lua"',
                'note="safe"\x0bfile="../Impl.lua"',
                'note="safe"\u2003file="../Impl.lua"',
                '\u00a0file="../Impl.lua"',
                'file\u00a0="../Impl.lua"',
                'file="../Impl.lua"\u00a0',
            )
            for attributes in invalid:
                with self.subTest(invalid=repr(attributes)):
                    target.write_text(
                        "<Ui><Script " + attributes + "/></Ui>\n",
                        encoding="utf-8")
                    with self.assertRaisesRegex(
                            ValueError, "Malformed XML Script/Include attribute"
                            "|XML attributes require separating whitespace"):
                        check_manifest(root)

    def test_unterminated_quoted_xml_load_attribute_is_refused(self):
        with tempfile.TemporaryDirectory() as temp:
            root = synthetic_package(temp)
            (root / "Compat/Libs/inner.xml").write_text(
                '<Ui><Script file="../Impl.lua/></Ui>\n',
                encoding="utf-8")
            with self.assertRaisesRegex(
                    ValueError, "Malformed XML Script/Include tag"):
                check_manifest(root)

    def test_xml_dtd_and_entity_declarations_refused(self):
        examples = (
            '<!DOCTYPE Ui><Ui><Script file="../Impl.lua"/></Ui>\n',
            '<!ENTITY external SYSTEM "file:///etc/passwd">'
            '<Ui><Script file="../Impl.lua"/></Ui>\n',
        )
        with tempfile.TemporaryDirectory() as temp:
            root = synthetic_package(temp)
            for contents in examples:
                with self.subTest(xml=contents):
                    (root / "Compat/Libs/inner.xml").write_text(
                        contents, encoding="utf-8")
                    with self.assertRaisesRegex(
                            ValueError, "Unsupported XML DTD/entity"):
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
