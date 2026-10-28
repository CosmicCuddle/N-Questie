#!/usr/bin/env python3
"""Public-safe, static, source-pinned N-Questie 335 reader consumer inventory.

No WoW client, addon runtime, SavedVariables, SQL, private datasets, or build.
Only invokes git show/git ls-tree on the authenticated original public 335 commit.
"""
from __future__ import annotations
import collections
import os
import re
import subprocess
from pathlib import Path

PIN = "8b23c6e2cfa00bb81cb26d40c44fef154e9e0070"
EXPECTED_BLOBS = {
    "Modules/Journey/QuestieSearch.lua": "999efb373c5cc61f258115cf89e5e587cc087855",
    "Modules/Journey/QuestieSearchResults.lua": "00b1b0382d301d2839f0cd7c30fe8ff7ac143353",
    "Modules/Quest/AvailableQuests.lua": "2664f09fdf1f5df4d94581414e9d5ea88e9af4e7",
    "Database/QuestieDB.lua": "5784cb65160175e1dce30fe20e8baada0af7e480",
    "Database/compiler.lua": "abba0249f44d14711dbdd46bbde969ccffbc2963",
}
REFERENCE = re.compile(
    r"\bQuestieDB\.(?P<api>Query(?:NPC|Quest|Object|Item)(?:Single)?"
    r"|_Query(?:NPC|Quest|Object|Item)(?:Single)?"
    r"|(?:NPC|Quest|Object|Item)Pointers)\b"
)
GLOBAL_FIELDS = re.compile(
    r"\bQuestie\.db\.global(?:\.sod)?\."
    r"(?P<kind>npc|quest|obj|item)(?P<part>Bin|Ptrs)\b"
)
CALL_INIT = re.compile(r"\bQuestieDB:Initialize\s*\(")
FACTORY = re.compile(r"\bQuestieDBCompiler:GetDBHandle\s*\(")
QUERY_VALUE = re.compile(
    r"\bQuestieDB\.Query(?:NPC|Quest|Object|Item)(?:Single)?\b"
)
checks = 0
def check(condition: bool, label: str) -> None:
    global checks
    if not condition:
        raise AssertionError(label)
    checks += 1

repo = Path(os.environ.get("NQ_G08_PINNED_REPO", ".")).resolve()
def git(*args: str) -> bytes:
    proc = subprocess.run(
        ["git", "-C", str(repo), *args],
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False, timeout=60
    )
    if proc.returncode != 0:
        raise RuntimeError(f"PINNED_GIT_READ_FAILED {args[0]}: {proc.stderr[:160]!r}")
    return proc.stdout

check(git("rev-parse", f"{PIN}^{{commit}}").decode().strip() == PIN,
      "I01_PROTECTED_PINNED_COMMIT_PRESENT")
tree = git("ls-tree", "-r", "--name-only", PIN).decode().splitlines()
check(len(tree) > 300, "I02_PROTECTED_TREE_PRESENT")
def selected(p: str) -> bool:
    return p.endswith(".lua") and not p.endswith(".test.lua") and (
        p.startswith("Modules/")
        or p in {
            "Database/QuestieDB.lua", "Database/compiler.lua",
            "Database/Corrections/QuestieCorrections.lua",
            "Compat/NQuestieCustomQuestLoader.lua",
            "Compat/NQuestieExistingQuestCorrections.lua",
            "Compat/Corrections.lua",
        }
    )
paths = sorted(p for p in tree if selected(p))
check(len(paths) >= 90 and len(paths) < 180, "I03_FIRSTPARTY_SCOPE_EXPECTED_SIZE")
check(all(p in paths for p in EXPECTED_BLOBS), "I04_KEY_CONSUMER_SOURCE_IN_SCOPE")
for path, oid in EXPECTED_BLOBS.items():
    check(git("rev-parse", f"{PIN}:{path}").decode().strip() == oid,
          "I05_AUTHENTIC_ORIGINAL_BLOB:" + path)

files: dict[str, str] = {}
for path in paths:
    files[path] = git("show", f"{PIN}:{path}").decode("utf-8")
check(len(files) == len(paths), "I10_READ_ALL_SELECTED_ORIGINAL_BLOBS")

references: list[tuple[str, int, str, str]] = []
globals_: list[tuple[str, int, str, str]] = []
init_calls: list[tuple[str, int]] = []
factory_calls: list[tuple[str, int]] = []
for path, src in files.items():
    for lineno, line in enumerate(src.splitlines(), 1):
        # Lexical scan only: includes some comment matches and misses dynamic accesses.
        for match in REFERENCE.finditer(line):
            references.append((path, lineno, match.group("api"), line.strip()))
        for match in GLOBAL_FIELDS.finditer(line):
            globals_.append((path, lineno,
                             match.group("kind") + match.group("part"), line.strip()))
        if CALL_INIT.search(line):
            init_calls.append((path, lineno))
        if FACTORY.search(line):
            factory_calls.append((path, lineno))
by_path = collections.Counter(p for p, _, _, _ in references)
by_field = collections.Counter(field for _, _, field, _ in references)
by_kind = collections.Counter(p for p, _, _, _ in globals_)

def exact(path: str, needle: str) -> bool:
    return needle in files[path]
