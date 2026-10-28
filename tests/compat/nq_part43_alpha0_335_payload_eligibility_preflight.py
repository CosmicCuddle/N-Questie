#!/usr/bin/env python3
"""Read-only, source-pinned 335 Alpha0 potential runtime-file eligibility audit.

No file lists written, no directories created, no addon files copied, no archives.
The candidate is an IN-MEMORY static comparison, not a shipping manifest.
"""
import ast
import hashlib
import os
import posixpath
import re
import subprocess

PIN = "8b23c6e2cfa00bb81cb26d40c44fef154e9e0070"
assert os.environ.get("NQ_ALPHA0_SOURCE_SHA") == PIN, "ALPHA0_PIN_REQUIRED"

def git(*args):
    return subprocess.check_output(
        ["git", *args], stderr=subprocess.STDOUT, timeout=45
    )

assert git("rev-parse", "--verify", PIN).decode().strip() == PIN
raw = git("ls-tree", "-r", "-z", "--full-tree", PIN)
tree = {}
for record in raw.split(b"\x00"):
    if not record:
        continue
    left, path = record.split(b"\t", 1)
    mode, kind, oid = left.decode("ascii").split(" ")
    name = path.decode("utf-8")
    assert name not in tree, "ALPHA0_DUPLICATE_GIT_PATH:" + name
    tree[name] = (mode, kind, oid)

def original(path):
    assert path in tree, "ALPHA0_SOURCE_NOT_IN_GIT:" + path
    assert tree[path][1] == "blob", "ALPHA0_NOT_BLOB:" + path
    return git("show", PIN + ":" + path).decode("utf-8")

def parse_toc(body):
    meta, ordered = {}, []
    for raw_line in body.splitlines():
        line = raw_line.strip()
        if line.startswith("## ") and ":" in line:
            key, value = line[3:].split(":", 1)
            meta[key] = value.strip()
        elif line and not line.startswith("#"):
            ordered.append(line.replace("\\", "/"))
    return meta, ordered

def resolve_ref(owner, child):
    rel = child.replace("\\", "/")
    assert rel and not rel.startswith("/") and ":" not in rel, (
        "ALPHA0_XML_EXTERNAL_PATH:" + child
    )
    resolved = posixpath.normpath(posixpath.join(posixpath.dirname(owner), rel))
    assert resolved not in (".", "..") and not resolved.startswith("../"), (
        "ALPHA0_XML_ESCAPE:" + child
    )
    return resolved

def xml_refs(body, owner):
    # Lexical reference audit only. Not a Warcraft XML parser.
    clean = re.sub(r"<!--.*?-->", "", body, flags=re.S)
    for tag, attrs in re.findall(
        r"<\s*(Script|Include)\b([^<>]*?)>", clean, flags=re.I | re.S
    ):
        match = re.search(r"\bfile\s*=\s*([\"'])(.*?)\1", attrs, flags=re.I | re.S)
        if match:
            yield resolve_ref(owner, match.group(2))

def closure(ordered, reader):
    deps = set(ordered)
    edges = []
    visited = set()
    pending = [p for p in ordered if p.lower().endswith(".xml")]
    while pending:
        owner = pending.pop()
        if owner in visited:
            continue
        visited.add(owner)
        for child in xml_refs(reader(owner), owner):
            edges.append((owner, child))
            deps.add(child)
            if child.lower().endswith(".xml"):
                pending.append(child)
    return deps, edges, visited

RUNTIME_DIRS = ("Compat", "Database", "Icons", "Libs", "Localization", "Modules")
# Deliberately omit extractor CSVs and non-runtime source docs. This is only
# a candidate eligibility model; final licensing and asset completeness are open.
ELIGIBLE_EXTS = frozenset({
    ".lua", ".xml", ".toc", ".blp", ".tga", ".png", ".jpg",
    ".jpeg", ".ttf", ".otf", ".wav", ".ogg", ".mp3"
})
def runtime_eligible(path):
    parts = path.split("/")
    if len(parts) < 2 or parts[0] not in RUNTIME_DIRS:
        return False
    if any(part.startswith(".") for part in parts):
        return False
    suffix = posixpath.splitext(path)[1].lower()
    return suffix in ELIGIBLE_EXTS

