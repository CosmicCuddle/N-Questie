#!/usr/bin/env python3
"""PRIVATE offline comparison of AzerothCore quest levels with Questie-335.

Compare quest_template.MinLevel/QuestLevel to generated WotLK Questie data and
literal Classic -> TBC -> WotLK quest correction layer overrides. Dynamic Lua
and Individual Progression availability are NOT evaluated. This is an audit,
not a patch.

python3 tools/audit_world_quest_levels.py --world /private/acore_world.zip \
  --output /private/quest-level-audit.json
Add --quest 1203 to include Jarl Needs a Blade even if levels match.
Never commit the SQL ZIP or resulting private report.
"""
import argparse
import json
import re
import sys
from pathlib import Path

from export_world_quests import HEADER, parse_row, sql_lines

QUESTIE_RAW = Path("Database/Wotlk/wotlkQuestDB.lua")
LEVEL_FIXES = (
    Path("Database/Corrections/classicQuestFixes.lua"),
    Path("Database/Corrections/tbcQuestFixes.lua"),
    Path("Database/Corrections/wotlkQuestFixes.lua"),
)
RECORD = re.compile(r"^\s*\[(\d+)\]\s*=\s*\{(.*)\},?\s*(?:--.*)?$")
TOP_FIX = re.compile(r"(?m)^        \[(\d+)\]\s*=\s*\{")
FIELD_FIX = re.compile(r"\[questKeys\.(requiredLevel|questLevel)\]\s*=\s*([^,\}\n]+)")


def integer(value, label):
    try:
        return int(value)
    except (TypeError, ValueError) as exc:
        raise ValueError("Invalid integer field " + label) from exc


def lua_fields(source):
    """Split outer Lua fields, ignoring commas inside strings and nested tables."""
    result, buffer = [], []
    depth, quote, escaped = 0, None, False
    for char in source:
        if quote is not None:
            buffer.append(char)
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == quote:
                quote = None
        elif char in ('"', "'"):
            buffer.append(char)
            quote = char
        elif char == "{":
            depth += 1
            buffer.append(char)
        elif char == "}":
            depth -= 1
            if depth < 0:
                raise ValueError("Malformed nested Lua table")
            buffer.append(char)
        elif char == "," and depth == 0:
            result.append("".join(buffer).strip())
            buffer = []
        else:
            buffer.append(char)
    if depth or quote:
        raise ValueError("Unclosed Lua string or table")
    if buffer:
        result.append("".join(buffer).strip())
    return result


def parse_questie_raw(content):
    quests, skipped = {}, []
    for lineno, line in enumerate(content.splitlines(), 1):
        if not re.match(r"^\s*\[\d+\]\s*=", line):
            continue
        match = RECORD.match(line)
        if not match:
            skipped.append(lineno)
            continue
        qid = int(match.group(1))
        if qid in quests:
            raise ValueError("Duplicate Questie quest ID " + str(qid))
        try:
            fields = lua_fields(match.group(2))
            if len(fields) < 5 or not all(re.fullmatch(r"-?\d+", f) for f in fields[3:5]):
                raise ValueError("Unsupported level format")
            name = fields[0]
            if name.startswith('"') and name.endswith('"'):
                try:
                    name = json.loads(name)
                except ValueError:
                    name = name[1:-1]
            quests[qid] = {
                "name": name, "requiredLevel": int(fields[3]), "questLevel": int(fields[4]),
            }
        except ValueError:
            skipped.append(lineno)
    if not quests:
        raise ValueError("No Questie WotLK quest records found")
    return quests, skipped


def parse_static_level_fixes(content):
    """Conservative: only literal numeric corrections in each file's :Load()."""
    match = re.search(r"(?m)^function \w+:Load\(\)\s*$", content)
    if not match:
        raise ValueError("Missing expected Questie :Load() method")
    start = content.find("    return {", match.end())
    next_method = re.search(r"(?m)^function\s+\w+[:.]", content[match.end():])
    if start < 0 or (next_method and start > match.end() + next_method.start()):
        raise ValueError("Missing correction return table inside :Load()")
    end = content.find("\n    }", start)
    if end < 0:
        raise ValueError("Cannot locate corrections table ending")
    source = content[start:end]
    blocks = list(TOP_FIX.finditer(source))
    fixes, unknown = {}, set()
    for i, block in enumerate(blocks):
        qid = int(block.group(1))
        stop = blocks[i + 1].start() if i + 1 < len(blocks) else len(source)
        body = source[block.end():stop]
        for field, expr in FIELD_FIX.findall(body):
            expr = expr.strip()
            if re.fullmatch(r"-?\d+", expr):
                fixes.setdefault(qid, {})[field] = int(expr)
            else:
                unknown.add(qid)
    return fixes, unknown


