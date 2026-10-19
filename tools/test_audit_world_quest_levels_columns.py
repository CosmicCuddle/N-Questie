#!/usr/bin/env python3
"""Pin column handling in the offline quest-level audit.

Synthetic HeidiSQL INSERT text only. No private world dump is read or written.
parse_world_quest_levels requires quest_template.ID, LogTitle, MinLevel and
QuestLevel by name, then parse_row rejects a tuple whose width differs from
that header. These tests record today's behaviour.
"""
import json
import tempfile
import unittest
import zipfile
from pathlib import Path

import audit_world_quest_levels as audit
from export_world_quests import parse_row


TICK = chr(96)
RAW = '[88001] = {"Synthetic Lantern",{},{},17,41},\n'
CORRECTION = """
function QuestieSyntheticFixes:Load()
    return {
    }
end
"""


def sql_insert(columns, rows, table="quest_template"):
    """Build one HeidiSQL-style INSERT. Strings are quoted; None is NULL."""
    quoted = ", ".join(TICK + column + TICK for column in columns)
    header = ("INSERT INTO " + TICK + table + TICK + " (" + quoted +
              ") VALUES\n")
    lines = []
    for index, values in enumerate(rows):
        rendered = []
        for value in values:
            if value is None:
                rendered.append("NULL")
            elif isinstance(value, str):
                escaped = value.replace("\\", "\\\\").replace("'", "\\'")
                rendered.append("'" + escaped + "'")
            else:
                rendered.append(str(value))
        suffix = ";" if index == len(rows) - 1 else ","
        lines.append("(" + ", ".join(rendered) + ")" + suffix)
    body = "\n".join(lines)
    if body:
        body += "\n"
    return header + body


def write_sql(directory, text, name="synthetic-world.sql"):
    path = Path(directory) / name
    path.write_text(text, encoding="utf-8")
    return path