selection = {"Questie-335.toc", "Questie.lua"}
selection.update(
    p for p, (mode, kind, oid) in tree.items()
    if kind == "blob" and runtime_eligible(p)
)
metadata, toc = parse_toc(original("Questie-335.toc"))
xml_roots = [p for p in toc if p.lower().endswith(".xml")]
deps, edges, visited_xml = closure(toc, original)
source_builder = original("build.py")
builder_vars = {}
for stmt in ast.parse(source_builder).body:
    if isinstance(stmt, ast.Assign):
        for target in stmt.targets:
            if isinstance(target, ast.Name) and target.id in (
                "addonDir", "directoriesToInclude", "filesToInclude", "tocs"
            ):
                builder_vars[target.id] = ast.literal_eval(stmt.value)

counter = 0
def check(ok, label):
    global counter
    assert ok, label
    counter += 1

check(git("rev-parse", PIN).decode().strip() == PIN,
      "P01_IMMUTABLE_SOURCE_PIN")
check(len(tree) >= 900 and "Database/compiler.lua" in tree,
      "P02_NONTRIVIAL_SOURCE_TREE")
check(len(selection) == 546, "P03_PINNED_IN_MEMORY_ELIGIBILITY_CENSUS")
check(selection == {"Questie-335.toc", "Questie.lua"} |
      {p for p in tree if tree[p][1] == "blob" and runtime_eligible(p)},
      "P04_NO_IMPLICIT_FILES")
check(all(p in tree for p in selection), "P05_ALL_SELECTED_PATHS_EXIST")
check(all(tree[p][1] == "blob" and tree[p][0] in ("100644", "100755")
          for p in selection), "P06_NO_SUBMODULES_OR_SYMLINKS")
check(len({p.lower() for p in selection}) == len(selection),
      "P07_NO_CASE_INSENSITIVE_COLLISIONS")
check(all(p in {"Questie-335.toc", "Questie.lua"} or runtime_eligible(p)
          for p in selection), "P08_ALLOWLIST_ONLY")
check(not any(p.startswith(("tests/", "docs/", ".github/", "tools/",
                            "cli/", ".types/", ".vscode/", ".dockerfiles/",
                            "ExternalScripts(DONOTINCLUDEINRELEASE)/",
                            "releases/", "dist/")) for p in selection),
      "P09_NO_PROJECT_TOOLING_PAYLOAD")
check(not any(p.lower().endswith((".csv", ".sql", ".db", ".sqlite",
                                   ".zip", ".py", ".md", ".textile"))
              for p in selection), "P10_NO_EXTRACTOR_OR_BUILD_ASSETS")
check(not any(p.startswith(".") or "/." in p for p in selection),
      "P11_NO_HIDDEN_FILES")
check("Questie-335.toc" in selection and "Questie-WOTLKC.toc" not in selection,
      "P12_CORRECT_335_ONLY_ROOT_TOC")
check(metadata.get("Interface") == "30300", "P13_WRATH_INTERFACE")
check(metadata.get("SavedVariables") == "QuestieConfig" and
      metadata.get("SavedVariablesPerCharacter") == "QuestieConfigCharacter",
      "P14_BACKUP_IDENTIFIER_CONTRACT")
check(len(toc) >= 130 and len(toc) == len(set(toc)),
      "P15_SUBSTANTIAL_UNIQUE_TOC")
check(len(xml_roots) == 6, "P16_ALL_335_XML_ROOTS")
check(len(visited_xml) >= 8 and len(edges) >= 70,
      "P17_NONTRIVIAL_XML_RECURSION")
