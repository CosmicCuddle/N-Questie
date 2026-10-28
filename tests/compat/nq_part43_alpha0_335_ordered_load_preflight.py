#!/usr/bin/env python3
"""Pinned, read-only Alpha 0 load-order audit. No directories or archives created.

Diagnostic only: this models active TOC and Script/Include file encounter order,
not the WoW 3.3.5a XML engine, Lua runtime or arbitrary asset references.
"""
import os
import posixpath
import re
import subprocess

PIN = "8b23c6e2cfa00bb81cb26d40c44fef154e9e0070"
assert os.environ.get("NQ_ALPHA0_SOURCE_SHA") == PIN, "ALPHA0_PIN_REQUIRED"

def git(*args):
    return subprocess.check_output(
        ["git", *args], stderr=subprocess.STDOUT, timeout=45
    ).decode("utf-8")

assert git("rev-parse", "--verify", PIN).strip() == PIN, "ALPHA0_SOURCE_PIN_MISSING"
paths = set(git("ls-tree", "-r", "--name-only", PIN).splitlines())

def exact(path, known=paths):
    if path not in known:
        if any(p.lower() == path.lower() for p in known):
            raise AssertionError("ALPHA0_PATH_CASE_MISMATCH:" + path)
        raise AssertionError("ALPHA0_MISSING_SOURCE:" + path)
    return path

def source(path):
    return git("show", PIN + ":" + exact(path))

def metadata_and_toc(body):
    metadata = {}
    ordered = []
    for line in body.splitlines():
        s = line.strip()
        if s.startswith("## ") and ":" in s:
            name, value = s[3:].split(":", 1)
            metadata[name] = value.strip()
        elif s and not s.startswith("#"):
            ordered.append(s.replace("\\", "/"))
    return metadata, ordered

def refs(xml, owner):
    # LIMITED scope: active XML Script/Include tags with a file attribute.
    clean = re.sub(r"<!--.*?-->", "", xml, flags=re.S)
    result = []
    for kind, attrs in re.findall(
        r"<\s*(Script|Include)\b([^<>]*?)>", clean, flags=re.I | re.S
    ):
        attr = re.search(r"\bfile\s*=\s*([\"'])(.*?)\1", attrs, flags=re.I | re.S)
        if not attr:
            continue  # e.g. an inline Script tag
        value = attr.group(2).replace("\\", "/")
        if not value or value.startswith("/") or ":" in value:
            raise AssertionError("ALPHA0_EXTERNAL_XML_PATH:" + value)
        normalized = posixpath.normpath(posixpath.join(
            posixpath.dirname(owner), value
        ))
        if normalized in ("", ".", "..") or normalized.startswith("../"):
            raise AssertionError("ALPHA0_XML_ROOT_ESCAPE:" + value)
        result.append(normalized)
    return result

def encounter(ordered_toc, load_xml, known=paths):
    # Repeated references remain repeated, rather than being silently de-duplicated.
    # Only nested XML cycles are rejected; this is a diagnostic expansion.
    ordered = []
    edges = []
    visited_xml = set()
    def visit(path, stack):
        exact(path, known)
        ordered.append(path)
        if not path.lower().endswith(".xml"):
            return
        if path in stack:
            raise AssertionError("ALPHA0_XML_INCLUDE_CYCLE:" + path)
        visited_xml.add(path)
        for child in refs(load_xml(path), path):
            edges.append((path, child))
            visit(child, stack + (path,))
    for item in ordered_toc:
        visit(item, ())
    return ordered, edges, visited_xml

counter = 0
def check(condition, label):
    global counter
    assert condition, label
    counter += 1

metadata, toc = metadata_and_toc(source("Questie-335.toc"))
check(PIN == git("rev-parse", PIN).strip(), "O01_EXACT_SOURCE_PIN")
check(metadata.get("Interface") == "30300", "O02_WRATH_INTERFACE")
check(metadata.get("SavedVariables") == "QuestieConfig"
      and metadata.get("SavedVariablesPerCharacter") == "QuestieConfigCharacter",
      "O03_BACKUP_IDENTIFIERS")
check(len(toc) >= 130 and len(toc) == len(set(toc)), "O04_TOC_ORDER_UNIQUE")
check(all(p in paths for p in toc), "O05_EXACT_SOURCE_CASE")
check(all(p.lower().endswith((".lua", ".xml")) for p in toc),
      "O06_TOC_LOADABLE_SUFFIXES")
xml_roots = [p for p in toc if p.lower().endswith(".xml")]
check(len(xml_roots) == 6, "O07_SIX_335_XML_ROOTS")
check(toc.index("Modules/Libs/QuestieLoader.lua") <
      toc.index("Modules/QuestieStream.lua") <
      toc.index("Database/compiler.lua") <
      toc.index("Modules/QuestieInit.lua") <
      toc.index("Questie.lua"), "O08_ORIGINAL_TOC_ANCHOR_ORDER")
check(toc.index("Compat/embeds.xml") <
      toc.index("Compat/NQuestieCustomQuestData.lua"),
      "O09_COMPAT_BEFORE_CUSTOM_DATA")
expanded, edges, xml_nodes = encounter(toc, source)
check(all(p in expanded for p in toc) and
      [p for p in expanded if p in toc][:1] == [toc[0]],
      "O10_ROOT_TOC_ENCOUNTER_ORDER")