class QuestLevelColumnTests(unittest.TestCase):
    def parse(self, text):
        with tempfile.TemporaryDirectory() as temp:
            path = write_sql(temp, text)
            return audit.parse_world_quest_levels(path)

    def refuse(self, text, message):
        with tempfile.TemporaryDirectory() as temp:
            path = write_sql(temp, text)
            with self.assertRaisesRegex(ValueError, message):
                audit.parse_world_quest_levels(path)

    def test_named_columns_parse_in_any_order(self):
        # QuestLevel is first and MinLevel is third. A positional reading of
        # (ID, LogTitle, MinLevel, QuestLevel) would swap or reject these.
        text = sql_insert(
            ["QuestLevel", "MinLevel", "ID", "LogTitle"],
            [
                (41, 17, 88031, "Synthetic, Comma"),
                (8, 3, 88032, "Synthetic Second"),
            ],
        )
        parsed = self.parse(text)
        self.assertEqual(parsed, {
            88031: {"name": "Synthetic, Comma", "requiredLevel": 17,
                    "questLevel": 41},
            88032: {"name": "Synthetic Second", "requiredLevel": 3,
                    "questLevel": 8},
        })
        self.assertNotIn(41, parsed)
        self.assertNotIn(17, parsed)

    def test_extra_unknown_column_is_ignored(self):
        text = sql_insert(
            ["ID", "LogTitle", "MinLevel", "UnknownFlag", "QuestLevel"],
            [(88041, "Synthetic Extra", 17, 999, 41)],
        )
        parsed = self.parse(text)
        self.assertEqual(parsed[88041], {
            "name": "Synthetic Extra", "requiredLevel": 17, "questLevel": 41,
        })
        self.assertNotEqual(parsed[88041]["requiredLevel"], 999)
        self.assertNotEqual(parsed[88041]["questLevel"], 999)

    def test_scrambled_header_with_extra_column_keeps_named_levels(self):
        text = sql_insert(
            ["QuestLevel", "UnknownFlag", "LogTitle", "MinLevel", "ID"],
            [(41, 999, "Synthetic Scramble", 17, 88051)],
        )
        parsed = self.parse(text)
        self.assertEqual(set(parsed), {88051})
        self.assertEqual(parsed[88051]["requiredLevel"], 17)
        self.assertEqual(parsed[88051]["questLevel"], 41)
        self.assertEqual(parsed[88051]["name"], "Synthetic Scramble")

    def test_whitespace_around_header_names_still_matches(self):
        text = (
            "INSERT INTO " + TICK + "quest_template" + TICK + " ( " +
            TICK + "QuestLevel" + TICK + " , " + TICK + "ID" + TICK + " , " +
            TICK + "LogTitle" + TICK + " , " + TICK + "MinLevel" + TICK +
            " ) VALUES\n(41, 88071, 'Synthetic Spaced', 17);\n"
        )
        parsed = self.parse(text)
        self.assertEqual(parsed[88071], {
            "name": "Synthetic Spaced", "requiredLevel": 17, "questLevel": 41,
        })

    def test_explicit_zero_levels_are_kept(self):
        # A literal 0 from the export is data. It is not the stand-in for a
        # column that was absent; those exports are refused below.
        text = sql_insert(
            ["ID", "LogTitle", "MinLevel", "QuestLevel"],
            [(88061, "Synthetic Zero", 0, 0)],
        )
        self.assertEqual(self.parse(text)[88061], {
            "name": "Synthetic Zero", "requiredLevel": 0, "questLevel": 0,
        })

    def test_missing_or_misspelled_level_columns_are_refused(self):
        cases = (
            (["ID", "LogTitle", "QuestLevel"],
             [(88011, "Synthetic Omit Min", 41)],
             "Missing quest_template.MinLevel"),
            (["ID", "LogTitle", "MinLevel"],
             [(88012, "Synthetic Omit Quest", 17)],
             "Missing quest_template.QuestLevel"),
            (["ID", "LogTitle"],
             [(88013, "Synthetic Omit Both")],
             "Missing quest_template.MinLevel"),
            (["ID", "LogTitle", "MinLvl", "QuestLevel"],
             [(88014, "Synthetic Misspell", 17, 41)],
             "Missing quest_template.MinLevel"),
            (["ID", "LogTitle", "minlevel", "QuestLevel"],
             [(88015, "Synthetic Case", 17, 41)],
             "Missing quest_template.MinLevel"),
            (["ID", "LogTitle", "Min Level", "QuestLevel"],
             [(88016, "Synthetic Space", 17, 41)],
             "Missing quest_template.MinLevel"),
            (["ID", "LogTitle", "MinLevel", "QuestLvl"],
             [(88017, "Synthetic Quest Lvl", 17, 41)],
             "Missing quest_template.QuestLevel"),
            (["ID", "LogTitle", "MinLevel", "questlevel"],
             [(88018, "Synthetic Quest Case", 17, 41)],
             "Missing quest_template.QuestLevel"),
            (["ID", "LogTitle", "MinLevel", "Quest-Level"],
             [(88019, "Synthetic Quest Dash", 17, 41)],
             "Missing quest_template.QuestLevel"),
        )
        for columns, rows, message in cases:
            with self.subTest(columns=columns):
                self.refuse(sql_insert(columns, rows), message)

    def test_unrecognized_insert_header_is_refused(self):
        valid_row = "(88021, 'Synthetic Lantern', 17, 41);\n"
        named = (TICK + "ID" + TICK + ", " + TICK + "LogTitle" + TICK + ", " +
                 TICK + "MinLevel" + TICK + ", " + TICK + "QuestLevel" + TICK)
        cases = (
            "INSERT INTO quest_template (" + named + ") VALUES\n" + valid_row,
            "  INSERT INTO " + TICK + "quest_template" + TICK + " (" + named +
            ") VALUES\n" + valid_row,
            sql_insert(["ID", "LogTitle", "MinLevel", "QuestLevel"],
                       [(88021, "Synthetic Lantern", 17, 41)],
                       table="quest_template_addon"),
            "INSERT INTO " + TICK + "quest_template" + TICK + " (" + named +
            ") VALUES " + valid_row,
            sql_insert(["ID", "LogTitle", "MinLevel", "QuestLevel"], []),
            "",
        )
        for text in cases:
            with self.subTest(text=text[:48]):
                self.refuse(text, "No supported HeidiSQL quest_template INSERT rows found")

    def test_tuple_width_must_match_header(self):
        columns = ["ID", "LogTitle", "MinLevel", "QuestLevel"]
        short = sql_insert(columns, [(88081, "Synthetic Short", 17)])
        long = sql_insert(columns, [(88082, "Synthetic Long", 17, 41, 999)])
        self.refuse(short, "Incorrect SQL tuple width")
        self.refuse(long, "Incorrect SQL tuple width")
        # A valid first tuple must not be returned when a later tuple is short.
        mixed = sql_insert(columns, [
            (88083, "Synthetic Ok", 17, 41),
            (88084, "Synthetic Tail", 17),
        ])
        self.refuse(mixed, "Incorrect SQL tuple width")

    def test_extra_header_without_matching_value_is_refused(self):
        text = sql_insert(
            ["ID", "LogTitle", "MinLevel", "UnknownFlag", "QuestLevel"],
            [(88091, "Synthetic Unaligned", 17, 41)],
        )
        self.refuse(text, "Incorrect SQL tuple width")

    def test_non_numeric_levels_are_not_coerced(self):
        columns = ["ID", "LogTitle", "MinLevel", "QuestLevel"]
        cases = (
            ([(88101, "Synthetic Bad Min", "nope", 41)],
             "Invalid integer field MinLevel"),
            ([(88102, "Synthetic Null Min", None, 41)],
             "Invalid integer field MinLevel"),
            ([(88103, "Synthetic Empty Min", "", 41)],
             "Invalid integer field MinLevel"),
            ([(88104, "Synthetic Bad Quest", 17, "41.5")],
             "Invalid integer field QuestLevel"),
            ([(88105, "Synthetic Null Quest", 17, None)],
             "Invalid integer field QuestLevel"),
        )
        for rows, message in cases:
            with self.subTest(message=message, title=rows[0][1]):
                self.refuse(sql_insert(columns, rows), message)

    def test_later_missing_column_does_not_return_earlier_rows(self):
        text = (
            sql_insert(["ID", "LogTitle", "MinLevel", "QuestLevel"],
                       [(88001, "Synthetic Lantern", 17, 41)]) +
            sql_insert(["ID", "LogTitle", "QuestLevel"],
                       [(88002, "Synthetic Other", 9)])
        )
        self.refuse(text, "Missing quest_template.MinLevel")

    def test_later_unrecognized_insert_is_not_merged(self):
        # Current behaviour: once one supported insert has been accepted, a
        # later statement that fails the HeidiSQL header pattern is skipped
        # with no error. Its levels are not invented and not copied across.
        named = (TICK + "ID" + TICK + ", " + TICK + "LogTitle" + TICK + ", " +
                 TICK + "MinLevel" + TICK + ", " + TICK + "QuestLevel" + TICK)
        text = (
            sql_insert(["ID", "LogTitle", "MinLevel", "QuestLevel"],
                       [(88001, "Synthetic Lantern", 17, 41)]) +
            "INSERT INTO quest_template (" + named + ") VALUES\n"
            "(88002, 'Synthetic Other', 4, 9);\n"
        )
        parsed = self.parse(text)
        self.assertEqual(parsed, {
            88001: {"name": "Synthetic Lantern", "requiredLevel": 17,
                    "questLevel": 41},
        })
        self.assertNotIn(88002, parsed)

    def test_duplicate_minlevel_header_keeps_the_later_value(self):
        # Current behaviour: duplicate names are not rejected. zip() keeps
        # the last MinLevel (99), so the earlier 17 is discarded.
        text = sql_insert(
            ["ID", "LogTitle", "MinLevel", "QuestLevel", "MinLevel"],
            [(88001, "Synthetic Lantern", 17, 41, 99)],
        )
        parsed = self.parse(text)
        self.assertEqual(parsed[88001]["requiredLevel"], 99)
        self.assertEqual(parsed[88001]["questLevel"], 41)

    def test_parse_row_maps_by_header_name_and_rejects_width(self):
        mapped = parse_row(
            "(41, 999, 'Synthetic, Comma', 17, 88041),",
            ["QuestLevel", "UnknownFlag", "LogTitle", "MinLevel", "ID"],
        )
        self.assertEqual(mapped, {
            "QuestLevel": "41", "UnknownFlag": "999",
            "LogTitle": "Synthetic, Comma", "MinLevel": "17", "ID": "88041",
        })
        with self.assertRaisesRegex(ValueError, "Incorrect SQL tuple width"):
            parse_row("(88041, 'Synthetic Short', 17),",
                      ["ID", "LogTitle", "MinLevel", "QuestLevel"])
        with self.assertRaisesRegex(ValueError, "Incorrect SQL tuple width"):
            parse_row("(88041, 'Synthetic Long', 17, 41, 999),",
                      ["ID", "LogTitle", "MinLevel", "QuestLevel"])

    def test_zip_follows_the_same_column_rules(self):
        good = sql_insert(
            ["QuestLevel", "ID", "LogTitle", "MinLevel"],
            [(41, 88031, "Synthetic Zip", 17)],
        )
        bad = sql_insert(
            ["ID", "LogTitle", "QuestLevel"],
            [(88011, "Synthetic Omit Min", 41)],
        )
        with tempfile.TemporaryDirectory() as temp:
            folder = Path(temp)
            good_zip = folder / "good.zip"
            with zipfile.ZipFile(good_zip, "w") as archive:
                archive.writestr("synthetic.sql", good)
            self.assertEqual(audit.parse_world_quest_levels(good_zip), {
                88031: {"name": "Synthetic Zip", "requiredLevel": 17,
                        "questLevel": 41},
            })
            bad_zip = folder / "bad.zip"
            with zipfile.ZipFile(bad_zip, "w") as archive:
                archive.writestr("synthetic.sql", bad)
            with self.assertRaisesRegex(ValueError, "Missing quest_template.MinLevel"):
                audit.parse_world_quest_levels(bad_zip)

    def test_cli_column_refusal_does_not_write_a_report(self):
        columns = ["ID", "LogTitle", "MinLevel", "QuestLevel"]
        cases = (
            (sql_insert(["ID", "LogTitle", "QuestLevel"],
                        [(88011, "Synthetic Omit Min", 41)]),
             "Missing quest_template.MinLevel"),
            (sql_insert(columns, [(88081, "Synthetic Short", 17)]),
             "Incorrect SQL tuple width"),
            (sql_insert(columns, [(88101, "Synthetic Bad Min", "nope", 41)]),
             "Invalid integer field MinLevel"),
        )
        for text, message in cases:
            with self.subTest(message=message):
                with tempfile.TemporaryDirectory() as temp:
                    base = Path(temp)
                    root = base / "public-repo"
                    raw_path = root / audit.QUESTIE_RAW
                    raw_path.parent.mkdir(parents=True)
                    raw_path.write_text(RAW, encoding="utf-8")
                    for fix in audit.LEVEL_FIXES:
                        destination = root / fix
                        destination.parent.mkdir(parents=True, exist_ok=True)
                        destination.write_text(CORRECTION, encoding="utf-8")
                    world = write_sql(base, text, name="private-world.sql")
                    report = base / "private" / "level-review.json"
                    args = ["--questie-root", str(root), "--world", str(world),
                            "--output", str(report), "--overwrite"]
                    with self.assertRaisesRegex(ValueError, message):
                        audit.main(args)
                    self.assertFalse(report.exists())
                    report.parent.mkdir(parents=True)
                    original = b'{"approved":false,"synthetic":true}\n'
                    report.write_bytes(original)
                    with self.assertRaisesRegex(ValueError, message):
                        audit.main(args)
                    self.assertEqual(report.read_bytes(), original)
                    self.assertNotIn(b"requiredLevel", report.read_bytes())
                    json.loads(report.read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
