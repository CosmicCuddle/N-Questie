#!/usr/bin/env python3
"""Pin current HeidiSQL quoting, escaping, line-ending and encoding behaviour.

Synthetic quest ids, titles and levels only. Every fixture is written under
tempfile.TemporaryDirectory(). This file does not change the parser, and no
workflow invokes it.

parse_row feeds the inside of one tuple to csv.reader with a single-quote
quotechar, a backslash escapechar and skipinitialspace. parse_world_quest_levels
reads those rows through sql_lines and then checks ID, MinLevel and QuestLevel
by column name. Assertions below record what that path does today.
"""
import subprocess
import sys
import tempfile
import unittest
import zipfile
from pathlib import Path

import audit_world_quest_levels as audit
import export_world_quests as exporter


COLUMNS = ("ID", "LogTitle", "MinLevel", "QuestLevel")
TICK = chr(96)

# Raw SQL tuple text, then the id / title / levels observed from today's parser.
# The SQL is not run through a second escaper: backslashes here are the bytes
# a HeidiSQL dump would contain.
GOOD_ROWS = (
    ("(910401, 'North, then east', 11, 21),",
     910401, "North, then east", 11, 21),
    ("(910402, 'It\\'s a lantern', 12, 22),",
     910402, "It's a lantern", 12, 22),
    ("(910403, 'It''s a lantern', 13, 23),",
     910403, "It's a lantern", 13, 23),
    ("(910404, 'O\\'Brien, Jr.', 14, 24),",
     910404, "O'Brien, Jr.", 14, 24),
    ("(910405, 'O''Brien, Jr.', 15, 25),",
     910405, "O'Brien, Jr.", 15, 25),
    ("(910406, 'back\\\\slash', 16, 26),",
     910406, "back\\slash", 16, 26),
    # POTENTIAL ISSUE: \\n and \\t are not MySQL newline/tab. The backslash is
    # discarded and the following letter is kept. Numeric columns stay put.
    ("(910407, 'line\\nfeed', 17, 27),",
     910407, "linenfeed", 17, 27),
    ("(910408, 'tab\\there', 18, 28),",
     910408, "tabthere", 18, 28),
    ("(910409, 'Say \"hello\"', 19, 29),",
     910409, 'Say "hello"', 19, 29),
    ("(910410, 'Go (north); wait', 20, 30),",
     910410, "Go (north); wait", 20, 30),
    # POTENTIAL ISSUE: unquoted NULL in a text column is the string NULL, the
    # same result as the quoted word NULL. It is not a distinct null, and it
    # does not shift the numeric columns.
    ("(910411, NULL, 21, 31),",
     910411, "NULL", 21, 31),
    ("(910419, 'NULL', 29, 39),",
     910419, "NULL", 29, 39),
    ("(910412, '', 22, 32),",
     910412, "", 22, 32),
    # VERIFIED: a title that ends in one backslash is the MySQL form \\ before
    # the closing quote. The returned title ends with \ and the levels match.
    ("(910413, 'Ends\\\\', 23, 33),",
     910413, "Ends\\", 23, 33),
    ("(910414, 'Café résumé', 24, 34),",
     910414, "Café résumé", 24, 34),
    ("(910415, '委托：雪原', 25, 35),",
     910415, "委托：雪原", 25, 35),
    ("(910416, 'wait);', 26, 36),",
     910416, "wait);", 26, 36),
    # POTENTIAL ISSUE: double quotes are not string delimiters. With no comma
    # inside them they stay in the title and the levels still line up.
    ('(910417, "PlainDouble", 27, 37),',
     910417, '"PlainDouble"', 27, 37),
    ("(910418, 'Café, O\\'Brien (north); say \"hi\" 雪', 28, 38),",
     910418, 'Café, O\'Brien (north); say "hi" 雪', 28, 38),
)


def tuple_lines():
    lines = [row[0] for row in GOOD_ROWS]
    if lines[-1].endswith(","):
        lines[-1] = lines[-1][:-1] + ";"
    return lines


def insert_text(lines, line_ending="\n"):
    header = "INSERT INTO " + TICK + "quest_template" + TICK + " (" + ", ".join(
        TICK + name + TICK for name in COLUMNS
    ) + ") VALUES"
    return header + line_ending + line_ending.join(lines) + line_ending


def expected_levels():
    return {
        qid: {"name": name, "requiredLevel": minimum, "questLevel": quest}
        for _sql, qid, name, minimum, quest in GOOD_ROWS
    }


class SqlQuotingTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.folder = Path(self.temp.name)

    def write_sql(self, data, name):
        path = self.folder / name
        path.write_bytes(data)
        return path

    def write_zip(self, data, name, member="synthetic.sql"):
        path = self.folder / name
        with zipfile.ZipFile(path, "w") as archive:
            archive.writestr(member, data)
        return path

    def test_shared_parser_and_fixture_bytes(self):
        # Both tools call this csv splitter. The fixture must still contain
        # the SQL escapes when it is written, not a pre-decoded title.
        self.assertIs(audit.parse_row, exporter.parse_row)
        self.assertIs(audit.sql_lines, exporter.sql_lines)
        self.assertIs(audit.HEADER, exporter.HEADER)
        text = insert_text(tuple_lines())
        self.assertIn("It\\'s a lantern", text)
        self.assertIn("It''s a lantern", text)
        self.assertIn("O\\'Brien, Jr.", text)
        self.assertIn("O''Brien, Jr.", text)
        self.assertIn("back\\\\slash", text)
        self.assertIn("line\\nfeed", text)
        self.assertIn("tab\\there", text)
        self.assertIn("Ends\\\\", text)
        self.assertIn("Café résumé", text)
        self.assertIn("委托：雪原", text)
        self.assertNotIn("linenfeed", text)
        self.assertNotIn("tabthere", text)

    def test_parse_row_quotes_do_not_move_numeric_fields(self):
        # A tab-indented tuple ending in LF, CRLF or a bare CR still returns
        # ID, LogTitle, MinLevel and QuestLevel in those columns. Surprising
        # title decodings are the ones marked on GOOD_ROWS.
        for sql, qid, name, minimum, quest in GOOD_ROWS:
            for suffix in ("\n", "\r\n", "\r"):
                with self.subTest(qid=qid, suffix=repr(suffix)):
                    row = exporter.parse_row("\t" + sql + suffix, COLUMNS)
                    self.assertEqual(
                        [row["ID"], row["LogTitle"], row["MinLevel"], row["QuestLevel"]],
                        [str(qid), name, str(minimum), str(quest)],
                    )
                    self.assertNotEqual(row["MinLevel"], name)
                    self.assertNotEqual(row["QuestLevel"], name)

    def test_lf_and_crlf_files_and_zips_keep_the_same_levels(self):
        # VERIFIED: a plain file is opened as text, so CRLF becomes LF.
        # A ZIP is read as bytes and keeps the CR, and parse_row strips it.
        # Accented and CJK titles survive both paths. Column alignment matches.
        expected = expected_levels()
        lf = insert_text(tuple_lines(), "\n").encode("utf-8")
        crlf = insert_text(tuple_lines(), "\r\n").encode("utf-8")
        sources = (
            self.write_sql(lf, "lf.sql"),
            self.write_sql(crlf, "crlf.sql"),
            self.write_zip(lf, "lf.zip"),
            self.write_zip(crlf, "crlf.zip"),
            self.write_sql(b"\xef\xbb\xbf" + crlf, "bom-crlf.sql"),
            self.write_zip(b"\xef\xbb\xbf" + lf, "bom-lf.zip"),
        )
        for path in sources:
            with self.subTest(path=path.name):
                parsed = audit.parse_world_quest_levels(path)
                self.assertEqual(parsed, expected)
                for qid, record in parsed.items():
                    self.assertIsInstance(qid, int)
                    self.assertIsInstance(record["requiredLevel"], int)
                    self.assertIsInstance(record["questLevel"], int)
                    self.assertNotEqual(record["requiredLevel"], qid)
                    self.assertNotEqual(record["questLevel"], qid)

    def test_invalid_utf8_is_replaced_without_shifting_levels(self):
        # POTENTIAL ISSUE: invalid UTF-8 does not raise. sql_lines uses
        # errors="replace", so 0xFF becomes U+FFFD and the row is returned.
        # MinLevel and QuestLevel stay in their columns for a plain file and
        # for a ZIP.
        body = insert_text(["(910430, 'caf\ufffd', 41, 51);"]).encode("utf-8")
        # The escape above is the replacement character itself. Overwrite the
        # title with a single illegal byte so the file is not valid UTF-8.
        marker = "caf\ufffd".encode("utf-8")
        self.assertIn(marker, body)
        data = body.replace(marker, b"caf\xff", 1)
        self.assertIn(b"caf\xff", data)
        expected = {910430: {"name": "caf\ufffd", "requiredLevel": 41, "questLevel": 51}}
        for path in (self.write_sql(data, "bad.sql"), self.write_zip(data, "bad.zip")):
            with self.subTest(path=path.name):
                self.assertEqual(audit.parse_world_quest_levels(path), expected)

    def test_carriage_return_inside_a_title_differs_for_a_zip(self):
        # POTENTIAL ISSUE: the same CR byte inside a quoted title is a line
        # break in a plain file and a character in a ZIP. The file is refused.
        # The ZIP returns the CR inside the title and keeps 44 / 55 aligned.
        text = insert_text(["(910360, 'fir\rst', 44, 55);"])
        data = text.encode("utf-8")
        self.assertIn(b"\r", data)
        plain = self.write_sql(data, "cr-title.sql")
        with self.assertRaises(ValueError) as caught:
            audit.parse_world_quest_levels(plain)
        self.assertEqual(str(caught.exception), "Expected one HeidiSQL tuple per row")
        self.assertNotIn("fir", str(caught.exception))
        self.assertIsNone(caught.exception.__cause__)
        zipped = self.write_zip(data, "cr-title.zip")
        self.assertEqual(audit.parse_world_quest_levels(zipped), {
            910360: {"name": "fir\rst", "requiredLevel": 44, "questLevel": 55},
        })

    def test_real_newline_inside_quotes_is_refused(self):
        # VERIFIED: a real LF inside quotes is split by sql_lines before
        # parse_row, for both a plain file and a ZIP. The refusal text is the
        # fixed tuple message and does not contain the title.
        data = insert_text(["(910361, 'SENTINEL_QUOTE_ROW_DO_NOT_ECHO_910361\nsecond', 45, 56);"]).encode("utf-8")
        for path in (self.write_sql(data, "nl.sql"), self.write_zip(data, "nl.zip")):
            with self.subTest(path=path.name):
                with self.assertRaises(ValueError) as caught:
                    audit.parse_world_quest_levels(path)
                self.assertEqual(str(caught.exception), "Expected one HeidiSQL tuple per row")
                self.assertNotIn("SENTINEL_QUOTE_ROW_DO_NOT_ECHO_910361", str(caught.exception))
                self.assertNotIn("910361", str(caught.exception))

    def test_odd_trailing_backslash_is_refused_without_the_row(self):
        # POTENTIAL ISSUE: one backslash immediately before the closing quote
        # escapes that quote (an odd trailing-backslash count). The row is not
        # returned, so MinLevel and QuestLevel cannot land in another column.
        # The message does not echo the source tuple. The even form is covered
        # by quest 910413 above.
        line = "(910501, 'SENTINEL_QUOTE_ROW_DO_NOT_ECHO_910501\\', 61, 71),"
        self.assertTrue(line.endswith("\\', 61, 71),"))
        with self.assertRaises(ValueError) as caught:
            exporter.parse_row(line, COLUMNS)
        self.assertEqual(str(caught.exception), "Incorrect SQL tuple width")
        self.assertNotIn("SENTINEL_QUOTE_ROW_DO_NOT_ECHO_910501", str(caught.exception))
        self.assertNotIn("910501", str(caught.exception))
        self.assertIsNone(caught.exception.__cause__)
        data = insert_text([line[:-1] + ";"]).encode("utf-8")
        for path in (self.write_sql(data, "odd.sql"), self.write_zip(data, "odd.zip")):
            with self.subTest(path=path.name):
                with self.assertRaises(ValueError) as caught_file:
                    audit.parse_world_quest_levels(path)
                self.assertEqual(str(caught_file.exception), "Incorrect SQL tuple width")
                self.assertNotIn("SENTINEL", str(caught_file.exception))

    def test_double_quoted_comma_is_refused(self):
        # POTENTIAL ISSUE: a comma inside double quotes is a delimiter, because
        # the only quotechar is the single quote. The width check refuses the
        # row instead of returning 63 or 64 in the wrong column.
        line = '(910372, "North, east", 63, 64),'
        with self.assertRaises(ValueError) as caught:
            exporter.parse_row(line, COLUMNS)
        self.assertEqual(str(caught.exception), "Incorrect SQL tuple width")
        self.assertNotIn("North", str(caught.exception))
        self.assertNotIn("910372", str(caught.exception))
        data = insert_text(['(910372, "North, east", 63, 64);']).encode("utf-8")
        with self.assertRaisesRegex(ValueError, "^Incorrect SQL tuple width$"):
            audit.parse_world_quest_levels(self.write_sql(data, "dq.sql"))

    def test_unescaped_apostrophe_corrupts_or_refuses(self):
        # POTENTIAL ISSUE: an apostrophe that is neither \\' nor '' is not a
        # hard error by itself. 'x'y' is returned as xy' (apostrophe dropped,
        # a quote appended) while 44 and 55 stay in MinLevel and QuestLevel.
        quiet = exporter.parse_row("(910370, 'x'y', 44, 55),", COLUMNS)
        self.assertEqual(quiet, {
            "ID": "910370", "LogTitle": "xy'", "MinLevel": "44", "QuestLevel": "55",
        })
        data = insert_text(["(910370, 'x'y', 44, 55);"]).encode("utf-8")
        self.assertEqual(audit.parse_world_quest_levels(self.write_sql(data, "bare.sql")), {
            910370: {"name": "xy'", "requiredLevel": 44, "questLevel": 55},
        })
        # Once a comma follows that broken quote, the width changes. Current
        # behaviour raises and does not return a shifted level.
        broken = "(910371, 'hero's path, continued', 61, 62),"
        with self.assertRaises(ValueError) as caught:
            exporter.parse_row(broken, COLUMNS)
        self.assertEqual(str(caught.exception), "Incorrect SQL tuple width")
        self.assertNotIn("hero", str(caught.exception))
        self.assertNotIn("continued", str(caught.exception))
        refused = insert_text(["(910371, 'hero's path, continued', 61, 62);"]).encode("utf-8")
        with self.assertRaisesRegex(ValueError, "^Incorrect SQL tuple width$"):
            audit.parse_world_quest_levels(self.write_sql(refused, "bare-comma.sql"))

    def test_cli_refusal_prints_a_fixed_line(self):
        # What the programs print on refusal is the fixed sentence below.
        # The source row, including the sentinel title, is not on stdout or
        # stderr. No review file is created.
        root = self.folder / "questie-root"
        raw = root / audit.QUESTIE_RAW
        raw.parent.mkdir(parents=True)
        raw.write_text('[910001] = {"Synthetic Fixture",{},{},1,2},\n', encoding="utf-8")
        for relative in audit.LEVEL_FIXES:
            path = root / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(
                "function QuestieSyntheticFixes:Load()\n"
                "    return {\n"
                "    }\n"
                "end\n",
                encoding="utf-8",
            )
        repo = Path(__file__).resolve().parents[1]
        width = insert_text([
            "(910501, 'SENTINEL_QUOTE_ROW_DO_NOT_ECHO_910501\\', 61, 71);",
        ]).encode("utf-8")
        shape = insert_text([
            "(910510, 'SENTINEL_QUOTE_ROW_DO_NOT_ECHO_910510', 62, 72",
        ]).encode("utf-8")
        cases = (
            ("export_world_quests.py", "width.sql", width, "910501",
             "N-Questie export failed: Incorrect SQL tuple width\n"),
            ("export_world_quests.py", "shape.sql", shape, "910510",
             "N-Questie export failed: Expected one HeidiSQL tuple per row\n"),
            ("audit_world_quest_levels.py", "audit-width.sql", width, None,
             "N-Questie level audit refused: Incorrect SQL tuple width\n"),
            ("audit_world_quest_levels.py", "audit-shape.sql", shape, None,
             "N-Questie level audit refused: Expected one HeidiSQL tuple per row\n"),
        )
        for script, name, data, quest, stderr in cases:
            with self.subTest(script=script, name=name):
                world = self.write_sql(data, name)
                report = self.folder / (name + ".json")
                command = [sys.executable, str(repo / "tools" / script)]
                if quest is None:
                    command.extend(["--questie-root", str(root)])
                else:
                    command.extend(["--quest", quest])
                command.extend(["--world", str(world), "--output", str(report)])
                completed = subprocess.run(
                    command, cwd=repo, capture_output=True, text=True, check=False,
                )
                self.assertEqual(completed.returncode, 1)
                self.assertEqual(completed.stdout, "")
                self.assertEqual(completed.stderr, stderr)
                self.assertNotIn("SENTINEL_QUOTE_ROW_DO_NOT_ECHO", completed.stderr)
                self.assertNotIn("SENTINEL_QUOTE_ROW_DO_NOT_ECHO", completed.stdout)
                self.assertNotIn("INSERT INTO", completed.stderr)
                self.assertFalse(report.exists())


if __name__ == "__main__":
    unittest.main()
