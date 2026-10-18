#!/usr/bin/env python3
"""Offline-only regression checks for approved N-Questie JSON-to-Lua generation."""
import copy
import json
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

import generate_custom_quests as generator


def quest(qid=2001):
    return {
        "id": qid, "title": "Ravenclaw Cleanup",
        "required_level": 12, "quest_level": 16, "zone_or_sort": 130,
        "required_races": 690, "quest_flags": 8,
        "pre_quest_single": [437], "starter_npcs": [2121],
        "ender_npcs": [2121],
        "kill_objectives": [{"npc": 1868, "count": 8},
                            {"npc": 1869, "count": 8}],
        "requires_review": ["Confirm existing Questie NPC spawn positions"],
    }


def reviewed(*records):
    return {"format": generator.FORMAT, "quests": list(records)}


def generate(document=None, approved=None, verified=None, revision=2):
    return generator.generate(
        document if document is not None else reviewed(quest()),
        approved if approved is not None else [2001],
        verified if verified is not None else [2121, 1868, 1869],
        revision,
    )


class GeneratorTests(unittest.TestCase):
    def test_known_quest_lua_structure(self):
        result = generate()
        self.assertIn("revision = 2", result)
        self.assertIn('[2001] = {', result)
        self.assertIn('name = "Ravenclaw Cleanup"', result)
        self.assertIn("startedByNpcs = {2121}", result)
        self.assertIn("finishedByNpcs = {2121}", result)
        self.assertIn("killNpcs = {1868, 1869}", result)
        self.assertIn("preQuestSingle = {437}", result)
        self.assertNotIn("requires_review", result)
        self.assertNotIn("count = 8", result)

    def test_explicit_quest_approval(self):
        with self.assertRaisesRegex(ValueError, "Approved quest IDs"):
            generate(approved=[2002])

    def test_explicit_verified_npcs(self):
        with self.assertRaisesRegex(ValueError, "Verified NPC IDs"):
            generate(verified=[2121, 1868])

    def test_unknown_format_and_fields_refused(self):
        bad = reviewed(quest())
        bad["format"] = "unknown"
        with self.assertRaisesRegex(ValueError, "Unknown review"):
            generate(bad)
        bad = reviewed(quest())
        bad["quests"][0]["secret_connection"] = "do not publish"
        with self.assertRaisesRegex(ValueError, "unexpected fields"):
            generate(bad)

    def test_bad_ids_counts_and_duplicates_refused(self):
        bad = reviewed(quest())
        bad["quests"][0]["id"] = True
        with self.assertRaises(ValueError):
            generate(bad)
        bad = reviewed(quest())
        bad["quests"][0]["kill_objectives"][0]["count"] = 0
        with self.assertRaises(ValueError):
            generate(bad)
        with self.assertRaisesRegex(ValueError, "Duplicate quest ID"):
            generate(reviewed(quest(), quest()), approved=[2001])
        bad = reviewed(quest())
        bad["quests"][0]["starter_npcs"] = [2121, 2121]
        with self.assertRaises(ValueError):
            generate(bad)

    def test_title_escaping_no_lua_injection(self):
        q = quest()
        q["title"] = 'Quoted "title" \\ slash'
        result = generate(reviewed(q))
        self.assertIn('name = "Quoted \\"title\\" \\\\ slash"', result)
        q["title"] = 'unsafe\nLua code'
        with self.assertRaisesRegex(ValueError, "control characters"):
            generate(reviewed(q))

    def test_sort_order_and_stable_output(self):
        other = quest(2002)
        document = reviewed(other, quest())
        expected = generate(document, approved=[2001, 2002])
        self.assertLess(expected.index("[2001] = {"), expected.index("[2002] = {"))
        self.assertEqual(expected, generate(copy.deepcopy(document),
                                            approved=[2002, 2001],
                                            verified=[1869, 2121, 1868]))

    @unittest.skipUnless(shutil.which("lua5.1"), "requires installed Lua 5.1")
    def test_generated_lua_loads_through_real_335_overlay(self):
        # This is a PUBLIC, fully invented fixture, not a private review JSON.
        # The approved generator must produce syntax the unchanged Lua 5.1
        # loader accepts, and both quests must coexist without clobbering NPCs.
        second = quest(2002)
        second["title"] = 'Synthetic "Second" \\ Quest'
        result = generate(reviewed(quest(), second),
                          approved=[2002, 2001],
                          verified=[1869, 2121, 1868], revision=7)
        lua_harness = r"""
local generated, loader = assert(arg[1]), assert(arg[2])
local callbacks = {}
QuestieCompat = {
    Is335 = true,
    RegisterCorrection = function(kind, callback)
        assert(callbacks[kind] == nil, "duplicate callback")
        callbacks[kind] = callback
    end,
}
local keys = {
    name = 1, startedBy = 2, finishedBy = 3, requiredLevel = 4,
    questLevel = 5, requiredRaces = 6, objectives = 10,
    preQuestSingle = 13, zoneOrSort = 17, questFlags = 23,
}
local db = {
    questKeys = keys,
    npcKeys = {questStarts = 10, questEnds = 11},
    npcData = {
        [2121] = {[10] = {477, 479}, [11] = {478, 480}},
        [1868] = {[10] = {}, [11] = {}},
        [1869] = {[10] = {}, [11] = {}},
    },
}
QuestieLoader = {
    ImportModule = function(_, name)
        assert(name == "QuestieDB")
        return db
    end,
}
dofile(generated)
assert(NQuestieCustomQuestData.revision == 7)
dofile(loader)
assert(type(callbacks.questData) == "function")
assert(type(callbacks.npcData) == "function")
local quests = callbacks.questData()
assert(quests[2001] and quests[2002], "generated quest missing")
assert(quests[2001][keys.name] == "Ravenclaw Cleanup")
assert(quests[2002][keys.name] == [[Synthetic "Second" \ Quest]],
    "generated Lua title escaping was not preserved")
assert(quests[2001][keys.objectives][1][1][1] == 1868)
assert(quests[2002][keys.objectives][1][2][1] == 1869)
assert(quests[2001][keys.preQuestSingle][1] == 437)
assert(quests[2002][keys.requiredLevel] == 12)
local npc = callbacks.npcData()[2121]
assert(npc and #npc[10] == 4 and #npc[11] == 4,
    "existing NPC relations lost or generated reverse link duplicated")
assert(npc[10][1] == 477 and npc[10][2] == 479)
assert(npc[11][1] == 478 and npc[11][2] == 480)
local function count(list, needle)
    local found = 0
    for _, id in ipairs(list) do
        if id == needle then found = found + 1 end
    end
    return found
end
for _, field in ipairs({10, 11}) do
    assert(count(npc[field], 2001) == 1)
    assert(count(npc[field], 2002) == 1)
end
assert(#db.npcData[2121][10] == 2 and #db.npcData[2121][11] == 2,
    "generator/loader integration mutated base NPC relations")
local again = callbacks.npcData()[2121]
assert(#again[10] == 4 and #again[11] == 4,
    "repeated generated callback appended duplicate NPC links")
print("PASS: generated reviewed JSON Lua loads through frozen Questie 3.3.5a overlay")
"""
        with tempfile.TemporaryDirectory() as temp:
            folder = Path(temp)
            generated = folder / "generated-synthetic-quests.lua"
            harness = folder / "synthetic-loader-harness.lua"
            generated.write_text(result, encoding="utf-8")
            harness.write_text(lua_harness, encoding="utf-8")
            root = Path(__file__).resolve().parents[1]
            process = subprocess.run(
                [shutil.which("lua5.1"), str(harness), str(generated),
                 str(root / "Compat/NQuestieCustomQuestLoader.lua")],
                cwd=root, capture_output=True, text=True, timeout=15,
                check=False,
            )
            self.assertEqual(0, process.returncode,
                             process.stdout + "\n" + process.stderr)
            self.assertIn("PASS: generated reviewed JSON Lua loads", process.stdout)

    def test_cli_requires_explicit_removal_approval(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            review = directory / "private.json"
            output = directory / "curated.lua"
            full = reviewed(quest(), quest(2002))
            review.write_text(json.dumps(full), encoding="utf-8")
            args = ["--review", str(review), "--approved-quest", "2001",
                    "--approved-quest", "2002", "--verified-npc", "2121",
                    "--verified-npc", "1868", "--verified-npc", "1869",
                    "--revision", "2", "--output", str(output)]
            generator.main(args)
            initial = output.read_text(encoding="utf-8")
            # Simulates a mistaken partial export containing only the new/current quest.
            review.write_text(json.dumps(reviewed(quest())), encoding="utf-8")
            partial_args = [argument for argument in args]
            removed_at = partial_args.index("2002")
            del partial_args[removed_at - 1:removed_at + 1]
            partial_args[partial_args.index("--revision") + 1] = "3"
            with self.assertRaises(SystemExit):
                generator.main(partial_args + ["--overwrite"])
            self.assertEqual(initial, output.read_text(encoding="utf-8"))
            # Incorrect approvals are rejected too.
            with self.assertRaises(SystemExit):
                generator.main(partial_args + ["--overwrite", "--approve-removal-quest", "2003"])
            self.assertEqual(initial, output.read_text(encoding="utf-8"))
            generator.main(partial_args + ["--overwrite", "--approve-removal-quest", "2002"])
            final = output.read_text(encoding="utf-8")
            self.assertIn("[2001] = {", final)
            self.assertNotIn("[2002] = {", final)
            self.assertIn("revision = 3", final)

    def test_cli_never_overwrites_existing_file_by_default(self):
        with tempfile.TemporaryDirectory() as temp:
            directory = Path(temp)
            review = directory / "private-review.json"
            output = directory / "generated.lua"
            review.write_text(json.dumps(reviewed(quest())), encoding="utf-8")
            args = ["--review", str(review),
                    "--approved-quest", "2001", "--verified-npc", "2121",
                    "--verified-npc", "1868", "--verified-npc", "1869",
                    "--revision", "2", "--output", str(output)]
            generator.main(args)
            before = output.read_text(encoding="utf-8")
            with self.assertRaises(SystemExit):
                generator.main(args)
            self.assertEqual(before, output.read_text(encoding="utf-8"))
            with self.assertRaises(SystemExit):
                generator.main(args + ["--overwrite"])
            self.assertEqual(before, output.read_text(encoding="utf-8"))
            revised = args.copy()
            revised[revised.index("--revision") + 1] = "3"
            generator.main(revised + ["--overwrite"])
            self.assertIn("revision = 3", output.read_text(encoding="utf-8"))
            output.write_text("-- unrelated Lua file\n", encoding="utf-8")
            with self.assertRaises(SystemExit):
                generator.main(revised + ["--overwrite"])
            self.assertEqual("-- unrelated Lua file\n",
                             output.read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
