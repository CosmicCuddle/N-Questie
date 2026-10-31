#!/usr/bin/env python3
"""Private, read-only whole-world N-Questie quest-ID gap inventory.

This is a CANDIDATE inventory, not a playable-quest claim. It includes all
server IDs, not only known pilot 1207-1209. Quests with MinLevel/QuestLevel
<= 60 are prioritized, not automatically classified as Vanilla/IP-eligible.

Run source baseline without server data:
    python3 tools/audit_missing_vanilla_coverage.py --source-only

Private input and output must NEVER be uploaded to public GitHub:
    python3 tools/audit_missing_vanilla_coverage.py \
      --world /private/acore_world.zip --output /private/nq-gap-review.json

No server connection, SQL mutation, addon build or public per-quest upload.
"""
import argparse
import json
import re
from pathlib import Path

from export_world_quests import selected_rows
from audit_world_quest_levels import parse_world_quest_levels
from inspect_missing_quest_pilot import KEY, SOURCES, ensure_world_tables

# The source-backed baseline, pinned until intentionally reviewed and updated.
EXPECTED = {'raw': 9086, 'inherited_added': 72, 'custom_added': 1,
            'effective': 9159}
INSERT = re.compile(r'(?m)^[ \t]*QuestieDB\.questData\[([0-9]+)\][ \t]*=[ \t]*\{[ \t]*\}')
INHERITED = {
    'classic': ('Database/Corrections/classicQuestFixes.lua', 'LoadMissingQuests'),
    'tbc': ('Database/Corrections/tbcQuestFixes.lua', 'InsertMissingQuestIds'),
    'wotlk': ('Database/Corrections/wotlkQuestFixes.lua', 'InsertMissingQuestIds'),
}
DEFERRED = frozenset({30000, 30001, 30002, 30003, 30004})


def literal_quest_records(source):
    return {int(text) for text in KEY.findall(source)}


def inherited_function_ids(source, method):
    matcher = re.compile(r'(?m)^function [^\n]*:' + re.escape(method)
                         + r'\(\)[ \t]*$')
    blocks = list(matcher.finditer(source))
    if len(blocks) != 1:
        raise ValueError('Expected exactly one inherited function ' + method)
    end = re.search(r'(?m)^end[ \t]*$', source[blocks[0].end():])
    if not end:
        raise ValueError('Unterminated inherited function ' + method)
    contents = source[blocks[0].end():blocks[0].end() + end.start()]
    ids = [int(match) for match in INSERT.findall(contents)]
    if not ids or len(ids) != len(set(ids)):
        raise ValueError('Missing or duplicate inherited quest insert for ' + method)
    return set(ids)


def effective_ids(root, pinned=True):
    raw = literal_quest_records(
        (root / SOURCES['wotlk']).read_text(encoding='utf-8-sig'))
    custom = literal_quest_records(
        (root / SOURCES['custom']).read_text(encoding='utf-8-sig'))
    inherited = set()
    for path, method in INHERITED.values():
        inherited.update(inherited_function_ids(
            (root / path).read_text(encoding='utf-8-sig'), method))
    extra = inherited - raw
    custom_extra = custom - raw - inherited
    all_ids = raw | inherited | custom
    counts = {'raw': len(raw), 'inherited_added': len(extra),
              'custom_added': len(custom_extra), 'effective': len(all_ids)}
    if pinned and counts != EXPECTED:
        raise ValueError('Pinned Questie source baseline changed: ' + str(counts)
                         + '; review source changes before trusting missing IDs')
    if pinned and (custom_extra != {2001} or any(q in all_ids for q in (1207, 1208, 1209))):
        raise ValueError('Expected protected source-only pilot and 2001 state changed')
    return all_ids, counts


def priority(level, minimum):
    # A low nominal quest level is a *hint*, NOT proof of Vanilla/IP eligibility.
    if minimum <= 60 and level <= 60:
        return 'LEVEL60_OR_BELOW_REVIEW'
    return 'LATER_OR_UNUSUAL_LEVEL_REVIEW'