check(len(edges) >= 70 and len(xml_nodes) >= 8,
      "O11_REAL_NESTED_XML_COVERAGE")
check(set(xml_roots).issubset(xml_nodes), "O12_ALL_XML_ROOTS_VISITED")
check(len(set(expanded) - set(toc)) >= 40,
      "O13_NESTED_DEPENDENCIES_INCLUDED")
check(all(p in paths for p in expanded), "O14_ALL_EXPANDED_FILES_EXACT")
check(all(expanded.index(p) < expanded.index(q) for p, q in [
    ("Compat/embeds.xml", "Compat/NQuestieCustomQuestData.lua"),
    ("Modules/QuestieStream.lua", "Database/compiler.lua"),
    ("Database/compiler.lua", "Questie.lua")]),
    "O15_EXPANSION_PRESERVES_TOC_ANCHORS")
selection = {"Questie-335.toc"} | set(expanded)  # IN MEMORY; never a folder.
check(selection.issubset(paths) and set(toc).issubset(selection),
      "O16_MINIMAL_FILENAME_SELECTION")
check(not any(p.startswith(("tests/", "docs/", ".github/", "releases/", "dist/"))
              for p in selection),
      "O17_NO_NONADDON_FILENAME_REFERENCES")
check("Questie-335.toc" in selection and
      "Questie-WOTLKC.toc" not in selection and
      "Compat/embeds.xml" in selection,
      "O18_CORRECT_335_TOC_AND_COMPAT_ONLY")
# Adversarial controls: synthetic mutations NEVER edit actual repository files.
wrong_case = "modules/Libs/QuestieLoader.lua"
try:
    exact(wrong_case)
except AssertionError as e:
    case_denied = str(e).startswith("ALPHA0_PATH_CASE_MISMATCH:")
else:
    case_denied = False
check(case_denied, "O19_CASE_ONLY_MUTATION_FAILS")
try:
    encounter(["Missing_Alpha0_Probe.lua"], lambda _: "")
except AssertionError as e:
    missing_denied = str(e).startswith("ALPHA0_MISSING_SOURCE:")
else:
    missing_denied = False
check(missing_denied, "O20_MISSING_DEPENDENCY_FAILS")
synthetic = '<!-- <Script file="Ghost.lua"/> -->' + (
    '<Include optional="x" file="Child.xml"/>'
    '<Script file=\'Child.lua\'/>'
)
check(refs(synthetic, "Compat/embeds.xml") ==
      ["Compat/Child.xml", "Compat/Child.lua"],
      "O21_COMMENT_AND_ATTRIBUTE_LEXING")
dupe = '<Script file="Twice.lua"/><Script file="Twice.lua"/>'
check(refs(dupe, "Compat/embeds.xml") ==
      ["Compat/Twice.lua", "Compat/Twice.lua"],
      "O22_DUPLICATE_REFERENCE_NOT_SILENTLY_LOST")
fake = {"Probe.xml", "Twice.lua"}
mock = {"Probe.xml": dupe}
walked, fake_edges, _ = encounter(
    ["Probe.xml"], lambda p: mock[p], fake
)
check(walked == ["Probe.xml", "Twice.lua", "Twice.lua"] and
      len(fake_edges) == 2, "O23_DUPLICATE_LOAD_ORDER_PRESERVED")
try:
    encounter(["Probe.xml"],
              lambda _: '<Include file="Probe.xml"/>', {"Probe.xml"})
except AssertionError as e:
    cycle_denied = str(e).startswith("ALPHA0_XML_INCLUDE_CYCLE:")
else:
    cycle_denied = False
check(cycle_denied, "O24_INCLUDE_CYCLE_FAILS")
for invalid in ("../../Escape.lua", "/Absolute.lua", "C:/Outside.lua"):
    try:
        refs('<Script file="' + invalid + '"/>', "Compat/embeds.xml")
    except AssertionError:
        continue
    raise AssertionError("O25_ROOT_ESCAPE_ACCEPTED:" + invalid)
check(True, "O25_EXTERNAL_AND_ESCAPE_PATHS_DENIED")
swapped = list(toc)
a, b = swapped.index("Database/compiler.lua"), swapped.index("Modules/QuestieStream.lua")
swapped[a], swapped[b] = swapped[b], swapped[a]
check(not (swapped.index("Modules/QuestieStream.lua") <
           swapped.index("Database/compiler.lua")),
      "O26_WRONG_TOC_ORDER_MUTANT_DETECTED")
again, again_edges, again_xml = encounter(toc, source)
check(expanded == again and edges == again_edges and xml_nodes == again_xml,
      "O27_ORDERED_EXPANSION_DETERMINISTIC")
check(all(p == exact(p) for p in selection), "O28_SELECTED_PATHS_CASE_EXACT")
assert counter == 28, "ALPHA0_ORDERED_CENSUS_CHANGED"
print("PUBLIC ALPHA0 PART43 ORDERED 335 LOAD PREFLIGHT: 28/28 PASS")
print("PUBLIC ALPHA0 PLAN: in-memory TOC-ordered active XML traversal; exact-case paths, duplicates, cycle and order mutants checked; NO package.")
print("PUBLIC ALPHA0 NOT ACCEPTED: XML runtime semantics, native 3.3.5a/IP play, SavedVariables, G08, ZIP/build/install/merge/release.")
