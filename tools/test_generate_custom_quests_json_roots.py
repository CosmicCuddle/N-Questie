#!/usr/bin/env python3
"""Fail-closed checks for invalid top-level JSON roots in the offline generator.

The invented quest 2001 fixture matches tools/test_generate_custom_quests.py.
Nothing here reads a server dump or a private review file. Each case invokes
tools/generate_custom_quests.py with sys.executable so the script entrypoint
is what maps ValueError and JSONDecodeError to SystemExit(1), a one-line
stderr refusal, and no traceback. Calling main() directly would let those
exceptions propagate instead of exercising that handler.
"""
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

import generate_custom_quests as generator


# Required top-level keys from generate():
#   set(review) != {"format", "quests"}
REQUIRED_TOP_LEVEL = ("format", "quests")
SENTINEL = "NQ_JSON_ROOT_SENTINEL_7f3a9c2e"
STRUCTURE_ERROR = (
    "N-Questie Lua generation refused: Unexpected review document structure\n"
)
GENERATOR = Path(__file__).resolve().parent / "generate_custom_quests.py"
REPO_ROOT = GENERATOR.parent.parent


def quest(qid=2001):
    return {
        "id": qid, "title": "Ravenclaw Cleanup",
        "required_level": 12, "quest_level": 16, "zone_or_sort": 130,
        "required_races": 690, "quest_flags": 8,
        "pre_quest_single": [437], "starter_npcs": [2121],
        "ender_npcs": [2121],
        "kill_objectives": [{"npc": 1868, "count": 8},
                            {"npc": 1869, "count": 8}],
        "requires_review": ["Confirm existing Questie NPC spawn positions"],
    }


def valid_looking_quest():
    """Quest-shaped object nested under an invalid root, with a leak sentinel."""
    record = quest()
    record["title"] = SENTINEL
    record["requires_review"] = [SENTINEL]
    if set(record) != generator.FIELDS:
        raise AssertionError("quest fixture drifted from generator.FIELDS")
    return record


def reviewed(*records):
    return {"format": generator.FORMAT, "quests": list(records)}


def invalid_payloads():
    looking = valid_looking_quest()
    payloads = [
        ("null", "null", "structure"),
        ("number", "0", "structure"),
        ("string", json.dumps(SENTINEL), "structure"),
        ("true", "true", "structure"),
        ("empty_list", "[]", "structure"),
        ("list_of_quest", json.dumps([looking]), "structure"),
        ("empty_object", "{}", "structure"),
        ("missing_format", json.dumps({"quests": [looking]}), "structure"),
        ("missing_quests", json.dumps({"format": generator.FORMAT}), "structure"),
        ("empty_file", "", "decode"),
        ("invalid_json", "{" + SENTINEL, "decode"),
    ]
    present = {name for name, _text, _kind in payloads}
    for key in REQUIRED_TOP_LEVEL:
        if "missing_" + key not in present:
            raise AssertionError("no payload for missing required key " + key)
    return payloads


def repository_status():
    result = subprocess.run(
        ["git", "status", "--porcelain"],
        cwd=REPO_ROOT,
        capture_output=True,
        text=True,
        timeout=30,
        check=False,
    )
    if result.returncode != 0:
        raise AssertionError(result.stderr)
    return result.stdout


def run_generator(review, output, revision, overwrite=False):
    argv = [
        sys.executable, str(GENERATOR),
        "--review", str(review),
        "--approved-quest", "2001",
        "--verified-npc", "2121",
        "--verified-npc", "1868",
        "--verified-npc", "1869",
        "--revision", str(revision),
        "--output", str(output),
    ]
    if overwrite:
        argv.append("--overwrite")
    return subprocess.run(
        argv,
        cwd=review.parent,
        capture_output=True,
        text=True,
        timeout=30,
        check=False,
    )


def write_review(path, text):
    path.write_text(text, encoding="utf-8")