def build(world, root, pinned=True):
    effective, counts = effective_ids(root, pinned=pinned)
    ensure_world_tables(world)
    server = parse_world_quest_levels(world)
    absent = sorted(set(server) - effective)
    _, addons, links = selected_rows(world, absent)
    details = []
    counters = {'total_server_quests': len(server),
                'effective_client_ids': len(effective),
                'server_only_candidates': len(absent),
                'owner_deferred': 0, 'level60_or_below_review': 0,
                'linked_level60_or_below_review': 0,
                'other_level_or_unusual_review': 0,
                'no_conventional_start_or_end': 0}
    for qid in absent:
        quest = server[qid]
        links_for = links[qid]
        starters = sorted(links_for['creature_queststarter'] |
                          links_for['gameobject_queststarter'])
        enders = sorted(links_for['creature_questender'] |
                        links_for['gameobject_questender'])
        level_kind = priority(quest['questLevel'], quest['requiredLevel'])
        deferred = qid in DEFERRED
        if deferred:
            counters['owner_deferred'] += 1
        elif level_kind == 'LEVEL60_OR_BELOW_REVIEW':
            counters['level60_or_below_review'] += 1
            if starters and enders:
                counters['linked_level60_or_below_review'] += 1
        else:
            counters['other_level_or_unusual_review'] += 1
        if not starters or not enders:
            counters['no_conventional_start_or_end'] += 1
        details.append({
            'id': qid, 'name': quest['name'],  # OWNER-PRIVATE ONLY
            'required_level': quest['requiredLevel'],
            'quest_level': quest['questLevel'],
            'priority': ('OWNER_DEFERRED_NO_IMPORT' if deferred else level_kind),
            'source_status': 'ABSENT_FROM_PINNED_EFFECTIVE_QUEST_ID_SET',
            'npc_starters': sorted(links_for['creature_queststarter']),
            'npc_enders': sorted(links_for['creature_questender']),
            'go_starters': sorted(links_for['gameobject_queststarter']),
            'go_enders': sorted(links_for['gameobject_questender']),
            'addon_row': qid in addons,
            'eligibility': 'UNVERIFIED_LIVE_SERVER_AND_IP',
            'objective_shape': 'UNVERIFIED',
            'owner_approval': 'NOT_GRANTED_BY_THIS_AUDIT',
        })
    if (counters['owner_deferred'] + counters['level60_or_below_review'] +
            counters['other_level_or_unusual_review']) != len(details):
        raise ValueError('Inventory categories fail to reconcile')
    return {'format': 'N-Questie OWNER-PRIVATE missing coverage candidates v1',
            'warning': ('Quest templates, levels and conventional starter/ender rows '
                        'do NOT prove a quest is currently offered or compatible with IP'),
            'source_count_pin': counts, 'summary': counters, 'candidates': details}


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--repo-root', type=Path,
                        default=Path(__file__).resolve().parents[1])
    parser.add_argument('--source-only', action='store_true')
    parser.add_argument('--world', type=Path)
    parser.add_argument('--output', type=Path)
    args = parser.parse_args(argv)
    if args.source_only:
        if args.world or args.output:
            parser.error('--source-only cannot accept private world/output')
        _, counts = effective_ids(args.repo_root)
        print('Protected source quest ID baseline verified: ' + json.dumps(counts))
        print('Pilot 1207/1208/1209 absent as quest records; no world eligibility claimed')
        return
    if not args.world or not args.world.is_file() or not args.output:
        parser.error('Private --world and --output required (or use --source-only)')
    private_out = args.output.resolve()
    if (args.output.exists() or private_out == args.world.resolve() or
            private_out.is_relative_to(args.repo_root.resolve())):
        parser.error('Refusing overwrite or output inside repo/source archive')
    try:
        report = build(args.world, args.repo_root)
    except (ValueError, OSError) as error:
        parser.error(str(error))
    args.output.write_text(json.dumps(report, indent=2, ensure_ascii=False) + '\n',
                           encoding='utf-8')
    print('OWNER-PRIVATE inventory written outside repository.')
    print('Aggregate ONLY: ' + json.dumps(report['summary'], sort_keys=True))
    print('No quest has been approved, added, or shown in-game by this audit.')


if __name__ == '__main__':
    main()
