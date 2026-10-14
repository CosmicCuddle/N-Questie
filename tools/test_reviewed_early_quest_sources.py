#!/usr/bin/env python3
"""Verify reviewed early-zone level corrections against PUBLIC source only.

This test uses the repository's original Questie WotLK data, not private
AzerothCore SQL. It guards against rebasing the patch onto changed upstream
levels or hidden literal numeric overrides in standard correction tables.
"""
import unittest
from pathlib import Path

from audit_world_quest_levels import (
    QUESTIE_RAW, LEVEL_FIXES, parse_questie_raw, parse_static_level_fixes
)

ROOT = Path(__file__).resolve().parents[1]
# [quest ID] = expected PUBLIC source MinLevel, questLevel.
# Confirmed server targets are documented in docs/EARLY-QUEST-LEVEL-AUDIT.md
# and the narrow Lua patch, NOT imported from the private database.
BASELINE = {
    98: (22, 32), 126: (15, 21), 169: (11, 26),
    180: (11, 26), 249: (20, 26), 256: (9, 22),
    304: (26, 31), 398: (4, 10), 442: (10, 20),
    895: (9, 16), 6284: (12, 21),
}

class EarlyQuestSourceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.questie, unparsed = parse_questie_raw(
            (ROOT / QUESTIE_RAW).read_text(encoding="utf-8")
        )
        if unparsed:
            raise AssertionError("Unparsed Questie records detected")

    def test_all_eleven_source_values_still_match(self):
        for qid, (minimum, level) in BASELINE.items():
            with self.subTest(quest_id=qid):
                self.assertIn(qid, self.questie)
                quest = self.questie[qid]
                self.assertEqual(quest["requiredLevel"], minimum)
                self.assertEqual(quest["questLevel"], level)

    def test_no_original_static_numeric_corrections_for_these_ids(self):
        # A future upstream fix must trigger review before shipping ours.
        for path in LEVEL_FIXES:
            fixes, uncertain = parse_static_level_fixes(
                (ROOT / path).read_text(encoding="utf-8")
            )
            for qid in BASELINE:
                with self.subTest(path=str(path), quest_id=qid):
                    self.assertNotIn(qid, fixes)
                    self.assertNotIn(qid, uncertain)

    def test_quest_1203_and_custom_2001_not_in_the_batch(self):
        self.assertNotIn(1203, BASELINE)
        self.assertNotIn(2001, BASELINE)
        self.assertEqual(len(BASELINE), 11)

if __name__ == "__main__":
    unittest.main()
