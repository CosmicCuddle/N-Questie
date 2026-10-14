#!/usr/bin/env python3
"""Regression against PUBLIC Questie WotLK source, never private acore_world.

The corresponding reviewed server values are written in docs/CLASSIC-CHAIN-
LEVEL-AUDIT.md; tests deliberately contain no private SQL or full audit data.
"""
import unittest
from pathlib import Path
from audit_world_quest_levels import (
    QUESTIE_RAW, LEVEL_FIXES, parse_questie_raw, parse_static_level_fixes,
)

ROOT = Path(__file__).resolve().parents[1]
DUSKWOOD = {225, 227, 228, 229, 231}
WETLANDS = {473, 464, 465, 474}
IDS = DUSKWOOD | WETLANDS

class ClassicQuestChainSourceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.quests, unparsable = parse_questie_raw(
            (ROOT / QUESTIE_RAW).read_text(encoding="utf-8")
        )
        if unparsable:
            raise AssertionError("Original Questie source was only partially parsed")

    def test_all_nine_inherited_level_pairs(self):
        for id in DUSKWOOD:
            with self.subTest(quest_id=id):
                q = self.quests[id]
                self.assertEqual((q["requiredLevel"], q["questLevel"]), (25, 30))
        for id in WETLANDS:
            with self.subTest(quest_id=id):
                q = self.quests[id]
                self.assertEqual((q["requiredLevel"], q["questLevel"]), (23, 26))

    def test_static_numeric_fix_layers_are_accounted_for(self):
        # Original TBC has a literal min-level fix for 225 to *25*, which
        # coincides with the baseline. A new fix for any other field/ID
        # requires explicit re-review, not a silent overwrite.
        for layer in LEVEL_FIXES:
            fixed, dynamic = parse_static_level_fixes(
                (ROOT / layer).read_text(encoding="utf-8")
            )
            expected = {225: {"requiredLevel": 25}} if layer.name == "tbcQuestFixes.lua" else {}
            for id in IDS:
                with self.subTest(layer=str(layer), quest_id=id):
                    self.assertEqual(fixed.get(id, {}), expected.get(id, {}))
                    self.assertNotIn(id, dynamic)

    def test_prior_level_batches_and_jarl_do_not_overlap(self):
        previous = {
            1166, 1168, 1169, 1170, 1171, 1172, 1205, 1252,
            98, 126, 169, 180, 249, 256, 304, 398, 442, 895, 6284,
            1203, 2001,
        }
        self.assertEqual(IDS & previous, set())
        self.assertEqual(len(IDS), 9)


if __name__ == "__main__":
    unittest.main()
