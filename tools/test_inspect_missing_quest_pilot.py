#!/usr/bin/env python3
"""No-server/no-private-data tests of first pilot's offline source census."""
import json
import tempfile
import unittest
import zipfile
from pathlib import Path

import inspect_missing_quest_pilot as checker


def sql_table(name, columns, data):
    q = chr(96)
    header = 'INSERT INTO ' + q + name + q + ' (' + ', '.join(q + c + q for c in columns) + ') VALUES\n'
    lines = []
    for i, row in enumerate(data):
        cells = [str(value) if isinstance(value, int) else "'" + value + "'" for value in row]
        lines.append('  (' + ', '.join(cells) + (');' if i == len(data) - 1 else '),'))
    return header + '\n'.join(lines) + '\n'


def fake_world():
    return '\n'.join([
        sql_table('quest_template', ['ID', 'LogTitle'], [(1207, 'Example A'), (1208, 'Example B')]),
        sql_table('quest_template_addon', ['ID', 'PrevQuestID'], [(1207, 0)]),
        sql_table('creature_queststarter', ['id', 'quest'], [(4, 1207), (5, 1208)]),
        sql_table('creature_questender', ['id', 'quest'], [(4, 1207)]),
        sql_table('gameobject_queststarter', ['id', 'quest'], [(999, 1208)]),
        sql_table('gameobject_questender', ['id', 'quest'], [(999, 1208)]),
    ])


class PilotTests(unittest.TestCase):
    def setUp(self):
        t = tempfile.TemporaryDirectory()
        self.addCleanup(t.cleanup)
        self.base = Path(t.name)
        self.world = self.base / 'world.sql'
        self.world.write_text(fake_world(), encoding='utf-8')
        for label, relative in checker.SOURCES.items():
            path = self.base / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            if label == 'custom':
                data = '        [2001] = { name = "x" },\n'
            else:
                data = '\n'.join('        [%d] = { "sample" },' % q for q in range(1000, 1501)) + '\n'
            path.write_text(data, encoding='utf-8')

    def test_source_keys_not_substring_or_objective_ids(self):
        path = self.base / checker.SOURCES['wotlk']
        with path.open('a', encoding='utf-8') as f:
            f.write('-- [1207] = { commented },\n')
            f.write('        [9999] = { 1207, 1208, 1209 },\n')
        result = checker.source_membership(self.base, (1207, 1208, 1209))
        self.assertTrue(result['wotlk'][1207])  # present among fake 1000-1500 IDs
        self.assertFalse(result['custom'][1207])
        self.assertFalse(result['custom'][1208])
        self.assertFalse(result['custom'][1209])

    def test_classification_is_only_snapshot_and_flags(self):
        report = checker.inspect(self.world, self.base)
        self.assertEqual([x['quest_id'] for x in report['quests']], [1207, 1208, 1209])
        self.assertEqual(report['quests'][2]['server_template'], 'ABSENT_IN_THIS_SNAPSHOT')
        self.assertEqual(report['quests'][1]['relations']['gameobject_queststarter'], 1)
        self.assertEqual(report['quests'][2]['assessment'], 'RECHECK_SERVER_SNAPSHOT_NOT_AN_IMPORT')
        self.assertNotIn('Example A', json.dumps(report))
        self.assertNotIn('Example B', json.dumps(report))
        self.assertNotIn('999', json.dumps(report))

    def test_missing_dump_table_refused(self):
        self.world.write_text(sql_table('quest_template', ['ID'], [(1207,)]))
        with self.assertRaisesRegex(ValueError, 'incomplete SQL export'):
            checker.inspect(self.world, self.base)

    def test_wrong_source_refused(self):
        (self.base / checker.SOURCES['classic']).write_text('[1207] = {}')
        with self.assertRaisesRegex(ValueError, 'complete classic'):
            checker.inspect(self.world, self.base)

    def test_zip_readonly_parity(self):
        z = self.base / 'world.zip'
        with zipfile.ZipFile(z, 'w') as a:
            a.writestr('world.sql', fake_world())
        self.assertEqual(checker.inspect(self.world, self.base), checker.inspect(z, self.base))

    def test_duplicate_and_invalid_ids_refused(self):
        for ids in ((1207, 1207), (0,), (True,), ()):
            with self.assertRaises(ValueError):
                checker.inspect(self.world, self.base, ids)


if __name__ == '__main__':
    unittest.main()