S = "Modules/Journey/QuestieSearch.lua"
R = "Modules/Journey/QuestieSearchResults.lua"
A = "Modules/Quest/AvailableQuests.lua"
D = "Database/QuestieDB.lua"
C = "Database/compiler.lua"
check(len(references) > 35, "I11_FIND_MANY_REAL_QUERY_AND_POINTER_REFERENCES")
check(len(by_path) >= 8, "I12_REFERENCES_SPAN_MULTIPLE_FIRSTPARTY_MODULES")
check(all(by_field[f"Query{k}Single"] > 0 for k in ("NPC", "Quest", "Object", "Item")),
      "I13_FOUR_KINDS_SINGLE_QUERY_EXPORTED_AND_CONSUMED")
check(all(by_field[f"{k}Pointers"] > 0 for k in ("NPC", "Quest", "Object", "Item")),
      "I14_FOUR_KINDS_POINTER_TABLE_EXPORTED_AND_CONSUMED")
check(exact(S, "databaseQueryHandle = QuestieDB.QueryNPCSingle")
      and exact(S, "databaseKeys = QuestieDB.NPCPointers")
      and exact(S, "databaseQueryHandle = QuestieDB.QueryQuestSingle")
      and exact(S, "databaseKeys = QuestieDB.QuestPointers"),
      "I15_REAL_JOURNEY_SEARCH_TWO_INDEPENDENT_FIELDS")
check(exact(R, 'query = QuestieDB.QueryNPCSingle')
      and exact(R, 'AddLinkedParagraph(details, "npc", startedBy[1]'),
      "I16_SEARCH_RESULTS_FUNCTION_ALIASES_AND_CALLBACK_PASSING")
check(exact(A, "local questData = QuestieDB.QuestPointers or QuestieDB.questData"),
      "I17_AVAILABLE_QUESTS_POINTER_ALIAS")
check(exact(D, "QuestieDB._QueryNPCSingle = QuestieDB.QueryNPC.QuerySingle")
      and exact(D, "QuestieDB.NPCPointers = QuestieDB.QueryNPC.pointers")
      and exact(D, "QuestieDB.QueryNPC = QuestieDB._QueryNPC"),
      "I18_ORIGINAL_DB_INITIALIZE_INDIVIDUAL_EXPORTS")
check(exact(C, 'Questie.db.global[databaseKey.."Bin"] = stream:Save()')
      and exact(C, 'Questie.db.global[databaseKey.."Ptrs"] = QuestieDBCompiler:EncodePointerMap(stream, pointerMap)'),
      "I19_ORIGINAL_COMPILER_INDIVIDUAL_BIN_PTRS_WRITES")
check(len(globals_) > 6 and len(by_kind) >= 2,
      "I20_ORIGINAL_GLOBAL_BIN_PTRS_LEGACY_CONSUMERS")
check(any(p == "Modules/QuestieInit.lua" for p, _ in init_calls),
      "I21_STAGE1_ACTUAL_QUESTIEDB_INITIALIZATION")
check(any(p == D for p, _ in factory_calls),
      "I22_ORIGINAL_DB_HAS_GETDBHANDLE_CALLS")

# Define a conservative lexical alias/pointer audit. This is neither a Lua
# parser nor a proof of exhaustive dataflow, especially for dynamic indexing.
stored_query = [
    (p, n, v) for p, n, field, line in references
    if field.startswith("Query") and not re.search(
        r"\bQuestieDB\." + re.escape(field) + r"\s*\(", line
    ) and "=" in line
    for v in [field]
]
pointer_lines = [(p, n) for p, n, field, _ in references
                 if field.endswith("Pointers")]
callback_lines = [(p, n, field) for p, n, field, line in references
                  if field.startswith("Query") and re.search(
                      r",\s*QuestieDB\." + re.escape(field) + r"\b", line
                  )]
check(len(stored_query) >= 5, "I23_REAL_QUERY_ALIASES_PRESERVED_IN_SOURCE")
check(len(pointer_lines) >= 8, "I24_REAL_POINTER_READS_PRESERVED_IN_SOURCE")
check(len(callback_lines) >= 3, "I25_REAL_CALLBACK_QUERY_PASSING")
assert checks == 25, f"SOURCE_CONSUMER_AUDIT_CENSUS_CHANGED:{checks}"

print("PUBLIC G08 PART43 PINNED FIRSTPARTY CONSUMER INVENTORY: 25/25 PASS")
print(f"PUBLIC G08 INVENTORY SCOPE: {len(paths)} first-party Lua files;"
      f" {len(references)} direct Query/Pointer references in {len(by_path)} files;"
      f" {len(globals_)} direct Bin/Ptrs matches in {len(by_kind)} files;"
      f" {len(stored_query)} conservative query assignments;"
      f" {len(callback_lines)} callback-value sites.")
for path, count in sorted(by_path.items(), key=lambda p: (-p[1], p[0]))[:20]:
    print(f"PUBLIC G08 CONSUMER PATH: {path} direct_refs={count}")
for path, n, field in sorted(callback_lines)[:20]:
    print(f"PUBLIC G08 CALLBACK ALIAS: {path}:{n} {field}")
for path, n, field in sorted(stored_query)[:20]:
    print(f"PUBLIC G08 STORED QUERY: {path}:{n} {field}")
print("PUBLIC G08 NOT ACCEPTED: conservative static first-party lexical matches only; no dynamic alias proof, real source ownership/stream leases, SavedVariables, native 3.3.5a/IP or ZIP/install/merge/release.")
