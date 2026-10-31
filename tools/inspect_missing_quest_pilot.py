#!/usr/bin/env python3
"""Read-only, private-world census for first missing N-Questie quest pilot.

This does not establish a quest is playable, create quest data, or alter SQL.
Only public pilot IDs and yes/no/count flags are printed; no titles or NPC IDs.
Usage: python3 tools/inspect_missing_quest_pilot.py --world /private/acore_world.zip
"""
import argparse
import json
import re
from pathlib import Path

from export_world_quests import HEADER, TABLES, selected_rows, sql_lines

PILOT = (1207, 1208, 1209)
SOURCES = {
    'classic': 'Database/Classic/classicQuestDB.lua',
    'tbc': 'Database/TBC/tbcQuestDB.lua',
    'wotlk': 'Database/Wotlk/wotlkQuestDB.lua',
    'custom': 'Compat/NQuestieCustomQuestData.lua',
}
# Only literal record keys at the start of an actual Lua line, not incidental
# objective/item IDs, comments, or substring matches.
KEY = re.compile(r'(?m)^[ \t]*\[([0-9]+)\][ \t]*=[ \t]*\{')


def ensure_world_tables(world):
    """A partial/misformatted dump is UNKNOWN, not proof of no server quest."""
    seen = set()
    for line in sql_lines(world):
        if line.startswith('INSERT INTO ' + chr(96)):
            match = HEADER.match(line.rstrip('\r\n'))
            if match and match.group(1) in TABLES:
                seen.add(match.group(1))
    absent = TABLES - seen
    if absent:
        raise ValueError('Unsupported or incomplete SQL export; missing INSERT headers: '
                         + ', '.join(sorted(absent)))


def source_membership(root, ids):
    result = {}
    for label, relative in SOURCES.items():
        path = root / relative
        source = path.read_text(encoding='utf-8-sig')
        found = {int(value) for value in KEY.findall(source)}
        # Fail closed on wrong/wrong-sized content; a false ABSENT would be worse.
        if len(found) < (500 if label != 'custom' else 1):
            raise ValueError('Could not verify complete ' + label + ' quest source')
        result[label] = {qid: qid in found for qid in ids}
    return result


def inspect(world, root, ids=PILOT):
    ids = tuple(ids)
    if not ids or any(type(qid) is not int or not 0 < qid < 16777216 for qid in ids):
        raise ValueError('Expected positive bounded quest IDs')
    if len(set(ids)) != len(ids):
        raise ValueError('Duplicate pilot quest IDs')
    ensure_world_tables(world)
    source = source_membership(root, ids)
    quests, addons, links = selected_rows(world, ids)
    rows = []
    for qid in ids:
        present = qid in quests
        records = {label: source[label][qid] for label in SOURCES}
        all_absent = not any(records.values())
        flags = {kind: len(links[qid][kind]) for kind in sorted(TABLES - {
            'quest_template', 'quest_template_addon'
        })}
        rows.append({
            'quest_id': qid,
            'server_template': 'PRESENT' if present else 'ABSENT_IN_THIS_SNAPSHOT',
            'server_addon': 'PRESENT' if qid in addons else 'ABSENT_IN_THIS_SNAPSHOT',
            'relations': flags,
            'client_source': records,
            'assessment': ('VERIFY_PRIVATE_ELIGIBILITY_AND_REFERENCES' if present and all_absent
                           else 'VERIFY_CLIENT_FILTERS_AND_QUEST_RELATIONS' if present
                           else 'RECHECK_SERVER_SNAPSHOT_NOT_AN_IMPORT'),
        })
    return {
        'format': 'N-Questie pilot private read-only census v1',
        'scope': 'SQL snapshot + source record keys, not effective client, gameplay or IP proof',
        'quests': rows,
    }


def main(argv=None):
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--world', type=Path, required=True,
                   help='Private full HeidiSQL world .sql or single-SQL .zip export')
    p.add_argument('--repo-root', type=Path,
                   default=Path(__file__).resolve().parents[1])
    p.add_argument('--quest', action='append', type=int,
                   help='Override default 1207,1208,1209 (repeatable)')
    p.add_argument('--output', type=Path,
                   help='Optional PRIVATE JSON report, must be outside repository')
    a = p.parse_args(argv)
    if not a.world.is_file():
        p.error('World archive not found')
    if a.output is not None:
        out = a.output.resolve()
        if a.output.exists():
            p.error('Refusing to overwrite existing report')
        if out == a.world.resolve() or out.is_relative_to(a.repo_root.resolve()):
            p.error('Report must be private and outside the source checkout')
    try:
        report = inspect(a.world, a.repo_root, a.quest or PILOT)
    except (ValueError, OSError) as exc:
        p.error(str(exc))
    for row in report['quests']:
        source = row['client_source']
        print('Quest %d: world=%s, custom=%s, raw_era=%s, NPC starters=%d, GO starters=%d, status=%s' % (
            row['quest_id'], row['server_template'],
            'YES' if source['custom'] else 'NO',
            'YES' if any(source[k] for k in ('classic', 'tbc', 'wotlk')) else 'NO',
            row['relations']['creature_queststarter'],
            row['relations']['gameobject_queststarter'], row['assessment']))
    print('This is not proof of live quest availability or approval to import.')
    if a.output:
        a.output.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
        print('Wrote private census; do not upload it to public GitHub.')


if __name__ == '__main__':
    main()