def parse_world_quest_levels(path):
    quests, active, columns, located = {}, False, [], False
    for line in sql_lines(path):
        if line.startswith("INSERT INTO "):
            match = HEADER.match(line.rstrip("\r\n"))
            active = bool(match and match.group(1) == "quest_template")
            if active:
                located = True
                columns = [x.strip().strip(chr(96)) for x in match.group(2).split(",")]
                for col in ("ID", "LogTitle", "MinLevel", "QuestLevel"):
                    if col not in columns:
                        raise ValueError("Missing quest_template." + col)
            continue
        if not active or not line.lstrip().startswith("("):
            continue
        row = parse_row(line, columns)
        qid = integer(row["ID"], "ID")
        if qid <= 0 or qid in quests:
            raise ValueError("Invalid or repeated world quest ID " + str(qid))
        quests[qid] = {
            "name": row["LogTitle"],
            "requiredLevel": integer(row["MinLevel"], "MinLevel"),
            "questLevel": integer(row["QuestLevel"], "QuestLevel"),
        }
    if not located or not quests:
        raise ValueError("No supported HeidiSQL quest_template INSERT rows found")
    return quests


def report_levels(server, raw, corrections, selected=None, skipped=()):
    ids = set(server) if selected is None else set(selected)
    absent = ids.difference(server)
    if absent:
        raise ValueError("Quest ID(s) missing from world export: " +
                         ", ".join(map(str, sorted(absent))))
    effective, unresolved = {}, set()
    for source, fixes, unknown in corrections:
        unresolved.update(unknown)
        for qid, changes in fixes.items():
            for field, value in changes.items():
                effective.setdefault(qid, {})[field] = (value, source)
    summary = {
        "server_quests": len(server), "questie_raw_quests": len(raw),
        "questie_unparsed_rows": len(skipped), "checked": len(ids),
        "match": 0, "mismatch": 0, "needs_review": 0, "missing_questie": 0,
    }
    rows = []
    for qid in sorted(ids):
        actual = server[qid]
        baseline = raw.get(qid)
        if baseline is None:
            summary["missing_questie"] += 1
            if selected is not None:
                rows.append({"id": qid, "name": actual["name"], "status": "missing_questie"})
            continue
        details, changed = {}, []
        for field in ("requiredLevel", "questLevel"):
            fix = effective.get(qid, {}).get(field)
            value = fix[0] if fix else baseline[field]
            details[field] = {
                "server": actual[field], "questie_raw": baseline[field],
                "questie_after_literal_fixes": value,
                "literal_fix_source": fix[1] if fix else None,
            }
            if value != actual[field]:
                changed.append(field)
        uncertain = qid in unresolved or actual["questLevel"] < -1 or actual["requiredLevel"] < 0
        status = "needs_review" if uncertain else "mismatch" if changed else "match"
        summary[status] += 1
        if selected is not None or status != "match":
            rows.append({
                "id": qid, "name": actual["name"], "questie_name": baseline["name"],
                "status": status, "different_fields": changed, "levels": details,
                "caution": "Dynamic correction or unusual negative level requires manual review" if uncertain else None,
            })
    return {
        "format": "N-Questie PRIVATE existing quest level audit v1",
        "scope": "Offline server export versus Questie WotLK plus literal Classic/TBC/WotLK corrections",
        "limitations": "Dynamic corrections, quest-log overrides and Individual Progression availability require separate verification",
        "summary": summary, "quests": rows,
    }


def inside(path, root):
    try:
        path.resolve().relative_to(root.resolve())
        return True
    except ValueError:
        return False


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--world", required=True, type=Path)
    ap.add_argument("--questie-root", type=Path, default=Path(__file__).resolve().parents[1])
    ap.add_argument("--quest", type=int, action="append",
                    help="Inspect a given ID even if equal; omit to audit all quests")
    ap.add_argument("--output", required=True, type=Path, help="Private JSON location outside checkout")
    ap.add_argument("--overwrite", action="store_true")
    args = ap.parse_args(argv)
    if not args.world.is_file():
        ap.error("World SQL/ZIP not found")
    if any(q <= 0 for q in (args.quest or [])):
        ap.error("Quest IDs must be positive")
    if inside(args.output, args.questie_root):
        ap.error("Refusing to write private JSON inside public addon checkout")
    if args.output.resolve() == args.world.resolve():
        ap.error("Refusing to overwrite the world source")
    if args.output.exists() and not args.overwrite:
        ap.error("Review file exists; explicit --overwrite required")
    root = args.questie_root
    raw, skipped = parse_questie_raw((root / QUESTIE_RAW).read_text(encoding="utf-8"))
    corrections = []
    for path in LEVEL_FIXES:
        fixes, unknown = parse_static_level_fixes((root / path).read_text(encoding="utf-8"))
        corrections.append((str(path), fixes, unknown))
    server = parse_world_quest_levels(args.world)
    report = report_levels(server, raw, corrections, args.quest, skipped)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    s = report["summary"]
    print("PRIVATE audit:", s["checked"], "checked,", s["mismatch"],
          "level mismatches,", s["needs_review"], "requiring review")
    print("Saved outside checkout:", args.output)
    print("No live server or installed addon changes were made.")


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError, UnicodeError) as exc:
        print("N-Questie level audit refused:", exc, file=sys.stderr)
        sys.exit(1)
