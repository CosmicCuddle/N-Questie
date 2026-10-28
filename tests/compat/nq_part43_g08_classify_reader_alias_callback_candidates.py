#!/usr/bin/env python3
"""Read-only, protected-335 static classifier of consumer reference candidates.

Source is public, pinned and read from Git only. This deliberately is NOT
a Lua parser, an alias lifetime proof, or a runtime/database test.
"""
import collections
import os
import re
import subprocess
from pathlib import Path

PIN = "8b23c6e2cfa00bb81cb26d40c44fef154e9e0070"
BLOBS = {
    "Modules/Journey/QuestieSearch.lua": "999efb373c5cc61f258115cf89e5e587cc087855",
    "Modules/Journey/QuestieSearchResults.lua": "00b1b0382d301d2839f0cd7c30fe8ff7ac143353",
    "Modules/Quest/AvailableQuests.lua": "2664f09fdf1f5df4d94581414e9d5ea88e9af4e7",
    "Database/QuestieDB.lua": "5784cb65160175e1dce30fe20e8baada0af7e480",
    "Database/compiler.lua": "abba0249f44d14711dbdd46bbde969ccffbc2963",
}
REF = re.compile(
    r"\bQuestieDB\.(?P<field>Query(?:NPC|Quest|Object|Item)(?:Single)?"
    r"|_Query(?:NPC|Quest|Object|Item)(?:Single)?"
    r"|(?:NPC|Quest|Object|Item)Pointers)\b"
)
TESTED_SCOPE = {
    "Database/QuestieDB.lua",
    "Database/compiler.lua",
    "Database/Corrections/QuestieCorrections.lua",
    "Compat/NQuestieCustomQuestLoader.lua",
    "Compat/NQuestieExistingQuestCorrections.lua",
    "Compat/Corrections.lua",
}
ROOT = Path(os.getenv("NQ_G08_PINNED_REPO", ".")).resolve()

def git(*args):
    p = subprocess.run(["git", "-C", str(ROOT), *args],
                       stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                       timeout=60, check=False)
    if p.returncode:
        raise RuntimeError("READ_ONLY_GIT_SOURCE_FAILURE:" + args[0] +
                           ":" + repr(p.stderr[:150]))
    return p.stdout.decode("utf-8")

checks = 0
def check(condition, code):
    global checks
    assert condition, code
    checks += 1

check(git("rev-parse", PIN + "^{commit}").strip() == PIN, "K01_ORIGINAL_COMMIT_PIN")
tree = git("ls-tree", "-r", "--name-only", PIN).splitlines()
paths = sorted(p for p in tree if p.endswith(".lua") and
    not p.endswith(".test.lua") and
    (p.startswith("Modules/") or p in TESTED_SCOPE))
check(len(paths) == 110, "K02_ORIGINAL_FIRSTPARTY_SCOPE_SAME_AS_CENSUS")
check(all(p in paths for p in BLOBS), "K03_KEY_PROTECTED_SOURCE_IN_SCOPE")
check(all(git("rev-parse", PIN + ":" + p).strip() == oid
          for p, oid in BLOBS.items()), "K04_FIVE_PROTECTED_BLOB_HASHES_PINNED")
source = {p: git("show", PIN + ":" + p) for p in paths}
check(len(source) == 110, "K05_ALL_SOURCE_BYTES_LOADED")

def comment_start(line):
    """Simple Lua single-line comment detection ignoring quoted delimiters.

    Long bracket-string and long block comments are NOT parsed; lines containing
    these can be ambiguous and are flagged as static classification limitations.
    """
    quote = None
    i = 0
    while i < len(line):
        c = line[i]
        if quote:
            if c == "\\":
                i += 2
                continue
            if c == quote:
                quote = None
        elif c == "'" or c == '"':
            quote = c
        elif c == "-" and line[i:i+2] == "--":
            return i
        i += 1
    return len(line)

def classify(line, match):
    beginning = line[:match.start()].rstrip()
    rest = line[match.end():].lstrip()
    if match.start() >= comment_start(line):
        return "COMMENT"
    if rest.startswith("("):
        return "DIRECT_CALL"
    if rest.startswith("=") and not rest.startswith("=="):
        return "EXPORT_ASSIGNMENT_LHS"
    if beginning.endswith("="):
        return "QUERY_VALUE_ASSIGNED_RHS"
    if beginning.endswith(","):
        return "QUERY_VALUE_PASSED_ARGUMENT"
    return "OTHER_NONCALL_REFERENCE"

records = []
old_stored = []
old_callbacks = []
for p, body in source.items():
    for n, line in enumerate(body.splitlines(), 1):
        for match in REF.finditer(line):
            field = match.group("field")
            cat = classify(line, match)
            row = (p, n, field, cat, line.strip())
            records.append(row)
            # Reproduce the prior conservative census EXACTLY to explain
            # where the 36 / 14 numbers came from (including false positives).
            if field.startswith("Query") and not re.search(
                    r"\bQuestieDB\." + re.escape(field) + r"\s*\(", line
                ) and "=" in line:
                old_stored.append(row)
            if field.startswith("Query") and re.search(
                    r",\s*QuestieDB\." + re.escape(field) + r"\b", line
                ):
                old_callbacks.append(row)

by_kind = collections.Counter(row[3] for row in records)
by_path = collections.Counter(row[0] for row in records)
old_stored_by_kind = collections.Counter(row[3] for row in old_stored)
old_callbacks_by_kind = collections.Counter(row[3] for row in old_callbacks)
real_value_uses = [r for r in records if r[3] in (
    "QUERY_VALUE_ASSIGNED_RHS", "QUERY_VALUE_PASSED_ARGUMENT")]
