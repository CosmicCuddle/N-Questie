#!/usr/bin/env python3
"""Synthetic offline tests. No private world export or credentials."""
import json
import tempfile
import unittest
import zipfile
from pathlib import Path

import audit_world_quest_levels as audit


RAW = '''
QuestieDB.questData = {
[1202] = {"Jarl Needs Eyes",{{4792}},{{4792}},30,35,0,nil,{"Bring 20 eyes"},nil,nil},
[1203] = {"Jarl Needs a Blade",{{4792}},{{4792}},30,35,0,nil,{"Bring Razorspine's Sword to \\"Swamp Eye\\" Jarl"},nil,{nil,nil,{{33110}}}},
[2001] = {"Ravenclaw Cleanup",{{2121}},{{2121}},12,16,690,nil,nil,nil,{{{1868},{1869}}}},
}
'''

CORRECTION = """
function QuestieWotlkQuestFixes:Load()
    local questKeys = QuestieDB.questKeys
    return {
        [1202] = {
            [questKeys.questLevel] = 34,
            [questKeys.requiredLevel] = 27,
        },
        [1203] = {
            [questKeys.questLevel] = -1,
        },
        [1204] = {
            [questKeys.questLevel] = dynamicLevel(),
        },
    }
end
"""


def sql_fixture(level=26, min_level=20):
    tick = chr(96)
    cols = ("ID", "LogTitle", "MinLevel", "QuestLevel")
    header = "INSERT INTO " + tick + "quest_template" + tick + " (" + ", ".join(
        tick + col + tick for col in cols
    ) + ") VALUES\n"
    return header + "(1202, 'Jarl Needs Eyes', 30, 35),\n" + (
        "(1203, 'Jarl Needs a Blade', %d, %d),\n" % (min_level, level)
    ) + "(2001, 'Ravenclaw Cleanup', 12, 16);\n"