class InvalidJsonRootTests(unittest.TestCase):
    def setUp(self):
        self.status_before = repository_status()

    def tearDown(self):
        self.assertEqual(repository_status(), self.status_before)

    def assert_closed_stderr(self, result, kind):
        self.assertEqual(result.returncode, 1)
        self.assertEqual(result.stdout, "")
        self.assertNotIn("Traceback", result.stderr)
        self.assertNotIn(SENTINEL, result.stderr)
        self.assertNotIn("Ravenclaw Cleanup", result.stderr)
        if kind == "structure":
            self.assertEqual(result.stderr, STRUCTURE_ERROR)
        else:
            self.assertEqual(result.stderr.count("\n"), 1)
            self.assertTrue(
                result.stderr.startswith(
                    "N-Questie Lua generation refused: Expecting "
                )
            )

    def assert_only_names(self, directory, names):
        found = sorted(path.name for path in directory.iterdir())
        self.assertEqual(found, sorted(names))

    def seed_generated_output(self, directory):
        review = directory / "review.json"
        output = directory / "curated.lua"
        write_review(review, json.dumps(reviewed(quest())))
        created = run_generator(review, output, revision=2)
        self.assertEqual(created.returncode, 0, created.stderr)
        self.assertEqual(created.stderr, "")
        before = output.read_bytes()
        self.assertIn(b"revision = 2", before)
        self.assertIn(b"[2001]", before)
        self.assertNotIn(SENTINEL.encode("ascii"), before)
        return review, output, before

    def test_valid_minimal_document_generates_lua(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            review = directory / "review.json"
            output = directory / "curated.lua"
            write_review(review, json.dumps(reviewed(quest())))
            result = run_generator(review, output, revision=2)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(result.stderr, "")
            self.assertNotIn("Traceback", result.stdout)
            self.assertIn(
                "Generated curated Lua records for 1 approved quests.",
                result.stdout,
            )
            text = output.read_text(encoding="utf-8")
            self.assertIn("revision = 2", text)
            self.assertIn("[2001] = {", text)
            self.assertIn('name = "Ravenclaw Cleanup"', text)
            self.assertNotIn(SENTINEL, text)
            self.assert_only_names(directory, ["review.json", "curated.lua"])
            self.assertEqual(output.resolve().parent, directory.resolve())

    def test_invalid_roots_do_not_create_output(self):
        for name, text, kind in invalid_payloads():
            with self.subTest(case=name):
                with tempfile.TemporaryDirectory() as temporary:
                    directory = Path(temporary)
                    review = directory / "review.json"
                    output = directory / "curated.lua"
                    write_review(review, text)
                    self.assertFalse(output.exists())
                    result = run_generator(review, output, revision=2)
                    self.assert_closed_stderr(result, kind)
                    self.assertFalse(output.exists())
                    self.assert_only_names(directory, ["review.json"])
                    self.assertEqual(review.read_text(encoding="utf-8"), text)

    def test_existing_output_unchanged_without_overwrite(self):
        # The overwrite guard runs before json.load. Exit 2 is argparse's
        # refusal; the review bytes are not the error text.
        for name, text, _kind in invalid_payloads():
            with self.subTest(case=name):
                with tempfile.TemporaryDirectory() as temporary:
                    directory = Path(temporary)
                    review, output, before = self.seed_generated_output(directory)
                    write_review(review, text)
                    result = run_generator(review, output, revision=3)
                    self.assertEqual(result.returncode, 2)
                    self.assertEqual(result.stdout, "")
                    self.assertIn(
                        "Output exists; pass --overwrite only after comparing revisions",
                        result.stderr,
                    )
                    self.assertNotIn("Traceback", result.stderr)
                    self.assertNotIn(SENTINEL, result.stderr)
                    self.assertNotIn("N-Questie Lua generation refused:", result.stderr)
                    self.assertEqual(output.read_bytes(), before)
                    self.assert_only_names(directory, ["review.json", "curated.lua"])

    def test_existing_output_unchanged_with_overwrite(self):
        # revision 3 is higher than the seeded revision 2, so the run reaches
        # JSON parsing instead of stopping on the revision guard.
        for name, text, kind in invalid_payloads():
            with self.subTest(case=name):
                with tempfile.TemporaryDirectory() as temporary:
                    directory = Path(temporary)
                    review, output, before = self.seed_generated_output(directory)
                    write_review(review, text)
                    result = run_generator(
                        review, output, revision=3, overwrite=True
                    )
                    self.assert_closed_stderr(result, kind)
                    self.assertEqual(output.read_bytes(), before)
                    self.assert_only_names(directory, ["review.json", "curated.lua"])


if __name__ == "__main__":
    unittest.main()
