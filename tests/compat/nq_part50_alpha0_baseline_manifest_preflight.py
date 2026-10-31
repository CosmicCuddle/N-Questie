#!/usr/bin/env python3
"""Read-only preflight of the REAL protected baseline (not a packaged addon).

This checks direct Questie-335.toc path resolution, exact Git tree case, and
Lua 5.1 / 5.4 parseability for directly referenced .lua files. It does NOT
follow XML include relationships, execute WoW client APIs, validate runtime
DB contents, install anything or make a release artifact.
"""
import argparse
import pathlib
import re
import subprocess
import tempfile

BASELINE = "26053bd28b0df3a01e5859f779d5f3cb4f57b221"
TOC_BLOB = "f59dc1c2b1987697e133297831224e6f0957bae8"
CRITICAL = {
    "Modules/QuestieInit.lua",
    "Database/compiler.lua",
    "Database/QuestieDB.lua",
    "Compat/NQuestieCustomQuestData.lua",
    "Compat/NQuestieCustomQuestLoader.lua",
    "Compat/NQuestieExistingQuestCorrections.lua",
    "Compat/NQuestieReviewedQuestLevelCorrections.lua",
    "Compat/NQuestieReviewedEarlyQuestLevels.lua",
    "Compat/NQuestieReviewedClassicChainLevels.lua",
}

def git(*args):
    result = subprocess.run(["git", *args], check=True, stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE)
    return result.stdout

def check(condition, label):
    if not condition:
        raise AssertionError("ALPHA0_BASELINE_PREFLIGHT: " + label)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--ref", default=BASELINE)
    parser.add_argument("--luac", choices=["luac5.1", "luac5.4"], required=True)
    args = parser.parse_args()
    # The fixed commit identity is mandatory. No mutable branch name alias.
    check(args.ref == BASELINE, "UNPINNED_BASELINE")
    check(git("rev-parse", args.ref + "^{commit}").decode().strip() == BASELINE,
          "BASELINE_COMMIT_ID")
    check(git("rev-parse", args.ref + ":Questie-335.toc").decode().strip() == TOC_BLOB,
          "BASELINE_TOC_BLOB")
    manifest = git("show", args.ref + ":Questie-335.toc").decode("utf-8-sig")
    check(re.search(r"^## Interface:\s*30300\s*$", manifest, re.M) is not None,
          "WOTLK_30300_INTERFACE")
    check(re.search(r"^## Title:\s*N-Questie", manifest, re.M) is not None,
          "NQUESTIE_TITLE")
    entries = []
    for line in manifest.splitlines():
        line = line.strip()
        if line and not line.startswith("#"):
            path = line.replace("\\", "/")
            check(path.lower().endswith((".lua", ".xml")), "UNEXPECTED_PATH_TYPE")
            check(not (path.startswith("/") or path.startswith("../") or
                       "/../" in path or path.startswith("./")), "UNSAFE_TOC_PATH")
            entries.append(path)
    # Pinned-source count, not an upstream or future TOC format guarantee.
    check(len(entries) == 143, "DIRECT_TOC_COUNT_" + str(len(entries)))
    check(len(set(entries)) == len(entries), "DUPLICATE_TOC_PATHS")
    check(len(set(x.casefold() for x in entries)) == len(entries),
          "CASE_FOLDED_TOC_COLLISION")
    blob_tree = git("ls-tree", "-r", "--name-only", args.ref).decode().splitlines()
    tree = set(blob_tree)
    missing = [path for path in entries if path not in tree]
    check(not missing, "MISSING_DIRECT_TOC_PATHS:" + ",".join(missing[:10]))
    check(CRITICAL.issubset(set(entries)), "CUSTOM_BOOTSTRAP_REFERENCE_MISSING")
    # Verify conventional unsupported fallback cannot replace the 3.3.5a TOC.
    unsupported = git("show", args.ref + ":Questie.toc").decode()
    check(re.search(r"^## Interface:\s*00000\s*$", unsupported, re.M) is not None,
          "UNSUPPORTED_FALLBACK_TOC_CHANGED")
    scripts = [path for path in entries if path.endswith(".lua")]
    xmls = [path for path in entries if path.endswith(".xml")]
    with tempfile.TemporaryDirectory(prefix="nq-alpha0-toc-preflight-") as folder:
        for i, path in enumerate(scripts, 1):
            data = git("show", args.ref + ":" + path)
            temp = pathlib.Path(folder) / ("toc-" + str(i) + ".lua")
            temp.write_bytes(data)
            parse = subprocess.run([args.luac, "-p", str(temp)],
                                   capture_output=True, text=True)
            check(parse.returncode == 0,
                  "LUA_PARSE_FAILURE:" + path + ":" + parse.stderr[:350])
    print("PUBLIC NQ PART50 ALPHA0 PROTECTED BASELINE TOC: 143/143 RESOLVED")
    print("PUBLIC NQ PART50 ALPHA0 DIRECT LUA PARSE: " +
          str(len(scripts)) + "/" + str(len(scripts)) + " PASS " + args.luac)
    print("PUBLIC NQ PART50 ALPHA0 XML DIRECT PATHS: " + str(len(xmls)) +
          " EXIST (XML NESTED INCLUDES NOT AUDITED)")
    print("PUBLIC NQ PART50 ALPHA0 NO NATIVE GAMEPLAY PROOF / NO BUILD / NO RELEASE")

if __name__ == "__main__":
    main()
