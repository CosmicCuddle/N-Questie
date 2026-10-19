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


QUEST_COLUMNS = [
    "ID", "LogTitle", "MinLevel", "QuestLevel", "QuestSortID",
    "AllowableRaces", "Flags", "RequiredNpcOrGo1",
    "RequiredNpcOrGoCount1", "RequiredNpcOrGo2", "RequiredNpcOrGoCount2",
    "RequiredNpcOrGo3", "RequiredNpcOrGoCount3",
    "RequiredNpcOrGo4", "RequiredNpcOrGoCount4",
]


def raven_row(**overrides):
    values = {
        "ID": 2001, "LogTitle": "Ravenclaw Cleanup", "MinLevel": 12,
        "QuestLevel": 16, "QuestSortID": 130, "AllowableRaces": 690,
        "Flags": 8, "RequiredNpcOrGo1": 1868, "RequiredNpcOrGoCount1": 8,
        "RequiredNpcOrGo2": 1869, "RequiredNpcOrGoCount2": 8,
        "RequiredNpcOrGo3": 0, "RequiredNpcOrGoCount3": 0,
        "RequiredNpcOrGo4": 0, "RequiredNpcOrGoCount4": 0,
    }
    values.update(overrides)
    return tuple(values[column] for column in QUEST_COLUMNS)


def filler_row():
    return (9999, "Ignore me", 1, 1, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)


