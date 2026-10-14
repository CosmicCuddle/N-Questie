# N-Questie — Read-only server quest export

**Early prototype:** the exporter creates a limited, curated **JSON review file** from an offline HeidiSQL world-database export. It does **not** automatically edit Questie, import all quests or guarantee accurate pins.

## Extract a specific quest

1. Keep the original \`acore_world.sql\` or \`acore_world.zip\` **outside the public repository** and make a private backup.
2. From a machine with Python 3, run:

\`\`\`bash
python3 tools/export_world_quests.py --world /private/acore_world.zip --quest 2001 --output review-2001.json
\`\`\`

For several verified quest IDs, repeat \`--quest\`:

\`\`\`bash
python3 tools/export_world_quests.py --world /private/acore_world.zip --quest 2001 --quest 30000 --output review-quests.json
\`\`\`

3. Inspect the JSON locally. Verify NPC IDs, objectives and prerequisites against the live server's actual rules. The script fails on unsupported gameobject quest starters/enders or gameobject objectives, negative prerequisites and missing NPC links.
4. **Only after review**, copy the safe, validated fields into \`Compat/NQuestieCustomQuestData.lua\` and increment its \`revision\`. Commit the **small curated Lua data file**, never the SQL ZIP or full generated raw extract.
5. Run \`python3 -m unittest discover -s tools -p 'test_export_world_quests.py'\` and \`lua5.1 tests/test_nquestie_overlay.lua\` locally where available. These do not replace WoW client tests.
6. Back up the installed Questie folder and account/character SavedVariables before testing. The revision change asks Questie to rebuild its compiled DB without wiping player preferences.

## Scope of this first exporter

Supported: quest title, min/quest level, race mask, flags, zone/sort, positive prerequisite, NPC quest starters/enders, and direct NPC kill-credit IDs/counts. The selected quest's original server source is authoritative for **its recorded values**, but runtime availability needs separate testing.

**Not yet automated:** mapping all raw AzerothCore world-space creature/gameobject spawn positions to 3.3.5a UI-zone map percentages, custom NPC creation, item/gameobject objectives, POI/scripts and server Individual Progression gating. Do not fabricate map coordinates or imply unsupported objectives are complete.

Next milestone: validate actual spawn-coordinate conversions and produce **reviewable Lua directly from the curated manifest** so future quests need only one safe command rather than hand-editing the small data file.

**Privacy:** The repository is public. The user approved publishing only curated quest IDs, names, links and coordinates needed for functionality. Keep the SQL export, server connection strings and unrelated data private.