class QuestLevelAuditTests(unittest.TestCase):
    def test_real_repository_jarl_record_and_literal_layers(self):
        # Public repo source only; no private acore_world required.
        root = Path(__file__).resolve().parents[1]
        raw, skipped = audit.parse_questie_raw(
            (root / audit.QUESTIE_RAW).read_text(encoding="utf-8")
        )
        self.assertGreater(len(raw), 5000)
        self.assertEqual(skipped, [], "Generated WotLK quest records must all parse")
        self.assertEqual(raw[1203]["name"], "Jarl Needs a Blade")
        self.assertEqual(raw[1203]["requiredLevel"], 30)
        self.assertEqual(raw[1203]["questLevel"], 35)
        # Explicitly fail if the inherited source acquires an unresolved Jarl fix.
        for name in audit.LEVEL_FIXES:
            overrides, unknown = audit.parse_static_level_fixes(
                (root / name).read_text(encoding="utf-8")
            )
            self.assertNotIn(1203, overrides)
            self.assertNotIn(1203, unknown)

    def test_parse_generated_lua_nested_quests(self):
        quests, skipped = audit.parse_questie_raw(RAW)
        self.assertEqual(skipped, [])
        self.assertEqual(quests[1203]["requiredLevel"], 30)
        self.assertEqual(quests[1203]["questLevel"], 35)
        self.assertEqual(quests[2001]["questLevel"], 16)

    def test_commas_and_escapes_in_lua(self):
        fields = audit.lua_fields(r'"a, \"quote\" text", {{12,15},{16,17}}, nil, 30, 35')
        self.assertEqual(len(fields), 5)
        self.assertEqual(fields[3:], ["30", "35"])

    def test_parse_static_layer_and_dynamic_guard(self):
        overrides, unresolved = audit.parse_static_level_fixes(CORRECTION)
        self.assertEqual(overrides[1202], {"questLevel": 34, "requiredLevel": 27})
        self.assertEqual(overrides[1203], {"questLevel": -1})
        self.assertIn(1204, unresolved)

    def test_missing_fix_table_rejected(self):
        with self.assertRaisesRegex(ValueError, "Missing expected"):
            audit.parse_static_level_fixes("nothing useful")

    def test_private_server_sql_and_zip(self):
        with tempfile.TemporaryDirectory() as temp:
            folder = Path(temp)
            sql = folder / "acore_world.sql"
            sql.write_text(sql_fixture(), encoding="utf-8")
            expected = audit.parse_world_quest_levels(sql)
            self.assertEqual(expected[1203]["questLevel"], 26)
            archive = folder / "world.zip"
            with zipfile.ZipFile(archive, "w") as output:
                output.writestr("acore_world.sql", sql_fixture())
            self.assertEqual(expected, audit.parse_world_quest_levels(archive))

    def test_mismatch_detection_with_literal_layer(self):
        raw, _ = audit.parse_questie_raw(RAW)
        server = {
            1202: {"name": "Jarl Needs Eyes", "questLevel": 34, "requiredLevel": 27},
            1203: {"name": "Jarl Needs a Blade", "questLevel": 26, "requiredLevel": 20},
        }
        result = audit.report_levels(server, raw, [
            ("classic", {1202: {"questLevel": 32}}, set()),
            ("wotlk", {1202: {"questLevel": 34, "requiredLevel": 27}}, set())
        ])
        self.assertEqual(result["summary"]["match"], 1)
        self.assertEqual(result["summary"]["mismatch"], 1)
        self.assertEqual(result["quests"][0]["id"], 1203)
        self.assertEqual(result["quests"][0]["different_fields"], ["requiredLevel", "questLevel"])
        self.assertEqual(result["quests"][0]["levels"]["questLevel"]["questie_raw"], 35)
        self.assertEqual(result["quests"][0]["levels"]["questLevel"]["server"], 26)

    def test_requested_match_is_included(self):
        raw, _ = audit.parse_questie_raw(RAW)
        server = {1203: {"name": "Jarl Needs a Blade", "questLevel": 35, "requiredLevel": 30}}
        result = audit.report_levels(server, raw, [], [1203])
        self.assertEqual(result["quests"][0]["status"], "match")

    def test_missing_quest_rejected(self):
        raw, _ = audit.parse_questie_raw(RAW)
        with self.assertRaisesRegex(ValueError, "missing from world export"):
            audit.report_levels({}, raw, [], [1203])

    def test_negative_dynamic_quest_requires_review(self):
        raw, _ = audit.parse_questie_raw(RAW)
        server = {1203: {"name": "Jarl Needs a Blade", "questLevel": -2, "requiredLevel": 30}}
        report = audit.report_levels(server, raw, [("wotlk", {}, {1203})], [1203])
        self.assertEqual(report["quests"][0]["status"], "needs_review")

    def test_refuse_private_output_inside_repo(self):
        with tempfile.TemporaryDirectory() as temp:
            base = Path(temp)
            root = base / "public-repo"
            root.mkdir()
            self.assertTrue(audit.inside(root / "report.json", root))
            self.assertFalse(audit.inside(base / "private" / "report.json", root))

    def test_full_cli_synthetic_audit(self):
        with tempfile.TemporaryDirectory() as temp:
            base = Path(temp)
            root = base / "public-repo"
            raw_file = root / audit.QUESTIE_RAW
            raw_file.parent.mkdir(parents=True)
            raw_file.write_text(RAW, encoding="utf-8")
            for fix in audit.LEVEL_FIXES:
                output = root / fix
                output.parent.mkdir(parents=True, exist_ok=True)
                output.write_text(CORRECTION, encoding="utf-8")
            world = base / "private-world.sql"
            world.write_text(sql_fixture(), encoding="utf-8")
            report_path = base / "private" / "level-review.json"
            args = ["--questie-root", str(root), "--world", str(world),
                    "--quest", "1203", "--output", str(report_path)]
            audit.main(args)
            report = json.loads(report_path.read_text(encoding="utf-8"))
            self.assertEqual(report["quests"][0]["id"], 1203)
            self.assertEqual(report["quests"][0]["status"], "mismatch")
            self.assertEqual(report["quests"][0]["levels"]["questLevel"]["server"], 26)
            with self.assertRaises(SystemExit):
                audit.main(args)
            with self.assertRaises(SystemExit):
                audit.main(args[:args.index("--output") + 1] + [str(root / "unsafe.json")])


if __name__ == "__main__":
    unittest.main()
