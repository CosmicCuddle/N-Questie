#!/usr/bin/env python3
"""Fictional-only tests for private whole-world missing-quest candidate report."""
import json
import tempfile
import unittest
from pathlib import Path

import audit_missing_vanilla_coverage as audit
from test_inspect_missing_quest_pilot import sql_table


def fake_world():
    return '\n'.join([
        sql_table('quest_template',
                  ['ID', 'LogTitle', 'MinLevel', 'QuestLevel'],
                  [(1207, 'Fictional early quest', 8, 10),
                   (30000, 'Fictional deferred quest', 10, 12),
                   (70000, 'Fictional late quest', 68, 72)]),
        sql_table('quest_template_addon', ['ID', 'PrevQuestID'],
                  [(1207, 0), (30000, 0), (70000, 0)]),
        sql_table('creature_queststarter', ['id', 'quest'], [(100, 1207)]),
        sql_table('creature_questender', ['id', 'quest'], [(101, 1207)]),
        sql_table('gameobject_queststarter', ['id', 'quest'], [(999, 30000)]),
        sql_table('gameobject_questender', ['id', 'quest'], [(999, 30000)]),
    ])


class CoverageTests(unittest.TestCase):
    def setUp(self):
        t = tempfile.TemporaryDirectory()
        self.addCleanup(t.cleanup)
        self.root = Path(t.name)
        self.world = self.root / 'world.sql'
        self.world.write_text(fake_world(), encoding='utf-8')
        # Fictional source ID tables and corrections.
        sources = {
            audit.SOURCES['wotlk']: '[1202] = {},\n[1203] = {},\n',
            audit.SOURCES['custom']: '[2001] = {},\n',
            audit.INHERITED['classic'][0]: (
                'function QuestieQuestFixes:LoadMissingQuests()\n'
                '  QuestieDB.questData[1202] = {}\n'
                '  QuestieDB.questData[2300] = {}\nend\n'),
            audit.INHERITED['tbc'][0]: (
                'function _QuestieTBCQuestFixes:InsertMissingQuestIds()\n'
                '  QuestieDB.questData[2400] = {} -- add\nend\n'),
            audit.INHERITED['wotlk'][0]: (
                'function _QuestieWotlkQuestFixes:InsertMissingQuestIds()\n'
                '  QuestieDB.questData[2500] = {}\nend\n'),
        }
        for path, content in sources.items():
            target = self.root / path
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(content, encoding='utf-8')

    def test_inherited_record_membership_not_raw_only(self):
        ids, counts = audit.effective_ids(self.root, pinned=False)
        self.assertEqual(ids, {1202, 1203, 2001, 2300, 2400, 2500})
        self.assertEqual(counts, {'raw': 2, 'inherited_added': 3,
                                  'custom_added': 1, 'effective': 6})

    def test_missing_and_deferred_remain_review_only(self):
        result = audit.build(self.world, self.root, pinned=False)
        rows = result['candidates']
        self.assertEqual([r['id'] for r in rows], [1207, 30000, 70000])
        self.assertEqual(rows[0]['priority'], 'LEVEL60_OR_BELOW_REVIEW')
        self.assertEqual(rows[1]['priority'], 'OWNER_DEFERRED_NO_IMPORT')
        self.assertEqual(rows[2]['priority'], 'LATER_OR_UNUSUAL_LEVEL_REVIEW')
        self.assertEqual(result['summary']['server_only_candidates'], 3)
        self.assertEqual(result['summary']['owner_deferred'], 1)
        self.assertEqual(result['summary']['linked_level60_or_below_review'], 1)
        self.assertEqual(result['summary']['other_level_or_unusual_review'], 1)
        self.assertEqual(rows[0]['npc_starters'], [100])
        self.assertEqual(rows[0]['eligibility'], 'UNVERIFIED_LIVE_SERVER_AND_IP')
        self.assertNotIn('APPROVED_TO_IMPLEMENT', json.dumps(result))

    def test_missing_world_table_refused(self):
        self.world.write_text(sql_table('quest_template',
                              ['ID', 'LogTitle', 'MinLevel', 'QuestLevel'],
                              [(1207, 'Small quest', 5, 10)]), encoding='utf-8')
        with self.assertRaisesRegex(ValueError, 'incomplete SQL export'):
            audit.build(self.world, self.root, pinned=False)

    def test_invalid_function_or_duplicate_id_refused(self):
        target = self.root / audit.INHERITED['tbc'][0]
        target.write_text('function X:InsertMissingQuestIds()\n'
                          ' QuestieDB.questData[2400] = {}\n'
                          ' QuestieDB.questData[2400] = {}\nend\n', encoding='utf-8')
        with self.assertRaisesRegex(ValueError, 'duplicate inherited'):
            audit.effective_ids(self.root, pinned=False)
        target.write_text('unrelated', encoding='utf-8')
        with self.assertRaisesRegex(ValueError, 'exactly one inherited'):
            audit.effective_ids(self.root, pinned=False)

    def test_stale_baseline_refused(self):
        with self.assertRaisesRegex(ValueError, 'Pinned Questie source baseline changed'):
            audit.effective_ids(self.root, pinned=True)

    def test_level_60_not_live_phase_proof(self):
        self.assertEqual(audit.priority(60, 60), 'LEVEL60_OR_BELOW_REVIEW')
        self.assertEqual(audit.priority(61, 1), 'LATER_OR_UNUSUAL_LEVEL_REVIEW')
        self.assertEqual(audit.priority(10, 65), 'LATER_OR_UNUSUAL_LEVEL_REVIEW')


if __name__ == '__main__':
    unittest.main()
