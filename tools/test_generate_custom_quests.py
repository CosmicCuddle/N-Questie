#!/usr/bin/env python3
"""Offline-only regression checks for approved N-Questie JSON-to-Lua generation."""
import copy
import json
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
            generator.main(args + ["--overwrite"])
            self.assertEqual(before, output.read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
