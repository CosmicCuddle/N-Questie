#!/usr/bin/env python3
"""Pin the current numeric checks in tools/generate_custom_quests.py.

NOT RUN IN CI. The overlay workflow runs tools/test_generate_custom_quests.py
only. Adding a workflow step for this file needs maintainer approval.

The fixtures are the invented public quest 2001 / NPC 2121 records already
used by the generator tests. Every review file and Lua output stays inside
tempfile.TemporaryDirectory. This module records today's refusal and
acceptance behaviour; it does not define a new validation policy.
"""
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

import generate_custom_quests as generator


SCRIPT = Path(__file__).resolve().parent / "generate_custom_quests.py"
REFUSAL = "N-Questie Lua generation refused: "
OUTPUT_EXISTS = "Output exists; pass --overwrite only after comparing revisions"
REVISION_NOT_HIGHER = "New revision must be higher than existing generated revision"
VERIFIED_TOKENS = ("2121", "1868", "1869")
# type(value) is not int rejects these. Zero is included only for minimum 1.
NON_INTS = (1.5, True, False, "2001")
MIN_ONE_VALUES = NON_INTS + (-1, 0)
MIN_ZERO_VALUES = NON_INTS + (-1,)


def quest():
    return {
        "id": 2001,
        "title": "Ravenclaw Cleanup",
        "required_level": 12,
        "quest_level": 16,
        "zone_or_sort": 130,
        "required_races": 690,
        "quest_flags": 8,
        "pre_quest_single": [437],
        "starter_npcs": [2121],
        "ender_npcs": [2121],
        "kill_objectives": [
            {"npc": 1868, "count": 8},
            {"npc": 1869, "count": 8},
        ],
        "requires_review": ["Confirm existing Questie NPC spawn positions"],
    }


def reviewed(record):
    return {"format": generator.FORMAT, "quests": [record]}


def valid_document():
    return reviewed(quest())


def with_field(field, value):
    record = quest()
    record[field] = value
    return reviewed(record)


def with_objective(key, value):
    record = quest()
    record["kill_objectives"][0][key] = value
    return reviewed(record)


def with_id_list(field, value):
    record = quest()
    record[field] = [value]
    return reviewed(record)


def whole_message(label, minimum):
    return REFUSAL + label + " must be an integer >= " + str(minimum)


def json_cases():
    """Return (name, document, stderr snippet, value-error handler used)."""
    cases = []

    def add(name, document, snippet):
        cases.append((name, document, snippet, True))

    add("quest ID json 2001.0", with_field("id", 2001.0), whole_message("quest ID", 1))
    for value in MIN_ONE_VALUES:
        add("quest ID %r" % (value,), with_field("id", value), whole_message("quest ID", 1))
        add("quest_level %r" % (value,), with_field("quest_level", value),
            whole_message("quest_level", 1))
        add("kill NPC ID %r" % (value,), with_objective("npc", value),
            whole_message("kill NPC ID", 1))
        add("kill count %r" % (value,), with_objective("count", value),
            whole_message("kill count", 1))
        add("starter_npcs %r" % (value,), with_id_list("starter_npcs", value),
            whole_message("starter_npcs", 1))
        add("ender_npcs %r" % (value,), with_id_list("ender_npcs", value),
            whole_message("ender_npcs", 1))
        add("pre_quest_single %r" % (value,), with_id_list("pre_quest_single", value),
            whole_message("pre_quest_single", 1))
    for value in MIN_ZERO_VALUES:
        add("required_level %r" % (value,), with_field("required_level", value),
            whole_message("required_level", 0))
        add("required_races %r" % (value,), with_field("required_races", value),
            whole_message("required_races", 0))
        add("quest_flags %r" % (value,), with_field("quest_flags", value),
            whole_message("quest_flags", 0))
    for value in NON_INTS:
        add("zone_or_sort %r" % (value,), with_field("zone_or_sort", value),
            REFUSAL + "zone_or_sort must be an integer")
    return cases


def cli_args(review, output, revision="2", approved=("2001",), verified=VERIFIED_TOKENS,
             overwrite=False):
    tokens = (revision, *approved, *verified)
    if not all(isinstance(token, str) for token in tokens):
        raise AssertionError("CLI tokens must stay strings so argparse performs conversion")
    args = ["--review", str(review)]
    for token in approved:
        args.extend(["--approved-quest", token])
    for token in verified:
        args.extend(["--verified-npc", token])
    args.extend(["--revision", revision, "--output", str(output)])
    if overwrite:
        args.append("--overwrite")
    return args


