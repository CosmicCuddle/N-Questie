#!/usr/bin/env python3
"""No external dependencies, no production world DB: scoped exporter tests."""
import tempfile
import unittest
import zipfile
from pathlib import Path

import export_world_quests as exporter


def table(name, columns, rows):
    quoted = ", ".join(chr(96) + col + chr(96) for col in columns)
    data = ["INSERT INTO " + chr(96) + name + chr(96) +
            " (" + quoted + ") VALUES"]
    for index, row in enumerate(rows):
        fields = []
        for value in row:
            if isinstance(value, str):
                fields.append("'" + value.replace("\\", "\\\\").replace("'", "\\'") + "'")
            else:
                fields.append(str(value))
        data.append("\t(" + ", ".join(fields) + (");" if index == len(rows) - 1 else "),"))
    return "\n".join(data) + "\n"


def fixture(include_go=False):
    sql = []
    sql.append(table("quest_template", [
        "ID", "LogTitle", "MinLevel", "QuestLevel", "QuestSortID",
        "AllowableRaces", "Flags", "RequiredNpcOrGo1",
        "RequiredNpcOrGoCount1", "RequiredNpcOrGo2", "RequiredNpcOrGoCount2",
        "RequiredNpcOrGo3", "RequiredNpcOrGoCount3",
        "RequiredNpcOrGo4", "RequiredNpcOrGoCount4",
    ], [
        (2001, "Ravenclaw Cleanup", 12, 16, 130, 690, 8, 1868, 8, 1869, 8, 0, 0, 0, 0),
        (9999, "Ignore me", 1, 1, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
    ]))
    sql.append(table("quest_template_addon", ["ID", "PrevQuestID"],
                     [(2001, 437), (9999, 0)]))
    sql.append(table("creature_queststarter", ["id", "quest"],
                     [(2121, 2001), (2121, 9999)]))
    sql.append(table("creature_questender", ["id", "quest"],
                     [(2121, 2001), (2121, 9999)]))
    sql.append(table("gameobject_queststarter", ["id", "quest"],
                     [(180717, 2001)] if include_go else [(180717, 9999)]))
    return "\n".join(sql)


class ExportTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.sql = Path(self.temp.name) / "world.sql"
        self.sql.write_text(fixture(), encoding="utf-8")

    def test_single_realistic_quest(self):
        review = exporter.curate(self.sql, [2001])
        self.assertEqual(len(review["quests"]), 1)
        item = review["quests"][0]
        self.assertEqual(item["title"], "Ravenclaw Cleanup")
        self.assertEqual(item["starter_npcs"], [2121])
        self.assertEqual(item["ender_npcs"], [2121])
        self.assertEqual(item["pre_quest_single"], [437])
        self.assertEqual(item["kill_objectives"], [
            {"npc": 1868, "count": 8}, {"npc": 1869, "count": 8},
        ])
        self.assertNotIn("Ignore me", str(review))
        self.assertNotIn("password", str(review))

    def test_zip_equals_sql(self):
        archive = Path(self.temp.name) / "world.zip"
        with zipfile.ZipFile(archive, "w") as handle:
            handle.writestr("acore_world.sql", fixture())
        self.assertEqual(exporter.curate(archive, [2001]),
                         exporter.curate(self.sql, [2001]))

    def test_missing_quest_fails_closed(self):
        with self.assertRaisesRegex(ValueError, "No quest_template"):
            exporter.curate(self.sql, [5555])

    def test_unsupported_gameobject_fails_closed(self):
        self.sql.write_text(fixture(include_go=True), encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "Gameobject"):
            exporter.curate(self.sql, [2001])


if __name__ == "__main__":
    unittest.main()
