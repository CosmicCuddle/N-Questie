#!/usr/bin/env python3
"""Generate a small N-Questie Lua overlay from a locally reviewed quest JSON.

This NEVER opens a world database or connects to AzerothCore. The input JSON
remains private. Only explicitly approved quest IDs and independently verified
existing Questie NPC locations may be emitted.
"""
import argparse
import json
import sys
from pathlib import Path

FORMAT = "N-Questie world quest review v1"
FIELDS = {
    "id", "title", "required_level", "quest_level", "zone_or_sort",
    "required_races", "quest_flags", "pre_quest_single", "starter_npcs",
    "ender_npcs", "kill_objectives", "requires_review",
}
OBJECTIVE_FIELDS = {"npc", "count"}


def whole(value, label, minimum=0):
    if type(value) is not int or value < minimum:
        raise ValueError(label + " must be an integer >= " + str(minimum))
    return value


def ids(value, label, maximum=32, required=False):
    if type(value) is not list or len(value) > maximum or (required and not value):
        raise ValueError(label + " must be a bounded ID list")
    found = [whole(number, label, 1) for number in value]
    if len(set(found)) != len(found):
        raise ValueError(label + " contains duplicate IDs")
    return found


def title_string(value):
    if not isinstance(value, str) or not value or len(value) > 300:
        raise ValueError("Quest title is missing or too long")
    if any(ord(char) < 32 or ord(char) == 127 for char in value):
        raise ValueError("Quest title contains unsupported control characters")
    return json.dumps(value, ensure_ascii=False)


def validate_quest(record):
    if type(record) is not dict or set(record) != FIELDS:
        raise ValueError("Quest review record has missing or unexpected fields")
    qid = whole(record["id"], "quest ID", 1)
    title = title_string(record["title"])
    for field in ("required_level", "required_races", "quest_flags"):
        whole(record[field], field)
    whole(record["quest_level"], "quest_level", 1)
    if type(record["zone_or_sort"]) is not int:
        raise ValueError("zone_or_sort must be an integer")
    prior = ids(record["pre_quest_single"], "pre_quest_single", maximum=1)
    starts = ids(record["starter_npcs"], "starter_npcs", required=True)
    ends = ids(record["ender_npcs"], "ender_npcs", required=True)
    objectives = record["kill_objectives"]
    if type(objectives) is not list or len(objectives) > 4:
        raise ValueError("kill_objectives must be a list of up to four NPCs")
    kills = []
    for objective in objectives:
        if type(objective) is not dict or set(objective) != OBJECTIVE_FIELDS:
            raise ValueError("Invalid kill objective fields")
        kills.append(whole(objective["npc"], "kill NPC ID", 1))
        whole(objective["count"], "kill count", 1)
    if len(set(kills)) != len(kills):
        raise ValueError("Duplicate kill NPC ID; requires manual review")
    if type(record["requires_review"]) is not list or not all(
        isinstance(item, str) and item for item in record["requires_review"]
    ):
        raise ValueError("Missing source review checklist")
    return {
        "id": qid, "title": title, "required_level": record["required_level"],
        "quest_level": record["quest_level"],
        "zone_or_sort": record["zone_or_sort"],
        "required_races": record["required_races"],
        "quest_flags": record["quest_flags"], "prior": prior,
        "starts": starts, "ends": ends, "kills": kills,
    }


def lua_ids(numbers):
    return "{" + ", ".join(map(str, numbers)) + "}"


def generate(review, approved, verified_npcs, revision):
    whole(revision, "revision", 1)
    if type(review) is not dict or set(review) != {"format", "quests"}:
        raise ValueError("Unexpected review document structure")
    if review["format"] != FORMAT:
        raise ValueError("Unknown review document format")
    records = review["quests"]
    if type(records) is not list or not 1 <= len(records) <= 64:
        raise ValueError("Review must include 1-64 quests")
    quests = [validate_quest(record) for record in records]
    quest_ids = [quest["id"] for quest in quests]
    if len(set(quest_ids)) != len(quest_ids):
        raise ValueError("Duplicate quest ID")
    if set(quest_ids) != set(ids(approved, "approved quests", maximum=64, required=True)):
        raise ValueError("Approved quest IDs must exactly match reviewed quests")
    all_npcs = set()
    for quest in quests:
        all_npcs.update(quest["starts"] + quest["ends"] + quest["kills"])
    if all_npcs != set(ids(verified_npcs, "verified NPCs", maximum=256, required=True)):
        raise ValueError("Verified NPC IDs must exactly cover all quest NPCs")
    lines = [
        "-- N-Questie curated public quest metadata; generated from reviewed offline JSON.",
        "-- NEVER commit the source review JSON, world SQL/ZIP, or connection details.",
        "-- NPC map positions must be checked independently before generation.",
        "-- Kill quantities come from the live quest log, not these map-marker links.",
        "-- Regenerate with tools/generate_custom_quests.py; do not hand-edit.",
        "NQuestieCustomQuestData = {",
        "    revision = " + str(revision) + ",",
        "    quests = {",
    ]
    for quest in sorted(quests, key=lambda row: row["id"]):
        lines += [
            "        [" + str(quest["id"]) + "] = {",
            "            name = " + quest["title"] + ",",
            "            requiredLevel = " + str(quest["required_level"]) + ",",
            "            questLevel = " + str(quest["quest_level"]) + ",",
            "            zoneOrSort = " + str(quest["zone_or_sort"]) + ",",
            "            requiredRaces = " + str(quest["required_races"]) + ",",
            "            questFlags = " + str(quest["quest_flags"]) + ",",
            "            preQuestSingle = " + lua_ids(quest["prior"]) + ",",
            "            startedByNpcs = " + lua_ids(quest["starts"]) + ",",
            "            finishedByNpcs = " + lua_ids(quest["ends"]) + ",",
            "            killNpcs = " + lua_ids(quest["kills"]) + ",",
            "        },",
        ]
    lines += ["    },", "}", ""]
    return "\n".join(lines)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--review", type=Path, required=True, help="Private locally reviewed JSON")
    parser.add_argument("--approved-quest", type=int, action="append", required=True)
    parser.add_argument("--verified-npc", type=int, action="append", required=True,
                        help="NPC with independently verified Questie map positions")
    parser.add_argument("--revision", type=int, required=True, help="Increment when curated records change")
    parser.add_argument("--output", type=Path, required=True, help="Generated Lua destination")
    parser.add_argument("--overwrite", action="store_true",
                        help="Explicitly replace an existing generated Lua file")
    args = parser.parse_args(argv)
    if not args.review.is_file():
        parser.error("Private review JSON is missing")
    if args.output.suffix.lower() != ".lua" or args.output.resolve() == args.review.resolve():
        parser.error("Output must be a separate .lua file")
    if args.output.exists() and not args.overwrite:
        parser.error("Output exists; pass --overwrite only after comparing revisions")
    with args.review.open(encoding="utf-8") as source:
        document = json.load(source)
    content = generate(document, args.approved_quest, args.verified_npc, args.revision)
    args.output.write_text(content, encoding="utf-8")
    print("Generated curated Lua records for", len(document["quests"]), "approved quests.")
    print("Review the diff before any public commit; never commit the private JSON.")


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError, UnicodeError, json.JSONDecodeError) as exc:
        print("N-Questie Lua generation refused:", str(exc), file=sys.stderr)
        sys.exit(1)