class NumericJsonTypeTests(unittest.TestCase):
    def run_cli(self, args, directory):
        review = Path(args[args.index("--review") + 1])
        output = Path(args[args.index("--output") + 1])
        self.assertTrue(review.resolve().is_relative_to(directory.resolve()))
        self.assertTrue(output.resolve().is_relative_to(directory.resolve()))
        return subprocess.run(
            [sys.executable, str(SCRIPT), *args],
            cwd=directory,
            capture_output=True,
            text=True,
            timeout=15,
            check=False,
        )

    def assert_cli(self, completed, code, snippet, handled_value_error):
        details = completed.stdout + "\n" + completed.stderr
        self.assertEqual(code, completed.returncode, details)
        self.assertIn(snippet, completed.stderr)
        self.assertNotIn("Traceback (most recent call last)", completed.stderr)
        self.assertNotIn("Generated curated Lua records", completed.stdout)
        if handled_value_error:
            self.assertIn(REFUSAL, completed.stderr)
        else:
            self.assertNotIn(REFUSAL, completed.stderr)

    def write_json(self, path, document):
        path.write_text(json.dumps(document), encoding="utf-8")

    def assert_refusal_preserves_files(self, document, args_for, fresh, bare, overwrite):
        """Fresh output is absent. An existing generated file keeps its bytes.

        ``bare`` is the no-overwrite invocation. ``overwrite`` passes
        --overwrite after a higher revision so validation itself, not the
        default overwrite guard, is what must refuse a partial write.
        """
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            review = directory / "review.json"
            output = directory / "curated.lua"
            self.write_json(review, document)
            completed = self.run_cli(args_for(review, output, "fresh"), directory)
            self.assert_cli(completed, *fresh)
            self.assertFalse(output.exists())
            self.assertEqual([], list(directory.glob("*.lua")))

        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            review = directory / "review.json"
            output = directory / "curated.lua"
            self.write_json(review, valid_document())
            created = self.run_cli(cli_args(review, output), directory)
            self.assertEqual(0, created.returncode, created.stdout + "\n" + created.stderr)
            original = output.read_bytes()
            self.assertIn(b"revision = 2", original)
            self.write_json(review, document)
            bare_run = self.run_cli(args_for(review, output, "bare"), directory)
            self.assert_cli(bare_run, *bare)
            self.assertEqual(original, output.read_bytes())
            replaced = self.run_cli(args_for(review, output, "overwrite"), directory)
            self.assert_cli(replaced, *overwrite)
            self.assertEqual(original, output.read_bytes())
            self.assertEqual([output], list(directory.glob("*.lua")))

    def assert_accepted(self, document, revision="2", approved=("2001",),
                        verified=VERIFIED_TOKENS):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            review = directory / "review.json"
            output = directory / "curated.lua"
            self.write_json(review, document)
            completed = self.run_cli(
                cli_args(review, output, revision=revision, approved=approved,
                         verified=verified),
                directory,
            )
            self.assertEqual(0, completed.returncode, completed.stdout + "\n" + completed.stderr)
            self.assertEqual("", completed.stderr)
            self.assertIn("Generated curated Lua records for 1 approved quests.",
                          completed.stdout)
            expected = generator.generate(
                document,
                [int(token) for token in approved],
                [int(token) for token in verified],
                int(revision),
            )
            self.assertEqual(expected, output.read_text(encoding="utf-8"))
            return expected

    def test_positive_control_minimal_review_generates_lua(self):
        # All twelve review fields are required by validate_quest(), so this
        # public fixture is a minimal document that must still succeed.
        text = self.assert_accepted(valid_document())
        self.assertIn("revision = 2", text)
        self.assertIn("[2001] = {", text)
        self.assertIn('name = "Ravenclaw Cleanup"', text)
        self.assertIn("startedByNpcs = {2121}", text)
        self.assertIn("finishedByNpcs = {2121}", text)
        self.assertIn("killNpcs = {1868, 1869}", text)
        self.assertIn("requiredLevel = 12", text)
        self.assertIn("questLevel = 16", text)
        self.assertTrue(text.endswith("\n"))

    def test_json_numeric_fields_are_refused_without_writing(self):
        # JSON true/false become Python bool. bool is an int subclass, and
        # whole() still refuses it because the check is `type(value) is not int`
        # (generate_custom_quests.py lines 23-26), not isinstance.
        def args_for(review, output, phase):
            return cli_args(
                review,
                output,
                revision="2" if phase == "fresh" else "3",
                overwrite=phase == "overwrite",
            )

        # No --overwrite: parser.error at lines 154-155 runs before json.load,
        # so the numeric message is not reached. Bytes still must not change.
        bare = (2, OUTPUT_EXISTS, False)
        for name, document, snippet, handled in json_cases():
            with self.subTest(field=name):
                self.assert_refusal_preserves_files(
                    document,
                    args_for,
                    fresh=(1, snippet, handled),
                    bare=bare,
                    overwrite=(1, snippet, handled),
                )

    def test_zero_on_minimum_zero_fields_is_currently_accepted(self):
        # POTENTIAL ISSUE, current behaviour: whole() defaults to minimum 0
        # (lines 23-26). required_level, required_races and quest_flags use
        # that default (lines 51-52), so JSON 0 is emitted. Negatives are
        # refused by the previous test. This does not decide a new policy.
        for field, lua_name in (
            ("required_level", "requiredLevel = 0"),
            ("required_races", "requiredRaces = 0"),
            ("quest_flags", "questFlags = 0"),
        ):
            with self.subTest(field=field):
                text = self.assert_accepted(with_field(field, 0))
                self.assertIn(lua_name, text)

    def test_zone_or_sort_currently_accepts_negative_and_zero(self):
        # POTENTIAL ISSUE, current behaviour: lines 54-55 check only
        # `type(record["zone_or_sort"]) is not int`. There is no minimum.
        # Floats, bools and strings are refused by the JSON matrix above.
        for value, lua_name in ((0, "zoneOrSort = 0"), (-1, "zoneOrSort = -1")):
            with self.subTest(value=value):
                text = self.assert_accepted(with_field("zone_or_sort", value))
                self.assertIn(lua_name, text)

    def test_cli_revision_tokens_follow_argparse_then_whole(self):
        # --revision is type=int (line 145). Non-integer tokens die in
        # argparse (exit 2) before any file is opened. Integer tokens reach
        # whole() only when no generated file exists yet (line 89). A file
        # at revision 2 refuses 0 and -1 earlier, at lines 160-162, because
        # the new revision is not higher.
        def check(token, fresh, bare, overwrite):
            def args_for(review, output, phase):
                return cli_args(
                    review,
                    output,
                    revision=token,
                    overwrite=phase == "overwrite",
                )

            self.assert_refusal_preserves_files(
                valid_document(), args_for, fresh, bare, overwrite,
            )

        for token in ("1.5", "true", "false", "2.0"):
            with self.subTest(revision=token):
                snippet = "invalid int value: '%s'" % (token,)
                refused = (2, snippet, False)
                check(token, refused, refused, refused)
        for token in ("0", "-1"):
            with self.subTest(revision=token):
                check(
                    token,
                    fresh=(1, whole_message("revision", 1), True),
                    bare=(2, OUTPUT_EXISTS, False),
                    overwrite=(2, REVISION_NOT_HIGHER, False),
                )

    def test_cli_numeric_string_revision_token_is_currently_accepted(self):
        # POTENTIAL ISSUE, current behaviour: the CLI token "2001" is a
        # string, but argparse type=int (line 145) coerces it before whole().
        # The same characters inside review JSON are refused. generate()
        # refuses a real str; see the library test below.
        text = self.assert_accepted(valid_document(), revision="2001")
        self.assertIn("\n    revision = 2001,\n", text)

    def test_cli_approved_and_verified_tokens(self):
        # --approved-quest and --verified-npc are type=int (lines 141-142).
        # A non-integer token exits 2 from argparse. Integer 0 and -1 reach
        # ids() -> whole(..., minimum=1) once --overwrite gets past the
        # revision guard.
        def check(approved, verified, fresh, bare, overwrite):
            def args_for(review, output, phase):
                return cli_args(
                    review,
                    output,
                    approved=approved,
                    verified=verified,
                    revision="2" if phase == "fresh" else "3",
                    overwrite=phase == "overwrite",
                )

            self.assert_refusal_preserves_files(
                valid_document(), args_for, fresh, bare, overwrite,
            )

        for flag, approved, verified in (
            ("approved", ("1.5",), VERIFIED_TOKENS),
            ("approved", ("true",), VERIFIED_TOKENS),
            ("approved", ("false",), VERIFIED_TOKENS),
            ("verified", ("2001",), ("1.5", "1868", "1869")),
            ("verified", ("2001",), ("true", "1868", "1869")),
            ("verified", ("2001",), ("false", "1868", "1869")),
        ):
            with self.subTest(flag=flag, approved=approved, verified=verified):
                token = approved[0] if flag == "approved" else verified[0]
                argument = "--approved-quest" if flag == "approved" else "--verified-npc"
                snippet = "argument %s: invalid int value: '%s'" % (argument, token)
                refused = (2, snippet, False)
                check(approved, verified, refused, refused, refused)

        bare = (2, OUTPUT_EXISTS, False)
        for token in ("0", "-1"):
            with self.subTest(approved=token):
                check(
                    (token,),
                    VERIFIED_TOKENS,
                    fresh=(1, whole_message("approved quests", 1), True),
                    bare=bare,
                    overwrite=(1, whole_message("approved quests", 1), True),
                )
            with self.subTest(verified=token):
                check(
                    ("2001",),
                    (token, "1868", "1869"),
                    fresh=(1, whole_message("verified NPCs", 1), True),
                    bare=bare,
                    overwrite=(1, whole_message("verified NPCs", 1), True),
                )

    def test_generate_refuses_non_ints_that_argparse_would_coerce(self):
        # The CLI cannot pass a real bool or str into revision or the
        # allowlists: argparse converts tokens first. whole() and ids()
        # still refuse those objects. True is refused even though
        # isinstance(True, int) is true and True >= 1.
        document = valid_document()
        verified = [2121, 1868, 1869]
        cases = (
            ("revision true", dict(revision=True), "revision must be an integer >= 1"),
            ("revision false", dict(revision=False), "revision must be an integer >= 1"),
            ("revision float", dict(revision=1.5), "revision must be an integer >= 1"),
            ("revision str", dict(revision="2001"), "revision must be an integer >= 1"),
            ("revision zero", dict(revision=0), "revision must be an integer >= 1"),
            ("revision negative", dict(revision=-1), "revision must be an integer >= 1"),
            ("approved true", dict(approved=[True]), "approved quests must be an integer >= 1"),
            ("approved false", dict(approved=[False]), "approved quests must be an integer >= 1"),
            ("approved float", dict(approved=[1.5]), "approved quests must be an integer >= 1"),
            ("approved str", dict(approved=["2001"]), "approved quests must be an integer >= 1"),
            ("approved zero", dict(approved=[0]), "approved quests must be an integer >= 1"),
            ("approved negative", dict(approved=[-1]), "approved quests must be an integer >= 1"),
            ("approved not a list", dict(approved=2001), "approved quests must be a bounded ID list"),
            ("verified true", dict(verified=[True, 1868, 1869]),
             "verified NPCs must be an integer >= 1"),
            ("verified false", dict(verified=[False, 1868, 1869]),
             "verified NPCs must be an integer >= 1"),
            ("verified float", dict(verified=[1.5, 1868, 1869]),
             "verified NPCs must be an integer >= 1"),
            ("verified str", dict(verified=["2121", 1868, 1869]),
             "verified NPCs must be an integer >= 1"),
            ("verified zero", dict(verified=[0, 1868, 1869]),
             "verified NPCs must be an integer >= 1"),
            ("verified negative", dict(verified=[-1, 1868, 1869]),
             "verified NPCs must be an integer >= 1"),
            ("verified not a list", dict(verified="2121"),
             "verified NPCs must be a bounded ID list"),
        )
        for name, overrides, message in cases:
            with self.subTest(name=name):
                call = dict(approved=[2001], verified_npcs=verified, revision=2)
                if "approved" in overrides:
                    call["approved"] = overrides["approved"]
                if "verified" in overrides:
                    call["verified_npcs"] = overrides["verified"]
                if "revision" in overrides:
                    call["revision"] = overrides["revision"]
                with self.assertRaises(ValueError) as caught:
                    generator.generate(
                        document, call["approved"], call["verified_npcs"], call["revision"],
                    )
                self.assertEqual(message, str(caught.exception))

    def test_quests_value_must_be_a_list(self):
        # Kills a mutant that deletes `type(records) is not list` around
        # generate() line 95. The dict and string are inside the 1..64
        # length window, so that mutant continues into validate_quest() and
        # raises a different ValueError. len(int) raises TypeError, which
        # the CLI wrapper does not turn into the list message. An empty
        # dict or string would still fail the length check and would not
        # kill the mutant.
        def args_for(review, output, phase):
            return cli_args(
                review,
                output,
                revision="2" if phase == "fresh" else "3",
                overwrite=phase == "overwrite",
            )

        snippet = REFUSAL + "Review must include 1-64 quests"
        payloads = (
            ("dict", {"id": 2001, "title": "not a list"}),
            ("str", "not-a-list"),
            ("int", 2001),
        )
        for name, quests in payloads:
            with self.subTest(quests=name):
                if name != "int":
                    self.assertGreaterEqual(len(quests), 1)
                    self.assertLessEqual(len(quests), 64)
                document = {"format": generator.FORMAT, "quests": quests}
                self.assert_refusal_preserves_files(
                    document,
                    args_for,
                    fresh=(1, snippet, True),
                    bare=(2, OUTPUT_EXISTS, False),
                    overwrite=(1, snippet, True),
                )


if __name__ == "__main__":
    unittest.main()