search_aliases = [r for r in records if
    r[0] == "Modules/Journey/QuestieSearch.lua" and
    r[3] == "QUERY_VALUE_ASSIGNED_RHS" and
    r[2].endswith("Single")]
results_aliases = [r for r in records if
    r[0] == "Modules/Journey/QuestieSearchResults.lua" and
    r[3] == "QUERY_VALUE_ASSIGNED_RHS"]
results_callbacks = [r for r in records if
    r[0] == "Modules/Journey/QuestieSearchResults.lua" and
    r[3] == "QUERY_VALUE_PASSED_ARGUMENT"]
database_exports = [r for r in records if
    r[0] == "Database/QuestieDB.lua" and
    r[3] == "EXPORT_ASSIGNMENT_LHS"]
pointer_alias = [r for r in records if
    r[0] == "Modules/Quest/AvailableQuests.lua" and
    r[2] == "QuestPointers"]
# The original candidate numbers are definitions, not validated alias lifetimes.
check(len(records) == 197, "K06_CENSUS_197_REFERENCES_REPRODUCED")
check(len(by_path) == 25, "K07_CENSUS_25_FILES_REPRODUCED")
check(len(old_stored) == 36, "K08_ORIGINAL_36_ASSIGNMENT_CANDIDATES_REPRODUCED")
check(len(old_callbacks) == 14, "K09_ORIGINAL_14_CALLBACK_CANDIDATES_REPRODUCED")
check(sum(by_kind.values()) == len(records), "K10_ALL_REFERENCES_CLASSIFIED_ONCE")
check(len(real_value_uses) >= 10, "K11_NONCALL_VALUE_SITES_FOUND")
check(len(search_aliases) >= 4, "K12_ORIGINAL_SEARCH_FOUR_LOCAL_QUERY_ALIASES")
check(len(results_aliases) >= 7, "K13_ORIGINAL_RESULTS_LOCAL_QUERY_ALIASES")
check(len(results_callbacks) >= 7, "K14_REAL_QUEST_DETAIL_QUERY_CALLBACK_ARGUMENTS")
check(len(database_exports) >= 8, "K15_ORIGINAL_QUERY_EXPORT_WRITES_NOT_RETAINED_ALIASES")
check(len(pointer_alias) >= 1, "K16_AVAILABLE_QUESTS_POINTER_ALIAS_PRESENT")
check(any(row[0] == "Modules/QuestieDebugOffer.lua" and
          row[3] == "DIRECT_CALL" for row in records),
      "K17_DEBUG_OFFER_QUERY_CALL_NOT_VALUE_ALIAS")
check(any(row[0] == "Modules/Tracker/TrackerLinePool.lua" and
          row[3] == "DIRECT_CALL" for row in records),
      "K18_TRACKER_QUERY_CALL_NOT_VALUE_ALIAS")
check(old_callbacks_by_kind["DIRECT_CALL"] >= 5,
      "K19_OLD_CALLBACK_HEURISTIC_INCLUDED_DIRECT_INVOCATIONS")
check(old_callbacks_by_kind["QUERY_VALUE_PASSED_ARGUMENT"] >= 7,
      "K20_TRUE_VALUE_CALLBACK_ARGUMENTS_FOUND")
check(old_stored_by_kind["EXPORT_ASSIGNMENT_LHS"] >= 8,
      "K21_OLD_STORED_HEURISTIC_INCLUDED_EXPORT_WRITES")
check(old_stored_by_kind["QUERY_VALUE_ASSIGNED_RHS"] >= 10,
      "K22_GENUINE_QUERY_REFERENCE_ASSIGNMENTS_FOUND")
check("COMMENT" in by_kind,
      "K23_COMMENT_TEXT_INCLUDED_IN_CONSERVATIVE_SOURCE_CENSUS")
check(all(row[3] != "COMMENT" for row in results_callbacks),
      "K24_QUEST_DETAIL_CALLBACK_SITES_ARE_NOT_COMMENT")
check(all(row[3] != "DIRECT_CALL" for row in results_aliases),
      "K25_QUEST_RESULTS_FUNCTION_VALUE_NOT_INVOCATION")
assert checks == 25, f"CLASSIFIER_ASSERTION_COUNT_CHANGED:{checks}"

print("PUBLIC G08 PART43 CONSUMER CANDIDATE CLASSIFIER: 25/25 PASS")
print(f"PUBLIC G08 REPRODUCED: {len(paths)} firstparty files;"
      f" {len(records)} references in {len(by_path)} files;"
      f" old_stored={len(old_stored)} old_callback={len(old_callbacks)}")
for cat in sorted(by_kind):
    print(f"PUBLIC G08 ALL CLASS: {cat} count={by_kind[cat]}")
for cat in sorted(old_stored_by_kind):
    print(f"PUBLIC G08 STORED RECLASSIFIED: {cat} count={old_stored_by_kind[cat]}")
for cat in sorted(old_callbacks_by_kind):
    print(f"PUBLIC G08 CALLBACK RECLASSIFIED: {cat} count={old_callbacks_by_kind[cat]}")
for path, n, field, cat, content in old_stored:
    print(f"PUBLIC G08 ORIGINAL STORED CANDIDATE: {cat} {path}:{n} {field} {content[:175]}")
for path, n, field, cat, content in old_callbacks:
    print(f"PUBLIC G08 ORIGINAL CALLBACK CANDIDATE: {cat} {path}:{n} {field} {content[:175]}")
print("PUBLIC G08 NOT ACCEPTED: regex source classifier, not Lua dataflow or lifetime analysis; dynamic aliases, long comments, original decoder, stream, SavedVariables, native 3.3.5a/IP and build/ZIP/install/merge/release NOT verified.")