def world(quest_rows, addon_rows=None, starters=None, enders=None):
    """Invented HeidiSQL text. Not a server dump."""
    if addon_rows is None:
        addon_rows = [(2001, 437), (9999, 0)]
    if starters is None:
        starters = [(2121, 2001), (2121, 9999)]
    if enders is None:
        enders = [(2121, 2001), (2121, 9999)]
    parts = [
        table("quest_template", QUEST_COLUMNS, quest_rows),
        table("quest_template_addon", ["ID", "PrevQuestID"], addon_rows),
        table("creature_queststarter", ["id", "quest"], starters),
        table("creature_questender", ["id", "quest"], enders),
    ]
    return "\n".join(parts)


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

    def write_case(self, sql):
        path = Path(self.temp.name) / "case.sql"
        path.write_text(sql, encoding="utf-8")
        return path

    def assert_message(self, sql, quest_ids, message):
        with self.assertRaises(ValueError) as caught:
            exporter.curate(self.write_case(sql), quest_ids)
        self.assertEqual(str(caught.exception), message)

    def test_negative_quest_id_is_skipped_and_missing_id_is_refused(self):
        # pins current behaviour; see POTENTIAL ISSUE in PR description
        # The quest_template prefilter is ^\s*\((\d+), so "-2001" and "+2001"
        # never reach parse_row. curate([2001]) still exports the positive row.
        negative = (-2001, "Ravenclaw Cleanup", 12, 16, 130, 690, 8,
                    1868, 8, 1869, 8, 0, 0, 0, 0)
        sql = world(
            [negative, raven_row(), filler_row()],
            addon_rows=[(-2001, 437), (2001, 437), (9999, 0)],
            starters=[(2121, -2001), (2121, 2001), (2121, 9999)],
            enders=[(2121, -2001), (2121, 2001), (2121, 9999)],
        )
        path = self.write_case(sql)
        quests, _addons, _links = exporter.selected_rows(path, [2001, -2001])
        self.assertIn(2001, quests)
        self.assertNotIn(-2001, quests)
        self.assertEqual(exporter.curate(path, [2001]),
                         exporter.curate(self.sql, [2001]))
        self.assert_message(sql, [-2001],
                            "No quest_template record for quest -2001")
        self.assert_message(fixture(), [5555],
                            "No quest_template record for quest 5555")

        plus_sql = world([raven_row(), filler_row()]).replace(
            "\t(2001,", "\t(+2001,", 1)
        plus_path = self.write_case(plus_sql)
        plus_quests, _, _ = exporter.selected_rows(plus_path, [2001])
        self.assertNotIn(2001, plus_quests)
        self.assert_message(plus_sql, [2001],
                            "No quest_template record for quest 2001")

    def test_signed_npc_ids_on_creature_links(self):
        # pins current behaviour; see POTENTIAL ISSUE in PR description
        # "+2121" is coerced with int() to 2121. "-2121" is stored as-is.
        starters = table("creature_queststarter", ["id", "quest"],
                         [(2121, 2001), (2121, 9999)]).replace(
            "(2121, 2001)", "(+2121, 2001)", 1)
        enders = table("creature_questender", ["id", "quest"],
                       [(-2121, 2001), (2121, 9999)])
        sql = "\n".join([
            table("quest_template", QUEST_COLUMNS, [raven_row(), filler_row()]),
            table("quest_template_addon", ["ID", "PrevQuestID"],
                  [(2001, 437), (9999, 0)]),
            starters,
            enders,
        ])
        review = exporter.curate(self.write_case(sql), [2001])
        expected = exporter.curate(self.sql, [2001])
        expected["quests"][0]["starter_npcs"] = [2121]
        expected["quests"][0]["ender_npcs"] = [-2121]
        self.assertEqual(review, expected)
        self.assertIn("(+2121, 2001)", sql)
        self.assertIn("(-2121, 2001)", sql)

    def test_negative_prev_quest_id_is_refused(self):
        sql = world([raven_row(), filler_row()],
                    addon_rows=[(2001, -437), (9999, 0)])
        self.assert_message(
            sql, [2001],
            "Negative prerequisite/group must be reviewed: 2001")

    def test_leading_whitespace_and_tabs_are_accepted(self):
        # pins current behaviour; see POTENTIAL ISSUE in PR description
        # "(2001,  12" and a tab before Flags are coerced to the same integers.
        # Leading whitespace before "(" is stripped. int("  2121 ") == 2121.
        quest = table("quest_template", QUEST_COLUMNS,
                      [raven_row(), filler_row()])
        quest = quest.replace("\t(2001,", " \t (2001,", 1)
        quest = quest.replace(", 12, 16,", ",  12, 16,", 1)
        quest = quest.replace(", 690, 8,", ", 690,\t8,", 1)
        addon = table("quest_template_addon", ["ID", "PrevQuestID"],
                      [(2001, 437), (9999, 0)]).replace(
            "\t(2001,", "  (2001,", 1)
        starters = table("creature_queststarter", ["id", "quest"],
                         [(2121, 2001), (2121, 9999)]).replace(
            "(2121, 2001)", "(  2121 , 2001)", 1)
        sql = "\n".join([
            quest, addon, starters,
            table("creature_questender", ["id", "quest"],
                  [(2121, 2001), (2121, 9999)]),
        ])
        self.assertIn(" \t (2001, 'Ravenclaw Cleanup',  12,", sql)
        self.assertIn(", 690,\t8,", sql)
        self.assertEqual(exporter.curate(self.write_case(sql), [2001]),
                         exporter.curate(self.sql, [2001]))

    def test_space_or_tab_after_opening_paren_skips_quest_row(self):
        # pins current behaviour; see POTENTIAL ISSUE in PR description
        # ^\s*\((\d+), does not allow whitespace between "(" and the quest ID,
        # so the row is skipped and curate reports a missing record.
        for prefix in ("( ", "(\t"):
            with self.subTest(prefix=prefix):
                sql = world([raven_row(), filler_row()]).replace(
                    "\t(2001,", "\t" + prefix + "2001,", 1)
                path = self.write_case(sql)
                quests, _, _ = exporter.selected_rows(path, [2001])
                self.assertNotIn(2001, quests)
                self.assert_message(sql, [2001],
                                    "No quest_template record for quest 2001")

    def test_empty_integer_fields_are_refused(self):
        quoted = {
            "MinLevel": raven_row(MinLevel=""),
            "QuestLevel": raven_row(QuestLevel=""),
            "Flags": raven_row(Flags=""),
            "RequiredNpcOrGoCount1": raven_row(RequiredNpcOrGoCount1=""),
        }
        unquoted = {
            "MinLevel": (", 12, 16,", ",, 16,"),
            "QuestLevel": (", 16, 130,", ",, 130,"),
            "Flags": (", 690, 8, 1868,", ", 690,, 1868,"),
            "RequiredNpcOrGoCount1": (", 1868, 8, 1869,", ", 1868,, 1869,"),
        }
        for field, row in quoted.items():
            with self.subTest(field=field, form="quoted"):
                sql = world([row, filler_row()])
                self.assertIn("''", sql)
                self.assert_message(sql, [2001],
                                    "Invalid integer field " + field)
        base = world([raven_row(), filler_row()])
        for field, (old, new) in unquoted.items():
            with self.subTest(field=field, form="unquoted"):
                sql = base.replace(old, new, 1)
                self.assertNotIn(old, sql.split("quest_template_addon")[0])
                self.assert_message(sql, [2001],
                                    "Invalid integer field " + field)

    def test_missing_integer_column_defaults_to_zero(self):
        # pins current behaviour; see POTENTIAL ISSUE in PR description
        # MinLevel is absent from the header, so integer() returns default 0.
        # An empty MinLevel value is refused; a missing column is not.
        columns = [column for column in QUEST_COLUMNS if column != "MinLevel"]
        row = tuple(value for column, value in zip(QUEST_COLUMNS, raven_row())
                    if column != "MinLevel")
        filler = tuple(value for column, value in zip(QUEST_COLUMNS, filler_row())
                       if column != "MinLevel")
        sql = "\n".join([
            table("quest_template", columns, [row, filler]),
            table("quest_template_addon", ["ID", "PrevQuestID"],
                  [(2001, 437), (9999, 0)]),
            table("creature_queststarter", ["id", "quest"],
                  [(2121, 2001), (2121, 9999)]),
            table("creature_questender", ["id", "quest"],
                  [(2121, 2001), (2121, 9999)]),
        ])
        self.assertNotIn("MinLevel", sql.split("quest_template_addon")[0])
        review = exporter.curate(self.write_case(sql), [2001])
        expected = exporter.curate(self.sql, [2001])
        expected["quests"][0]["required_level"] = 0
        self.assertEqual(review, expected)

    def test_unsafe_integer_coercion(self):
        # Accepted by int() today, including the questionable cases:
        # pins current behaviour; see POTENTIAL ISSUE in PR description
        #   1_000 -> 1000, " 12 " -> 12, +5 -> 5, quoted '12' -> 12
        # Refused: 0x10, 12.0, 1e3, NULL -> "Invalid integer field MinLevel"
        accepted = {
            "1_000": 1000,
            " 12 ": 12,
            "+5": 5,
            "'12'": 12,
        }
        refused = ("0x10", "12.0", "1e3", "NULL")
        base = world([raven_row(), filler_row()])
        for token, level in accepted.items():
            with self.subTest(token=token):
                sql = base.replace(", 12,", ", " + token + ",", 1)
                review = exporter.curate(self.write_case(sql), [2001])
                expected = exporter.curate(self.sql, [2001])
                expected["quests"][0]["required_level"] = level
                self.assertEqual(review, expected)
        for token in refused:
            with self.subTest(token=token):
                sql = base.replace(", 12,", ", " + token + ",", 1)
                self.assert_message(sql, [2001],
                                    "Invalid integer field MinLevel")

    def test_incorrect_sql_tuple_width(self):
        base = world([raven_row(), filler_row()])
        short = base.replace("0, 0, 0, 0),", "0, 0, 0),", 1)
        long = base.replace("0, 0, 0, 0),", "0, 0, 0, 0, 99),", 1)
        self.assert_message(short, [2001], "Incorrect SQL tuple width")
        self.assert_message(long, [2001], "Incorrect SQL tuple width")

    def test_row_must_end_as_heidi_tuple(self):
        middle = world([raven_row(), filler_row()]).replace(
            "0, 0, 0, 0),", "0, 0, 0, 0)", 1)
        self.assert_message(middle, [2001],
                            "Expected one HeidiSQL tuple per row")
        final = world([filler_row(), raven_row()]).replace(
            "0, 0, 0, 0);", "0, 0, 0, 0)", 1)
        self.assert_message(final, [2001],
                            "Expected one HeidiSQL tuple per row")
        comma_only = world([raven_row(), filler_row()]).replace(
            "0, 0, 0, 0),", "0, 0, 0, 0,", 1)
        self.assert_message(comma_only, [2001],
                            "Expected one HeidiSQL tuple per row")


if __name__ == "__main__":
    unittest.main()
