#!/usr/bin/env python3
"""Pin record counts, unique quest IDs, and stable report order.

Invented rows only (public-style IDs such as 2001 and 9999). No private world
export is read or required. Every output path is under tempfile and is refused
if it falls inside the repository tree.

NOT RUN IN CI. The overlay workflow executes tools/test_audit_world_quest_levels.py
only. This module is a local contract pin (DEV-066) and does not change the audit.
"""
import io
import json
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path

import audit_world_quest_levels as audit


# Questie side deliberately omits 9999. Levels are the raw baseline.
RAW = """
QuestieDB.questData = {
[2001] = {"Invented Differ",{},{},10,14},
[3333] = {"Invented Last Row",{},{},1,1},
[4100] = {"Invented Match Mid",{},{},20,25},
[5005] = {"Invented Match High",{},{},40,45},
[7777] = {"Invented Needs Review",{},{},5,8},
[8888] = {"Invented Partial Diff",{},{},15,22},
}
"""

# Physical order is not ID order. 5005 is first and 3333 is last so a dropped
# first or last tuple changes the parsed ID set. 3333 differs from Questie by
# exactly one quest level (1 vs 2), which an off-by-one comparison would hide.
ORDER_A = (
    (5005, "Invented Match High", 40, 45),
    (8888, "Invented Partial Diff", 15, 30),
    (9999, "Invented Absent", 60, 70),
    (4100, "Invented Match Mid", 20, 25),
    (2001, "Invented Differ", 12, 16),
    (7777, "Invented Needs Review", 5, -2),
    (3333, "Invented Last Row", 1, 2),
)
# Same seven rows, opposite physical order, so a last-row skip drops 2001 here
# and 3333 in ORDER_A. Sorted report output must still match.
ORDER_B = tuple(reversed(ORDER_A))

EXPECTED_IDS = (2001, 3333, 4100, 5005, 7777, 8888, 9999)
# Full-audit rows omit matches and Questie-absent IDs. Needs-review stays in
# the discrepancy list. Order is ascending ID, not input order.
FULL_AUDIT_ROW_IDS = (2001, 3333, 7777, 8888)
EMPTY_CORRECTION = """
function QuestieSyntheticFixes:Load()
    local questKeys = QuestieDB.questKeys
    return {
    }
end
"""


def world_sql(rows):
    tick = chr(96)
    cols = ("ID", "LogTitle", "MinLevel", "QuestLevel")
    header = "INSERT INTO " + tick + "quest_template" + tick + " (" + ", ".join(
        tick + col + tick for col in cols
    ) + ") VALUES\n"
    lines = []
    for index, (qid, name, min_level, quest_level) in enumerate(rows):
        end = ";" if index == len(rows) - 1 else ","
        lines.append("(%d, '%s', %d, %d)%s" % (qid, name, min_level, quest_level, end))
    return header + "\n".join(lines) + "\n"


def level_pair(server_required, server_quest, raw_required, raw_quest):
    return {
        "requiredLevel": {
            "server": server_required,
            "questie_raw": raw_required,
            "questie_after_literal_fixes": raw_required,
            "literal_fix_source": None,
        },
        "questLevel": {
            "server": server_quest,
            "questie_raw": raw_quest,
            "questie_after_literal_fixes": raw_quest,
            "literal_fix_source": None,
        },
    }


def compared_row(qid, name, status, fields, levels, caution=None):
    return {
        "id": qid,
        "name": name,
        "questie_name": name,
        "status": status,
        "different_fields": list(fields),
        "levels": levels,
        "caution": caution,
    }


def expected_full_rows():
    caution = "Dynamic correction or unusual negative level requires manual review"
    return [
        compared_row(2001, "Invented Differ", "mismatch",
                     ["requiredLevel", "questLevel"],
                     level_pair(12, 16, 10, 14)),
        compared_row(3333, "Invented Last Row", "mismatch",
                     ["questLevel"],
                     level_pair(1, 2, 1, 1)),
        compared_row(7777, "Invented Needs Review", "needs_review",
                     ["questLevel"],
                     level_pair(5, -2, 5, 8), caution),
        compared_row(8888, "Invented Partial Diff", "mismatch",
                     ["questLevel"],
                     level_pair(15, 30, 15, 22)),
    ]


def expected_summary():
    return {
        "server_quests": 7,
        "questie_raw_quests": 6,
        "questie_unparsed_rows": 0,
        "checked": 7,
        "match": 2,
        "mismatch": 3,
        "needs_review": 1,
        "missing_questie": 1,
    }