check(set(xml_roots).issubset(visited_xml), "P18_XML_ROOT_COVERAGE")
check(deps.issubset(selection), "P19_NO_REFERENCED_PAYLOAD_OMISSIONS")
check(len(deps - set(toc)) >= 40, "P20_REAL_NESTED_DEPENDENCIES")
check("Compat/embeds.xml" in deps and
      "Modules/QuestieStream.lua" in deps and
      "Database/compiler.lua" in deps,
      "P21_335_CORE_CHAIN_COVERED")
check(any(p.startswith("Icons/") for p in selection) and
      any(p.startswith("Libs/") for p in selection) and
      all(any(p.startswith(d + "/") for p in selection) for d in RUNTIME_DIRS),
      "P22_ICONS_LIBS_AND_COMPAT_SELECTED")
check("Compat/ExtractMapData/UiMap.csv" in tree and
      "Compat/ExtractMapData/UiMap.csv" not in selection,
      "P23_TOOLING_CSV_EXCLUDED")
check("ExternalScripts(DONOTINCLUDEINRELEASE)" in
      {p.split("/")[0] for p in tree} and
      not any(p.startswith("ExternalScripts(DONOTINCLUDEINRELEASE)/")
              for p in selection), "P24_EXTERNAL_SCRIPTS_EXCLUDED")
check(builder_vars.get("addonDir") == "Questie" and
      builder_vars.get("tocs", [None]*4)[3] == "Questie-WOTLKC.toc" and
      "Compat" not in builder_vars.get("directoriesToInclude", []),
      "P25_LEGACY_BUILDER_STILL_UNSAFE")
check(not deps.issubset(selection - {"Compat/embeds.xml"}),
      "P26_MISSING_REQUIRED_COMPAT_IS_DETECTED")
fake_paths = {"Questie-335.toc", "Questie.lua", "Compat/embeds.xml"}
check(not deps.issubset(fake_paths), "P27_TRUNCATED_MODEL_FAILS_CLOSURE")
check(not runtime_eligible("docs/research/Private.sql") and
      not runtime_eligible("Compat/ExtractMapData/UiMap.csv") and
      not runtime_eligible("tools/arbitrary.py"),
      "P28_DENYLIST_NEGATIVE_MUTANTS")
try:
    resolve_ref("Compat/embeds.xml", "../../Outside.lua")
except AssertionError:
    escape_denied = True
else:
    escape_denied = False
check(escape_denied, "P29_PATH_ROOT_ESCAPE_DENIED")
check(list(xml_refs('<!-- <Script file="Bad.lua"/> --><Script file="Good.lua"/>',
                    "Compat/embeds.xml")) == ["Compat/Good.lua"],
      "P30_XML_COMMENT_DELETION")
# Name + original Git blob identity fingerprint: not a materialized manifest.
def fingerprint(items):
    canonical = "\n".join(
        "\t".join((p,) + tree[p]) for p in sorted(items)
    )
    return hashlib.sha256(canonical.encode("utf-8")).hexdigest()
one = fingerprint(selection)
check(len(one) == 64 and one == fingerprint(set(reversed(sorted(selection)))),
      "P31_DETERMINISTIC_IN_MEMORY_GIT_OID_FINGERPRINT")
check(all(p in tree and tree[p][0] != "160000" for p in selection),
      "P32_GITLINKS_NOT_ELIGIBLE")
assert counter == 32, "ALPHA0_PAYLOAD_AUDIT_CENSUS_CHANGED"
print("PUBLIC ALPHA0 PART43 PAYLOAD ELIGIBILITY PREFLIGHT: 32/32 PASS")
print("PUBLIC ALPHA0 PAYLOAD MODEL: 546 pinned file references in memory; all TOC/XML closure, strict runtime allowlist, no private/tooling/source-doc directories; NO build.")
print("PUBLIC ALPHA0 NOT ACCEPTED: byte payload review, runtime assets and Lua dynamic references, licensing, WoW 3.3.5a/IP, SavedVariables, G08, ZIP/install/merge/release.")
