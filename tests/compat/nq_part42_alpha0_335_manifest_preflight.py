#!/usr/bin/env python3
"""Read-only, pinned N-Questie Alpha 0 manifest check. Never make a ZIP."""
import ast
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

assert git("rev-parse", PIN).strip() == PIN, "ALPHA0_MISSING_PINNED_COMMIT"
files = set(git("ls-tree", "-r", "--name-only", PIN).splitlines())

def original_file(path):
    assert path in files, "ALPHA0_MISSING_SOURCE_FILE:" + path
    return git("show", PIN + ":" + path)

def assignments(code):
    values = {}
    for node in ast.parse(code).body:
        if isinstance(node, ast.Assign):
            for target in node.targets:
                if isinstance(target, ast.Name) and target.id in (
                    "addonDir", "directoriesToInclude", "filesToInclude", "tocs"
                ):
                    values[target.id] = ast.literal_eval(node.value)
    return values

toc = original_file("Questie-335.toc")
builder = original_file("build.py")
readme = original_file("README.md")
legacy = assignments(builder)
metadata = {}
manifest = []
for raw in toc.splitlines():
    stripped = raw.strip()
    if stripped.startswith("## ") and ":" in stripped:
        key, value = stripped[3:].split(":", 1)
        metadata[key] = value.strip()
    elif stripped and not stripped.startswith("#"):
        manifest.append(stripped.replace("\\", "/"))

def includes(xml_text, owner):
    # Scope: active Script/Include file references. No full XML parser claim.
    clean = re.sub(r"<!--.*?-->", "", xml_text, flags=re.S)
    found = re.findall(
        r"<(?:Script|Include)\s+[^>]*?\bfile\s*=\s*[\"']([^\"']+)[\"']",
        clean, flags=re.I | re.S
    )
    resolved = []
    for relative in found:
        if relative.startswith("/") or ":" in relative:
            raise AssertionError("ALPHA0_EXTERNAL_XML_REFERENCE:" + relative)
        path = posixpath.normpath(posixpath.join(
            posixpath.dirname(owner), relative.replace("\\", "/")
        ))
        if path.startswith("../") or path == "..":
            raise AssertionError("ALPHA0_XML_ESCAPES_ADDON_ROOT:" + relative)
        resolved.append(path)
    return resolved

counter = 0
def check(condition, label):
    global counter
    assert condition, label
    counter += 1

check(git("rev-parse", "--verify", PIN).strip() == PIN,
      "A01_SOURCE_PIN")
check(len(files) > 700 and "Database/compiler.lua" in files,
      "A02_EXPECTED_SOURCE_TREE")
check("Questie-335.toc" in files and "Questie-WOTLKC.toc" in files,
      "A03_335_AND_UPSTREAM_TOC_EXIST")
check(metadata.get("Interface") == "30300", "A04_335_CLIENT_INTERFACE")
check("N-Questie" in metadata.get("Title", ""), "A05_FORK_IDENTITY")
check(metadata.get("SavedVariables") == "QuestieConfig"
      and metadata.get("SavedVariablesPerCharacter") ==
      "QuestieConfigCharacter", "A06_SAVEDVARIABLES_BACKUP_TARGETS")
check(len(manifest) >= 130 and len(manifest) == len(set(manifest)),
      "A07_UNIQUE_SUBSTANTIAL_335_MANIFEST")
check(all(p in files for p in manifest), "A08_335_TOC_ENTRIES_EXIST_EXACT")
compat = [p for p in manifest if p.startswith("Compat/")]
check(len(compat) >= 7 and "Compat/embeds.xml" in compat,
      "A09_335_TOC_REQUIRES_COMPAT_TREE")
check("Compat/embeds.xml" in files and
      len([p for p in files if p.startswith("Compat/")]) > 20,
      "A10_COMPAT_SOURCE_DEPENDENCIES_TRACKED")
xml_deps = includes(original_file("Compat/embeds.xml"),
                    "Compat/embeds.xml")
check(len(xml_deps) >= 15, "A11_COMPAT_XML_HAS_ACTIVE_INCLUDES")
check(all(p in files for p in xml_deps),
      "A12_COMPAT_XML_REFERENCES_EXIST")
check("Interface/AddOns/Questie-335/" in readme,
      "A13_DOCUMENTED_INSTALL_FOLDER")
check(legacy["addonDir"] == "Questie",
      "A14_LEGACY_FOLDER_MISMATCH")
check("Compat" not in legacy["directoriesToInclude"],
      "A15_LEGACY_COMPAT_OMISSION")
check("Questie-335.toc" not in legacy["filesToInclude"] and
      legacy["tocs"][3] == "Questie-WOTLKC.toc",
      "A16_LEGACY_WRATH_TOC_MISMATCH")
check("'--wotlk'" in builder and "--release" in builder,
      "A17_LEGACY_RELEASE_SWITCH_EXISTS")

legacy_root = set(legacy["filesToInclude"]) | {legacy["tocs"][3]}
legacy_dirs = set(legacy["directoriesToInclude"])
legacy_plan = {p for p in files if p in legacy_root or
               p.split("/", 1)[0] in legacy_dirs}
missing_from_legacy = set(manifest) - legacy_plan
check("Questie-335.toc" not in legacy_plan and
      "Compat/embeds.xml" in missing_from_legacy,
      "A18_LEGACY_PLAN_KNOWN_UNSAFE")
check(set(compat).issubset(missing_from_legacy),
      "A19_LEGACY_OMITS_335_COMPAT_MANIFEST")
# A filename-selection model only. NO file copying, packaging or ZIP.
hypothetical = set(legacy_plan) | {"Questie-335.toc"}
hypothetical.update(p for p in files if p.startswith("Compat/"))
check(set(manifest).issubset(hypothetical),
      "A20_MODEL_COVERS_ALL_335_TOC_ENTRIES")
check(set(xml_deps).issubset(hypothetical),
      "A21_MODEL_COVERS_COMPAT_XML_REFERENCES")
check(not any(p.startswith(("tests/", "docs/", ".github/", "releases/"))
              for p in hypothetical),
      "A22_MODEL_EXCLUDES_TEST_DOC_RELEASE_FILES")
check("Questie-335.toc" in hypothetical and
      legacy["addonDir"] != "Questie-335",
      "A23_MODEL_REQUIRES_CORRECT_FOLDER")
check(not set(manifest).issubset(hypothetical - {"Compat/embeds.xml"}),
      "A24_OMITTED_COMPAT_XML_DETECTED")
check("Questie-335.toc" not in hypothetical - {"Questie-335.toc"},
      "A25_MISSING_335_TOC_DETECTED")
check("Questie-335-Classic.toc" in files and
      "Questie-335-TBC.toc" in files,
      "A26_OTHER_335_EXPANSION_VARIANTS_EXIST")
check("release.py" in files and "build.py" in files,
      "A27_ORIGINAL_BUILDER_UNCHANGED")
assert counter == 27, "ALPHA0_PREFLIGHT_CENSUS_CHANGED"
print("PUBLIC ALPHA0 335 MANIFEST PREFLIGHT: 27/27 PASS")
print("PUBLIC ALPHA0 KNOWN BLOCKERS: original build.py targets Questie folder and upstream Wrath TOC and omits required Compat tree; no installable build generated.")
print("PUBLIC ALPHA0 NOT ACCEPTED: package generation, approval to distribute/install, live WoW 3.3.5a startup, SavedVariables backup/relog, G08, or release.")