class AuditCountAndOrderTests(unittest.TestCase):
    def setUp(self):
        self.repo = Path(__file__).resolve().parents[1]

    def parse_world(self, rows):
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "invented-world.sql"
            self.assertFalse(audit.inside(path, self.repo))
            path.write_text(world_sql(rows), encoding="utf-8")
            return audit.parse_world_quest_levels(path)

    def test_known_dataset_counts_and_exact_order(self):
        raw, skipped = audit.parse_questie_raw(RAW)
        self.assertEqual(skipped, [])
        self.assertEqual(tuple(sorted(raw)), EXPECTED_IDS[:-1])
        self.assertNotIn(9999, raw)

        server = self.parse_world(ORDER_A)
        # Seven SQL tuples, seven unique IDs. The first physical row (5005)
        # and the last physical row (3333) must both survive.
        self.assertEqual(len(ORDER_A), 7)
        self.assertEqual(len(server), 7)
        self.assertEqual(tuple(sorted(server)), EXPECTED_IDS)
        self.assertEqual(len(server), len(set(server)))
        self.assertEqual(server[5005]["requiredLevel"], 40)
        self.assertEqual(server[5005]["questLevel"], 45)
        self.assertEqual(server[3333]["name"], "Invented Last Row")
        self.assertEqual(server[3333]["requiredLevel"], 1)
        self.assertEqual(server[3333]["questLevel"], 2)
        self.assertEqual(server[9999]["questLevel"], 70)

        report = audit.report_levels(server, raw, [])
        summary = report["summary"]
        self.assertEqual(summary, expected_summary())
        # The tool has no single discrepancy field. Non-matches are the three
        # separate counters; their sum plus matches equals records checked.
        non_matches = (summary["mismatch"] + summary["needs_review"]
                       + summary["missing_questie"])
        self.assertEqual(non_matches, 5)
        self.assertEqual(summary["match"] + non_matches, summary["checked"])
        self.assertEqual(summary["checked"], summary["server_quests"])
        self.assertEqual(summary["server_quests"], len(server))

        rows = report["quests"]
        ids = [row["id"] for row in rows]
        file_order = [qid for qid, _name, _min_level, _quest_level in ORDER_A
                      if qid in set(FULL_AUDIT_ROW_IDS)]
        self.assertEqual(file_order, [8888, 2001, 7777, 3333])
        self.assertNotEqual(ids, file_order)
        self.assertEqual(ids, list(FULL_AUDIT_ROW_IDS))
        self.assertEqual(ids, sorted(ids))
        self.assertEqual(len(ids), len(set(ids)))
        self.assertEqual(len(rows), summary["mismatch"] + summary["needs_review"])
        self.assertEqual(rows, expected_full_rows())
        # 9999 is counted as missing Questie data and is not emitted on a
        # full audit. 4100 and 5005 match and are not emitted either.
        self.assertNotIn(9999, ids)
        self.assertNotIn(4100, ids)
        self.assertNotIn(5005, ids)

        selected_order = [9999, 5005, 2001, 3333, 8888, 7777, 4100]
        selected = audit.report_levels(server, raw, [], selected_order)
        self.assertEqual(selected["summary"], expected_summary())
        selected_ids = [row["id"] for row in selected["quests"]]
        self.assertEqual(selected_ids, list(EXPECTED_IDS))
        self.assertEqual(len(selected_ids), len(set(selected_ids)))
        self.assertEqual(selected["quests"][2]["id"], 4100)
        self.assertEqual(selected["quests"][2]["status"], "match")
        self.assertEqual(selected["quests"][2]["different_fields"], [])
        self.assertEqual(selected["quests"][3]["status"], "match")
        self.assertEqual(selected["quests"][-1], {
            "id": 9999, "name": "Invented Absent", "status": "missing_questie",
        })
        # Repeated selected IDs are a set: one checked row, not two.
        collapsed = audit.report_levels(server, raw, [], [2001, 3333, 2001])
        self.assertEqual(collapsed["summary"]["checked"], 2)
        self.assertEqual([row["id"] for row in collapsed["quests"]], [2001, 3333])

    def test_order_stable_across_runs_and_input_permutations(self):
        raw, _skipped = audit.parse_questie_raw(RAW)
        first = audit.report_levels(self.parse_world(ORDER_A), raw, [])
        second = audit.report_levels(self.parse_world(ORDER_A), raw, [])
        reversed_input = audit.report_levels(self.parse_world(ORDER_B), raw, [])
        rendered = json.dumps(first, indent=2, ensure_ascii=False) + "\n"
        self.assertEqual(rendered, json.dumps(second, indent=2, ensure_ascii=False) + "\n")
        self.assertEqual(rendered,
                         json.dumps(reversed_input, indent=2, ensure_ascii=False) + "\n")
        self.assertEqual([row["id"] for row in reversed_input["quests"]],
                         list(FULL_AUDIT_ROW_IDS))
        self.assertEqual(self.parse_world(ORDER_A), self.parse_world(ORDER_B))

        server = self.parse_world(ORDER_A)
        forward = [9999, 5005, 2001, 3333, 8888, 7777, 4100]
        backward = list(reversed(forward))
        left = audit.report_levels(server, raw, [], forward)
        right = audit.report_levels(server, raw, [], backward)
        self.assertEqual(json.dumps(left, indent=2, ensure_ascii=False),
                         json.dumps(right, indent=2, ensure_ascii=False))
        self.assertEqual([row["id"] for row in left["quests"]], list(EXPECTED_IDS))

    def test_cli_json_bytes_identical_and_outside_repo(self):
        with tempfile.TemporaryDirectory() as temp:
            base = Path(temp)
            self.assertFalse(audit.inside(base, self.repo))
            root = base / "public-repo"
            raw_path = root / audit.QUESTIE_RAW
            raw_path.parent.mkdir(parents=True)
            raw_path.write_text(RAW, encoding="utf-8")
            for fix in audit.LEVEL_FIXES:
                destination = root / fix
                destination.parent.mkdir(parents=True, exist_ok=True)
                destination.write_text(EMPTY_CORRECTION, encoding="utf-8")

            def write_report(rows, name):
                world = base / (name + ".sql")
                report = base / "private" / (name + ".json")
                self.assertFalse(audit.inside(world, self.repo))
                self.assertFalse(audit.inside(report, self.repo))
                self.assertFalse(audit.inside(report, root))
                world.write_text(world_sql(rows), encoding="utf-8")
                args = ["--questie-root", str(root), "--world", str(world),
                        "--output", str(report)]
                with redirect_stdout(io.StringIO()):
                    audit.main(args)
                self.assertTrue(report.is_file())
                return report.read_bytes()

            first = write_report(ORDER_A, "run-a")
            second = write_report(ORDER_A, "run-b")
            third = write_report(ORDER_B, "run-c")
            self.assertEqual(first, second)
            self.assertEqual(first, third)
            payload = json.loads(first.decode("utf-8"))
            self.assertEqual(payload["summary"], expected_summary())
            self.assertEqual([row["id"] for row in payload["quests"]],
                             list(FULL_AUDIT_ROW_IDS))
            self.assertEqual(payload["quests"], expected_full_rows())
            self.assertTrue(first.endswith(b"\n"))

    def test_duplicate_world_quest_id_rejected(self):
        # Explicit contract: a repeated positive ID aborts the parse. The
        # second tuple is not kept, and the first is not returned as a report.
        repeated = ORDER_A + ((2001, "Invented Differ Again", 99, 98),)
        self.assertEqual(len(repeated), 8)
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "repeated.sql"
            path.write_text(world_sql(repeated), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "Invalid or repeated world quest ID 2001"):
                audit.parse_world_quest_levels(path)
            # The same ID in a later INSERT is still one namespace, not per statement.
            split = world_sql(((2001, "Invented Differ", 12, 16),)) + "\n" + world_sql(
                ((2001, "Invented Differ Again", 99, 98),))
            other = Path(temp) / "split-insert.sql"
            other.write_text(split, encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "Invalid or repeated world quest ID 2001"):
                audit.parse_world_quest_levels(other)

    def test_duplicate_questie_id_rejected(self):
        duplicate = RAW + '[2001] = {"Invented Differ Copy",{},{},99,98},\n'
        with self.assertRaisesRegex(ValueError, "Duplicate Questie quest ID 2001"):
            audit.parse_questie_raw(duplicate)

    def test_repeated_correction_id_policy_is_not_stated(self):
        # parse_static_level_fixes does not reject a repeated quest ID. A later
        # literal for the same field overwrites the earlier one, and a second
        # correction file can overwrite a field from an earlier file. The source
        # never says whether first, last, or reject is required. World SQL and
        # Questie raw duplicates are explicit rejects and are pinned above.
        # Choosing a correction policy here would overlap DEV-063.
        self.skipTest(
            "UNKNOWN policy: repeated correction quest IDs are not rejected; "
            "last literal assignment is what the code does today, but that "
            "policy is not stated (DEV-063 overlap)"
        )


if __name__ == "__main__":
    unittest.main()
