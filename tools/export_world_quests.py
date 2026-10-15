#!/usr/bin/env python3
"""Read-only selected-quest export from a HeidiSQL acore_world dump.

python3 tools/export_world_quests.py --world /private/acore_world.zip --quest 2001 --output review.json

Review the generated JSON before committing any curated records. Never commit
raw SQL, connection details or the entire database. Does not access the server.
"""
import argparse
import csv
import json
import re
import sys
import zipfile
from collections import defaultdict
from pathlib import Path

TABLES = {
    "quest_template", "quest_template_addon",
    "creature_queststarter", "creature_questender",
    "gameobject_queststarter", "gameobject_questender",
}
HEADER = re.compile(r"^INSERT INTO \x60([a-zA-Z0-9_]+)\x60 \((.*)\) VALUES\s*$")


def sql_lines(path):
    if zipfile.is_zipfile(path):
        with zipfile.ZipFile(path) as archive:
            files = [name for name in archive.namelist() if name.lower().endswith(".sql")]
            if len(files) != 1:
                raise ValueError("Expected exactly one .sql file in ZIP")
            with archive.open(files[0]) as source:
                for line in source:
                    yield line.decode("utf-8-sig", errors="replace")
    else:
        with open(path, encoding="utf-8-sig", errors="replace") as source:
            yield from source


def parse_row(line, columns):
    value = line.strip()
    if not (value.startswith("(") and value.endswith(("),", ");"))):
        raise ValueError("Expected one HeidiSQL tuple per row")
    parts = next(csv.reader([value[1:-2]], delimiter=",",
                            quotechar="'", escapechar="\\", skipinitialspace=True))
    if len(parts) != len(columns):
        raise ValueError("Incorrect SQL tuple width")
    return dict(zip(columns, parts))


def selected_rows(world, ids):
    wanted = set(ids)
    quests, addons = {}, {}
    links = defaultdict(lambda: defaultdict(set))
    active, cols = None, None
    for line in sql_lines(world):
        if line.startswith("INSERT INTO \x60"):
            header = HEADER.match(line.rstrip("\r\n"))
            active = header.group(1) if header and header.group(1) in TABLES else None
            cols = [s.strip().strip(chr(96)) for s in header.group(2).split(",")] if active else None
            continue
        if not active or not line.lstrip().startswith("("):
            continue
        if active in ("quest_template", "quest_template_addon"):
            match = re.match(r"^\s*\((\d+),", line)
            if not match or int(match.group(1)) not in wanted:
                continue
        row = parse_row(line, cols)
        if active == "quest_template":
            quests[int(row["ID"])] = row
        elif active == "quest_template_addon":
            addons[int(row["ID"])] = row
        else:
            quest_id = int(row["quest"])
            if quest_id in wanted:
                links[quest_id][active].add(int(row["id"]))
    return quests, addons, links


def integer(row, field, default=0):
    try:
        return int(row.get(field, default))
    except (TypeError, ValueError) as exc:
        raise ValueError("Invalid integer field " + field) from exc


def curate(world, quest_ids):
    quests, addons, links = selected_rows(world, quest_ids)
    output = []
    for qid in sorted(set(quest_ids)):
        if qid not in quests:
            raise ValueError("No quest_template record for quest " + str(qid))
        row = quests[qid]
        addon = addons.get(qid, {})
        starters = sorted(links[qid]["creature_queststarter"])
        enders = sorted(links[qid]["creature_questender"])
        if not starters or not enders:
            raise ValueError("Missing NPC quest starter/ender for " + str(qid))
        if (links[qid]["gameobject_queststarter"] or
                links[qid]["gameobject_questender"]):
            raise ValueError("Gameobject quest givers/enders need separate mapping: " + str(qid))
        objectives = []
        for slot in range(1, 5):
            npc = integer(row, "RequiredNpcOrGo" + str(slot))
            count = integer(row, "RequiredNpcOrGoCount" + str(slot))
            if npc > 0 and count > 0:
                objectives.append({"npc": npc, "count": count})
            elif npc != 0 or count != 0:
                raise ValueError("Unsupported or incomplete objective on quest " + str(qid))
        prev = integer(addon, "PrevQuestID")
        if prev < 0:
            raise ValueError("Negative prerequisite/group must be reviewed: " + str(qid))
        output.append({
            "id": qid, "title": row["LogTitle"],
            "required_level": integer(row, "MinLevel"),
            "quest_level": integer(row, "QuestLevel"),
            "zone_or_sort": integer(row, "QuestSortID"),
            "required_races": integer(row, "AllowableRaces"),
            "quest_flags": integer(row, "Flags"),
            "pre_quest_single": [prev] if prev else [],
            "starter_npcs": starters,
            "ender_npcs": enders,
            "kill_objectives": objectives,
            "requires_review": [
                "Compare creature spawns to Questie 3.3.5a map coordinates",
                "Verify faction, conditions, quest eligibility and scripted behavior",
                "Review item/gameobject objectives separately",
            ],
        })
    return {"format": "N-Questie world quest review v1", "quests": output}


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--world", required=True, type=Path)
    parser.add_argument("--quest", required=True, type=int, action="append")
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args(argv)
    if not args.world.is_file():
        parser.error("World export is missing")
    if args.world.resolve() == args.output.resolve():
        parser.error("Refusing to overwrite source SQL")
    if any(q <= 0 for q in args.quest):
        parser.error("Quest ID must be positive")
    result = curate(args.world, args.quest)
    args.output.write_text(json.dumps(result, indent=2, ensure_ascii=False) + "\n",
                           encoding="utf-8")
    print("Prepared", len(result["quests"]), "curated quest records:", args.output)


if __name__ == "__main__":
    try:
        main()
    except (ValueError, zipfile.BadZipFile, csv.Error) as error:
        print("N-Questie export failed:", error, file=sys.stderr)
        sys.exit(1)
